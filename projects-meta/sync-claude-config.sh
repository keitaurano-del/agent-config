#!/usr/bin/env bash
# sync-claude-config.sh — agent-config の凜環境を各 sub-repo に full sync
#
# 同期するもの:
#   - CLAUDE.md の <!-- BEGIN: claude-config-sync ... END --> ブロック
#     (内側の SKIP マーカー範囲は除外)
#     + 蓄積メモリを inline 展開
#   - .claude/agents/   ← projects-meta/agents/
#   - .claude/memory/   ← projects/-root-projects/memory/
#   - .claude/settings.json (permission 部分のみ)
#
# 実行例:
#   bash ~/.claude/projects-meta/sync-claude-config.sh
#     → settings.json の permittedRepositories 全部に sync
#   bash ~/.claude/projects-meta/sync-claude-config.sh ~/projects/logic
#     → 単一 repo dir 指定

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-${HOME}/.claude}"
PROJECTS_DIR="${PROJECTS_DIR:-${HOME}/projects}"
SETTINGS_FILE="${SETTINGS_FILE:-${CLAUDE_DIR}/settings.json}"
SOURCE_CLAUDE_MD="${SOURCE_CLAUDE_MD:-${CLAUDE_DIR}/projects-meta/CLAUDE.md}"
SOURCE_AGENTS_DIR="${SOURCE_AGENTS_DIR:-${CLAUDE_DIR}/projects-meta/agents}"
SOURCE_MEMORY_DIR="${SOURCE_MEMORY_DIR:-${CLAUDE_DIR}/projects/-root-projects/memory}"

BEGIN_MARK='<!-- BEGIN: claude-config-sync'
END_MARK='<!-- END: claude-config-sync -->'
SKIP_BEGIN='<!-- BEGIN-SKIP: claude-config-sync -->'
SKIP_END='<!-- END-SKIP: claude-config-sync -->'

for f in "${SOURCE_CLAUDE_MD}"; do
  [[ -f "$f" ]] || { echo "❌ source 不在: $f" >&2; exit 1; }
done
for d in "${SOURCE_AGENTS_DIR}" "${SOURCE_MEMORY_DIR}"; do
  [[ -d "$d" ]] || { echo "❌ source dir 不在: $d" >&2; exit 1; }
done

# ───────────────────────────────────────────────
# 1. CLAUDE.md sync ブロックを抽出（SKIP 範囲を除外）
# ───────────────────────────────────────────────
extract_claude_section() {
  awk -v b="${BEGIN_MARK}" -v e="${END_MARK}" \
      -v sb="${SKIP_BEGIN}" -v se="${SKIP_END}" '
    index($0, b)  { in_block = 1; print; next }
    index($0, e)  { print; in_block = 0; next }
    index($0, sb) { skip = 1; next }
    index($0, se) { skip = 0; next }
    in_block && !skip { print }
  ' "${SOURCE_CLAUDE_MD}"
}

# ───────────────────────────────────────────────
# 2. memory ブロックを inline 生成（CLAUDE.md 末尾に追加する想定）
# ───────────────────────────────────────────────
build_memory_block() {
  echo "<!-- BEGIN: claude-config-memory (auto-synced — do not edit) -->"
  echo "## 蓄積メモリ"
  echo ""
  echo "agent-config の \`projects/-root-projects/memory/\` から sync。個別ファイルは \`.claude/memory/\` 配下にもコピー済み。"
  echo ""

  # MEMORY.md (インデックス) を最初に出す
  if [[ -f "${SOURCE_MEMORY_DIR}/MEMORY.md" ]]; then
    echo "### MEMORY.md (index)"
    echo ""
    cat "${SOURCE_MEMORY_DIR}/MEMORY.md"
    echo ""
  fi

  # それ以外のメモリファイルを名前順に
  local files
  mapfile -t files < <(find "${SOURCE_MEMORY_DIR}" -maxdepth 1 -type f -name "*.md" \
    ! -name "MEMORY.md" | sort)
  for f in "${files[@]}"; do
    echo "### $(basename "$f")"
    echo ""
    cat "$f"
    echo ""
  done

  echo "<!-- END: claude-config-memory -->"
}

