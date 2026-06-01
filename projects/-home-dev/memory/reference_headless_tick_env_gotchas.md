---
name: reference-headless-tick-env-gotchas
description: 無人自律ティック(headless 林)環境の2つの落とし穴：カスタム subagent が未登録・gh の GH_TOKEN が非対話シェルで未ロード
metadata: 
  node_type: memory
  type: reference
  originSessionId: 1bb37f25-d899-47a8-972e-e4b6bdc81be4
---

無人自律ティック（headless 林、`claude --print`）の実行環境で踏んだ2つの落とし穴（2026-05-31 観測、Vultr 新箱 /home/dev）。

1. **カスタム subagent（dev-logic / content-creator / designer 等）は Agent ツールに未登録。** 使えるのは built-in タイプのみ（claude / Explore / general-purpose / Plan / statusline-setup）。`subagent_type: 'content-creator'` は `Agent type not found` で失敗する。委譲は `general-purpose`（全ツール持ち）に、人格・役割をプロンプトで指定して投げる。[[feedback-delegate-dev]] の「林は実装を巻き取らない」は維持しつつ、委譲先は general-purpose 経由になる。

2. **`gh` は GH_TOKEN が無いと失敗する。** 非対話シェル（Bash ツール）は `~/.bashrc` を読まないので、`~/.bashrc` の `export GH_TOKEN=...` が効かず `gh auth login` を促されて EXIT 4。git push は SSH 鍵で通るが gh だけ落ちる。対処: `export GH_TOKEN="$(grep -E '^export GH_TOKEN=' ~/.bashrc | head -1 | sed -E 's/^export GH_TOKEN=//; s/^["'"'"']//; s/["'"'"']$//')"` で同一コマンド内にロードしてから `gh workflow run ...`。deploy（`gh workflow run deploy-production.yml -f confirm=yes`）の前に必須。

関連: [[project-autonomous-rin]]、[[reference-deploy-commands]]、[[feedback-delegate-dev]]
