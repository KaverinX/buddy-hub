---
description: 任务完成后归档，提炼经验写入 lessons.md 知识库
---

# /sop-close — 任务归档与经验沉淀

## 前置条件

读取 `.sop/state.json`：
- `current_phase` 必须为 `"DONE"`，否则：
  > "任务尚未完成（当前阶段：{current_phase}）。请先完成所有阶段再执行归档。"
  > 停止执行。

## 执行步骤

### Step 1 — 读取本次任务的完整记录

依次读取：
- `.sop/plan.md` — 任务规划与子任务
- `.sop/arch.md` — 所有 ADR 决策记录
- `.sop/review.md` — 所有轮次的审查报告
- `.sop/fixes.md`（若存在）— 修复了哪些问题

### Step 2 — 经验提炼（内部推导，不输出）

思考四个问题：
1. 哪些设计决策值得未来类似任务复用？（来自 ADR）
2. 踩过什么坑？根因是什么？（来自 review 中被修复的 Critical 问题）
3. 哪些类型的问题在本任务中反复出现？
4. 下次类似任务应该在哪个阶段、用什么方式提前规避？

### Step 3 — 追加 lessons.md

将提炼的经验以下面的结构化格式追加到 `.sop/lessons.md`（不覆盖历史记录）：

```markdown

---

## 任务 {task_id}：{task_summary}

归档时间：{ISO8601}
审查轮次：{iteration}
关键词：{从 task_summary 和 arch.md 中提取 3-5 个关键词，便于后续 /sop-init 时匹配}

### 架构决策（可复用）

{对每条核心 ADR，按以下格式：}
- **情境**：{什么场景下面临此决策}
- **决策**：{选择了哪个方案}
- **结果**：{实际落地后的效果，包括意外收获和代价}

### 踩坑记录

{对每个被修复的 Critical 问题：}
- **坑**：{描述}
  **根因**：{为什么会出现这个问题}
  **规避方法**：{下次应该在哪个阶段、用什么方式避免}

### 审查发现的典型问题

{按 reviewer 分类：}
- **arch-reviewer 类**：{本任务中典型的架构偏离类型}
- **security-reviewer 类**：{本任务中典型的安全问题类别}
- **logic-reviewer 类**：{本任务中典型的逻辑或边界问题}

### 对 SOP 流程本身的改进建议

{若执行中发现 SOP 流程有不合理之处，记录于此供未来优化 SOP plugin}
```

### Step 4 — 归档 state.json

更新 `state.json`，添加归档标记：
```json
{
  "archived_at": "<ISO8601>",
  "lessons_written": true
}
```

### Step 5 — 输出归档确认

```
✅ 任务 {task_id} 已归档

经验已写入 .sop/lessons.md：
  - 架构决策：{N} 条
  - 踩坑记录：{M} 条
  - 典型问题：{K} 条

累计经验库：{lessons.md 总条目数} 条历史任务记录

下次执行 /sop-init 时，规划阶段将自动引用与新任务相关的历史经验。
```
