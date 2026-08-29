---
name: handoff-memo-can-be-empty
description: .terminal-handoff.md は生成失敗で実質空になることがある。src jsonl を直接読んで復元する
metadata: 
  node_type: memory
  type: reference
  originSessionId: 22f1767f-7197-45a5-8742-20d71bdb7f9d
---

`.terminal-handoff.md` は terminal-session-manager.sh の generate_handoff（`claude --print` + haiku）が要約でなく一行の相槌（例:「引き継ぎメモを保存しました ✅」）を返すと、ヘッダー＋その一行だけの実質空メモになる（2026-07-25 観測）。

対処: メモのヘッダー2行目の `src: <uuid>.jsonl` を見て `~/.claude/projects/-home-dev/<uuid>.jsonl` を直接パースし、末尾の user/assistant メッセージから文脈を復元する。tail -c でのバイト切りは UTF-8 分断で UnicodeDecodeError になるので、python で errors='replace' 指定か全文読みにする。

スクリプト側の恒久対策: **実装済み（2026-07-25）**。cron-scripts 版 generate_handoff に空メモガードを追加 — 出力が HANDOFF_MIN_LINES(5)行未満 or HANDOFF_MIN_CHARS(200)バイト未満なら失敗扱い、HANDOFF_RETRIES(2)回まで再試行、全滅なら旧メモ温存で return 1。HANDOFF_ONLY=1 モードの exit code バグ（FAILでも0）も同時修正。バックアップ: terminal-session-manager.sh.bak-before-empty-guard-20260725。稼働中インスタンス（旧コード）には次のマネージャ再起動まで反映されない点に注意。repo 版は 2026-07-26 に同期済み（cxo-agent commit 8b4ef76、空メモガード＋fable5化＋RIN_MODEL固定）。

ガードの限界（2026-07-26 観測）: 閾値 5行/200B は「要旨だけの薄いメモ」（3世代連続で発生）をすり抜ける。薄いメモを見たら src jsonl 直パースが引き続き必須。

4世代目（2026-07-27 08:46 生成分）はさらに悪化: セッション本体は文脈復元に成功していたのに、メモは「git リポジトリでない・タスク特定不可・Keita確認待ち」と実態と逆の内容を生成（行数・バイト数は閾値を満たすためガード通過）。長さチェックでは防げない実例 — 内容検証（対象ファイル名 or commit ID の含有チェック）が必要という判断材料。

関連: [[reference_handoff_premise_fabricated_2026-06-11]]（空とは別に、内容が捏造のケースもある — どちらにせよ着手前に実物裏取り）
