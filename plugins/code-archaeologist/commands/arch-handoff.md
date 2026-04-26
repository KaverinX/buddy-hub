---
description: 将考古结论手动注入到 flowsmith 任务的 plan.md（自动或手动触发）
---

# /arch-handoff — flowsmith 集成

## 用途

将 `.archaeology/report.md` 的关键结论注入到 `.sop/plan.md` 的"约束与前提"章节，
使 flowsmith 的规划/架构/编码阶段都能感知考古发现，避免踩坑。

通常由 `/arch-report` 在检测到 flowsmith 上下文时**自动调用**，
也可以在以下场景**手动调用**：
- 考古完成后才决定启动 flowsmith
- flowsmith 任务中途，想引用一份历史考古的结论

## 执行步骤

### Step 1 — 校验前置条件

**校验 1**：考古报告存在
读取 `.archaeology/state.json`，确认 `report.status = "done"`。
否则：
> "考古报告尚未生成。请先执行 /arch-report。"
> 停止。

**校验 2**：flowsmith 已安装且有进行中的任务
读取 `.sop/state.json`：
- 文件不存在：
  > "未找到 .sop/state.json，flowsmith 任务不存在。
  > 请先执行 /sop-init 启动 flowsmith 任务，再执行本命令。
  > 或参考 .archaeology/report.md 手动整合考古结论。"
  > 停止。
- 文件存在但 `current_phase` 已不在 PLANNING 或 ARCHITECTURE：
  > "⚠️ flowsmith 当前阶段为 {current_phase}，已过规划/架构阶段。
  > 仍要注入考古结论吗？这会修改 plan.md，但可能与已完成的架构设计不一致。(y/N)"
  > 用户确认后继续。

### Step 2 — 提取考古关键结论

从 `.archaeology/report.md` 提取以下字段：

- `archaeology_id`
- `target.path`
- `risk_level`
- `recommended_strategy`
- `不可跨越的红线` 一节的全部内容
- `重构前置条件清单` 一节的全部内容
- `关键发现汇总` 一节的全部内容

### Step 3 — 注入到 .sop/plan.md

#### 3a. 检查是否已有考古引用块
扫描 `plan.md`，查找标记 `<!-- archaeology:injected:{archaeology_id} -->`：
- 若已存在：提示用户是否覆盖
- 若不存在：在"约束与前提"章节末尾追加

#### 3b. 追加内容（在"约束与前提"末尾）

```markdown

<!-- archaeology:injected:{archaeology_id} -->
### 来自代码考古的约束（archaeology_id: {archaeology_id}）

> 完整考古报告：`.archaeology/report.md`
> 风险评级：{risk_level}
> 推荐策略：{recommended_strategy}

#### 不可跨越的红线
{从 report.md 复制"不可跨越的红线"全部内容}

#### 重构前置条件清单
{从 report.md 复制"重构前置条件清单"全部内容}

#### 关键发现摘要
{从 report.md 复制"关键发现汇总"全部内容}

<!-- archaeology:injected:end -->
```

### Step 4 — 互相回链

#### 4a. 在 .archaeology/state.json 中记录关联
更新：
```json
{
  "context": {
    "flowsmith_task_id": "<sop state.task_id>",
    "trigger": "<原值>"
  },
  "handoff": {
    "injected_at": "<ISO8601>",
    "target_file": ".sop/plan.md",
    "injected_marker": "archaeology:injected:{archaeology_id}"
  }
}
```

#### 4b. 在 .sop/state.json 中记录关联
读取 .sop/state.json，追加（不破坏现有字段）：
```json
{
  "linked_archaeologies": [
    {
      "archaeology_id": "<id>",
      "target": "<path>",
      "linked_at": "<ISO8601>",
      "report_path": ".archaeology/report.md"
    }
  ]
}
```

注意：`linked_archaeologies` 是数组，可能有多次考古关联到同一 flowsmith 任务（如先考古模块 A，再考古模块 B）。

### Step 5 — 输出确认

```
🔗 考古结论已注入 flowsmith

考古 ID：{archaeology_id}
flowsmith 任务：{flowsmith_task_id}
目标文件：.sop/plan.md（追加于"约束与前提"章节）

注入内容：
  - 风险评级与推荐策略
  - {N} 条不可跨越的红线
  - {M} 条重构前置条件
  - {K} 条关键发现

下一步：
  - flowsmith 后续阶段（规划/架构/编码）将自动感知这些约束
  - 重构编码时如果发现违反红线的实现，flowsmith 的 reviewer 会标记为 Critical
  - 任务完成后，/sop-close 会将考古经验汇总到 .sop/lessons.md
```

---

## 设计说明：为什么这是关键的协同点

flowsmith 的 plan.md 是**所有后续阶段的输入**：
- arch-design 读它做架构决策
- implementation-guide 读它确定子任务边界
- reviewer 读它做需求覆盖矩阵

把考古结论注入到这一份"上游契约"中，意味着**考古发现的所有约束会自动渗透到下游所有阶段**，
而不需要在每个阶段单独提醒。这是 plugin 协同的最干净实现方式。
