---
name: openclaw Anthropic OAuth セットアップ済み
description: openclaw の Anthropic provider が Claude.ai プラン OAuth で認証されている状態。env var の API キーは削除済み。
type: project
originSessionId: dd295a05-e465-465b-9e20-25be9f193e21
---
openclaw の Anthropic provider 認証は **Claude.ai プラン OAuth** に切り替え済み（2026-05-10 セットアップ）。
`auth-profiles.json` に `anthropic:claude-cli=OAuth` プロファイルが登録され、`effective.kind: "profiles"` で env var より優先される。`/root/.bashrc` の `ANTHROPIC_API_KEY` export は削除済み。

**Why:** Pro/Max プランの OAuth 経由で opus-4-7 / sonnet-4-6 等の上位モデルにアクセスできるようにするため。API キー従量課金から OAuth プラン定額への移行。

**How to apply:**
- openclaw 経由の推論が `Unknown provider` 系で落ちたら、`openclaw plugins registry --refresh` を最初に試す（registry stale が頻出）
- `claude-cli` は **provider ID ではなく CLI backend ID / synthetic auth ref**。auth login コマンドには `--provider anthropic` を渡し、interactive 選択肢で "Anthropic Claude CLI"（choiceId: `anthropic-cli`）を選ぶ
- OAuth ログインの前段に `claude auth login --claudeai` で Claude CLI 自体の OAuth が必要（credentials.json に `claudeAiOauth` キーが入る）
- デフォルトモデルは `anthropic/claude-sonnet-4-6`、aliases に `opus`/`sonnet` あり
- env var を再追加すると effective が profiles から env に戻る可能性あり（現状は profiles 優先）
