---
name: feedback-logic-lesson-visual-hybrid
description: Logic レッスン本文の視覚化方針。図解(SVG diagram)に加え、インライン視覚要素は SVGアイコン+絵文字のハイブリッドで読みやすくする。UI chrome は従来通りアイコンのみ。
metadata:
  type: feedback
  originSessionId: 2026-05-26
---

Logic のレッスンは「文字ベースすぎる」ので、視覚化して読みやすくする取り組みを進める。2026-05-26 Keita 指示。

**Why:** レッスン本文が文字の塊で分かりにくい。図解(diagram)だけでなく、本文中のインライン視覚要素（アイコン・絵文字）でも情報の塊を視覚的に整理して可読性を上げたい。Keita 明示「図解以外でも、絵文字やSVGアイコンを使ってもっと読みやすくしたい」。方針は「ハイブリッド」を選択。

**How to apply（インライン視覚要素のハイブリッド方針）:**
- 体系的・反復的なもの（✓/✗ の良い例悪い例、要点、注意、ポイント、手順番号など）は `src/icons/index.tsx` の SVG アイコンで統一する（ブランド統一・テーマ色追従・端末差なし）。現状41種、足りなければ追加。
- 手頃なアイコンが無い・話題物（その回特有のモチーフ）には絵文字も許可する。
- 適用範囲は**レッスン本文（lesson body / explain step）限定**。UI chrome（ナビ・ボタン・ラベル等）は従来どおり SVG アイコンのみ、絵文字NGを維持。
- これは「UI では絵文字NG・src/icons の SVG を使う」という従来の明文ルール（logic/CLAUDE.md「Common gotchas」#5、ジャーナルの mood/weather/phase/streak のみ例外）への**追加例外**。レッスン本文に絵文字があっても旧ルールで消し戻さないこと。
- 読み上げ(TTS)対策: 本文に入れたアイコントークン・絵文字は `stripMarkup`（src/richText.ts）で剥がし、読み上げで「炎 絵文字」等と喋らせない。emoji unicode 範囲とアイコントークンを strip 対象に追加する。
- ロールアウトはサンプル先行: 1レッスンで見た目を作って Keita 承認 → カテゴリ単位で展開（過去のサムネ事故の教訓と同じ、[[feedback-logic-course-thumbnails]] のサンプル承認フロー踏襲）。

**関連する別取り組み（図解 diagram の拡充）:**
- レッスンは `visual:`（図の種類）+ `visualProps:`（データ）で SVG 図解を表示できる。図解コンポーネントは `src/visuals/index.ts` に68種登録済み。
- カバレッジは ja explain ステップ 744 中 222（約30%）に図解あり（2026-05-26 集計）。残り約7割は文字のみ。手薄な高価値カテゴリ: numeracy(12%/50説明) > cognitive(13%) > issue(12%) > peakPerformance(13%) など。career系・easternPhilosophy は3〜7%。
- インライン視覚要素（本記事の主題）と図解拡充は両輪で「文字ベースすぎる」を解消する。

**実装状況（2026-05-26、第一弾 shipped・PR #219 で main マージ済み）:**
- 記法は実装済み: 本文に `[icon:name]`（インラインSVGアイコン。`icon:` 固定prefixで `3:1`/`10:30` 等のコロンと衝突しない）と `:::tip` / `:::warn` / `:::point` / `:::note`（注記ボックス、kind別アイコン+テーマ色）。
- 実装場所: `src/richText.ts`（パーサ・stripMarkup）、`src/components/RichLessonText.tsx`（ICON_REGISTRY・描画）、`src/lessonSlides.ts`（splitBody を callout-aware 化＝`:::`ブロックは分割の atomic unit）。
- 執筆ガイドは `logic/CLAUDE.md` gotchas #5 に記載: 正準アイコン名は good/bad/point/warn（エイリアスは内部互換用）、name は小文字＋ハイフンのみ、意味アイコンは語ラベル併記、callout は1スライド最大1個・構造化済みの塊には使わない、密度目安 callout最大1/inlineアイコン2〜3、絵文字は話題物限定で `✓✗★` は生記号でなくアイコン記法。
- サンプル適用済み: cognitive `id:700`/`id:704`（ja/en）。logic-coach + reviewer 監査通過。
- 残課題: カバレッジ拡大は未着手（cognitive 2レッスンのみ）。手薄カテゴリ numeracy/cognitive/issue を優先展開予定。`id:704` の good/bad アイコンを個別項目に付けるか（現状は見出しラベル方式）は Keita 判断保留。

**注意点:**
- 絵文字は端末/フォントで見た目が変わるので、ブランドの肝になる所は SVG を優先（だからハイブリッド）。
- 新カテゴリへ展開する時は上記の執筆ガイド（logic/CLAUDE.md gotchas #5）に従い、サンプル先行→Keita 承認→カテゴリ単位展開のフローを守る。

関連 memory: [[feedback-logic-course-thumbnails]]（サンプル承認フロー）、[[feedback-no-markdown-emphasis]]、[[project-logic-content-audit-20260525]]（レッスン品質の取り組み）
