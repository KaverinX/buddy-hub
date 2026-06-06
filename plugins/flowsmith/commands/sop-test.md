---
description: 进入 TEST_FIRST 阶段，为架构契约与子任务验收点编写"先失败"的测试（red），通过后方可进入实现
argument-hint: [--command="<运行测试的命令>"]
---

# /sop-test — TEST_FIRST 阶段（先写失败的测试）

参数：$ARGUMENTS

## 执行步骤

### Step 1 — 前置校验
读取 `.sop/state.json`：
- `current_phase` 必须为 `ARCHITECTURE` 且 `ARCHITECTURE.status = "done"`，否则拒绝并提示正确操作
- 若 `version < 1.2`，提示先执行迁移（见 state-machine.md「1.1→1.2 迁移规则」）

### Step 2 — 确认测试命令
- 若 `--command=` 传入，写入 `test_gate.command`
- 否则沿用 state.json 已探测的 `test_gate.command`；仍为空则询问用户

### Step 3 — 进入 TEST_FIRST
将 `current_phase` 置 `TEST_FIRST`，`TEST_FIRST.status = "running"`。

### Step 4 — 调用 tdd skill 的 RED 阶段
遵循 `skills/tdd/SKILL.md`：
- 针对 `.sop/arch.md` 每个公开接口契约、`.sop/plan.md` 每个子任务验收点写测试
- 运行 `test_gate.command`，**确认测试失败且失败原因是功能未实现**
- 失败证据写入 `.sop/tests-plan.md`

### Step 5 — 完成 TEST_FIRST
- `TEST_FIRST.status = "done"`，`completed_at` 填时间
- emit `test.red.created`
- 提示用户：测试已就绪并确认为红，可执行实现（进入 IMPLEMENTATION）

## 拒绝条件
- arch 未完成 → 提示先 /sop-step 完成架构
- 测试首次运行即全绿 → 警告：测试可能无效，要求修正使其能反映"功能未实现"
