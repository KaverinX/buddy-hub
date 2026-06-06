---
name: tdd
description: 测试驱动开发纪律 Skill。在 SOP 的 TEST_FIRST 阶段与 IMPLEMENTATION 阶段强制 red-green-refactor。先写失败测试、再写实现、最后重构。当 .sop/state.json 的 current_phase 为 TEST_FIRST 或 IMPLEMENTATION 时由 Claude 主动遵循。对标 Superpowers 的 TDD 铁律。
---

# 测试驱动开发（tdd）

## ⚖️ IRON LAW（不可协商）

**测试未先失败（red），不得编写任何实现代码。**

## 🚩 红旗清单（识别即停，回到 IRON LAW）

- "这个逻辑很简单，直接写实现就行" → 停，先写测试
- "测试首次运行就通过了" → 危险信号：测试可能根本没在测你以为的东西。先确认它在缺少实现时会失败
- "先把功能写完，测试最后一起补" → "最后"=永不。停
- "改动很小，不值得写测试" → 规模不豁免纪律
- 以及共享红旗词表（见 `../_shared/iron-law.md`）

## 前置读取

1. `../_shared/iron-law.md` — 行为契约
2. `task-planning/reference/state-machine.md` — 确认 TEST_FIRST 在 ARCHITECTURE 之后、IMPLEMENTATION 之前
3. `.sop/arch.md` — 测试要覆盖架构里声明的公开接口契约
4. `.sop/plan.md` — 测试要覆盖每个子任务的验收点

## red-green-refactor 循环

### 🔴 RED — 先写失败的测试（TEST_FIRST 阶段）

针对 `arch.md` 中每个公开接口契约与 `plan.md` 每个子任务的验收点，写测试用例：

- 测试必须**先于实现**存在
- 运行测试，**必须看到它失败**，且失败原因是"功能未实现"而非"测试本身写错/导入报错"
- 把失败证据记入 `.sop/tests-plan.md`（哪些用例、当前为何失败）
- 这一步完成才允许 FSM 从 TEST_FIRST → IMPLEMENTATION

> 一个首次就通过的测试是 bug，不是好消息——它没在测你以为的东西。

### 🟢 GREEN — 写最小实现让测试变绿（IMPLEMENTATION 阶段）

- 只写**让当前测试通过所需的最小代码**，不提前实现未被测试覆盖的功能
- 全部相关测试通过（绿）前，**不得**触发 `IMPLEMENTATION → OPTIMIZATION` 迁移
- 绿灯由 `hooks/validate-tests.sh` 在阶段迁移时校验

### ♻️ REFACTOR — 在绿灯保护下重构

- 测试保持绿，才能重构
- 每次重构后立即重跑测试，红了立刻退回

## 与 SkillBus 的联动

- 写出失败测试：emit `test.red.created`
- 测试转绿：emit `test.green.passed`
- 绿灯门禁拦截迁移：emit `test.gate.blocked`
（emit 方式见 context-keeper 的 event-emission skill）

## 合法跳过

沿用 flowsmith 既有 `skipped + 理由` 机制：单行 typo、纯文档、纯配置可在 state.json 标记 `TEST_FIRST.status = "skipped"` 并附理由。其余一律不可跳过。
