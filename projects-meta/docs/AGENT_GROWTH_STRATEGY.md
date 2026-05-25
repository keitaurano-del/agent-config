# AGENT_GROWTH_STRATEGY.md

林（メイン）+ subagent 群の中長期成長戦略。
Keita が「来週どこから手をつけるか」を一発で判断できる粒度でまとめる。

最終更新: 2026-05-24
策定: 林（rin）
承認者: Keita

---

## 1. 現状評価（2026-05-24 時点）

### 1.1 構成サマリ

メイン: 林（おじいちゃん口調、Keita と直接対話する相棒、subagent オーケストレーター）
subagent 7 体:

| agent | 立ち位置 | 主担当 | 直近の使用頻度感 |
|---|---|---|---|
| ceo | 戦略・横断レポート・優先順位提示 | プロジェクト横断 | 低（明示依頼時のみ） |
| secretary | スケジュール・メール・リマインダー | 日常運用 | 低（gcalcli 未確認、出番少） |
| dev-logic | Logic コード・ビルド・デプロイ | logic | 高（Phase 1〜2 の主力） |
| marketing | SNS・ブログ・コピー | logic / en-chakai | 中（リリース告知のみ） |
| designer | サムネ・ビジュアル・Figma | logic（コースサムネ）/ en-chakai | 中（コースサムネ v3 で活躍） |
| content-creator | レッスン教材本体 | logic | 高（Phase 1 認知科学コース以降フル稼働） |
| reviewer | 独立品質保証 | 横断 | 中（dev-logic 成果物の最終確認） |

注: CLAUDE.md の memory「project_agent_cleanup_20260511.md」では 5 体構成と記載されているが、その後 reviewer（2026-05-22）と content-creator（2026-05-22）が追加され実態は 7 体。メモ更新が必要。

### 1.2 強み・弱み・隙間

強い領域:
- Logic 開発の上流〜下流（content-creator → dev-logic → reviewer）はサイクル成立済み
- ビジュアル系（designer + Figma + 手書きスタイル）はスタイル確立済み

弱い領域・隙間:
- 数値分析（PostHog / Metabase / Stripe ダッシュボード等）の専任不在 → ceo が兼務している状態だが本格的な集計はやれてない
- ユーザーサポート（問い合わせ対応・FAQ 整備）不在 → 現状ユーザー数が少ないため顕在化していないだけ
- 法務・規約系（利用規約・プライバシーポリシー）不在 → Logic 1.0.0 リリース済みだが定期見直しの主体がいない
- secretary が「メール下書きのみ・送信しない」制約と Gmail MCP のフル権限がギャップ。Gmail/GCal の自動化が機能していない

重複懸念:
- ceo と林の役割分担が曖昧。林がオーケストレーターで ceo が戦略助言だが、Keita との一次窓口は林一本で良いはず。ceo は「林がレビューに使う第二の戦略視点」と位置づけ直し推奨
- marketing と content-creator の境界。レッスンコンテンツの引用ツイート文等が両者にまたがる可能性 → 暫定で「アプリ内コンテンツは content-creator、対外発信は marketing」と明文化

### 1.3 林の役割評価

良い:
- Keita 全権委任の判断軸を理解、push 承認の閾値を共有
- おじいちゃん口調が確立、Keita との対話に温度感あり
- subagent への発注（タスク分解 + 依頼文作成）はできている

改善余地:
- 林が subagent を呼ばずに自分で全部やってしまうケースがある（特に小さめタスク）→ 専門性を活かしきれていない
- subagent 同士の連携（例: content-creator → reviewer → dev-logic）を林が逐次仲介する構造で、林がボトルネック化する余地あり
- 林自身のメモリ・学習ログが ad-hoc。何が成功・失敗パターンか体系化されていない

---

## 2. 成長フェーズ定義

### Phase 1（現状〜1 ヶ月: 2026-05〜2026-06）

テーマ: 安定運用、衝突回避、メモリ整理

