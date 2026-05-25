# Memory Separation

エージェント別メモリ分離の運用方針。

最終更新: 2026-05-25
策定: ceo + 林（rin）

---

## 概要

これまで全 agent 共通の `memory/` 一階層だったメモリを、共通 + agent 別に二階層化した。

### 動機

- 各 agent が起動時に自分専用メモリだけロードできる（コンテキスト効率化）
- agent ごとに専門知見が蓄積される
- 共通メモリは引き続き全 agent から参照可能（前提情報として）

---

## ディレクトリ構造

```
~/.claude/projects/-root-projects/memory/
├── MEMORY.md                          # 共通インデックス
├── feedback_*.md                      # 共通 feedback memory
├── project_*.md                       # 共通 project memory
├── reference_*.md                     # 共通 reference memory
└── agents/                            # agent 別 memory
    ├── ceo/                           # 戦略 / KPI / 横断判断
    ├── dev-logic/                     # Logic 実装知見
    ├── designer/                      # Figma / Gemini / サムネ
    ├── content-creator/               # レッスン本文ノウハウ
    ├── marketing/                     # マーケ / ASO / SNS
    ├── secretary/                     # Calendar / メール
    ├── reviewer/                      # 品質保証パターン
    ├── test-smoke/                    # スモーク失敗パターン
    ├── test-sanity/                   # happy path シナリオ
    ├── test-functional/               # end-to-end シナリオ
    ├── test-unit/                     # テストパターン
    └── hayashi-rin/                   # 林本体（メインアシスタント）
```

---

## 共通 vs agent 別の振り分けルール

### 共通メモリに置くもの

複数 agent が参照する必要がある前提情報:

- アシスタント名・口調（林本体だが、全 agent が「林という上位がいる」前提を持つ）
- プロジェクトのリブランド情報（en-chakai 等）
- 全 agent 共通の制約（Pixa 不使用、cxo-agent 不使用、Markdown 装飾控えめ）
- agent 体制全体の構成情報（subagent cleanup）
- 共通インフラ情報（agent-config 同期）
- アプリ UI 文言ルール（複数 agent がアプリに関わるため）

### agent 別メモリに置くもの

特定 agent が主に使う専門知見:

- ceo: KPI 設計、Metabase、戦略判断履歴
- dev-logic: Logic 実装ノウハウ、Play Billing、Render、Android デプロイ
- designer: Figma、Gemini プロンプト、サムネスタイル
- content-creator: レッスン執筆、カテゴリ別前提データ
- marketing: マーケ NG ルール、競合分析
- reviewer: レビュー指摘パターン、セキュリティチェックリスト
- test-*: 失敗パターン、シナリオ集

### 両方に置く（重複 OK）

agent 別と共通の両方で参照される頻度が高いものは、両方に置く:

- `feedback_app_copy_neutral.md` → 共通 + content-creator / reviewer / test-functional / hayashi-rin
- `project_logic_mobile_only.md` → 共通 + ceo / dev-logic / content-creator / marketing
- `feedback_logic_course_thumbnails.md` → 共通 + designer / content-creator

重複の同期は将来課題（cron で差分検知 → 警告等）。当面は手動で両方更新。

---

## agent 起動時の読み込み

各 agent.md に「メモリ」セクションで自分専用メモリパスを明記済み:

```markdown
## メモリ

<agent名> 専用メモリ: `~/.claude/projects/-root-projects/memory/agents/<agent名>/`
- 何が入っているかの説明

共通メモリ: `~/.claude/projects/-root-projects/memory/`（全 agent 共通の前提）
```

agent は両方を参照する。専用が優先、衝突時は専用ルール。

---

## 新規 memory 追加時の判断フロー

```
新規メモを書く
  ↓
誰が使う？
  ├─ 複数 agent → 共通 memory に追加
  ├─ 1 agent 専用 → agents/<name>/ に追加
  └─ 複数 agent + 1 agent 専用知見 → 両方に追加
  ↓
MEMORY.md（共通 index）に追記（共通の場合のみ）
  ↓
agent-config repo に commit + push
  ↓
sync-claude-config.sh で全 sub-repo に反映
```

---

## 同期方針

agent-config repo の `projects/-root-projects/memory/` を master とする。

sub-repo の `.claude/memory/` には共通 memory のみコピー（agent 別 memory は agent-config 内に閉じる）。

理由: sub-repo はプロジェクト固有のコード repo なので、全 agent 別 memory を同期する必要がない。agent 別 memory は agent が起動するクラウド環境（agent-config 同期先）で持っていれば足りる。

---

## 移行履歴

### 2026-05-25 初版

- agents/ サブディレクトリ作成（11 agent + hayashi-rin）
- 既存共通 memory を関連 agent サブディレクトリにコピー（重複 OK、元は共通に残す）
- 各 agent.md にメモリセクション追加

---

## 今後の改善

- 重複 memory の同期検知（cron で diff チェック）
- memory の使用頻度ログ（どの memory が実際に参照されたか）
- 古い memory の自動 archive
- `memory/error_patterns/` `memory/success_patterns/` の追加検討（AGENT_GROWTH_STRATEGY 参照）
- 林専用 memory `memory/agents/hayashi-rin/` の充実

---

## 関連ドキュメント

- `~/.claude/projects-meta/CLAUDE.md` — agent-config master
- `~/.claude/projects-meta/docs/AGENT_GROWTH_STRATEGY.md` — 中長期戦略
- `~/.claude/projects-meta/docs/MORNING_BRIEFING_RUNBOOK.md` — 朝ブリーフィング
- `~/.claude/projects/-root-projects/memory/MEMORY.md` — 共通 memory インデックス
