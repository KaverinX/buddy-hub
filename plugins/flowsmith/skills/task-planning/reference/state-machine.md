# SOP 状态机契约（State Machine Schema）

本文件定义整个 SOP 系统的状态机模型。所有 Skill、Subagent、Command 读写
`.sop/state.json` 时，必须严格遵循此契约，不得假设字段含义或自行扩展格式。

## `.sop/state.json` 完整结构（version 1.2）

```json
{
  "version": "1.2",
  "task_id": "<8 字符随机字符串>",
  "task_summary": "<一句话概括任务>",
  "current_phase": "<PHASE_NAME>",
  "phases": {
    "PLANNING":      { "status": "...", "completed_at": null, "output": ".sop/plan.md" },
    "ARCHITECTURE":  { "status": "...", "completed_at": null, "output": ".sop/arch.md" },
    "TEST_FIRST":    { "status": "...", "completed_at": null, "output": ".sop/tests-plan.md" },
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
  "test_gate": {
    "command": "<运行测试的命令，如 `npm test` / `mvn -q test`>",
    "last_status": "unknown",
    "last_run_at": null
  },
  "spec_context": {
    "linked_change_id": null,
    "spec_dir": "spec/"
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

- `1.0` — 不含 `git_context` 和 `change_records`
- `1.1` — 增加 `git_context` 与 `change_records`
- `1.2` — 新增 **TEST_FIRST 阶段**（对标 Superpowers TDD）、`test_gate`（测试绿灯门禁元信息）、
  `spec_context`（对标 OpenSpec，关联 spec-keeper 的变更）。纯增量、可重跑、不破坏老数据。

## 1.1 → 1.2 迁移规则

迁移**纯增量、可重跑、不破坏老数据**：

1. `phases` 中在 ARCHITECTURE 与 IMPLEMENTATION 之间插入 `TEST_FIRST`：
   `{ "status": "pending", "completed_at": null, "output": ".sop/tests-plan.md" }`
   - 老任务若 current_phase 已越过 ARCHITECTURE，则 TEST_FIRST 直接置 `"skipped"`，理由 `"1.2 迁移：任务在引入 TDD 前已开工"`
2. 添加 `test_gate`：`command` 自动探测（见下），探不到留空由用户首次 /sop-test 时填
3. 添加 `spec_context`：`{ "linked_change_id": null, "spec_dir": "spec/" }`
4. 升级 `version` 为 `"1.2"`，不修改任何已有字段
5. 幂等：对已是 1.2 的任务无副作用

## test_gate 字段说明

| 字段 | 含义 | 维护方 |
|------|------|--------|
| `command` | 运行全部相关测试的命令 | /sop-init 探测（package.json→`npm test`、pom.xml→`mvn -q test`、build.gradle→`gradle test`、pytest→`pytest`），探不到则用户填 |
| `last_status` | `passed` / `failed` / `unknown` | `hooks/validate-tests.sh` 在阶段迁移时写入 |
| `last_run_at` | 上次跑测试时间 | 同上 |

## spec_context 字段说明

| 字段 | 含义 |
|------|------|
| `linked_change_id` | 关联的 spec-keeper 变更 id（`spec/changes/<id>/`）；无则 null |
| `spec_dir` | living spec 根目录，默认 `spec/` |

/sop-init 时若检测到 `spec/` 存在且当前变更可匹配，记录 `linked_change_id`，PLANNING 阶段把对应 living spec 作为硬约束注入 plan.md。

## 阶段 status 取值

- `pending` / `running` / `done`（须 completed_at） / `skipped`（须附理由） / `failed`（仅 REVIEW）

## 合法状态迁移表（FSM Transition Table）

```
INIT          → PLANNING       条件：state.json 不存在，由 /sop-init 创建
PLANNING      → ARCHITECTURE   条件：plan.md 存在 且 用户确认
ARCHITECTURE  → TEST_FIRST     条件：arch.md 存在 且 用户确认
TEST_FIRST    → IMPLEMENTATION 条件：tests-plan.md 存在 且 至少一条测试处于"红"（失败因功能未实现）
IMPLEMENTATION→ OPTIMIZATION   条件：【测试绿灯门禁】test_gate.last_status = "passed" 且 changelog 无未备注改动
OPTIMIZATION  → REVIEW         条件：optimizer subagent 退出
REVIEW        → IMPLEMENTATION 条件：review.md 中存在 status=open 的 Critical 问题
REVIEW        → DONE           条件：review.md 中无 status=open 的 Critical 问题
DONE          → archived       条件：/sop-close 执行
```

> 关键新增：**`IMPLEMENTATION → OPTIMIZATION` 是绿灯门禁**。迁移前由 `hooks/validate-tests.sh`
> 运行 `test_gate.command`，非 `passed` 则拒绝迁移并 emit `test.gate.blocked`。这是对标 Superpowers
> "测试不绿不准走"的硬约束，也是 flowsmith「过程即护栏」口号的真正落地。

注：`/sop-diff --backfill` 不影响 phase。

## 非法迁移（必须拒绝并提示）

- 跳过 PLANNING / ARCHITECTURE（除非显式 skipped 且附理由）
- **跳过 TEST_FIRST 直接进 IMPLEMENTATION**（除非 TEST_FIRST.status = "skipped" 且附理由）
- **测试未绿就从 IMPLEMENTATION 进 OPTIMIZATION**
- REVIEW.status = "running" 时重新触发 REVIEW
- 任何当前阶段 status = "running" 时触发同阶段再次启动
- DONE 未 /sop-close 就开新任务

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

跳过必须显式标记 `"status": "skipped"` 并附理由：
- 单行 typo / 配置修改 → 可跳过 PLANNING、ARCHITECTURE、TEST_FIRST
- 纯文档更新 → 可跳过所有阶段
- 紧急热修复 → 可跳过 PLANNING/ARCHITECTURE/TEST_FIRST，但 REVIEW 不可跳过；热修复事后须补回归测试
