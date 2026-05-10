# SOP 状态机契约（State Machine Schema）

本文件定义整个 SOP 系统的状态机模型。所有 Skill、Subagent、Command 读写
`.sop/state.json` 时，必须严格遵循此契约，不得假设字段含义或自行扩展格式。

## `.sop/state.json` 完整结构（version 1.1）

```json
{
  "version": "1.1",
  "task_id": "<8 字符随机字符串>",
  "task_summary": "<一句话概括任务>",
  "current_phase": "<PHASE_NAME>",
  "phases": {
    "PLANNING":      { "status": "...", "completed_at": null, "output": ".sop/plan.md" },
    "ARCHITECTURE":  { "status": "...", "completed_at": null, "output": ".sop/arch.md" },
    "IMPLEMENTATION":{ "status": "...", "completed_at": null, "output": "src/" },
    "OPTIMIZATION":  { "status": "...", "completed_at": null, "output": "src/" },
    "REVIEW":        { "status": "...", "completed_at": null, "output": ".sop/review.md" }
  },
  "git_context": {
    "base_branch": "main",
    "head_branch": "feat/notification",
    "worktree_path": "/Users/dev/repos/proj-feat-notification",
    "is_worktree": true
  },
  "open_issues": [],
  "change_records": {
    "next_id": 1,
    "log_file": ".sop/changelog.md"
  },
  "iteration": 1,
  "created_at": "<ISO8601>",
  "archived_at": null,
  "lessons_written": false
}
```

### version 历史

- `1.0` — 不含 `git_context` 和 `change_records`，由旧版 /sop-init 创建
- `1.1` — 增加 `git_context`（worktree/branch 元信息）和 `change_records`（changelog.md 维护）

## 1.0 → 1.1 迁移规则

迁移**纯增量、可重跑、不破坏老数据**。由 `/sop-diff --backfill` 自动触发，规则：

1. 添加 `git_context`：自动探测当前 git 环境
   - `base_branch`：优先 `git symbolic-ref refs/remotes/origin/HEAD`，回退 main/master/develop
   - `head_branch`：当前分支
   - `worktree_path`：`git rev-parse --show-toplevel`
   - `is_worktree`：判断 `git rev-parse --git-dir` 是否含 `worktrees/`
   - 不是 git 仓库时四项均 `null`
2. 添加 `change_records`：`{ "next_id": 1, "log_file": ".sop/changelog.md" }`
3. 升级 `version` 字段为 `"1.1"`
4. 不修改任何已有字段（包括 phases / open_issues / iteration / 时间戳等）

工具读取时：
- 1.0 任务对 /sop-status、/sop-resume、/sop-review、/sop-close 等只读型命令仍能工作（缺失字段降级处理）
- 1.0 任务执行 /sop-diff 时，提示用户先 `/sop-diff --backfill` 完成升级
- 升级是幂等的：对已经是 1.1 的任务无副作用

## git_context 字段说明

| 字段 | 含义 | 取值规则 |
|------|------|---------|
| `base_branch` | 本任务的对比基线分支 | /sop-init 时探测，可被 /sop-diff 的 `--base=` 临时覆盖 |
| `head_branch` | 本任务对应的工作分支 | /sop-init 时记录；切换分支后会失真，仅做参考 |
| `worktree_path` | 任务所在工作区根路径 | 用于排查"我在哪个 worktree" |
| `is_worktree` | 是否运行在 git worktree 中 | true 则可在 `git worktree list` 中找到 |

非 git 项目下，四项均为 `null`，`/sop-diff` 不可用。

## change_records 字段说明

| 字段 | 含义 | 维护方 |
|------|------|-------|
| `next_id` | 下一条 CR 应使用的编号（自增）| implementation-guide skill 在每次写完一条 CR 后自增；--backfill 一次性多次自增 |
| `log_file` | 变更日志文件路径 | 默认 `.sop/changelog.md`，理论上不应改 |

## 阶段 status 取值

- `pending`  — 尚未开始
- `running`  — 进行中
- `done`     — 已完成（必须设置 completed_at）
- `skipped`  — 显式跳过（必须附理由）
- `failed`   — 仅 REVIEW 阶段使用，表示发现 Critical 问题需返工

## 合法状态迁移表（FSM Transition Table）

```
INIT          → PLANNING       条件：state.json 不存在，由 /sop-init 创建
PLANNING      → ARCHITECTURE   条件：plan.md 存在 且 用户确认
ARCHITECTURE  → IMPLEMENTATION 条件：arch.md 存在 且 用户确认
IMPLEMENTATION→ OPTIMIZATION   条件：用户声明编码完成 且 changelog 无未备注改动
OPTIMIZATION  → REVIEW         条件：optimizer subagent 退出
REVIEW        → IMPLEMENTATION 条件：review.md 中存在 status=open 的 Critical 问题
REVIEW        → DONE           条件：review.md 中无 status=open 的 Critical 问题
DONE          → archived       条件：/sop-close 执行
```

注：`/sop-diff --backfill` **不影响 phase**——它只读 git diff、写 changelog.md，
即使 current_phase 为 OPTIMIZATION/REVIEW/DONE 也允许执行。

## 非法迁移（必须拒绝并提示）

- 跳过 PLANNING 直接进 ARCHITECTURE（除非 PLANNING.status = "skipped" 且 task_summary 已填写）
- 跳过 ARCHITECTURE 直接进 IMPLEMENTATION
- 在 REVIEW.status = "running" 时重新触发 REVIEW
- 任何当前阶段 status = "running" 时触发同阶段再次启动
- DONE 状态下未执行 /sop-close 就开始新任务

## open_issues 数组元素结构

```json
{
  "id": "C-1",
  "level": "critical|warning|info",
  "description": "...",
  "location": "src/auth.ts:42",
  "source_reviewer": "arch-reviewer|security-reviewer|logic-reviewer",
  "status": "open|fixed|wontfix",
  "fixed_at": null,
  "found_in_iteration": 1
}
```

## 跳过阶段的合法场景

跳过必须显式标记 `"status": "skipped"` 并在 `task_summary` 中附理由：
- 单行 typo / 配置修改 → 可跳过 PLANNING 和 ARCHITECTURE
- 纯文档更新 → 可跳过所有阶段
- 紧急热修复 → 可跳过 PLANNING/ARCHITECTURE，REVIEW 不可跳过
