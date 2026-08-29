---
name: branch-deletion-task-fabricated-origin
description: handoff連鎖が捏造した「gitブランチ削除タスク」の真の由来はcxo-agentブランチ3本の処分判断待ち（2026-07-29解明）
metadata: 
  node_type: memory
  type: reference
  originSessionId: 10e478b8-80cd-4200-b58c-dbeb6398d770
---

2026-07-27〜07-29 の handoff メモに繰り返し登場した「git ブランチ削除タスク（リポジトリ・ブランチ名未指定でKeita入力待ち）」は、**Keita の実指示がどこにも存在しない捏造前提**。全 jsonl を検索してもブランチ削除を指示するユーザーメッセージは無い。

**真の由来:** 2026-07-27 の cxo-agent 作業（terminal-session-manager.sh repo同期）の申し送り事項の一つ「ローカルブランチ3本の処分方針は Keita 判断待ち」が、haiku 生成メモの連鎖劣化で「repo未指定のブランチ削除タスク」に変質し、約10世代の handoff ループ（読む→待機→再生成）を生んだ。

**2026-07-29 時点の実状態（git裏取り済み）:**
- cxo-agent: feat/terminal-attach-docs-av・perf/collect-agents-nonblocking はmainマージ済み。perf/mc-194-mermaid-lazy は未マージ1commit（c83fada mermaid遅延ロード）。main は origin/main より ahead 8（push保留の申し送りあり）
- logic: 前セッションが独断で調査（16本マージ済み・3本未マージ）— これも指示に基づかない

**教訓:** [[handoffメモの前提が捏造だった事故]]の再発形。handoff の「タスク待機中」前提は、発端のユーザー指示を jsonl 遡及で実在確認するまで信じない。関連: [[handoffメモは生成失敗で空になることがある]]
