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
| `projects-meta/web-hooks/` | Claude Code on the web 用 SessionStart フック (各サブプロジェクトに展開) |
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
~/projects/CLAUDE.md                              -> ~/.claude/projects-meta/CLAUDE.md
~/projects/.claude/agents                         -> ~/.claude/projects-meta/agents
~/.claude/projects/-<PROJECTS_DIR>/memory         -> ~/.claude/projects/-root-projects/memory
```

3つ目は、Claude Code が cwd ごとに別の memory ディレクトリを参照する仕様への対応。
ローカルの cwd（例: `/home/keita/projects`）でも、リポと同じ auto memory が読み込まれるようになる。

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

## Claude Code on the web で凜を呼び出すには

ブラウザ版の Claude Code はリポ単体で起動するため、`~/projects/CLAUDE.md` を遡って読んでくれない。
凜のペルソナを web セッションでも読ませるには SessionStart フックを各サブプロジェクトに展開する：

```bash
cd ~/projects/logic   # または sengoku-chakai / cxo-agent
mkdir -p .claude/hooks
cp ~/.claude/projects-meta/web-hooks/session-start.sh .claude/hooks/session-start.sh
chmod +x .claude/hooks/session-start.sh
cp ~/.claude/projects-meta/web-hooks/settings.json .claude/settings.json  # 既存があれば hooks ブロックをマージ
git add .claude/ && git commit -m "add SessionStart hook to inject 凜 persona" && git push
```

詳細は `projects-meta/web-hooks/README.md` 参照。

## 注意

- **認証情報はリポに含まれない**。新マシンでは個別に `claude auth login --claudeai` が必要。
- **openclaw を使う場合**は別途認証セットアップが必要（`~/.openclaw/` は同期対象外）。
- symlink を採用しているため、Windows ネイティブでは追加権限が必要。**WSL での運用を推奨**。
