---
description: 综合三个考古员的输出，生成最终考古报告与重构策略建议
---

# /arch-report — 生成综合报告

## 执行步骤

### Step 1 — 状态校验

读取 `.archaeology/state.json`：

- 若三个 agent 的 status 不都为 `done`：
  > "考古尚未完成。当前状态：
  >   📜 history-archaeologist: {status}
  >   🕸️  dependency-archaeologist: {status}
  >   💭 intent-archaeologist: {status}
  > 请先完成所有考古员工作，或执行 /arch-resume 恢复中断的考古员。"
  > 停止执行。

- 若 `report.status = "done"`：
  > "考古报告已存在：.archaeology/report.md
  > 是否重新生成？(y/N)"
  > 用户确认后才覆盖。

### Step 2 — 触发 refactor-strategy skill

调用 `refactor-strategy` skill 生成报告。
该 skill 会读取三个 agent 的输出，结合 `${CLAUDE_PLUGIN_ROOT}/schemas/report-schemas.md` 中 `report.md` 格式生成最终报告。

### Step 3 — 解析报告关键字段并回写 state.json

从生成的 `report.md` 中提取：
- Risk Level → `state.report.risk_level`
- Strategy → `state.report.recommended_strategy`

写回 `state.json`。

将 `state.report.status` 改为 `"done"`。

### Step 4 — flowsmith 集成（核心协同逻辑）

**判断条件**：`context.trigger == "flowsmith-recommended"` 且 `context.flowsmith_task_id` 不为 null

若满足，自动调用 `/arch-handoff` 命令将考古结论注入 flowsmith：

```
🔗 检测到 flowsmith 任务关联（task_id: {flowsmith_task_id}）
   正在自动注入考古结论到 .sop/plan.md ...
```

执行 `/arch-handoff` 完成回传。

### Step 5 — 输出报告摘要

```
📋 考古报告生成完成

文件：.archaeology/report.md

🎯 风险评级：{risk_level}
🛠️  推荐策略：{recommended_strategy}

关键发现：
{从 report.md 的"关键发现汇总"章节摘抄前 3 条}

{若 trigger == flowsmith-recommended：
  '🔗 已自动注入到 flowsmith 任务 {flowsmith_task_id} 的 plan.md
   接下来可继续 flowsmith 流程，规划阶段会引用本考古结论'
}
{若 trigger == manual：
  '下一步建议：
   - 若策略为 safe-refactor / staged-refactor：执行 /sop-init 启动 flowsmith 重构流程
   - 若策略为 freeze-and-document：执行 /arch-freeze 冻结决策
   - 若策略为 escalate：将 .archaeology/report.md 提交架构评审'
}

执行 /arch-close 归档本次考古，并将经验沉淀到 .sop/lessons.md（若 flowsmith 已安装）。
```
