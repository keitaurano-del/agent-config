# web-hooks — Claude Code on the web 向け SessionStart フック

Claude Code をブラウザ (web) で起動すると、リポジトリ単体がチェックアウトされた状態で
セッションが始まる。ローカル WSL のように `~/projects/CLAUDE.md` を親ディレクトリから
読み込んでもらえないため、**凜のペルソナ定義がそのままでは届かない**。

このディレクトリの SessionStart フックを各サブプロジェクトに展開しておくと、
web セッションの起動時に凜の名前・口調・動作ルールを context に注入できる。

## 含まれるもの

| ファイル | 役割 |
| --- | --- |
| `session-start.sh` | `CLAUDE_CODE_REMOTE=true` のときだけ凜のペルソナを stdout に出力する |
| `settings.json` | `.claude/settings.json` の hooks 部分テンプレート (既存ファイルがあればマージ) |

## デプロイ手順

各サブプロジェクト (logic / sengoku-chakai / cxo-agent / ...) で 1 回ずつ実行する。

```bash
# 例: logic への展開
cd ~/projects/logic
mkdir -p .claude/hooks
cp ~/.claude/projects-meta/web-hooks/session-start.sh .claude/hooks/session-start.sh
chmod +x .claude/hooks/session-start.sh

# settings.json — 既存があれば hooks ブロックをマージ、無ければまるごとコピー
if [[ -f .claude/settings.json ]]; then
  echo "既存の .claude/settings.json があるので hooks ブロックを手動マージしてください"
  diff -u .claude/settings.json ~/.claude/projects-meta/web-hooks/settings.json || true
else
  cp ~/.claude/projects-meta/web-hooks/settings.json .claude/settings.json
fi

git add .claude/
git commit -m "add SessionStart hook to inject 凜 persona on Claude Code web"
git push
```

push したらマージして、以降のすべての web セッションでフックが走る。

## ローカル WSL での挙動

`CLAUDE_CODE_REMOTE` 環境変数が `true` でないと早期 exit するので、
ローカル (WSL) では何も注入されない。ローカルは `~/projects/CLAUDE.md` 経由で
同じ情報が読み込まれるので二重に注入されないようになっている。

## 動作確認

リポジトリにコピーしたあとに手元で挙動確認したいときは：

```bash
CLAUDE_CODE_REMOTE=true .claude/hooks/session-start.sh
```

stdout にペルソナ定義の Markdown が出力されれば OK。

## 更新フロー

凜のペルソナ・口調・動作ルールを変えたいときは：

1. agent-config 側で source of truth を更新
   - `projects-meta/CLAUDE.md`
   - `projects/-root-projects/memory/feedback_assistant_name.md`
   - `projects/-root-projects/memory/feedback_tone.md`
2. `projects-meta/web-hooks/session-start.sh` の `cat` ブロックを揃える
3. 各サブプロジェクトに `cp` で再展開して commit & push