# ───────────────────────────────────────────────
# 3. CLAUDE.md を target に書き込む（既存マーカー間置換 or 冒頭挿入）
# ───────────────────────────────────────────────
write_claude_md() {
  local target="$1"
  local section="$2"
  local memory="$3"

  # 古い rin-section マーカーが残ってたら除去（移行サポート）
  if grep -qF '<!-- BEGIN: rin-section' "${target}"; then
    local tmp_legacy
    tmp_legacy="$(mktemp)"
    awk '
      /<!-- BEGIN: rin-section/ { skip = 1; next }
      /<!-- END: rin-section -->/ { skip = 0; next }
      !skip { print }
    ' "${target}" > "${tmp_legacy}"
    mv "${tmp_legacy}" "${target}"
  fi

  # claude-config-memory ブロックも一旦除去（後で末尾に再追加）
  if grep -qF '<!-- BEGIN: claude-config-memory' "${target}"; then
    local tmp_mem
    tmp_mem="$(mktemp)"
    awk '
      /<!-- BEGIN: claude-config-memory/ { skip = 1; next }
      /<!-- END: claude-config-memory -->/ { skip = 0; next }
      !skip { print }
    ' "${target}" > "${tmp_mem}"
    mv "${tmp_mem}" "${target}"
  fi

  # 末尾の連続空行を全削除（冪等のため）
  local tmp_trim
  tmp_trim="$(mktemp)"
  awk '
    /./ { for (i = 0; i < blanks; i++) print ""; print; blanks = 0; next }
    { blanks++ }
  ' "${target}" > "${tmp_trim}"
  mv "${tmp_trim}" "${target}"

  local tmp
  tmp="$(mktemp)"

  if grep -qF "${BEGIN_MARK}" "${target}"; then
    # 既存 sync ブロックを置換
    awk -v repl="${section}" \
        -v b="${BEGIN_MARK}" -v e="${END_MARK}" '
      BEGIN { skipping = 0 }
      index($0, b) { print repl; skipping = 1; next }
      skipping && index($0, e) { skipping = 0; next }
      skipping { next }
      { print }
    ' "${target}" > "${tmp}"
  else
    # 冒頭タイトル直下に挿入
    awk -v repl="${section}" '
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
  fi

  # 末尾に空行 + memory ブロックを追加
  printf '\n%s\n' "${memory}" >> "${tmp}"

  if cmp -s "${tmp}" "${target}"; then
    rm -f "${tmp}"
    return 1   # 変更なし
  else
    mv "${tmp}" "${target}"
    return 0   # 変更あり
  fi
}

# ───────────────────────────────────────────────
# 4. .claude/{agents,memory,bootstrap-rin.sh} を配置
#    settings.json は触らない（hook 含む repo 側設定を保護）
# ───────────────────────────────────────────────
SOURCE_BOOTSTRAP="${SOURCE_BOOTSTRAP:-${CLAUDE_DIR}/projects-meta/bootstrap-rin.sh}"
SOURCE_SETTINGS_TEMPLATE="${SOURCE_SETTINGS_TEMPLATE:-${CLAUDE_DIR}/projects-meta/repo-settings.json.template}"

sync_dot_claude() {
  local repo_dir="$1"
  mkdir -p "${repo_dir}/.claude/agents" "${repo_dir}/.claude/memory"

  # --delete は使わない: 各 repo 独自の agents/ や memory/ を残すため
  rsync -a \
    --exclude '.git' \
    "${SOURCE_AGENTS_DIR}/" "${repo_dir}/.claude/agents/"

  rsync -a \
    --exclude '.git' \
    "${SOURCE_MEMORY_DIR}/" "${repo_dir}/.claude/memory/"

  # bootstrap-rin.sh は常に最新のものに上書き（hook が呼ぶ実体）
  if [[ -f "${SOURCE_BOOTSTRAP}" ]]; then
    install -m 0755 "${SOURCE_BOOTSTRAP}" "${repo_dir}/.claude/bootstrap-rin.sh"
  fi

  # settings.json は既存があれば触らず、無ければテンプレートから初期生成
  if [[ ! -f "${repo_dir}/.claude/settings.json" ]] && [[ -f "${SOURCE_SETTINGS_TEMPLATE}" ]]; then
    cp "${SOURCE_SETTINGS_TEMPLATE}" "${repo_dir}/.claude/settings.json"
  fi
}

# ───────────────────────────────────────────────
# 5. メインループ
# ───────────────────────────────────────────────
declare -a TARGETS
if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
else
  if [[ ! -f "${SETTINGS_FILE}" ]]; then
    echo "❌ ${SETTINGS_FILE} が無い。引数で repo dir を渡して。" >&2
    exit 1
  fi
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
    TARGETS+=("${PROJECTS_DIR}/${name}")
  done
fi

SECTION="$(extract_claude_section)"
MEMORY_BLOCK="$(build_memory_block)"

if [[ -z "${SECTION}" ]]; then
  echo "❌ CLAUDE.md sync ブロックが抽出できなかった" >&2
  exit 1
fi

echo "🔁 sync 開始 (${#TARGETS[@]} repo)"
for repo_dir in "${TARGETS[@]}"; do
  name="$(basename "${repo_dir}")"
  echo ""
  echo "── ${name} ──"

  if [[ ! -d "${repo_dir}" ]]; then
    echo "  ⚠️  ${repo_dir} が無い — スキップ"
    continue
  fi

  target_md="${repo_dir}/CLAUDE.md"
  if [[ ! -f "${target_md}" ]]; then
    echo "  ⚠️  ${target_md} が無い — CLAUDE.md だけ最小生成して続行"
    printf '# CLAUDE.md\n\n' > "${target_md}"
  fi

  if write_claude_md "${target_md}" "${SECTION}" "${MEMORY_BLOCK}"; then
    echo "  ✅ CLAUDE.md 更新"
  else
    echo "  ✓ CLAUDE.md 変更なし"
  fi

  sync_dot_claude "${repo_dir}"
  echo "  ✅ .claude/{agents,memory,settings.json} 配置"
done

echo ""
echo "✨ full sync 完了"
echo ""
echo "次にやること: 各 repo で git add . && git commit && git push"
