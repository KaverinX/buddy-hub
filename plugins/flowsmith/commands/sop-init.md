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

### Step 3 — 探测 git 上下文（用于 worktree 流和 /sop-diff）

按以下顺序探测，结果存入 state.json：

1. **base_branch** — 本任务相对哪个分支衡量"本次改动"
   - 优先读 `git symbolic-ref refs/remotes/origin/HEAD --short`，去掉 `origin/` 前缀
   - 失败则按顺序尝试：`main` / `master` / `develop`
   - 都不存在则置为 `null`，并提示用户在首次执行 `/sop-diff` 时用 `--base=` 显式指定

2. **head_branch** — 当前分支（`git rev-parse --abbrev-ref HEAD`）

3. **worktree_path** — 当前工作区路径（`git rev-parse --show-toplevel`）

4. **is_worktree** — 是否在 git worktree 中（检查 `git rev-parse --git-dir` 是否包含 `worktrees/`）

若不是 git 仓库，四项均置 `null`，不阻断流程（SOP 也支持非 git 项目，但 `/sop-diff` 不可用）。

### Step 4 — 初始化 state.json

写入 `.sop/state.json`，结构严格遵循 task-planning skill 的 reference/state-machine.md：

```json
{
  "version": "1.1",
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
  "git_context": {
    "base_branch": "<Step 3 探测结果或 null>",
    "head_branch": "<Step 3 探测结果或 null>",
    "worktree_path": "<Step 3 探测结果或 null>",
    "is_worktree": <true/false>
  },
  "open_issues": [],
  "change_records": {
    "next_id": 1,
    "log_file": ".sop/changelog.md"
  },
  "iteration": 1,
  "created_at": "<当前 ISO8601 时间>"
}
```

> 注：`version` 升至 `1.1` 标识包含 `git_context` 与 `change_records` 字段。校验 hook 兼容老版本 1.0。

### Step 5 — 初始化 lessons.md（若不存在）

若 `.sop/lessons.md` 不存在，创建：

```markdown
# SOP 经验积累库

本文件由 /sop-close 自动维护。每次任务完成后追加，不删除历史记录。

---
```

### Step 6 — 初始化 changelog.md

创建 `.sop/changelog.md`（覆盖已有同名文件，因为这是新任务）：

```markdown
# 变更日志（Change Log）

> task_id: {task_id}
> task: {task_summary}
> base_branch: {git_context.base_branch}
> head_branch: {git_context.head_branch}
> worktree: {git_context.worktree_path}
> 由 implementation-guide 中"变更日志纪律"在实施阶段维护
> 通过 /sop-diff 查看带备注的 diff

---
```

### Step 7 — 引用历史经验

读取 `.sop/lessons.md`，提取与当前任务（$ARGUMENTS）相关的历史教训。
关键词匹配标准：技术栈、模块名、问题类别（如"通知"、"认证"、"队列"）。

### Step 8 — 输出确认

```
✅ SOP 初始化完成

任务 ID：{task_id}
任务描述：{task_summary}
当前状态：PLANNING

Git 上下文：
  分支：{head_branch}{若 is_worktree：' (worktree)'}
  基线：{base_branch}{若 base_branch=null：' ⚠️ 未探测到，/sop-diff 时需 --base=<branch> 指定'}

历史教训：{N} 条可参考（来自 .sop/lessons.md）
{若 N > 0，列出每条的简短标题}

下一步：开始任务规划。
请触发 task-planning skill 进入规划阶段。

提示：实施阶段开始后，可随时执行 /sop-diff 查看带备注的 diff。
```
