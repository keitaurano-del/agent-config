#!/usr/bin/env bash
# clone-projects.sh — settings.json の permittedRepositories を ~/projects/ 配下に展開する
#
# 想定環境: Claude Code on the web のサンドボックス / ローカル Linux / WSL / macOS
# 既存 clone は fetch + ff-only pull、新規はSSH→HTTPSの順にフォールバック。
#
# 実行例:
#   bash ~/.claude/projects-meta/clone-projects.sh
#   PROJECTS_DIR=/custom/path bash ~/.claude/projects-meta/clone-projects.sh

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-${HOME}/.claude}"
PROJECTS_DIR="${PROJECTS_DIR:-${HOME}/projects}"
SETTINGS_FILE="${SETTINGS_FILE:-${CLAUDE_DIR}/settings.json}"

echo "🦞 clone-projects"
echo "  SETTINGS_FILE = ${SETTINGS_FILE}"
echo "  PROJECTS_DIR  = ${PROJECTS_DIR}"
echo ""

if [[ ! -f "${SETTINGS_FILE}" ]]; then
  echo "❌ ${SETTINGS_FILE} が見つからない" >&2
  exit 1
fi

# permittedRepositories を抽出。jq があれば使う、無ければ素朴な grep + sed。
extract_repos() {
  if command -v jq >/dev/null 2>&1; then
    jq -r '.permittedRepositories[]?' "${SETTINGS_FILE}"
  else
    # "permittedRepositories": [ ... ] ブロックの中の文字列だけ拾う
    awk '
      /"permittedRepositories"[[:space:]]*:/ { in_block = 1; next }
      in_block && /\]/                       { in_block = 0; next }
      in_block && /"[^"]+"/ {
        match($0, /"[^"]+"/)
        print substr($0, RSTART + 1, RLENGTH - 2)
      }
    ' "${SETTINGS_FILE}"
  fi
}

mapfile -t REPOS < <(extract_repos)

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "⚠️  permittedRepositories が空。何もしない。" >&2
  exit 0
fi

mkdir -p "${PROJECTS_DIR}"

clone_one() {
  local full="$1"          # owner/repo
  local name="${full##*/}" # repo
  local target="${PROJECTS_DIR}/${name}"
  local ssh_url="git@github.com:${full}.git"
  local https_url="https://github.com/${full}.git"

  if [[ -d "${target}/.git" ]]; then
    echo "  ↻ ${name}: 既存 — fetch + pull --ff-only"
    if git -C "${target}" fetch --quiet origin 2>/dev/null \
       && git -C "${target}" pull --ff-only --quiet 2>/dev/null; then
      echo "    ✅ 最新化"
    else
      echo "    ⚠️  pull に失敗（ローカル変更/conflict の可能性）— スキップして続行"
    fi
    return 0
  fi

  echo "  + ${name}: 新規 clone"
  if git clone --quiet "${ssh_url}" "${target}" 2>/dev/null; then
    echo "    ✅ SSH で clone 完了"
    return 0
  fi
  if git clone --quiet "${https_url}" "${target}" 2>/dev/null; then
    echo "    ✅ HTTPS で clone 完了"
    return 0
  fi
  echo "    ❌ SSH / HTTPS 両方で clone 失敗 (${full})" >&2
  return 1
}

FAIL=0
for repo in "${REPOS[@]}"; do
  clone_one "${repo}" || FAIL=$((FAIL + 1))
done

echo ""
echo "📋 サマリ:"
for repo in "${REPOS[@]}"; do
  name="${repo##*/}"
  target="${PROJECTS_DIR}/${name}"
  if [[ -d "${target}/.git" ]]; then
    if [[ -f "${target}/CLAUDE.md" ]]; then
      echo "  ✅ ${name}  (CLAUDE.md あり)"
    else
      echo "  ⚠️  ${name}  (CLAUDE.md なし)"
    fi
  else
    echo "  ❌ ${name}  (未取得)"
  fi
done

echo ""
if [[ ${FAIL} -gt 0 ]]; then
  echo "⚠️  ${FAIL} 件のリポジトリで失敗。auth (SSH 鍵 or GitHub MCP の repo スコープ) を確認して。" >&2
  exit 1
fi
echo "✨ clone-projects 完了"
