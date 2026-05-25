---
updated: 2026-05-25
purpose: feedback-watcher agent の運用手順書 (Supabase ユーザフィードバック定期回収)
---

# Feedback Watcher Runbook

毎朝 06:00 JST に Supabase reports / feedback テーブルを polling して、ユーザフィードバックを構造化レポートにする手順書。

## 概要

| 項目 | 内容 |
|---|---|
| 担当 agent | feedback-watcher |
| 実行時刻 | 毎日 06:00 (Asia/Tokyo) + 月曜 09:00 (週次) |
| 実行方式 | cron + claude headless + MCP Supabase |
| 出力先 | `obsidian-vault/50-Daily/feedback/YYYY-MM-DD.md` |
| 翌朝連携 | 07:00 の ceo 朝ブリーフィングが拾って Daily Note に統合 |

## 仕組み

```
06:00 ─┐
       ├─→ feedback-watcher.sh
       │     ├─→ claude --print --agent feedback-watcher
       │     │     └─→ Supabase MCP で reports / feedback を取得
       │     ├─→ レポート md 生成 → 50-Daily/feedback/
       │     └─→ git commit + push (obsidian-vault)
       │
07:00 ─┤
       └─→ ceo 朝ブリーフィング
             ├─→ 50-Daily/inspections/$(yesterday).md (night-patrol)
             ├─→ 50-Daily/feedback/$(today).md (feedback-watcher)
             └─→ Daily Note 朝枠に統合
```

## night-patrol との職掌分離

| 項目 | night-patrol | feedback-watcher |
|---|---|---|
| 実行時刻 | 03:00 | 06:00 |
| 対象 | Render 本番のサーバ・スモーク・ログ | Supabase reports / feedback |
| 観点 | サーバ・課金・デプロイ系の異常 | ユーザの生の声 |
| 出力先 | inspections/ | feedback/ |
| 致命時通知 | Daily Note 朝枠（朝ブリ経由） | Daily Note 朝枠（朝ブリ経由） |

## セットアップ手順（Keita 操作）

### 1. cron 登録

```bash
crontab -e
```

以下を追加 (night-patrol と並べる):

```
# Night Patrol — 毎日 03:00 JST に Logic 本番巡回
0 3 * * * /root/.claude/projects-meta/scripts/night-patrol.sh >> /var/log/night-patrol.log 2>&1

# Feedback Watcher — 毎朝 06:00 JST に Supabase フィードバック回収
0 6 * * * /root/.claude/projects-meta/scripts/feedback-watcher.sh >> /var/log/feedback-watcher.log 2>&1

# Morning Briefing — 毎朝 07:00 JST に ceo がブリーフィング生成 (上の 2 つを統合)
0 7 * * * /usr/local/bin/run-morning-briefing.sh >> /var/log/morning-briefing.log 2>&1
```

### 2. ログファイル

```bash
sudo touch /var/log/feedback-watcher.log
sudo chown $(whoami) /var/log/feedback-watcher.log
```

### 3. 動作確認（手動実行）

```bash
/root/.claude/projects-meta/scripts/feedback-watcher.sh
```

成功すると `obsidian-vault/50-Daily/feedback/YYYY-MM-DD.md` が生成される。

### 4. claude headless の認証確認

```bash
claude auth status
```

Supabase MCP が呼び出せるよう、MCP 接続も併せて確認 (`mcp__claude_ai_Supabase__list_tables` が動けば OK)。

## アクション分岐ロジック

| 条件 | アクション |
|---|---|
| 新着 0 件 | レポートのみ、silent (Daily Note 追記なし) |
| 新着 1-2 件 | Daily Note 朝枠に件数 + サマリ追記 (朝ブリ経由) |
| 同種報告 3 件以上 | GitHub Issue 化推奨 (user-feedback ラベル) → Keita 朝の承認後実行 |
| バグ報告 / コンテンツ誤り 致命 | dev-logic に修正タスク委譲推奨 |
| Jira 起票失敗 (env 未設定) | 報告に env 確認推奨を明記 |

## 既知ギャップ（要 Keita 判断）

1. **APOLLO_WEBHOOK_URL の本番設定状況** — 未設定なら Apollo リアルタイム通知は無効、feedback-watcher が代替経路として機能
2. **既存 Jira 起票の疎通実績** — `reports` 1 件 (2026-04-17) が Jira に飛んだか実績未確認
3. **GitHub Issue 自動化の承認ライン** — 同種 3 件以上で自動 issue 化するか、Keita 承認後にするか
4. **Phase 2 Play Console / App Store 取込** — 現状 Play Store のみ稼働、レビュー API 取込は Phase 2 で実装
5. **scripts/feedback-watcher.sh の claude --print --agent syntax** — 実 claude CLI の syntax と差異がある場合は修正

## トラブルシュート

### cron が起動しない
```bash
systemctl status cron
crontab -l | grep feedback
tail -50 /var/log/feedback-watcher.log
```

### Supabase MCP が応答しない
```bash
claude auth status
# MCP 接続再確認
```

### obsidian-vault push でコンフリクト
night-patrol (inspections/) と feedback-watcher (feedback/) は別ディレクトリなので衝突しないはず。
凜の Daily Note 更新と被ったら:
```bash
cd /root/projects/obsidian-vault
git pull --rebase origin main
git push origin main
```

## Phase 2 拡張

- Google Play Developer API (reviews:list) 取込
- App Store Connect API 取込 (iOS リリース後)
- 同種報告の AI クラスタリング精度向上
- Slack / メール通知（critical のみ）

## 設定変更履歴

- 2026-05-25 初版作成（reports + feedback テーブル対応、Phase 1）

## 関連

- `~/.claude/projects-meta/agents/feedback-watcher.md` — agent 定義
- `~/.claude/projects-meta/scripts/feedback-watcher.sh` — 実行スクリプト
- `~/.claude/projects-meta/agents/night-patrol.md` — サーバ系巡回（職掌分離）
- `~/.claude/projects-meta/docs/MORNING_BRIEFING_RUNBOOK.md` — 朝ブリ統合
- `logic/docs/FEEDBACK_OPS.md` — 既存運用設計
- `logic/docs/APOLLO_JIRA_AUTOMATION.md` — Apollo / Jira 自動化
