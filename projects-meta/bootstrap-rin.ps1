# bootstrap-rin.ps1 — Windows 用 SessionStart hook が呼ぶ凜環境自動更新スクリプト
#
# 動作:
#   1. agent-config を ~\.cache\agent-config に clone or pull
#   2. setup-rin-windows.ps1 を実行して global CLAUDE.md / agents / memory を更新
#
# 失敗してもセッションは続行させる（exit 0）

$ErrorActionPreference = "SilentlyContinue"

$AC_DIR = if ($env:AC_DIR) { $env:AC_DIR } else { Join-Path $env:USERPROFILE ".cache\agent-config" }
$repoHttps = "https://github.com/keitaurano-del/agent-config.git"

$parent = Split-Path $AC_DIR -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

if (Test-Path (Join-Path $AC_DIR ".git")) {
    git -C $AC_DIR fetch --quiet origin main 2>$null
    if ($LASTEXITCODE -eq 0) {
        git -C $AC_DIR reset --hard origin/main --quiet 2>$null
    } else {
        Write-Warning "agent-config fetch failed (offline?) - using existing cache"
    }
} else {
    git clone --quiet $repoHttps $AC_DIR 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "agent-config clone failed - skipping Rin sync"
        exit 0
    }
}

$setupScript = Join-Path $AC_DIR "projects-meta\setup-rin-windows.ps1"
if (Test-Path $setupScript) {
    & $setupScript -AgentConfigDir $AC_DIR -ClaudeDir (Join-Path $env:USERPROFILE ".claude") 2>$null | Out-Null
} else {
    Write-Warning "setup-rin-windows.ps1 not found at $setupScript"
}

exit 0
