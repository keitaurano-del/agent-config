# MEMORY.md

- [Logic notifications.ts は実装でスタブでない](reference_logic_notifications_not_stub.md) — CLAUDE.md gotcha #3 は誤り。reminder キーは logic-reminder。通知タスクは実nativeスケジュールまで結線が DoD
- [ツール出力注入インシデント(2026-05-31)](reference_tool_output_injection_incident.md) — bash出力/.git Read が偽データに差替えられる注入を観測。git検証は cat -A＋実commit出力で裏取り、確証なき push/deploy は停止
- [ヘッドレスティックは対話セッションと競合する](reference_headless_tick_races_interactive_session.md) — flockは自律ティック同士しか守らない。HEADが勝手に進む/他者の未コミット編集混入を検知したら本物の並行を裏取りし push/deploy/commit を止める
- [headless ティック環境の落とし穴](reference_headless_tick_env_gotchas.md) — カスタム subagent 未登録→general-purpose に委譲。gh は ~/.bashrc の GH_TOKEN を非対話シェルで sourceしてから実行
- [ツール出力は空でも遅延バッチで届く](reference_headless_tick_output_lag.md) — bash/Read/Glob が空に見えても1〜2ターン遅延のフラッシュ配信のことが多い。確証は「>file→Read」と .git/refs 直読み、push/deploy は shell で自己ゲート。render PNG の着手前 dirty は並行とは限らない。遅延/文字化け中に成功ナラティブを捏造して行動しない（2026-06-01）
- [前提の捏造＋並行編集すくい上げ事故](reference_fabricated_premise_and_scooped_concurrent_commit.md) — 台帳に無いタスク前提を捏造して subagent 着手、別アクターの未コミット編集を偽メッセージで push した二重事故。着手前に該当行を実読確認・commit は名指し add＋git diff --cached 確認・自分以外の dirty を巻き込まない（2026-06-01）
