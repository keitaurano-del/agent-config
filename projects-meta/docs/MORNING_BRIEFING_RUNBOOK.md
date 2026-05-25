# Morning Briefing Runbook

朝 7:00 に ceo が自動でブリーフィングを生成する仕組みの手順書。

最終更新: 2026-05-25

---

## 概要

- 担当 agent: ceo
- 実行時刻: 毎朝 7:00 (Asia/Tokyo)
- 出力先: `obsidian-vault/50-Daily/briefings/YYYY-MM-DD.md`
- テンプレ: `obsidian-vault/90-Templates/briefing-template.md`
- 受け取り: 林が起床後に確認し、Keita に咀嚼して伝える

---

## 仕組みの選択肢

### 案 A: claude headless + cron（推奨、Phase 1）

クラウド環境（`/root` ベース）で動かす想定。WSL ローカル側は別途検討。

```bash
# crontab -e で以下を追加
0 7 * * * /usr/local/bin/run-morning-briefing.sh >> /var/log/morning-briefing.log 2>&1
```

`/usr/local/bin/run-morning-briefing.sh` の中身:

```bash
#!/bin/bash
set -euo pipefail

DATE=$(date +%Y-%m-%d)
OUTPUT="/root/projects/obsidian-vault/50-Daily/briefings/${DATE}.md"
TEMPLATE="/root/projects/obsidian-vault/90-Templates/briefing-template.md"

mkdir -p "$(dirname "$OUTPUT")"

# claude headless 起動、ceo agent に投げる
claude --headless --agent ceo \
  --prompt "今日 ${DATE} の朝ブリーフィングを生成してくれ。テンプレは ${TEMPLATE} を使う。出力先は ${OUTPUT}。前日の git log を logic / en-chakai / obsidian-vault / agent-config の各 repo から拾って KPI と一緒にまとめる。Supabase MCP で DAU / 課金率の最新値も取得。" \
  > "$OUTPUT"

cd /root/projects/obsidian-vault
git add "$OUTPUT"
git commit -m "briefing: ${DATE} morning briefing by ceo"
git push origin main
```

権限:
```bash
chmod +x /usr/local/bin/run-morning-briefing.sh
```

### 案 B: schedule skill（Claude Code 内蔵）

Claude Code に `schedule` skill があるので、それを使って cron job として登録する手もある。

```
/schedule daily 07:00 /briefing
```

ただし schedule skill は remote agent ベースで、ローカル cron より柔軟だが Claude Code セッションがアクティブでない時の挙動は要検証。

### 案 C: GitHub Actions（バックアップ案）

agent-config repo に `.github/workflows/morning-briefing.yml` を置く。

```yaml
name: Morning Briefing
on:
  schedule:
    - cron: '0 22 * * *'  # UTC 22:00 = JST 07:00
jobs:
  briefing:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run ceo briefing
        run: |
          # claude API key で headless claude を起動
          # ...
```

メリット: クラウド環境がダウンしてても動く
デメリット: API キー必要（OAuth ではなく従量課金）

---

## 推奨運用

Phase 1 では **案 A（cron + claude headless）** で立ち上げ、安定したら案 B に移行検討。

---

## ブリーフィング内容のチェックリスト

ceo が朝ブリーフィング生成時に必ず含めるべき項目:

- [ ] 前日の commit 一覧（logic / en-chakai / agent-config / obsidian-vault）
- [ ] 完了タスク（kanban の Done に移ったもの）
- [ ] 残課題（持ち越し）
- [ ] 今日の推奨タスク Top 3（理由付き、担当 agent 指定）
- [ ] KPI スナップ（Logic DAU / 課金率 / クラッシュ率 / en-chakai 予約・訪問）
- [ ] ceo からの戦略提案（中期視点で今これをやる理由）
- [ ] 林への申し送り（Keita に咀嚼して伝えるポイント）

---

## トラブルシュート

### ブリーフィングが生成されない

1. `crontab -l` で job が登録されてるか確認
2. `/var/log/morning-briefing.log` でエラー確認
3. claude headless モードの認証確認: `claude auth status`
4. obsidian-vault repo の push 権限確認: `cd /root/projects/obsidian-vault && git push --dry-run`

### KPI が取れない

1. Supabase MCP 接続確認: `mcp__claude_ai_Supabase__get_project --id yctlelmlwjwlcpcxvmgx`
2. Metabase Phase 1 のセットアップ状況確認（[[project_metabase_setup]]）

### git push でコンフリクト

1. 凜が並行で同じファイルを編集してる可能性
2. `git pull --rebase` してから再 push
3. それでもダメなら手動 merge

---

## 林との連動

林は朝の作業開始時にまずブリーフィングを読む:

```bash
cat /root/projects/obsidian-vault/50-Daily/briefings/$(date +%Y-%m-%d).md
```

ブリーフィング読了後、林が Keita 向けに要約:
- 今日の Top 3 を 1-2 行で
- ceo の戦略提案の要点
- Keita 判断必要な項目

---

## 設定変更履歴

- 2026-05-25 初版作成（ceo 朝ブリーフィング機能新設）

---

## 関連

- `~/.claude/projects-meta/agents/ceo.md` — ceo agent 定義
- `obsidian-vault/90-Templates/briefing-template.md` — テンプレ本体
- `obsidian-vault/50-Daily/briefings/` — 出力先（凜が作業中、必要に応じてディレクトリ作成）
