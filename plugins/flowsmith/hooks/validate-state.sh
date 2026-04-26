#!/usr/bin/env bash
# SOP State Machine Validator Hook
#
# 在每次 Write/Edit 工具调用后触发，校验 .sop/state.json 的合法性。
# 仅当 .sop/state.json 存在时才执行校验，避免影响非 SOP 项目。
#
# 校验规则：
# 1. JSON 格式合法
# 2. current_phase 在合法集合中
# 3. 各阶段 status 在合法集合中
# 4. 若 phase.status = "done"，必须有 completed_at
# 5. 若 current_phase = "DONE"，open_issues 中不应有 status = "open" 的 Critical
#
# 退出码：
#   0 = 校验通过，或 state.json 不存在（非 SOP 项目）
#   1 = 警告（不阻断，仅提示）
#   2 = 错误（建议人工介入）

set -uo pipefail

STATE_FILE=".sop/state.json"

# 非 SOP 项目，直接放行
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# 检查 jq 是否可用
if ! command -v jq &> /dev/null; then
  echo "⚠️  [SOP Hook] jq 未安装，跳过状态校验。建议安装：brew install jq / apt install jq"
  exit 0
fi

# 校验 JSON 格式
if ! jq empty "$STATE_FILE" 2>/dev/null; then
  echo "🔴 [SOP Hook] .sop/state.json JSON 格式错误，请人工检查。"
  exit 2
fi

# 提取关键字段
CURRENT_PHASE=$(jq -r '.current_phase // "UNKNOWN"' "$STATE_FILE")
VALID_PHASES=("PLANNING" "ARCHITECTURE" "IMPLEMENTATION" "OPTIMIZATION" "REVIEW" "DONE")

# 校验 current_phase 合法性
phase_valid=0
for valid in "${VALID_PHASES[@]}"; do
  if [[ "$CURRENT_PHASE" == "$valid" ]]; then
    phase_valid=1
    break
  fi
done

if [[ $phase_valid -eq 0 ]]; then
  echo "🔴 [SOP Hook] current_phase 非法值：$CURRENT_PHASE"
  echo "    合法值：${VALID_PHASES[*]}"
  exit 2
fi

# 校验各阶段 status 与 completed_at 一致性
INCONSISTENT=$(jq -r '
  .phases | to_entries[] |
  select(.value.status == "done" and (.value.completed_at == null or .value.completed_at == "")) |
  .key
' "$STATE_FILE")

if [[ -n "$INCONSISTENT" ]]; then
  echo "⚠️  [SOP Hook] 以下阶段标记为 done 但缺少 completed_at："
  echo "$INCONSISTENT" | sed 's/^/    - /'
  exit 1
fi

# 校验：若 current_phase = DONE，不应有未修复的 Critical
if [[ "$CURRENT_PHASE" == "DONE" ]]; then
  OPEN_CRITICAL=$(jq -r '
    [.open_issues[] | select(.level == "critical" and .status == "open")] | length
  ' "$STATE_FILE")

  if [[ "$OPEN_CRITICAL" -gt 0 ]]; then
    echo "⚠️  [SOP Hook] 任务标记为 DONE 但仍有 $OPEN_CRITICAL 个未修复 Critical 问题。"
    echo "    建议：执行 /sop-status 查看详情，或继续修复后再标记完成。"
    exit 1
  fi
fi

# 全部校验通过
exit 0
