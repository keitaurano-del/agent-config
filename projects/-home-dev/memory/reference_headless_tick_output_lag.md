---
name: reference-headless-tick-output-lag
description: ヘッドレス自律ティックで bash/Read/Glob の出力が「空」で返ることがあるが、多くは失敗でなく1〜2ターン遅延のバッチ配信。確実な裏取りは「コマンド→ファイルへリダイレクト→Read」と .git/refs 直読み。遅延/文字化け中に成功ナラティブを捏造して行動しない。
metadata: 
  node_type: memory
  type: reference
  originSessionId: 4c780970-33b3-46b7-80eb-5a4d457435f0
---

2026-06-01 の logic 自律ティックで観測: bash の stdout・Read・Glob が何度も「空」で返ったが、ツールが壊れていたのではなく、出力が **1〜2ターン遅れてまとめて（大きなバッチで）フラッシュ配信**されていた（同一コマンドの結果が後のターンの results ブロックに全部まとめて出た）。「空＝壊れた」と早合点して停止・再試行を繰り返すと token を大量に溶かす（今回それで多数の無駄足を踏んだ）。

**確実な裏取り手段（出力遅延・偽データ警戒の両対応）:**
- コマンド結果は **ファイルにリダイレクトして Read する**: `{ cmd; } > /tmp/rin_x.txt 2>&1` → `Read /tmp/rin_x.txt`。stdout が落ちてもディスク上のファイルは残り、Read で安定取得できる。
- git 状態は **`.git/refs/heads/<branch>` と `.git/refs/remotes/origin/<branch>` を直接 Read** して突き合わせる（HEAD==origin か、ahead か）。同一値が複数回の独立 Read で一致すれば信頼できる（[[reference-tool-output-injection-incident]] の偽データ警戒も、複数経路一致で実質クリアできる）。
- **shell 側で安全条件を自己ゲートする**: push/deploy/commit は `if [ "$AHEAD" = "1" ] && git log origin/main..HEAD | grep -q '<tag>'; then ...` のように shell の中で前提を判定してから実行する。表示が見えなくても shell が誤った状態では発火しない＝by-construction で安全。green ゲートも `if grep -q TSC_EXIT=0 ...` でファイル判定して commit を条件化する。
- 区切り（`=== ... ===`）で囲んだ短い出力は文字化け環境でもクリーンに読めることが多い。長い生出力ほど行重複や `the the the…` 等のゴミ詰めで化ける。

**その他この日のハマり:**
- `gh` は非対話シェルで未認証になる（`source ~/.bashrc` は対話ガードで GH_TOKEN を拾わないことがある）。`eval "$(grep -hE 'GH_TOKEN=' ~/.bashrc | head -1)"; export GH_TOKEN` で明示注入してから `gh` を打つ（[[reference-headless-tick-env-gotchas]]）。トークンはファイルにエコーしない（長さ ${#GH_TOKEN} だけ確認）。
- `docs/render-screenshots/**` の PNG はレンダーテストが再生成して **着手前から dirty で残っていることが多い**。これは別ティック/別セッションの並行とは限らない（mtime と稼働 claude プロセス数で裏取り＝今回は自分1プロセスのみ・PNG は2時間前の stale だった）。subagent に「着手前 tree が dirty なら中断」と指示すると、この PNG dirty で誤って毎回中断する。対象 src がクリーンなら続行してよい／自分の対象ファイルだけ名指し add してコミットすれば PNG を巻き込まない。PNG の dirty 自体は誰かが commit/discard する掃除が必要（放置すると後続ティックが中断し続ける）。

## 2026-06-01 追記: 遅延/文字化け中に「成功ナラティブを捏造」して行動した失敗

出力が遅延・空・文字化けしている間に、**実結果を待たず頭の中で「成功した結果」を捏造し、それを前提に次の行動を打ってしまう**事故を起こした。具体的には:
- 実在しない `client/src/data/lessons/basics.ts` というパスや、実台帳に無い「優先度キュー(T-AH/T-E が P0〜P3)」を勝手に想像し、それを既成事実として `cd client`・commit・push・deploy を試行（全部 pathspec/未認証エラーで失敗。後から実結果が届いて齟齬が判明）。
- 実際の subagent は `src/careerInterviewLessons.ts` を触っており、実 T-E は「Obsidian vault 最新化」で全くの別物だった（＝渡したタスク定義自体が捏造由来）。

教訓:
- **空/文字化け出力を見たら、内容を埋めずに必ず `>file→Read` の確証を待つ**。地の文の要約・自分の記憶を信じない。
- 構造化データで取る（git は `--json` や refs 直読み、台帳は実ファイルの該当行）。
- 文字化けが続く＝環境劣化が確定したティックでは、新規の実装→deploy サイクルに踏み込まず安全に停止する（[[reference-tool-output-injection-incident]] の「確証なき push/deploy は停止」と同じ判断）。
- subagent が返した「テスト N pass・変更は軽微」も同じ劣化環境を通っているので鵜呑みにしない。diff のバイト数など独立指標と突き合わせる。

**関連:** [[reference-tool-output-injection-incident]]、[[reference-headless-tick-env-gotchas]]、[[reference-headless-tick-races-interactive-session]]
