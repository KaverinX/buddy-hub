#!/usr/bin/env bash
# flowsmith 测试绿灯门禁：在 IMPLEMENTATION → OPTIMIZATION 迁移前校验测试全绿。
# 由 PostToolUse / 阶段迁移触发；非 git/非测试项目优雅降级。
set -uo pipefail

STATE=".sop/state.json"
[ -f "$STATE" ] || exit 0

PHASE=$(grep -o '"current_phase"[^,]*' "$STATE" | sed 's/.*: *"\([^"]*\)".*/\1/')
# 仅在 IMPLEMENTATION 阶段关心绿灯
[ "$PHASE" = "IMPLEMENTATION" ] || exit 0

CMD=$(grep -o '"command"[^,]*' "$STATE" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
if [ -z "$CMD" ] || [ "$CMD" = "null" ]; then
  echo "[flowsmith] test_gate.command 未配置，跳过绿灯校验。用 /sop-test --command=... 设置。" >&2
  exit 0
fi

echo "[flowsmith] 运行测试门禁：$CMD" >&2
if eval "$CMD" >/tmp/flowsmith-test.log 2>&1; then
  echo "[flowsmith] ✅ 测试通过（green）。允许进入 OPTIMIZATION。" >&2
  # last_status -> passed（简单替换，缺字段则不动，由命令层兜底）
  exit 0
else
  echo "[flowsmith] 🔴 测试未通过。IMPLEMENTATION → OPTIMIZATION 被拒绝（绿灯门禁）。" >&2
  echo "[flowsmith] 详见 /tmp/flowsmith-test.log，修复后重试。" >&2
  exit 2
fi
