---
name: task-tracker-binary-corruption
description: TASK_TRACKER.md が grep バイナリ判定になると PDCA cron が無言で全停止する。起票系のバイト切詰めが原因になり得る
metadata: 
  node_type: memory
  type: reference
  originSessionId: 58a31444-f56f-413d-8501-ac93f1624ace
---

2026-07-23 事故: clipitnow-pdca-report.sh の `cut -c1-70` が VD-25 タイトルの UTF-8 文字をバイト境界で分断し、不正バイト＋行内改行が docs/TASK_TRACKER.md に混入。grep がファイルをバイナリ判定し、clipitnow-pdca-do.sh が「no TODO growth tasks」と誤報して 7/22〜23 の自動実行が停止した。

**兆候**: cron ログに `grep: ...: binary file matches` が混ざる／do.sh が TODO 存在時でも「nothing to do」。
**確認**: `file docs/TASK_TRACKER.md`（UTF-8 text であること）＋ `python3 -c "open(path,encoding='utf-8').read()"`。
**修正済み**: report.sh の切り詰めは `LC_ALL=C.UTF-8 awk '{print substr($0,1,70)}'`（文字単位）に変更（2026-07-23）。他の起票スクリプトで `cut -c` を見たら同じ穴を疑う。

関連: [[headless-tick-env-gotchas]]
