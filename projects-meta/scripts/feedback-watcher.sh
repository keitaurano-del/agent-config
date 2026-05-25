#!/bin/bash
# feedback-watcher.sh — 毎朝 06:00 JST に Supabase reports / feedback を polling
# cron: 0 6 * * * /root/.claude/projects-meta/scripts/feedback-watcher.sh >> /var/log/feedback-watcher.log 2>&1
#
# Phase 1: claude headless + MCP Supabase で取得（API key 不要、OAuth 経由）
# Phase 2: 直接 curl + service_role key にすると高速化可能

set -uo pipefail

DATE=$(date +%Y-%m-%d)
HOUR=$(date +%H:%M)
VAULT_DIR="/root/projects/obsidian-vault"
OUT_DIR="${VAULT_DIR}/50-Daily/feedback"
OUTPUT="${OUT_DIR}/${DATE}.md"

mkdir -p "$OUT_DIR"

echo "[$(date)] feedback-watcher start"

# ============================================================
# claude headless を feedback-watcher agent として呼ぶ
# ============================================================
claude --print --agent feedback-watcher <<PROMPT > "$OUTPUT" 2>&1
今日 ${DATE} ${HOUR} のフィードバック巡回を実行する。

手順:
1. Supabase MCP で reports テーブルの直近 24h の新着を取得
   - mcp__claude_ai_Supabase__execute_sql に: SELECT * FROM public.reports WHERE created_at >= NOW() - INTERVAL '24 hours' ORDER BY created_at DESC;
2. 同じく feedback テーブルの直近 24h を取得
   - SELECT * FROM public.feedback WHERE created_at >= NOW() - INTERVAL '24 hours' ORDER BY created_at DESC;
3. 結果を以下のフォーマットで出力（このメッセージへの応答そのものをファイル化する）

---
date: ${DATE}
time: ${HOUR}
agent: feedback-watcher
---

# Feedback Watcher ${DATE} ${HOUR}

## サマリ
- reports 新着: N 件
- feedback 新着: N 件
- 致命度: normal | needs_attention | critical

## reports 新着詳細
（件数 0 なら「新着なし」と記載）

| id | lesson_id | issue_type | comment 抜粋 | created_at |
|---|---|---|---|---|
| ... |

## feedback 新着詳細
（件数 0 なら「新着なし」と記載）

| id | category | message 抜粋 | created_at |
|---|---|---|---|
| ... |

## 重複テーマ検出
- 過去 7 日の同種報告クラスタリング結果

## アクション推奨
- 即対応: 0 件 / 〜
- GitHub Issue 化推奨: 0 件 / 〜
- dev-logic 委譲推奨: 0 件 / 〜

## 朝ブリ統合用
- ceo 朝ブリーフィングが 07:00 に拾う想定の要約（3 行以内）
PROMPT

# ============================================================
# obsidian-vault に commit + push
# ============================================================
cd "$VAULT_DIR"
git add "50-Daily/feedback/${DATE}.md" 2>/dev/null || true

if git diff --cached --quiet; then
  echo "[$(date)] no changes to commit"
else
  git commit -m "feedback(${DATE}): daily snapshot" || true
  git push origin main || echo "[$(date)] push failed, will retry next run"
fi

echo "[$(date)] feedback-watcher done"
exit 0
