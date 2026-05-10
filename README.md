# agent-config

Claude Code のユーザー設定 + プロジェクトレベルのエージェント定義を Git で同期するためのリポジトリ。
クラウド環境（リモートサーバ）とローカル WSL の間で、同じエージェントをどこからでも呼び出せる状態を作る。

## 含まれるもの

| パス | 内容 |
| --- | --- |
| `settings.json` | Claude Code のユーザー設定 |
| `projects/-root-projects/memory/` | auto memory（MEMORY.md と各メモリファイル） |
| `projects-meta/CLAUDE.md` | `~/projects/CLAUDE.md` の実体 — プロジェクト全体方針 |
| `projects-meta/agents/` | `~/projects/.claude/agents/` の実体 — ceo / pm / secretary / dev-* / marketing |
| `bootstrap.sh` | clone 後にローカルで symlink を張るスクリプト |
| `.gitignore` | 認証情報・セッション履歴・キャッシュ等を除外 |

## 含まれないもの（`.gitignore` 対象）

- `.credentials.json` — Claude CLI の OAuth トークン
- `.mcp.json` — MCP 設定（環境固有）
- `sessions/` / `history.jsonl` / `paste-cache/` / `cache/` などのセッション履歴・一時ファイル
- `plugins/` / `tasks/` / `plans/` — マシン固有の状態
- `settings.local.json` — ローカル個別設定

## ローカルへのセットアップ手順（WSL Ubuntu 想定）

```bash
# 1. clone
cd ~
git clone git@github.com:keitaurano-del/agent-config.git .claude

# 2. symlink を張る
cd ~/.claude
./bootstrap.sh

# 3. Claude Code の認証（ブラウザ経由）
claude auth login --claudeai

# 4. サブプロジェクトを clone（必要に応じて）
mkdir -p ~/projects && cd ~/projects
git clone git@github.com:keitaurano-del/logic.git
git clone git@github.com:keitaurano-del/sengoku-chakai.git
git clone git@github.com:keitaurano-del/cxo-agent.git
```

bootstrap 後、以下の symlink が張られる：

```
~/projects/CLAUDE.md       -> ~/.claude/projects-meta/CLAUDE.md
~/projects/.claude/agents  -> ~/.claude/projects-meta/agents
```

## 編集フロー

エージェント定義や CLAUDE.md を編集したら、`~/.claude` で commit & push するだけ：

```bash
cd ~/.claude
git add -A
git commit -m "update agent: ceo の権限を更新"
git push
```

別マシンでは `git pull` するだけで反映される（symlink 経由なので即時反映）。

## カスタムパス

`~/projects` 以外に置きたい場合は環境変数で指定：

```bash
PROJECTS_DIR=/custom/path ~/.claude/bootstrap.sh
```

## 注意

- **認証情報はリポに含まれない**。新マシンでは個別に `claude auth login --claudeai` が必要。
- **openclaw を使う場合**は別途認証セットアップが必要（`~/.openclaw/` は同期対象外）。
- symlink を採用しているため、Windows ネイティブでは追加権限が必要。**WSL での運用を推奨**。
