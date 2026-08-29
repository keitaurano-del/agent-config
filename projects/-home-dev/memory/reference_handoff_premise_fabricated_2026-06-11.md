---
name: reference_handoff_premise_fabricated_2026-06-11
description: .terminal-handoff.md が実在しない commit/ファイル/staging を前提化していた事故。handoff は着手前に git で全数裏取り
metadata: 
  node_type: memory
  type: reference
  originSessionId: 80c1f1fe-c9bd-4f82-ab1f-7298b176f207
---

2026-06-11、`/home/dev/.terminal-handoff.md` が「NUL制御バイト修正タスク最終段＝5ファイル staging 済み、コミット作成が次の一手」と記述。だが `projects/logic` 実状態は全面矛盾：staging 空、対象 `src/utils/utils.ts`・`src/constant/constant.ts` は不在、`src/components/*/Logic*.tsx` も該当無し、src 配下に生制御バイト0件、参照 commit `bce37b2`/`cdc8bbb`/`2e740bf` は全て `git cat-file` で MISSING。handoff の前提は捏造/陳腐で、指示どおりコミットすれば捏造の追認になるところだった。

**Why:** handoff メモ自体が注入/陳腐化の媒体になりうる。記述を信じて commit/push すると偽成果を生む。

**How to apply:** handoff から再開する時は着手前に必ず git で全数裏取り（HEAD・`git status`・`git diff --cached`・参照 commit を `git cat-file -t`・対象ファイルの実在・実際の差分内容）。1つでも不一致なら作業せず Keita に矛盾を報告して停止。確証なき commit/push は禁止。[[reference_fabricated_premise_and_scooped_concurrent_commit]] [[reference_tool_output_injection_incident]]
