---
description: 从 state.json 检查点恢复中断的 SOP 任务
---

# /sop-resume — 任务断点恢复

## 执行步骤

### Step 1 — 读取状态

读取 `.sop/state.json`：
- 若文件不存在，输出：
  > "未找到 .sop/state.json，没有进行中的任务可以恢复。
  > 请执行 /sop-init <任务描述> 开始新任务。"
  > 停止执行。

### Step 2 — 重建上下文摘要

输出任务状态恢复报告：

```
📋 任务恢复报告
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

任务：{task_summary}
任务 ID：{task_id}
当前阶段：{current_phase}
第 {iteration} 轮

Git 上下文：（version >= 1.1 时显示）
  分支：{head_branch}{若 is_worktree：' (worktree)'}
  基线：{base_branch 或 '⚠️ 未配置，/sop-diff 时需 --base= 指定'}

阶段进度：
{对每个阶段输出，根据 status 选择图标：
  - pending  → ⬜
  - running  → ⏳
  - done     → ✅（附 completed_at）
  - skipped  → ⏭️
  - failed   → 🔴
}

变更记录：（若 changelog.md 存在）
  - 已记录 {N} 条 CR
  - 最近一条：CR-{n} {标题}（{timestamp}）
  - 涉及文件：{distinct file count} 个

未解决问题：{open_issues 中 status="open" 的数量} 个
{若有，列出每条 Critical 问题}

产出文件检查：
  - .sop/plan.md：{是否存在，最后修改时间}
  - .sop/arch.md：{是否存在，最后修改时间}
  - .sop/changelog.md：{是否存在，最后修改时间，CR 数量}
  - .sop/review.md：{是否存在，最后修改时间}
  - .sop/fixes.md：{是否存在，未修复 Critical 数量}
```

### Step 3 — 引导继续执行

根据 `current_phase` 给出明确的下一步指令：

| current_phase | 输出指令 |
|--------------|---------|
| `PLANNING` | "请触发 task-planning skill 继续规划，或确认进入架构阶段。" |
| `ARCHITECTURE` | "请触发 arch-design skill 继续架构设计，或确认进入编码阶段。" |
| `IMPLEMENTATION` | "请继续编码。参考 .sop/arch.md 的模块定义和 .sop/plan.md 的子任务进度。建议先执行 /sop-diff 查看截至目前的带备注改动，回到上下文。{若 open_issues 非空：'优先处理以下 Critical 修复任务：...'}" |
| `OPTIMIZATION` | "请调用 @optimizer 继续优化阶段。可先 /sop-diff 复习改动。" |
| `REVIEW` | "请执行 /sop-review 重新触发审查（上次审查可能未完成）。" |
| `DONE` | "任务已完成！请执行 /sop-close 归档经验。" |

### Step 4 — 状态完整性校验

执行以下健康检查并输出警告：
- `PLANNING.status = done` 但 `.sop/plan.md` 不存在 → ⚠️ 状态与产出不一致
- `ARCHITECTURE.status = done` 但 `.sop/arch.md` 不存在 → ⚠️ 状态与产出不一致
- `current_phase = DONE` 但仍有未修复 Critical → ⚠️ 数据异常
- `current_phase` 已离开 IMPLEMENTATION 但仍有未备注改动（粗略对账：git diff 文件数 > changelog 文件数）→ ⚠️ 建议执行 /sop-diff --unannotated 后补记