具体施策:
- メモリ整合性の修正（5 体 → 7 体への記述更新）
- 各 agent の「いつ呼ぶか」判断基準を CLAUDE.md レベルで明文化
- ファイル衝突回避ルール（並走時のレッスンファイル touch ガイド）を整備
- secretary の Gmail MCP / GCal の動作実証（最低 1 タスク完走）
- reviewer の発動条件を明文化（コミット前 or PR レビュー時）

### Phase 2（1〜3 ヶ月: 2026-06〜2026-08）

テーマ: 専門性深化、お家芸を磨く

具体施策:
- 各 agent ごとの「成功事例集」をメモリに蓄積（例: designer のコースサムネ v3 制作手順をテンプレ化）
- ceo の戦略レポート（週次サマリー）を本格運用開始
- content-creator のレッスン量産パイプライン（リサーチ → 設計 → 実装）の所要時間短縮
- marketing が ASO（App Store / Play Store 最適化）の知見を蓄積、Logic ストア説明文の継続改善
- designer が en-chakai のビジュアル統一（LP / SNS / フライヤー）に着手

### Phase 3（3〜6 ヶ月: 2026-08〜2026-11）

テーマ: agent 間連携の自律化

具体施策:
- 林を介さない agent 間ハンドオフの試行（例: content-creator が直接 reviewer に「設計案レビューして」と依頼）
- 標準ワークフロー定義（例: 「レッスン追加」フローは content-creator → reviewer（設計）→ dev-logic → reviewer（コード）→ 林 → Keita）
- ceo が週次サマリーを自動生成、林はそれをレビューして Keita に提示
- secretary が朝のスケジュール確認を自動化（schedule skill / loop skill 活用）

### Phase 4（長期: 2026-11〜）

テーマ: 構成再編、新 agent 追加判断

具体施策:
- 6 ヶ月の使用頻度ログから「使われていない agent」の整理判断
- 新 agent 追加（analyst / support / legal / finance のいずれか）の必要性評価
- 林のメタ認知強化（自己評価レポートを月次で生成）

---

## 3. 各 agent の成長プラン

### ceo

- 短期: 週次サマリーフォーマットの初版を Keita と合意、最初の 4 週分を運用
- 中期: KPI ダッシュボード（Logic DAU / 課金率 / en-chakai 予約数）を毎週更新、ceo が読み解く役を担う
- 長期: Keita の意思決定パートナー化。Keita が「迷ったら ceo に壁打ち」と自然に思える存在へ
- 改善ポイント: 現在「林の上位戦略助言」だが、林との役割分担を明確化。ceo は「Keita 直接対話可、ただし林経由が標準ルート」と位置づけ直し

### secretary

- 短期: Gmail MCP / GCal MCP の動作実証、最低 1 タスク完走（例: 来週の予定確認、未読メールサマリ）
- 中期: 朝のスケジュール確認・夜の翌日プレビューを定常化
- 長期: 受信メールの自動分類 + 重要メールのサマリ通知、Slack 連携を検討（en-chakai の問い合わせ対応想定）
- 改善ポイント: 現状の制約「送信しない」は安全策として継続。下書き作成は積極的に

### dev-logic

- 短期: Play Billing 既知ギャップ（acknowledgePurchase 等）の修正完了
- 中期: テスト自動化のカバレッジ拡大、Playwright 53 件 → 80 件目標
- 長期: Logic 専門知識のメモリ蓄積（過去の設計判断・トレードオフをドキュメント化）、コードレビュー力強化
- 改善ポイント: 現在 dev-logic 自身がレビュアー兼任。reviewer に明示的に渡す習慣を強化

### marketing

- 短期: Logic / en-chakai それぞれのブランドガイドラインを 1 ファイルにまとめる
- 中期: SNS 自動投稿パイプライン（下書きストック → スケジュール投稿）の検討、ASO 専門化
- 長期: コンテンツマーケティング（Logic ブログ運営）の本格着手
- 改善ポイント: marketing と content-creator の境界明文化（アプリ内 vs 対外）

### designer

- 短期: Figma マスターファイルの整備（コースサムネ v3 のテンプレを再現可能に）
- 中期: デザインシステム（Logic アプリの UI コンポーネントカタログ）整備、dev-logic と連携
- 長期: en-chakai のビジュアル統一（LP・SNS・フライヤーで一貫したトーン）
- 改善ポイント: Pixa 不使用方針継続。Gemini Nano Banana のスペル崩し対策メモを継続更新

