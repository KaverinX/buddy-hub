# SOP 状态机契约（State Machine Schema）

本文件定义整个 SOP 系统的状态机模型。所有 Skill、Subagent、Command 读写
`.sop/state.json` 时，必须严格遵循此契约，不得假设字段含义或自行扩展格式。

## `.sop/state.json` 完整结构

```json
{
  "version": "1.0",
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
  "open_issues": [],
  "iteration": 1,
  "created_at": "<ISO8601>",
  "archived_at": null,
  "lessons_written": false
}
```

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
IMPLEMENTATION→ OPTIMIZATION   条件：用户声明编码完成
OPTIMIZATION  → REVIEW         条件：optimizer subagent 退出
REVIEW        → IMPLEMENTATION 条件：review.md 中存在 status=open 的 Critical 问题
REVIEW        → DONE           条件：review.md 中无 status=open 的 Critical 问题
DONE          → archived       条件：/sop-close 执行
```

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
