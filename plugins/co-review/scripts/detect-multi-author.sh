#!/usr/bin/env bash
# ============================================================================
#  co-review — PostToolUse hook
#
#  与 flowsmith 协同的关键集成点。
#
#  触发条件（全部满足才提示）：
#  1. 被编辑的文件是 .sop/state.json（flowsmith 状态变更）
#  2. flowsmith 的 REVIEW.status 刚变为 "done"（审查完成）
#  3. 当前分支与 base 的 commits 涉及 ≥ 2 位作者
#  4. .team-scope/state.json 不存在或上次审查已归档
#
#  退出码：始终为 0（提示通过 stderr，不阻断 Claude）
# ============================================================================
set -uo pipefail

# 显式开关
if [[ "${BUDDY_COREVIEW_AUTO_SUGGEST:-1}" == "0" ]]; then
    exit 0
fi

# 读取 hook 输入
INPUT="$(cat 2>/dev/null || true)"
[[ -z "$INPUT" ]] && exit 0

# 提取被编辑的文件路径
FILE_PATH=""
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi
[[ -z "$FILE_PATH" ]] && exit 0

# 仅关心 .sop/state.json
case "$FILE_PATH" in
    */.sop/state.json|.sop/state.json) ;;
    *) exit 0 ;;
esac

# 找项目根
PROJECT_ROOT="$(dirname "$(dirname "$FILE_PATH")")"
[[ -d "$PROJECT_ROOT" ]] || exit 0
cd "$PROJECT_ROOT" 2>/dev/null || exit 0

# 加载共享库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/git-helpers.sh
source "${PLUGIN_ROOT}/scripts/lib/git-helpers.sh"

# 检查 flowsmith 状态
SOP_STATE=".sop/state.json"
[[ -f "$SOP_STATE" ]] || exit 0

if ! command -v jq >/dev/null 2>&1; then
    # 无 jq 无法判断状态，跳过
    exit 0
fi

REVIEW_STATUS=$(jq -r '.phases.REVIEW.status // empty' "$SOP_STATE" 2>/dev/null)
CURRENT_PHASE=$(jq -r '.current_phase // empty' "$SOP_STATE" 2>/dev/null)

# 仅在 REVIEW 阶段刚完成时触发
[[ "$REVIEW_STATUS" != "done" ]] && exit 0

# 避免重复触发：若 .team-scope 存在且上次审查仍在进行 OR 刚归档（< 1 小时前）
if [[ -f ".team-scope/state.json" ]]; then
    REPORT_STATUS=$(jq -r '.report.status // empty' .team-scope/state.json 2>/dev/null)
    [[ "$REPORT_STATUS" != "done" ]] && exit 0  # 进行中
    
    # 已 done，检查是否在 1 小时内
    ARCHIVED_AT=$(jq -r '.archived_at // empty' .team-scope/state.json 2>/dev/null)
    [[ -n "$ARCHIVED_AT" ]] && exit 0  # 已归档，本次 sop-review 完成无需再提示
fi

# 检查是否多人协作
if ! is_in_git_repo; then
    exit 0
fi

BRANCH=$(current_branch)
[[ -z "$BRANCH" ]] && exit 0

# 默认 base 用 main
BASE="main"
git rev-parse --verify "$BASE" >/dev/null 2>&1 || BASE="origin/main"
git rev-parse --verify "$BASE" >/dev/null 2>&1 || exit 0

# 当前在 base 分支上，无需提示
[[ "$BRANCH" == "$BASE" || "$BRANCH" == "main" || "$BRANCH" == "master" ]] && exit 0

AUTHORS=$(author_count "$BASE")
[[ "$AUTHORS" -lt 2 ]] && exit 0

# 输出建议（stderr）
cat >&2 <<EOF

[co-review] 💡 检测到 flowsmith 任务审查已完成，且当前分支由 ${AUTHORS} 位开发者协作。

强烈建议执行团队协作审查：

  /scope-review

它会从贡献画像、完成度、协作风险三个维度分析团队工作，生成合并策略建议。
也可以忽略此建议直接合并。

可选选项：
  /scope-review --with-scores              启用维度评分
  /scope-review --with-private-feedback    生成私聊反馈

如不需要本次提示，可设置 BUDDY_COREVIEW_AUTO_SUGGEST=0 关闭。
EOF

exit 0