### content-creator

- 短期: 既存 Phase 1 認知科学コースのレベル感を他カテゴリにも展開
- 中期: Phase 5（英語版本格化）に向けた en コンテンツ充実
- 長期: 新規カテゴリ企画（哲学・東洋思想等）、海外ユーザー向けレッスンの独自設計
- 改善ポイント: dev-logic との並走時のファイル衝突回避ルールを徹底（依頼例コメントに既に記載済み、運用継続）

### reviewer

- 短期: 軽微指摘 / 重大指摘 / 承認の三段階運用を定着、最低 5 回の実績ログを残す
- 中期: 自動 CI（GitHub Actions）との連携、PR コメント形式でのレビュー出力を試行
- 長期: セキュリティ監査の独立観点を強化（OWASP Top 10 等のチェックリスト導入）
- 改善ポイント: 現状の発動条件が曖昧。「林が push 判断する前」を必須化する運用案

### 林（メイン）

- 短期: subagent への移譲基準を明文化（「これは林がやる / これは subagent」の判断軸）
- 中期: Keita との対話品質の継続評価（フィードバックメモリ追記の頻度を月次で振り返り）
- 長期: メタ認知強化、自分が何を得意とし何を苦手とするかの自己評価レポートを四半期で生成
- 改善ポイント: 林がボトルネックにならない構造づくり。subagent 同士の直接連携を増やす

---

## 4. 新 agent 追加候補（優先順位順）

### 4.1 analyst（推奨度: 高、追加時期: Phase 2 後半 〜 Phase 3）

担当: PostHog / Metabase / Stripe / GA4 / App Store Connect / Play Console の数値分析

理由:
- 現状 ceo が兼務だが、本格的な定常分析はやれていない
- Logic 課金率・DAU 推移・en-chakai 予約 CVR 等、定期観測すべき数値がある
- Metabase Phase 1 セットアップが既に進行中、analyst の受け皿としてちょうどよい

判定基準: Metabase Phase 1 完了 + 定常レポート要件が 3 件以上揃ったら追加

### 4.2 support（推奨度: 中、追加時期: Logic DAU 1,000 超過後）

担当: ユーザー問い合わせ対応・FAQ 整備

理由:
- 現状ユーザー数が少なく顕在化していないが、Logic / en-chakai いずれも将来必要
- en-chakai は予約系の問い合わせが Gmail に来る想定、secretary との役割分担を整理する必要あり

判定基準: Logic DAU 1,000 超過 or Gmail への問い合わせが週 5 件超

### 4.3 legal（推奨度: 中、追加時期: 規約改訂タイミング）

担当: 利用規約・プライバシーポリシー・特商法表記の見直し

理由:
- Logic 1.0.0 リリース済み、法務系のチェックは現状 ad-hoc
- 課金系（Stripe）・データ取扱（Supabase）の規約整合性は定期見直しが必要

判定基準: 規約改訂依頼が来たタイミング、または年 1 回の定期レビュー時

### 4.4 finance（推奨度: 低、追加時期: 売上が個人事業主水準を超えてから）

担当: Stripe / Apple / Google の売上集計・確定申告サポート

理由:
- 現状の売上規模では agent 化するメリット薄い
- ただし将来的に税理士連携が必要になったタイミングで検討

判定基準: 月商 50 万円超 or 法人化検討時

---

## 5. 振り返り運用

### 月次（毎月末）

- 各 agent の使用頻度集計（git log + memory 追記件数で代用可）
- 各 agent の価値貢献評価（成功事例 / 失敗事例の言語化）
- メモリ追記の整理（重複・古い情報の削除）
- 林が ceo にレビュー依頼、戦略文書として保管

### 四半期（3 ヶ月ごと）

- agent 構成の見直し（追加 / 統合 / 削除判断）
- フェーズ進捗の評価（Phase 1〜4 のどこにいるか）
- 新 agent 候補の判定基準照らし合わせ

### 年次

