---
name: session-cleanup-killed-cowork
description: session-cleanup.sh の /claude/ 誤爆で Cowork chromium が停止した事故（2026-08-01 修正済）
metadata: 
  node_type: memory
  type: reference
  originSessionId: b40b2e63-75bc-4984-a97a-6815c69e2055
---

2026-08-01 02:00、`~/cron-scripts/session-cleanup.sh`（2時間おきcron）の抽出パターン `/[c]laude/` が、パスに claude を含む無関係プロセス（`~/.openclaw/claude-browser/` の Cowork ブラウザスタック＝MC-350）まで reap し、apollo-claude-chromium が約9時間停止した。x11vnc は Restart=always で復帰するが chromium は SIGTERM=正常終了扱いで Restart=on-failure が発火せず死んだままになる。

同日修正済み: `$3 ~ /(^|\/)claude$/` でコマンド本体が claude の場合のみ対象に（バックアップ `session-cleanup.sh.bak.cowork-guard-20260801`）。

**診断の手がかり:** 「Cowork がまた止まった」ときは (1) `systemctl status apollo-claude-chromium`（inactive dead の停止時刻が偶数時ちょうどなら cron 誤爆系を疑う） (2) `~/logs/session-cleanup.log` の reap 行と journal の PID 突合 (3) 復旧は `sudo systemctl start apollo-claude-chromium`（プロファイル永続なのでログインは残る）。バックアップから旧版が復元されると再発する点にも注意。
