---
name: reference-logic-notifications-not-stub
description: Logic の src/notifications.ts は CLAUDE.md gotcha #3 の記述と違い「スタブ」ではなく @capacitor/local-notifications の完全実装。reminder の localStorage キーは logic-reminder（logic-notifications は別物）。
metadata:
  type: reference
  originSessionId: autonomous-tick-2026-05-31
---

Logic（/home/dev/projects/logic）の通知まわりで、CLAUDE.md と台帳に古い/誤った記述があり、実装エージェントが under-scope する事故が起きやすい。2026-05-31 の DF-F8 実装で実際に1巡分の手戻りが出た。

**事実（実ソースで確認済み）:**
- `src/notifications.ts` は「スタブ」ではない。`@capacitor/local-notifications` の `LocalNotifications.schedule/cancel/getPending` を実際に呼ぶ完全実装（daily/streak/journal の3リマインダー）。Web は no-op、native のみ実発火。CLAUDE.md「Common gotchas」#3 の「src/sentry.ts と src/notifications.ts は stub」は **notifications.ts については誤り**（sentry.ts は実際スタブのまま）。
- reminder 時刻の localStorage キーは **`logic-reminder`**（`REMINDER_PREF_KEY`）。CLAUDE.md の localStorage 表と台帳が言う `logic-notifications`（string）は誤記。実体の `logic-notifications` は `src/Profile.tsx` の通知 on/off マスタートグル（`'on'`/`'off'`）であって reminder 時刻ではない。
- Capacitor の Weekday enum は 1 始まり・日曜=1（Sunday=1…Saturday=7、`node_modules/@capacitor/local-notifications` の型定義で確認）。アプリ内部の曜日配列は JS `getDay()` 準拠（0=日）なので +1 変換が要る。

**How to apply:**
- 通知系を触るタスクで「notifications.ts はスタブだから設定UIと永続化だけ」と早合点しない。設定値を実 native スケジュールまで結線するのが DoD（さもないと DF-F2 と同じ「コードはあるが実機で効かない」第3層になる）。
- reminder pref を読む/書くなら `logic-reminder` を使う。`logic-notifications` は別レイヤー。
- CLAUDE.md gotcha #3 と localStorage 表は将来クリーンに直す価値がある（別タスク。直すなら sentry.ts はスタブ・notifications.ts は実装、と分離して記述）。

**関連:** [[project-logic-mobile-only]]、[[reference-deploy-commands]]
