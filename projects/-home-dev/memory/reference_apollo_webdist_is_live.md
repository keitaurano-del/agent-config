---
name: apollo-webdist-is-live
description: cxo-agent の web/dist は本番配信実体 — 検証ビルドでも npm run build を repo 内で叩くと即本番反映される
metadata: 
  node_type: memory
  type: reference
  originSessionId: 61c7ff8a-df1e-40ce-aa0e-c24eaafa1c74
---

Apollo server（port 4317・tsx 常駐）は `express.static` で `cxo-agent/web/dist` をリクエスト毎にディスクから直接配信する。つまり `web/` で `npm run build` を実行した瞬間、その内容（未コミットの他者 WIP を含む）が本番に出る。restart 不要で即反映＝「ビルド＝デプロイ」。

2026-08-05 に検証目的のビルドで他者 WIP（BottomNav.tsx 等）混入バンドルを約5分間本番配信するインシデントを起こした（改善台帳に記録済み）。

**正しい手順**: 検証・デプロイとも `git worktree add /tmp/... HEAD` → `ln -s` で node_modules を共有 → worktree 内で build → `rsync -a --delete` で dist 差し替え → 配信バンドルのハッシュを curl（mc_token は `/proc/<pid>/environ` から取得可）で実確認。関連: [[headless-tick-races-interactive-session]]
