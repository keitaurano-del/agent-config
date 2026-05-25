#!/bin/bash
# night-patrol.sh — 深夜 3:00 JST に Logic 本番 (Render) を巡回
# cron: 0 3 * * * /root/.claude/projects-meta/scripts/night-patrol.sh >> /var/log/night-patrol.log 2>&1

set -uo pipefail
# set -e は外す（異常検出時もレポート生成を続行するため）

DATE=$(date +%Y-%m-%d)
HOUR=$(date +%H:%M)
LOGIC_DIR="/root/projects/logic"
VAULT_DIR="/root/projects/obsidian-vault"
INSPECT_DIR="${VAULT_DIR}/50-Daily/inspections"
REPORT="${INSPECT_DIR}/${DATE}.md"
SCREENSHOT_DIR="${INSPECT_DIR}/screenshots/${DATE}"

mkdir -p "$INSPECT_DIR" "$SCREENSHOT_DIR"

echo "[$(date)] night-patrol start"

# ============================================================
# 1. ヘルスチェック
# ============================================================
echo "[$(date)] health check..."

FRONT_STATUS=$(curl -sf -o /dev/null -w "%{http_code}|%{time_total}" https://logic-u5wn.onrender.com/ 2>&1 || echo "ERR|0")
API_STATUS=$(curl -sf -o /dev/null -w "%{http_code}|%{time_total}" https://logic-u5wn.onrender.com/api/health 2>&1 || echo "ERR|0")

FRONT_CODE=$(echo "$FRONT_STATUS" | cut -d'|' -f1)
FRONT_TIME=$(echo "$FRONT_STATUS" | cut -d'|' -f2)
API_CODE=$(echo "$API_STATUS" | cut -d'|' -f1)
API_TIME=$(echo "$API_STATUS" | cut -d'|' -f2)

HEALTH_OK="yes"
[[ "$FRONT_CODE" != "200" ]] && HEALTH_OK="no"
[[ "$API_CODE" != "200" ]] && HEALTH_OK="no"

# ============================================================
# 2. Playwright スモーク
# ============================================================
echo "[$(date)] playwright smoke..."

cd "$LOGIC_DIR"
SMOKE_SPEC=$(ls -t e2e/render-smoke-*.spec.ts 2>/dev/null | head -1)
SMOKE_RESULT="skipped"
SMOKE_OUTPUT=""

if [[ -n "$SMOKE_SPEC" ]]; then
  if SMOKE_OUTPUT=$(npx playwright test "$SMOKE_SPEC" --config=playwright.render.config.ts --reporter=line 2>&1); then
    SMOKE_RESULT="pass"
  else
    SMOKE_RESULT="fail"
    # スクショを保存場所にコピー
    if [[ -d "test-results" ]]; then
      cp -r test-results/* "$SCREENSHOT_DIR/" 2>/dev/null || true
    fi
  fi
else
  SMOKE_OUTPUT="render-smoke-*.spec.ts が見つかりません"
fi

# ============================================================
# 3. 致命度判定
# ============================================================
SEVERITY="normal"
if [[ "$HEALTH_OK" == "no" ]]; then
  SEVERITY="critical"
elif [[ "$SMOKE_RESULT" == "fail" ]]; then
  SEVERITY="high"
fi

# ============================================================
# 4. レポート生成
# ============================================================
echo "[$(date)] generating report -> $REPORT"

cat > "$REPORT" <<EOF
---
date: ${DATE}
time: ${HOUR}
agent: night-patrol
severity: ${SEVERITY}
---

# Night Patrol ${DATE} ${HOUR}

## サマリ

| 項目 | 結果 |
|---|---|
| 致命度 | ${SEVERITY} |
| フロント (https://logic-u5wn.onrender.com/) | ${FRONT_CODE} (${FRONT_TIME}s) |
| API (/api/health) | ${API_CODE} (${API_TIME}s) |
| Playwright スモーク | ${SMOKE_RESULT} |

## ヘルスチェック詳細

- フロント HTTP コード: ${FRONT_CODE}
- フロント応答時間: ${FRONT_TIME} 秒
- API HTTP コード: ${API_CODE}
- API 応答時間: ${API_TIME} 秒

## Playwright スモーク詳細

\`\`\`
$(echo "$SMOKE_OUTPUT" | tail -50)
\`\`\`

## 翌朝対応

EOF

case "$SEVERITY" in
  critical)
    echo "- 致命: フロント or API が応答していない。Render ダッシュボード即確認、deploy 履歴 + ログ調査。" >> "$REPORT"
    ;;
  high)
    echo "- 高: スモークテストが失敗。Daily Note 翌朝枠に詳細追記して dev-logic に修正依頼。" >> "$REPORT"
    ;;
  normal)
    echo "- 正常: 巡回継続。次回は翌日 03:00。" >> "$REPORT"
    ;;
esac

cat >> "$REPORT" <<EOF

## スクショ

$(ls "$SCREENSHOT_DIR" 2>/dev/null | head -10 | sed 's|^|- screenshots/'"${DATE}"'/|' || echo "なし")

---

night-patrol agent 自動生成
EOF

# ============================================================
# 5. obsidian-vault に commit + push
# ============================================================
echo "[$(date)] git commit + push..."

cd "$VAULT_DIR"
git add "50-Daily/inspections/${DATE}.md" "50-Daily/inspections/screenshots/${DATE}/" 2>/dev/null || true

if git diff --cached --quiet; then
  echo "[$(date)] no changes to commit"
else
  git commit -m "night-patrol(${DATE}): ${SEVERITY}" || true
  git push origin main || echo "[$(date)] push failed, will retry next run"
fi

echo "[$(date)] night-patrol done (severity=${SEVERITY})"
exit 0
