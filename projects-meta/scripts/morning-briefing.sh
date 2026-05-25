#!/bin/bash
# morning-briefing.sh — 毎朝 07:00 JST に ceo が朝ブリーフィング生成
# cron: 0 7 * * * /root/.claude/projects-meta/scripts/morning-briefing.sh >> /var/log/morning-briefing.log 2>&1
#
# 仕組み: claude headless + ceo agent
# 入力: 前日の night-patrol (03:00) + 当日の feedback-watcher (06:00) の出力
# 出力: obsidian-vault/50-Daily/briefings/YYYY-MM-DD.md

set -uo pipefail

DATE=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
HOUR=$(date +%H:%M)
VAULT_DIR="/root/projects/obsidian-vault"
TEMPLATE="${VAULT_DIR}/90-Templates/briefing-template.md"
OUT_DIR="${VAULT_DIR}/50-Daily/briefings"
OUTPUT="${OUT_DIR}/${DATE}.md"

# 前日夜の night-patrol + 当日朝の feedback-watcher を素材として参照
NIGHT_PATROL="${VAULT_DIR}/50-Daily/inspections/${YESTERDAY}.md"
FEEDBACK="${VAULT_DIR}/50-Daily/feedback/${DATE}.md"

mkdir -p "$OUT_DIR"

echo "[$(date)] morning-briefing start"

# ============================================================
# 素材ファイルの存在確認
# ============================================================
SOURCES=""
[[ -f "$NIGHT_PATROL" ]] && SOURCES+="\n- night-patrol: ${NIGHT_PATROL}"
[[ -f "$FEEDBACK" ]] && SOURCES+="\n- feedback-watcher: ${FEEDBACK}"
[[ -f "$TEMPLATE" ]] && SOURCES+="\n- template: ${TEMPLATE}"

# ============================================================
# claude headless を ceo agent として呼ぶ
# ============================================================
claude --print --agent ceo <<PROMPT > "$OUTPUT" 2>&1
今日 ${DATE} ${HOUR} の朝ブリーフィングを生成してくれ。

素材:${SOURCES}

手順:
1. 上記素材 (night-patrol + feedback-watcher + template) を読む
2. logic / en-chakai / agent-config / obsidian-vault の git log を前日分取得 (git -C /root/projects/<repo> log --since="${YESTERDAY}" --oneline)
3. Supabase MCP で DAU / 課金率の最新値取得（mcp__claude_ai_Supabase__execute_sql）
4. テンプレ (${TEMPLATE}) のフォーマットに沿って ${OUTPUT} に書き出す（この応答自体を md にする）

含めるべき項目:
- 前日の commit 一覧 (logic / en-chakai / agent-config / obsidian-vault)
- 完了タスク (kanban Done)
- 残課題 (持ち越し)
- 今日の推奨タスク Top 3 (理由付き + 担当 agent 指定)
- KPI スナップ (Logic DAU / 課金率 / クラッシュ率 / en-chakai 予約・訪問)
- night-patrol 結果サマリ (致命なら最優先で記載)
- feedback-watcher 結果サマリ (新着あれば朝枠アクションに)
- ceo からの戦略提案
- 林への申し送り (Keita に咀嚼して伝えるポイント)

中立的丁寧体 + 装飾記号 ** 使わない。
PROMPT

# ============================================================
# obsidian-vault に commit + push
# ============================================================
cd "$VAULT_DIR"
git add "50-Daily/briefings/${DATE}.md" 2>/dev/null || true

if git diff --cached --quiet; then
  echo "[$(date)] no changes to commit"
else
  git commit -m "briefing(${DATE}): morning briefing by ceo" || true
  git push origin main || echo "[$(date)] push failed, will retry next run"
fi

echo "[$(date)] morning-briefing done"
exit 0
