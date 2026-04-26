#!/usr/bin/env bash
# ============================================================================
#  code-archaeologist — PostToolUse hook
#
#  与 flowsmith 协同的关键集成点。在 flowsmith 写入 .sop/plan.md 后，
#  扫描其中是否描述了"重构"类任务，主动提示用户先做考古。
#
#  触发条件（全部满足才提示）：
#  1. 被编辑的文件是 .sop/plan.md
#  2. flowsmith 的 state.json 显示 current_phase = PLANNING
#  3. plan.md 内容中包含重构/重组/拆分等关键词
#  4. 不存在已关联的 .archaeology/state.json（避免重复提示）
#
#  退出码：始终为 0（提示通过 stderr 输出，不阻断 Claude）
# ============================================================================
set -uo pipefail

# 仅在显式启用时工作（默认开启，但允许用户关闭）
if [[ "${BUDDY_ARCH_AUTO_SUGGEST:-1}" == "0" ]]; then
    exit 0
fi

# ---------- 1. 读取 hook 输入 ----------
INPUT="$(cat 2>/dev/null || true)"
[[ -z "$INPUT" ]] && exit 0

# 提取被编辑的文件路径
FILE_PATH=""
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
fi
[[ -z "$FILE_PATH" ]] && exit 0

# ---------- 2. 仅关心 .sop/plan.md ----------
case "$FILE_PATH" in
    */.sop/plan.md|.sop/plan.md) ;;
    *) exit 0 ;;
esac

# ---------- 3. 找项目根（从 plan.md 反推）----------
PROJECT_ROOT="$(dirname "$(dirname "$FILE_PATH")")"
[[ -d "$PROJECT_ROOT" ]] || exit 0

cd "$PROJECT_ROOT" 2>/dev/null || exit 0

# ---------- 4. 校验 flowsmith 状态 ----------
SOP_STATE=".sop/state.json"
[[ -f "$SOP_STATE" ]] || exit 0

if command -v jq >/dev/null 2>&1; then
    CURRENT_PHASE=$(jq -r '.current_phase // empty' "$SOP_STATE" 2>/dev/null)
    [[ "$CURRENT_PHASE" != "PLANNING" ]] && exit 0
fi

# ---------- 5. 避免重复提示 ----------
# 已存在进行中的考古，不再提示
if [[ -f ".archaeology/state.json" ]] && command -v jq >/dev/null 2>&1; then
    REPORT_STATUS=$(jq -r '.report.status // empty' ".archaeology/state.json" 2>/dev/null)
    if [[ "$REPORT_STATUS" != "done" ]]; then
        # 有进行中或失败的考古，不重复提示
        exit 0
    fi
fi

# 已经有 archaeology:injected 标记，说明用户已主动做过
if grep -q "archaeology:injected" "$FILE_PATH" 2>/dev/null; then
    exit 0
fi

# ---------- 6. 检测重构意图关键词 ----------
# 只对 plan.md 的"任务描述"段落做检测，避免假阳性
TASK_DESCRIPTION=$(awk '
    /^## 任务描述/ { capture=1; next }
    /^## / { capture=0 }
    capture { print }
' "$FILE_PATH" 2>/dev/null)

[[ -z "$TASK_DESCRIPTION" ]] && exit 0

# 关键词清单（中英文）
REFACTOR_KEYWORDS='重构|重组|拆分|抽离|抽取|改造|迁移|升级|替换|refactor|refactoring|restructure|extract|split|migrate|rewrite|legacy|遗留'

if ! echo "$TASK_DESCRIPTION" | grep -iqE "$REFACTOR_KEYWORDS"; then
    exit 0
fi

# ---------- 7. 提示用户 ----------
# 提示通过 stderr，Claude Code 会显示给用户（按 Ctrl+O 查看 verbose）
cat >&2 <<'EOF'

[code-archaeologist] 💡 检测到当前 flowsmith 任务描述中包含重构关键词。

强烈建议在规划阶段之前先执行一次代码考古：

  /arch-init <要重构的文件或模块>

考古会从历史、依赖、意图三个维度分析目标代码，识别隐藏风险，
其结论将自动注入到 .sop/plan.md 的"约束与前提"，让后续阶段感知。

如不需要本次提示，可设置 BUDDY_ARCH_AUTO_SUGGEST=0 关闭。
EOF

exit 0