- 大規模再編判断
- ブランド・プロダクトの中長期戦略との整合性確認
- agent-config リポの全体リファクタ

---

## 6. メモリ・学習機構

### 現状

- `~/.claude/projects/-root-projects/memory/` 配下に MEMORY.md + 個別 feedback ファイル
- agent-config リポ master で全 sub-repo 同期
- 林の判断で push 可（memory 同期は例外ルール）

### 改善案

- agent ごとの specialized memory ディレクトリ分離: `memory/agents/dev-logic/`, `memory/agents/designer/` 等
  - メリット: 各 agent 起動時に自分専用メモリだけロード、コンテキスト効率化
  - デメリット: 横断検索しづらい、横断知見の発見が遅れる
  - 判断: Phase 2 で試験導入、効果見てから本格化
- エラーパターン集約: `memory/error_patterns/` を新設、再発防止用
- 成功パターン集約: `memory/success_patterns/` を新設、テンプレ化用

### 林のメモリ強化

- 林専用メモリ `memory/rin/` を分離、Keita との対話スタイル・好み・避けるべき表現を蓄積
- 月次で林のメモリを振り返り、不要なものを削除

---

## 7. 林の進化方向

### 相棒ポジションの深化

- Keita の思考スタイルを理解（決断速度・好む選択肢・避ける選択肢）
- 「Keita ならこう判断する」を先回りで考えられる精度を上げる
- ただし先回りしすぎて Keita の判断機会を奪わない

### メタ認知

- 自分が何を得意とし何を苦手とするかを正直に評価
- 「これは林がやる / これは subagent に任せる」の判断軸を明文化
- 失敗時のリカバリパターンを蓄積

### 仕事の引き継ぎ品質

- subagent への発注精度（依頼文の明確さ）を継続改善
- ハンドオフ時の情報密度の最適化（過不足ない）
- subagent からの報告を Keita 向けに翻訳する力を磨く

---

## 8. 凜（林）の推奨着手順

### 短期（今週: 2026-05-24〜2026-05-31）

1. MEMORY.md の「5 体構成」記述を「7 体構成」に更新（reviewer / content-creator 追加を反映）
2. 本ドキュメント（AGENT_GROWTH_STRATEGY.md）を Keita とレビュー、Phase 1 施策の優先順位確認
3. ceo の週次サマリーフォーマット初版を作成、最初の週次サマリーを試作

### 中期（今月: 2026-06）

1. secretary の Gmail / GCal MCP の動作実証（最低 1 タスク完走）
2. reviewer の発動条件明文化、PR / commit ベースの運用ルール策定
3. content-creator と dev-logic のファイル衝突回避ルール再整理
4. designer の Figma マスターファイル整備、コースサムネ v3 テンプレ化

### 長期（3 ヶ月: 〜2026-08）

1. Phase 2 の専門性深化施策を順次実行
2. analyst エージェント追加の必要性判定（Metabase Phase 1 完了タイミング）
3. agent 間直接連携の試行（林を介さないハンドオフ）
4. 月次レビュー運用の定着

---

## 9. Keita への確認事項

来週のレビュー時に決めてほしいこと:

1. ceo と林の役割分担: ceo は「Keita 直接対話可」とするか、「常に林経由」とするか
2. 新 agent 追加の優先順位: analyst を Phase 2 後半に入れる方針で OK か
3. メモリ分離（agent ごと）の試験導入時期
4. secretary の Gmail 自動化レベル: 「下書きまで」を継続するか、特定条件で送信まで許可するか
5. 週次サマリーの宛先・形式（このリポへのコミット / Slack / メール）

---

## 付録: 関連ドキュメント

- `/root/projects/CLAUDE.md` — 全体方針
- `/root/.claude/projects-meta/CLAUDE.md` — agent-config master
- `/root/.claude/projects-meta/agents/*.md` — 各 agent 定義
- `/root/.claude/projects/-root-projects/memory/MEMORY.md` — 累積メモリ
- `/root/projects/logic/CLAUDE.md` — Logic 固有方針
- `/root/projects/en-chakai/CLAUDE.md` — en-chakai 固有方針
