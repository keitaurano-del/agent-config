#!/usr/bin/env bash
# sync-rin-section.sh — agent-config の凜セクションを各 repo の CLAUDE.md に同期する
#
# 動作:
#   1. agent-config (projects-meta/CLAUDE.md) から
#      <!-- BEGIN: rin-section --> ... <!-- END: rin-section --> の範囲を抽出
#   2. 各 target repo の CLAUDE.md に対して:
#      - 既に同マーカーがあれば中身を置換
#      - なければタイトル行（# ...）の直下に挿入
#
# 実行例:
#   bash ~/.claude/projects-meta/sync-rin-section.sh
#   # → settings.json の permittedRepositories 全部に sync
#
#   bash ~/.claude/projects-meta/sync-rin-section.sh ~/projects/logic/CLAUDE.md
#   # → 単一ファイル指定

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-${HOME}/.claude}"
PROJECTS_DIR="${PROJECTS_DIR:-${HOME}/projects}"
SETTINGS_FILE="${SETTINGS_FILE:-${CLAUDE_DIR}/settings.json}"
SOURCE_FILE="${SOURCE_FILE:-${CLAUDE_DIR}/projects-meta/CLAUDE.md}"

BEGIN_MARK='<!-- BEGIN: rin-section'
END_MARK='<!-- END: rin-section -->'

if [[ ! -f "${SOURCE_FILE}" ]]; then
  echo "❌ source ${SOURCE_FILE} が無い" >&2
  exit 1
fi

# 凜セクションを抽出（マーカー行も含めて）
RIN_SECTION="$(awk -v b="${BEGIN_MARK}" -v e="${END_MARK}" '
  index($0, b) { in_block = 1 }
  in_block     { print }
  index($0, e) { in_block = 0 }
' "${SOURCE_FILE}")"

if [[ -z "${RIN_SECTION}" ]]; then
  echo "❌ ${SOURCE_FILE} から凜セクションを抽出できなかった。マーカーを確認して。" >&2
  exit 1
fi

echo "📝 抽出した凜セクション ($(echo "${RIN_SECTION}" | wc -l) 行)"
echo ""

# 対象ファイル一覧を組み立て
declare -a TARGETS
if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
else
  if [[ ! -f "${SETTINGS_FILE}" ]]; then
    echo "❌ ${SETTINGS_FILE} が無い。引数で CLAUDE.md を直接渡して。" >&2
    exit 1
  fi
  # permittedRepositories からターゲットを組み立てる
  if command -v jq >/dev/null 2>&1; then
    mapfile -t REPOS < <(jq -r '.permittedRepositories[]?' "${SETTINGS_FILE}")
  else
    mapfile -t REPOS < <(awk '
      /"permittedRepositories"[[:space:]]*:/ { in_block = 1; next }
      in_block && /\]/                       { in_block = 0; next }
      in_block && /"[^"]+"/ {
        match($0, /"[^"]+"/)
        print substr($0, RSTART + 1, RLENGTH - 2)
      }
    ' "${SETTINGS_FILE}")
  fi
  for repo in "${REPOS[@]}"; do
    name="${repo##*/}"
    TARGETS+=("${PROJECTS_DIR}/${name}/CLAUDE.md")
  done
fi

sync_one() {
  local target="$1"
  local name
  name="$(basename "$(dirname "${target}")")"

  if [[ ! -f "${target}" ]]; then
    echo "  ⚠️  ${name}: ${target} が無い — スキップ"
    return 0
  fi

  if grep -qF "${BEGIN_MARK}" "${target}"; then
    # 既存マーカー間を置換
    local tmp
    tmp="$(mktemp)"
    awk -v b="${BEGIN_MARK}" -v e="${END_MARK}" -v repl="${RIN_SECTION}" '
      BEGIN { skipping = 0 }
      index($0, b) { print repl; skipping = 1; next }
      skipping && index($0, e) { skipping = 0; next }
      skipping { next }
      { print }
    ' "${target}" > "${tmp}"
    if cmp -s "${tmp}" "${target}"; then
      echo "  ✓ ${name}: 変更なし"
      rm -f "${tmp}"
    else
      mv "${tmp}" "${target}"
      echo "  ↻ ${name}: 既存セクションを更新"
    fi
  else
    # タイトル行（# で始まる最初の行）の直下に挿入
    local tmp
    tmp="$(mktemp)"
    awk -v repl="${RIN_SECTION}" '
      BEGIN { inserted = 0 }
      !inserted && /^# / { print; print ""; print repl; print ""; inserted = 1; next }
      { print }
      END {
        if (!inserted) {
          print ""
          print repl
        }
      }
    ' "${target}" > "${tmp}"
    mv "${tmp}" "${target}"
    echo "  + ${name}: 新規挿入"
  fi
}

echo "🔁 sync 開始"
for t in "${TARGETS[@]}"; do
  sync_one "${t}"
done
echo ""
echo "✨ sync 完了"
echo ""
echo "次にやること: 各 repo で CLAUDE.md を git add / commit / push"
