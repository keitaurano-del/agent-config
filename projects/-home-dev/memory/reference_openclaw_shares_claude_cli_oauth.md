---
name: reference_openclaw_shares_claude_cli_oauth
description: openclaw各TUIのanthropic認証はClaude Codeと同じclaude-cli OAuth creds共有。/login一発で全復旧、再開は新ターンで足りる
metadata: 
  node_type: memory
  type: reference
  originSessionId: 889db4bd-b3d4-4fd6-ab0a-3142a57c7054
---

openclaw の anthropic プロバイダ認証は `~/.openclaw/openclaw.json` の `auth.profiles."anthropic:claude-cli" = {provider: claude-cli, mode: oauth}`。実体は Claude Code と**同じ** `~/.claude/.credentials.json`（claude-cli OAuth）。

つまりトークン失効で openclaw-son/gateway 等が「auth or provider access failed for anthropic. Run /auth anthropic」でerror停止しても、**メインの Claude Code で `/login` すれば全 openclaw TUI の認証も同時に復旧**する（別途 `/auth anthropic` 不要）。creds mtime と expiresAt を実測して裏取り。

停止した TUI の**再開手順**: creds復旧後、TUIは新ターンを起こさないと古いerror表示のまま。`tmux send-keys -t <session> Enter` の空Enterでは発火しない → 実メッセージ（例「続けて」）を送ると creds を読み直して復旧。停止していたのが error 状態のセッションだけか各ペインの status 行（`local ready | error` vs `| idle`）で判別してから nudge する。idle は正常＝触らない。

2026-08-24 に handoff空(401)から復旧した際に確認。[[reference_handoff_memo_can_be_empty]]

**2026-08-26 恒久対策（Keita「再ログインを毎回やるのやめたい」）**: accessTokenは8h寿命＋更新でrefreshTokenがローテーション。走りっぱなしのopenclaw gatewayが古いトークンを握ったまま失効→"revoked"→8h毎に手動/loginが要る、が発端だった。Keita選択は「OAuth自動更新デーモン（追加費用なし）」。実装済み:
- `~/cron-scripts/claude-auth-keepalive.sh`（crontab `20 */2 * * *`）: `claude auth status`＋`claude -p PONG`でトークンを検証・失効時リフレッシュを誘発し常に有効化。creds mtimeが変わったら（refresh発生）`openclaw-nudge-errors.sh`でerrorペインを自動再開。refreshTokenまで死んで手動login必須の時だけ `notify-agent.sh rin` でKeitaに1日1回通知。ログ=`~/logs/claude-auth-keepalive.log`。
- `~/cron-scripts/openclaw-nudge-errors.sh`: status行が`| error`のopenclawペインだけ実メッセージで再開。idle/busy(streaming)は触らない。手動一括復旧コマンドとしても使える。
- これで通常の8h失効は自動自己回復。**別デバイス/claude.aiでログインして全トークンが外部revokeされた時だけ**手動/loginが残る（その時は通知が飛ぶ→/login後は自動再開）。API未設定＝完全OAuth依存は不変。

**2026-08-26 稼働初日に設計ギャップ発覚→先回りリフレッシュ追加**: 15:14 JSTの自然失効で再びrevoked→手動/login発生。ログで根因確定: claude CLIは期限が来るまでrefreshしないため、2h毎cronの`claude -p`は一度もrefreshを起こさず（expiresAt不変のまま「OK healthy」）、refreshは常に「失効の瞬間に走っていた並行プロセス（son等）」が実行することになる。refreshTokenは使い捨てなので失効境界で複数プロセスが同時にrefreshを試みると再利用検知でセッションごとrevoked。対策=keepaliveに「残り2.5hを切ったらexpiresAtを過去に書き換えて直後のclaude -pに静かな時間帯でrefreshさせる」を追加（閾値2.5h>cron間隔2hで失効前に必ず1回発火。旧accessTokenは自然期限まで有効なので並行プロセス無影響）。ログに「forcing early refresh」が出て以後expiresAtが伸びていれば正常動作。

