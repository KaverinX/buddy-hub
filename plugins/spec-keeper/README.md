# spec-keeper — 规格驱动开发（SDD）

**角色：规格真相维护者** | `v1.0.0` | 5 commands, 1 skill | 对标 OpenSpec

把"规格"做成 buddy-hub 的第一公民：按**能力**组织、长期存活、与代码持续同步的 living spec，配合
`proposal → apply → archive` 三动作与 `ADDED/MODIFIED/REMOVED` delta，让"写什么"在动手前先对齐、且这份对齐长期可 diff、可复审。

## 为什么需要它

flowsmith 的 `plan.md / arch.md` 是**任务级、关任务即归档**的临时产物——系统里没有一份"当前具备哪些能力、每个能力预期行为是什么"的长期文档。spec-keeper 补上这一层（这是 buddy-hub 相对 OpenSpec 的最大结构性缺口）。

## 核心概念

- `spec/capabilities/<id>/spec.md` — **living spec**：系统当前能力的真相（应然）
- `spec/changes/<id>/` — 每个变更一个文件夹：`proposal.md`（含 delta）+ `tasks.md`
- **delta** 在行为层用 `ADDED/MODIFIED/REMOVED` 表达相对现有真相的变化（brownfield 友好）

## 命令

| 命令 | 作用 |
|------|------|
| `/spec-bootstrap` | 反向：为已有项目捕获当前行为，生成整体 living spec（brownfield） |
| `/spec-sync` | 反向·增量：用当前分支的实际改动互补 living spec（代码已变、spec 没跟上时回填） |
| `/spec-propose <描述>` | 基于现有 living spec 写出变更 delta + 任务拆解 |
| `/spec-apply <change-id>` | 把已实现的 delta 合并进 living spec，成为新真相 |
| `/spec-archive <change-id>` | 归档已落地的变更 |
| `/spec-check` | 规格健康度与 drift 检测（悬挂提案 / 自洽性 / 规格↔测试覆盖） |
| `/spec-status` | 能力清单、活跃变更、与 flowsmith 任务的关联 |

## 与生态集成

- **flowsmith**：`/sop-init` 把关联能力的 living spec 作为硬约束注入 plan.md；`/sop-close` 触发 `/spec-apply` 沉淀真相。state.json `spec_context.linked_change_id` 双向关联。
- **context-keeper**：每个动作 emit SkillBus 事件（`spec.proposed` / `spec.delta.recorded` / `spec.applied` / `spec.drift.detected`），规格变更天然进入知识图谱——这是 OpenSpec 本身没有的「规格 + 事件溯源」组合。

## 典型流程

```
/spec-propose "通知支持邮件渠道"   → spec/changes/notify-email-a1b2/proposal.md（delta）
   ↓ 评审 proposal
/sop-init "实现邮件通知渠道"       → flowsmith 读取 living spec 作硬约束 → TEST_FIRST → 实现 → REVIEW → DONE
   ↓ /sop-close 自动触发
/spec-apply notify-email-a1b2     → 邮件渠道行为合并进 capabilities/notification/spec.md
/spec-archive notify-email-a1b2
```

## 设计原则

1. 能力优先于任务（spec 长命，task 短命）
2. 真相与提案分离（capabilities = 现状，changes = 打算怎么改，二者 diff 即评审对象）
3. delta 在行为层（可判定、能写成测试，直接喂给 TEST_FIRST）
4. fluid 而非僵硬阶段门（artifact 可随时更新，对标 OpenSpec）

License: MIT © Velpro
