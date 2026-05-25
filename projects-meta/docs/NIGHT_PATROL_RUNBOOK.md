---
updated: 2026-05-25
purpose: 深夜 3:00 JST に Logic 本番 (Render) を自動巡回する night-patrol agent の運用手順書
---

# Night Patrol Runbook

毎日深夜 3:00 JST に Logic 本番 (Render) を巡回して、夜間の異常を「翌朝 Keita が起きる前」に捕まえる仕組みの手順書。

## 概要

| 項目 | 内容 |
|---|---|
| 担当 agent | night-patrol |
| 実行時刻 | 毎日 03:00 (Asia/Tokyo) |
| 実行方式 | cron + 純シェル + Playwright（claude headless 不使用）|
| 出力先 | `obsidian-vault/50-Daily/inspections/YYYY-MM-DD.md` |
| 翌朝連携 | 07:00 の ceo 朝ブリーフィングが拾って Daily Note に統合 |

## 仕組み

```
03:00 ─┐
       ├─→ night-patrol.sh
       │     ├─→ curl ヘルスチェック (フロント + API)
       │     ├─→ npx playwright test render-smoke-*.spec.ts
       │     ├─→ レポート md 生成 → 50-Daily/inspections/
       │     └─→ git commit + push (obsidian-vault)
       │
07:00 ─┤
       └─→ ceo 朝ブリーフィング
             └─→ inspections/$(date -d yesterday) を読み込み
                 → Daily Note 朝枠に致命・高ラベルを統合
```

## セットアップ手順（Keita 操作）

### 1. cron 登録

```bash
crontab -e
```

以下を追加:

```
# Night Patrol — 毎日 03:00 JST に Logic 本番巡回
0 3 * * * /root/.claude/projects-meta/scripts/night-patrol.sh >> /var/log/night-patrol.log 2>&1
```

### 2. ログファイル作成

```bash
sudo touch /var/log/night-patrol.log
sudo chown $(whoami) /var/log/night-patrol.log
```

### 3. スモーク spec の存在確認

```bash
ls /root/projects/logic/e2e/render-smoke-*.spec.ts
```

なければ test-smoke agent に最新版を作らせる。

### 4. 動作確認（手動実行）

```bash
/root/.claude/projects-meta/scripts/night-patrol.sh
```

成功すると `obsidian-vault/50-Daily/inspections/YYYY-MM-DD.md` が生成される。

### 5. 朝ブリーフィングと連動

`MORNING_BRIEFING_RUNBOOK.md` の ceo prompt に「前日の inspections/$(yesterday).md を読んで致命・高ラベルを Daily Note 朝枠に統合する」を追加する（既に追記済の場合はスキップ）。

## レポート構成

各レポートに以下のセクションを含む:

- サマリ表 (致命度 / フロント / API / スモーク結果)
- ヘルスチェック詳細 (HTTP コード + 応答時間)
- Playwright スモーク詳細 (最後 50 行)
- 翌朝対応の推奨アクション
- スクショ一覧

## 致命度ラベル

| ラベル | 条件 | 翌朝アクション |
|---|---|---|
| critical | フロント or API が 200 以外 | Render ダッシュボード即確認、deploy 履歴 + ログ調査 |
| high | スモークが失敗 | Daily Note 翌朝枠に詳述、dev-logic に修正依頼 |
| normal | 全部 pass | 継続記録のみ |

## トラブルシュート

### cron が起動しない

```bash
# cron 自体が動いてるか
systemctl status cron

# 登録確認
crontab -l | grep night-patrol

# ログ確認
tail -50 /var/log/night-patrol.log
```

### Playwright が失敗する（環境問題）

```bash
cd /root/projects/logic
npx playwright install chromium
```

### obsidian-vault の push でコンフリクト

night-patrol は inspections/ 配下しか触らないので、凜の Daily Note 編集と衝突しないはず。
もし衝突したら:

```bash
cd /root/projects/obsidian-vault
git pull --rebase origin main
git push origin main
```

## Phase 2 拡張（後日）

- Render API key 取得 → 直近 24h の error / warn ログ抽出
- 同一エラーの頻度集計 + 新規パターン検出
- en-chakai (Vercel) も巡回対象に追加
- Slack / メール通知（critical のみ）

## 設定変更履歴

- 2026-05-25 初版作成（Logic 本番のみ、Render ログは Phase 2）

## 関連

- `~/.claude/projects-meta/agents/night-patrol.md` — agent 定義
- `~/.claude/projects-meta/scripts/night-patrol.sh` — 実行スクリプト
- `~/.claude/projects-meta/docs/MORNING_BRIEFING_RUNBOOK.md` — 翌朝の朝ブリ
- `obsidian-vault/50-Daily/inspections/` — 出力先