**2026-08-27 また失効→backdate poisoning バグ発覚→hardening**: 18:20 JSTに再びrevoked→Son停止→Keita手動/login。ログで16:20の1回だけ`forcing early refresh`が出たのに`credentials refreshed`が出ず（=backdateだけ書かれ実refreshが永続化しなかった）。旧accessTokenは真の期限18:20まで有効なのでPONGは通り「healthy」誤判定→過去日時のexpiresAtがファイルに残り（poisoning）真の失効まで気づけなかった。16:20はSonが実タスク中でbackdateの強制refreshがレースした可能性大。hardening4点を実装（`.bak-before-hardening-20260827`退避）: (A)backdate前に本来のexpiresAtを退避し、健全性チェック後に「実refreshが着地したか=新expiresAtが現在+1hより未来か」を検証、着地してなければ退避値へ復元してpoisoning防止・次cronで再挑戦。(B)先回り閾値2.5h→4h前倒し（エージェント自身の失効境界から遠い時刻に単独refreshさせレース回避）。(C)cron間隔2h→1h（`20 * * * *`、1トークン周期で最大4回の再挑戦機会）。(D)flockで自身の多重起動排他。ログの`WARN forced refresh did NOT persist; restored original expiresAt`が復元発火の印。**まだ残る構造リスク**=全プロセスが1個のOAuth creds共有＝並行refreshレースの根絶にはエージェント毎に別OAuthプロファイル分離が要る（未実装・Keita判断待ちの大対策）。

**2026-08-28 hardening後も再発→revoke機構が完全判明→対策E/F追加**: 06:20の強制refreshが「サーバ側では成功（refreshToken消費）・ファイル永続化だけレースで消失」→対策Aの復元はexpiresAtしか戻せず「消費済みrefreshToken」がファイルに残存→07:20の再backdateが使用済みトークンでrefreshを叩き**再利用検知でトークンファミリーごと即revoke**→13h停止・手動/login。つまり永続化失敗が起きた時点でそのトークン系は詰み（/login不可避）で、再試行はrevokeを前倒しするだけ。対策E=非永続化を検知したトークン(expiresAt記録=`~/.claude-auth-keepalive.noforce`)には二度とbackdateしない（自然refreshに任せ延命）。対策F=非永続化検知の瞬間にKeitaへ即通知（従来はrevoke後まで沈黙5h）→先回り/loginで停止窓を最小化。`.bak-before-noforce-20260828`退避・実走green。**hardeningで縮められるのはここまで**＝共有1ファイルの限界。根絶は下記の認証分離のみ。

