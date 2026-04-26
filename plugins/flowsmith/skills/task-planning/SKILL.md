---
name: task-planning
description: 任务规划 Skill。在 SOP 流程的 PLANNING 阶段使用，对用户提出的开发任务进行系统性分解、风险识别、影响范围分析，产出 .sop/plan.md。当 .sop/state.json 中 current_phase 为 PLANNING 时由 Claude 主动触发。
---

# 任务规划（task-planning）

## 前置读取（每次执行必须先做）

1. 读取 `reference/state-machine.md` — 确认状态转换规则
2. 读取 `reference/document-schemas.md` — 获取 plan.md 格式定义
3. 读取 `.sop/state.json` — 确认当前 phase = PLANNING，若不是则拒绝执行并提示
4. 读取 `.sop/lessons.md`（若存在）— 提取与本次任务相关的历史教训

## 执行指令

你现在进入 **【阶段 1：任务规划（PLANNING）】**。

### Step 1 — 更新状态

将 `.sop/state.json` 中 `PLANNING.status` 改为 `"running"`。

### Step 2 — 深度任务分析（内部推导，不输出）

在生成文档前，先做以下思考：

**需求分析**
- 用户的显性需求是什么？
- 有哪些隐性需求没有被明说但必然存在？（如：性能要求、向后兼容、错误处理）
- 有哪些假设需要在规划中明确？

**约束识别**
- 技术栈约束：项目已有的框架、语言版本不可随意更改
- 接口约束：现有 API 调用方不可破坏（Hyrum's Law）
- 时间约束：工作量是否在可接受范围，否则应建议拆分

**风险评估方法论**
- 不确定性来源：需求模糊 / 技术不熟悉 / 依赖第三方
- 影响路径分析：这个改动的"蝴蝶效应"会传播多远
- 失败模式枚举：如果出错，最可能在哪里出错

### Step 3 — 生成 plan.md

严格按照 `reference/document-schemas.md` 中 `plan.md` 格式生成文档。

**质量要求**：
- 子任务粒度：每个子任务应在 2-4 小时内可完成，否则继续拆分
- 依赖关系：必须识别可并行的子任务，为后续优化执行顺序提供依据
- 历史教训引用：若 `lessons.md` 中有相关内容，必须在"历史教训引用"一节引用，不允许留空"无"（除非确实无关联）
- 风险矩阵：至少识别 2 条风险，并提供可操作的应对策略，不接受"加强测试"这类空洞策略

### Step 4 — 更新状态

将 `.sop/state.json` 中：
```json
{
  "PLANNING": { "status": "done", "completed_at": "<当前 ISO8601 时间>" }
}
```

### Step 5 — 向用户汇报

```
✅ 规划完成

任务拆解为 {N} 个子任务，其中 {M} 个可并行执行。

主要风险：
- 🔴 {最高风险描述}
- 🟡 {次要风险描述}

引用历史教训：{引用条数} 条

工作量评估：{S/M/L/XL}

是否确认规划，进入架构设计阶段？（有修改意见请直接说明）
```

## 拒绝执行的条件

- `.sop/state.json` 不存在 → 提示：`请先执行 /sop-init <任务描述>`
- `state.json` 中 `current_phase` 不是 `PLANNING` → 提示当前所在阶段及正确操作
- `PLANNING.status` 已是 `done` → 提示：规划已完成，如需修改请说明修改点
