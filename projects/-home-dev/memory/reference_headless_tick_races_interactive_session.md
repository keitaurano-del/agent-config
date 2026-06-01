---
name: reference-headless-tick-races-interactive-session
description: ヘッドレス自律ティックは、同一リポで動く別の対話 claude セッションと競合しうる。flock は autonomous-rin 同士しか守らない。検知したら push/deploy は止める。
metadata: 
  node_type: memory
  type: reference
  originSessionId: 3761196c-5abb-43a0-bade-39441bf332c6
---

自律ティック（headless `claude --print`）は、同じリポで並行して動く「別の対話 claude セッション」と working tree / origin を取り合うことがある。flock(`/tmp/autonomous-rin.lock`) は autonomous-rin ティック同士の排他しか保証せず、独立した対話セッション（例: 4h 稼働の `claude` PID）には効かない。

**Why（2026-05-31 観測）:** AF-02（フェルミ Daily Fermi CTA 白ピル化）の自律ティック中に、別の生セッション(PID 154317, 約4h)が同一 Apollo 受信箱 id `6238b74a` を UI-27 として並行起票し、commit `1d09d9b` を origin/main に push していた。ティック冒頭の `git log` では HEAD=1cbc815 だったのが、コミット直前に HEAD=1d09d9b に変わり、working tree の TASK_TRACKER 差分に自分が書いていない UI-27 エントリが混入していた＝二重処理・同一 working tree 二重書き込みのサイン。

**継続観測（2026-05-31 後続ティック）:** 同一の対話セッション PID 154317 が5h超まだ生存（cwd=/home/dev/projects、ログインシェル -bash 配下＝オーケストレーターでなく独立）。logic working tree には AF-02/UI-27 の HomeScreenV3.tsx 視認性修正＋タスクID採番ドキュメント群＋スクショ再生成が uncommitted のまま残置（前ティックのハンドオフが未出荷）。過去30分の logic ファイル変更ゼロでアイドルだが、独立ライタが生きている以上 push/deploy/commit はしない判断を踏襲。単一ライタ窓（154317 終了後）まで出荷を見送る。

**How to apply:**
- 検知のサイン: (1) ティック中に `git log`/HEAD が勝手に進む、(2) `git diff HEAD` に自分が書いていない他者の未コミット編集が混ざる、(3) `ps -eo pid,etimes,cmd | grep claude` に自分以外の長寿命 claude がいる。
- 注入([[reference-tool-output-injection-incident]])と区別: bash の `grep`/`cat -A`/`git cat-file -t`/`git branch -r --contains` で実ファイル・実コミットを裏取りする。実在すれば「本物の並行」、実ファイルに無ければ「注入」。今回は実在＝本物の並行だった。
- 本物の並行を確認したら: push / deploy / commit / 台帳編集はしない（二重 push・二重 deploy・他者の未コミット編集巻き込みを回避）。自分の green な作業ファイルは uncommitted のまま安全ハンドオフ用に残し、受信箱 id は正直なノート付きで consumed 追記してヘッドレスループの再二重取りを防ぐ。
- 構造対策の候補（未実装・要 Keita 判断）: autonomous-rin の flock をリポ単位ロックに拡張し、対話セッション起動時にも同ロックを取らせる／対話林が実装着手時に inbox 該当 id を先に consumed する、等。

**関連:** [[project-autonomous-rin]]、[[project-vultr-second-server]]（二箱の二重 push 競合）、[[reference-tool-output-injection-incident]]、[[project-apollo-dashboard]]