**2026-08-27 分離アーキの調査完了（openclaw 2026.6.1 ソース実測）**: 「openclawがbackendにエージェントIDを渡せるか」= **YES**。①`prepare.runtime`が`OPENCLAW_MCP_AGENT_ID=<sessionAgentId>`をCLI子プロセスenvに必ず注入（claude-cli backendは`bundleMcp: true`・現に`--allowedTools mcp__openclaw__*`でloopback稼働中）②env構築順は「clearEnvで`CLAUDE_CONFIG_DIR`等を除去→backend.env→preparedBackend.env(AGENT_ID含む)」なのでwrapperがexec前にsetすれば通る③per-agentの`AgentConfig`型に`cliBackends`は無い（`AgentDefaultsConfig`のみ）＝config単独のper-agent分離は不可でwrapper方式が正解。**実装済(未配線)**: `~/cron-scripts/claude-cli-agent-wrapper.sh`——AGENT_ID(なければworkspace PWD推定)で`~/.claude-agents/<id>/`が存在する時だけCLAUDE_CONFIG_DIRを向ける完全後方互換（dir未作成なら共有~/.claude続行）。テスト3種green。**残り(Keita操作/判断)**: (a)エージェント毎ブラウザOAuth login=`CLAUDE_CONFIG_DIR=~/.claude-agents/<id> claude /login`（対象候補: main/son/yui/haru。kimiはmoonshotで対象外）(b)openclaw.jsonの`agents.defaults.cliBackends["claude-cli"].command`をwrapper絶対パスに差替え+gateway reload（稼働中son一瞬停止リスク→タイミングはKeita判断）(c)分離後はkeepaliveの複数dir対応（~/.claude-agents/*を各々監視）を配線と同時に実装予定。

**2026-08-29 対策Eに封印バグ発覚→修正（結果は自動復旧の結果オーライ）**: 06:20 強制refresh非永続化→E/F設計通り作動（NOFORCE flag set＋Keita早期通知）。しかし07:20のskip実行で `REFRESH_LANDED` が「新expiresAtが現在+1hより未来」**だけ**で真になる誤判定（残り~2hのskip時は refresh してなくても真）→L152の「着地したらflag不要」でNOFORCE flagを誤削除→08:20に封印が破れ再backdate強行→**refreshが成功**しexpiresAt 8h延伸・自動復旧（/login不要だった）。判明事項2つ: ①「非永続化=refreshToken消費済み」は常に真ではない（8/28は消費済み→revoke連鎖、8/29は未消費→成功。非永続化検知時にどちらかは事前判別不能なので封印方針自体は維持が正）②flagの実パスは各dirの `$DIR/.keepalive-noforce`（旧記述 `~/.claude-auth-keepalive.noforce` は複数dir化前の名残・誤り）。**修正済(8/29)**: REFRESH_LANDED判定に「NEW_EXP > ORIG_EXP（run開始時より延伸）」を追加し実refreshのみ真に。退避=`claude-auth-keepalive.sh.bak-before-landed-fix-20260829`・bash -n green・次cron(毎時20分)から有効。

**8/29夜(23:20)**: 非永続化がまた再発（今月4回目）→対策E/Fは修正後初の実戦で設計通り作動（封印set・即時通知・誤削除なし）→Keita /login(23:22)→openclaw-nudge-errors.sh手動実行でson復旧（error→streaming）。NOFORCEフラグはL79の「保存expiresAt≠現在値なら自動削除」で次cronに自動解消＝ログイン後の手動掃除は不要。非永続化の頻発はhardeningの限界を再確認＝根絶は認証分離（per-agent login 2件＋reload GO、Keitaゲート）のみ。

8/29深夜: per-agentログイン2件完了（son 23:32:47/main 23:33:04・別グラント・~/.claude-agents/{son,main}/.credentials.json）。keepaliveは23:33以降 [agent:main]/[agent:son] を自動認識しhealthy継続。認証分離の残りは gateway reload のみ（配線=openclaw.json:11→wrapper済・林が実行・Son一瞬停止のためタイミングだけKeita判断）。注意: バックグラウンド起動のloginは「exit 144失敗」に見えてもKeita認可で成功しうる=credentials mtime+expiresAt逆算で先に確認。

**8/30 04:21-04:31 認証分離が本番発効（完了）**: Keita GO→gateway reload実施。だが**CLI spawn元はgatewayでなく各TUI（openclaw-tui, local mode）**＝pane footer「local ready」のとおりTUIがopenclaw.jsonを起動時読込してclaude CLIを直接spawnする（実測: claude procのppid=TUI）。config差替え前(8/26)起動のTUIはstale in-memory configでwrapper無効→**terminal-rescue.sh restart-{masayoshi,son,kimi} でTUI 3本再起動が発効の本体**。発効証跡=~/logs/claude-cli-agent-wrapper.log に agent=main/son の config_dir 切替行＋per-agent dirへの.claude.json/sessions実書込。落とし穴2つ: ①TUI再起動直後の旧セッションresumeは新config dirにtranscriptが無く「run error: Claude CLI failed→CLI session cleared」（1回限り・実メッセージ再送で新規セッション復旧）②openclawのtranscript probeは`~/.claude/projects`固定参照（resolveClaudeCliProjectDirForWorkspaceがhomeDir基準・CLAUDE_CONFIG_DIR非対応）→probe missでセッション未登録＝毎ターンuseResume=false（Son記憶喪失）。**解=per-agentの`projects/`を`~/.claude/projects`へのsymlink化**（分離すべきは.credentials.jsonだけ・transcriptは共有で無害）。symlink後 useResume=true・Sonが前ターン内容を正答し文脈保持実証。旧dirは projects.pre-symlink-20260830 に退避。kimiはdir未作成＝共有 ~/.claude 続行（設計通りの後方互換）。これで今月4度のrefreshレースの構造的根絶が完成。
