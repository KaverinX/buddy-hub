# buddy-hub 专项升级 v1.2 — 对标 OpenSpec 与 Superpowers

本次升级在**不推倒、向后兼容**前提下，落地两大对标缺口。所有新能力均长在 context-keeper 事件地基上。

## A. 对标 Superpowers —— 工程纪律硬化（改造 flowsmith，无新插件）

| 项 | 内容 | 文件 |
|----|------|------|
| TEST_FIRST 阶段 | FSM 在 ARCHITECTURE 与 IMPLEMENTATION 间插入 TEST_FIRST，先写失败测试（red） | state-machine.md（v1.1→v1.2） |
| 测试绿灯门禁 | `IMPLEMENTATION → OPTIMIZATION` 须 `test_gate.last_status=passed`，否则拒绝迁移 | state-machine.md / validate-tests.sh / hooks.json |
| TDD 技能 | red-green-refactor 铁律 | skills/tdd/SKILL.md |
| 系统化调试技能 | 四阶段"先根因后修复" | skills/systematic-debugging/SKILL.md |
| Iron Law + 红旗模板 | 反自我开脱的统一行为契约 + 通用红旗词表 | skills/_shared/iron-law.md |
| 已套用红旗 | implementation-guide 加 Iron Law 头部（示范模式） | skills/implementation-guide/SKILL.md |
| 新命令 | `/sop-test` 驱动 TEST_FIRST | commands/sop-test.md |

flowsmith 版本 1.0.1 → **1.2.0**。

## B. 对标 OpenSpec —— 规格层（新插件 spec-keeper）

| 项 | 内容 |
|----|------|
| living spec | `spec/capabilities/<id>/spec.md`，按能力组织、长期存活、= 系统真相 |
| 变更 delta | `spec/changes/<id>/proposal.md`，ADDED/MODIFIED/REMOVED 行为级 diff |
| 三动作 | `/spec-propose` → `/spec-apply` → `/spec-archive`（fluid，非僵硬阶段门） |
| drift 检测 | `/spec-check` 校验悬挂提案 / 自洽性 / 规格↔测试覆盖 |
| 总览 | `/spec-status` |
| 撰写纪律 | skills/spec-authoring（行为可判定、delta 表达变化） |

## C. 地基对接（context-keeper）

event-schema 追加：
- 规格域：`spec.proposed` / `spec.delta.recorded` / `spec.applied` / `spec.archived` / `spec.drift.detected`
- 测试域：`test.red.created` / `test.green.passed` / `test.gate.blocked` / `debug.rootcause.found` / `debug.fix.verified`
- 实体类型新增：`capability` / `spec_change`

## 升级后的主链路

```
/spec-propose（delta，对标 OpenSpec）
   ↓ 注入 living spec 作硬约束
flowsmith FSM：PLANNING → ARCHITECTURE → TEST_FIRST → IMPLEMENTATION → OPTIMIZATION → REVIEW → DONE
                              (红)            (绿灯门禁，对标 Superpowers)
   ↓ /sop-close 触发
/spec-apply（delta 合并进 living spec，成为新真相）
   ↓ 全程 emit
context-keeper：events.jsonl + 物化视图（独有地基）

横切：所有刚性 skill = Iron Law + 红旗（对标 Superpowers 行为内核）
```

## 兼容性
- state.json v1.1 → v1.2 为纯增量迁移（插入 TEST_FIRST 阶段、加 test_gate/spec_context），老任务可降级运行，越过 ARCHITECTURE 的老任务自动把 TEST_FIRST 置 skipped。
- 事件 schema 遵循"只追加不重命名"，v1 事件永久可读。
- 单行/纯文档/热修复等场景沿用 flowsmith 既有 `skipped + 理由` 机制，避免轻量改动被重流程拖累。
