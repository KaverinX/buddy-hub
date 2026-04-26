---
description: 初始化新的 SOP 任务，创建 .sop/ 目录与 state.json，进入 PLANNING 阶段
argument-hint: <任务描述>
---

# /sop-init — 初始化 SOP 任务

任务描述：$ARGUMENTS

## 执行步骤

### Step 1 — 前置检查

检查 `.sop/state.json` 是否已存在：
- 若存在且 `current_phase` 不是 `DONE` 或 `archived_at` 字段不存在，输出：
  > "发现未完成的任务：{task_summary}（当前阶段：{current_phase}）。
  > 如需继续该任务，请执行 /sop-resume。
  > 如需放弃并开始新任务，请删除 .sop/state.json 后重新执行 /sop-init。"
  > 然后停止执行。

### Step 2 — 创建目录结构

```bash
mkdir -p .sop
```

### Step 3 — 初始化 state.json

写入 `.sop/state.json`，结构严格遵循 task-planning skill 的 reference/state-machine.md：

```json
{
  "version": "1.0",
  "task_id": "<生成 8 位随机字符串>",
  "task_summary": "<$ARGUMENTS 原文>",
  "current_phase": "PLANNING",
  "phases": {
    "PLANNING":       { "status": "pending", "completed_at": null, "output": ".sop/plan.md" },
    "ARCHITECTURE":   { "status": "pending", "completed_at": null, "output": ".sop/arch.md" },
    "IMPLEMENTATION": { "status": "pending", "completed_at": null, "output": "src/" },
    "OPTIMIZATION":   { "status": "pending", "completed_at": null, "output": "src/" },
    "REVIEW":         { "status": "pending", "completed_at": null, "output": ".sop/review.md" }
  },
  "open_issues": [],
  "iteration": 1,
  "created_at": "<当前 ISO8601 时间>"
}
```

### Step 4 — 初始化 lessons.md（若不存在）

若 `.sop/lessons.md` 不存在，创建：

```markdown
# SOP 经验积累库

本文件由 /sop-close 自动维护。每次任务完成后追加，不删除历史记录。

---
```

### Step 5 — 引用历史经验

读取 `.sop/lessons.md`，提取与当前任务（$ARGUMENTS）相关的历史教训。
关键词匹配标准：技术栈、模块名、问题类别（如"通知"、"认证"、"队列"）。

### Step 6 — 输出确认

```
✅ SOP 初始化完成

任务 ID：{task_id}
任务描述：{task_summary}
当前状态：PLANNING

历史教训：{N} 条可参考（来自 .sop/lessons.md）
{若 N > 0，列出每条的简短标题}

下一步：开始任务规划。
请触发 task-planning skill 进入规划阶段。
```
