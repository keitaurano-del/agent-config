#!/usr/bin/env bash
# bootstrap.sh — clone 後にローカル環境で symlink を張るスクリプト
#
# 想定環境: Linux / WSL / macOS
# 実行例:
#   cd ~/.claude && ./bootstrap.sh
#   PROJECTS_DIR=/custom/path ./bootstrap.sh   # ~/projects 以外に置きたい場合

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-${HOME}/.claude}"
PROJECTS_DIR="${PROJECTS_DIR:-${HOME}/projects}"
META_DIR="${CLAUDE_DIR}/projects-meta"

echo "🦞 agent-config bootstrap"
echo "  CLAUDE_DIR   = ${CLAUDE_DIR}"
echo "  PROJECTS_DIR = ${PROJECTS_DIR}"
echo "  META_DIR     = ${META_DIR}"
echo ""

if [[ ! -d "${META_DIR}" ]]; then
  echo "❌ ${META_DIR} が見つからない。リポを clone した直後に実行してる？" >&2
  exit 1
fi

mkdir -p "${PROJECTS_DIR}/.claude"

backup_if_exists() {
  local target="$1"
  if [[ -e "${target}" && ! -L "${target}" ]]; then
    local backup="${target}.pre-bootstrap.$(date +%Y%m%d-%H%M%S).bak"
    echo "  📦 既存ファイルをバックアップ: ${backup}"
    mv "${target}" "${backup}"
  elif [[ -L "${target}" ]]; then
    echo "  🔗 既存 symlink を削除: ${target}"
    rm "${target}"
  fi
}

link() {
  local src="$1"
  local dst="$2"
  backup_if_exists "${dst}"
  ln -s "${src}" "${dst}"
  echo "  ✅ ${dst} -> ${src}"
}

echo "プロジェクトレベル設定の symlink を作成..."
link "${META_DIR}/CLAUDE.md" "${PROJECTS_DIR}/CLAUDE.md"
link "${META_DIR}/agents"    "${PROJECTS_DIR}/.claude/agents"

echo ""
echo "auto memory の cross-cwd symlink を作成..."
# Claude Code は cwd を /-/ 区切りに変換したディレクトリ名で memory を保管する。
# クラウド環境の memory は /root/projects 由来の `-root-projects/memory` に集約されているため、
# ローカルの PROJECTS_DIR から想定される名前のディレクトリを作って symlink で指す。
SOURCE_MEMORY="${CLAUDE_DIR}/projects/-root-projects/memory"
if [[ ! -d "${SOURCE_MEMORY}" ]]; then
  echo "  ⚠️  ${SOURCE_MEMORY} が無いので memory symlink はスキップ"
else
  # PROJECTS_DIR の絶対パスを `/` → `-` に変換してプロジェクト識別名を作る
  PROJ_ABS="$(cd "${PROJECTS_DIR}" 2>/dev/null && pwd || echo "${PROJECTS_DIR}")"
  PROJ_SLUG="${PROJ_ABS#/}"
  PROJ_SLUG="-${PROJ_SLUG//\//-}"
  LOCAL_PROJ_DIR="${CLAUDE_DIR}/projects/${PROJ_SLUG}"
  TARGET_MEMORY="${LOCAL_PROJ_DIR}/memory"

  if [[ "${TARGET_MEMORY}" == "${SOURCE_MEMORY}" ]]; then
    echo "  ℹ️  PROJECTS_DIR が /root/projects と一致。memory symlink は不要"
  else
    mkdir -p "${LOCAL_PROJ_DIR}"
    link "${SOURCE_MEMORY}" "${TARGET_MEMORY}"
  fi
fi

echo ""
echo "✨ bootstrap 完了"
echo ""
echo "次にやること:"
echo "  1. Claude Code 認証: claude auth login --claudeai"
echo "  2. openclaw を使うなら別途認証セットアップ"
echo "  3. ~/projects/{logic,sengoku-chakai,cxo-agent} はサブプロジェクトとして git clone で取得"
