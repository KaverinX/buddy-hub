#!/usr/bin/env bash
# ============================================================================
#  co-review — git helpers
#
#  共享工具函数：git 命令封装、JSON 解析、过滤等。
#  被 hook、TUI、和（间接被）agent prompt 使用。
# ============================================================================

# 默认排除模式（与 schema 中保持一致）
DEFAULT_EXCLUDE_PATTERNS=(
    "*.lock"
    "package-lock.json"
    "yarn.lock"
    "pnpm-lock.yaml"
    "dist/**"
    "target/**"
    "node_modules/**"
    "*.min.js"
    "*.min.css"
    "*.map"
)

# 检查路径是否被排除模式匹配
is_excluded() {
    local path="$1"
    shift
    local patterns=("$@")
    [[ ${#patterns[@]} -eq 0 ]] && patterns=("${DEFAULT_EXCLUDE_PATTERNS[@]}")

    for pattern in "${patterns[@]}"; do
        case "$path" in
            $pattern) return 0 ;;
        esac
    done
    return 1
}

# 获取当前分支名
current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# 检查是否在 git 仓库
is_in_git_repo() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# 获取 base..HEAD 的 commits（排除 merge）
non_merge_commits() {
    local base="${1:-main}"
    git log --no-merges --pretty=format:'%H' "${base}..HEAD" 2>/dev/null
}

# 获取 base..HEAD 的所有作者（去重，按 email local-part）
unique_authors() {
    local base="${1:-main}"
    git log --no-merges --pretty=format:'%ae' "${base}..HEAD" 2>/dev/null | \
        awk -F@ '{print tolower($1)}' | \
        sort -u
}

# 获取 base..HEAD 的作者数量
author_count() {
    unique_authors "${1:-main}" | wc -l | tr -d ' '
}

# 获取 base..HEAD 的 commit 数量（排除 merge）
commit_count() {
    non_merge_commits "${1:-main}" | wc -l | tr -d ' '
}

# JSON 字段读取（用于读 state.json）
state_get() {
    local path="$1"
    local file="${2:-.team-scope/state.json}"
    [[ -f "$file" ]] || { echo ""; return; }
    if command -v jq >/dev/null 2>&1; then
        jq -r "$path // empty" "$file" 2>/dev/null
    else
        echo ""
    fi
}

# 检测 flowsmith 是否安装且有进行中任务
flowsmith_active() {
    [[ -f ".sop/state.json" ]] || return 1
    local phase
    phase=$(jq -r '.current_phase // empty' .sop/state.json 2>/dev/null)
    [[ -n "$phase" && "$phase" != "DONE" ]]
}

# 检测 archaeology 是否完成
archaeology_done() {
    [[ -f ".archaeology/state.json" ]] || return 1
    local status
    status=$(jq -r '.report.status // empty' .archaeology/state.json 2>/dev/null)
    [[ "$status" == "done" ]]
}

# 简单 ISO8601 时间戳
now_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}
