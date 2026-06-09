# spec-keeper — 规格驱动开发（SDD）

**角色：规格真相维护者** | `v2.0.0` | 8 commands, 1 skill | **逐字节对齐 OpenSpec**

把"规格"做成 buddy-hub 的第一公民：按 **domain** 组织、长期存活、与代码持续同步的 living spec，配合
`propose → apply → archive` 三动作与 `ADDED/MODIFIED/REMOVED` delta，让"写什么"在动手前先对齐、且这份对齐长期可 diff、可复审。

> **v2.0 起产物逐字节对齐 [OpenSpec](https://github.com/Fission-AI/OpenSpec)**：目录用 `openspec/specs` + `openspec/changes`，delta 是独立 spec 文件，需求用 `### Requirement:` + `#### Scenario:`（GIVEN/WHEN/THEN）+ RFC2119 关键字。产物可直接 `openspec validate --strict`。生态专属字段（flowsmith 关联等）收进 OpenSpec 允许的可选 `.openspec.yaml`，不污染 spec。

## 为什么需要它

flowsmith 的 `plan.md / arch.md` 是**任务级、关任务即归档**的临时产物——系统里没有一份"当前具备哪些能力、每个能力预期行为是什么"的长期文档。spec-keeper 补上这一层。

## 核心概念

- `openspec/specs/<domain>/spec.md` — **真相（source of truth）**：系统当前行为（应然），`## Purpose` + `## Requirements`，每条 `### Requirement:` 带 ≥1 个 `#### Scenario:`
- `openspec/changes/<id>/` — 每个变更一个自包含文件夹：`proposal.md`（Intent/Scope/Approach）+ `specs/<domain>/spec.md`（**独立 delta**）+ `tasks.md` + `.openspec.yaml`（可选元数据）
- **delta** 用 `## ADDED/MODIFIED/REMOVED Requirements` 表达相对真相的变化（brownfield 友好）
- 归档 → `openspec/changes/archive/<日期>-<id>/`

## 命令

| 命令 | 作用 |
|------|------|
| `/spec-align` | **对齐到 OpenSpec**：把旧版 `spec/` 原生格式迁移为 `openspec/`，或校验一致性（`--migrate`(默认) / `--project` / `--check`） |
| `/spec-bootstrap` | 反向：为已有项目捕获当前行为，生成整体真相 spec（brownfield） |
| `/spec-sync` | 反向·增量：用当前分支的实际改动互补真相 spec（代码已变、spec 没跟上时回填） |
| `/spec-propose <描述>` | 基于现有真相写出变更 delta（独立文件）+ proposal + 任务拆解 |
| `/spec-apply <change-id>` | 把已实现的 delta 合并进真相 spec，成为新真相 |
| `/spec-archive <change-id>` | 归档已落地的变更 → `changes/archive/<日期>-<id>/` |
| `/spec-check` | OpenSpec 一致性校验 + 健康度 + drift 检测 |
| `/spec-status` | domain 清单、活跃变更、与 flowsmith 任务的关联 |

## 存量迁移（重要）

v1.x 的旧版格式（`spec/capabilities/...`、delta 内联在 proposal、`R-n` + 当/则/除非）**已废弃**。一键迁移：

```
/spec-align --migrate     # spec/ → openspec/，转格式、拆 delta、补 Scenario，删旧目录（留指针）
/spec-align --check       # 只校验是否符合 OpenSpec，不写文件（CI 闸门）
```

## 与生态集成

- **flowsmith**：`/sop-init` 把关联 domain 的真相 spec 作为硬约束注入 plan.md；`/sop-close` 触发 `/spec-apply`。双向关联：`.openspec.yaml.linked_sop_task` ↔ state.json `spec_context.linked_change_id`。
- **context-keeper**：每个动作 emit SkillBus 事件（`spec.proposed` / `spec.delta.recorded` / `spec.applied` / `spec.archived` / `spec.drift.detected` / `spec.aligned`），规格变更天然进入知识图谱——这是 OpenSpec 本身没有的「规格 + 事件溯源」组合。

## 典型流程

```
/spec-propose "通知支持邮件渠道"   → openspec/changes/add-notify-email/{proposal.md, specs/notification/spec.md(delta), tasks.md}
   ↓ 评审 proposal + delta
/sop-init "实现邮件通知渠道"       → flowsmith 读取真相 spec 作硬约束 → TEST_FIRST(用 Scenario 写测试) → 实现 → REVIEW → DONE
   ↓ /sop-close 自动触发
/spec-apply add-notify-email      → 邮件渠道 Requirement 合并进 specs/notification/spec.md
/spec-archive add-notify-email    → 移入 changes/archive/<日期>-add-notify-email/
```

## 设计原则

1. domain 优先于任务（spec 长命，task 短命）
2. 真相与提案分离（specs = 现状，changes = 打算怎么改，二者 diff 即评审对象）
3. delta 在行为层、是独立 spec 文件（可判定、能写成测试，直接喂给 TEST_FIRST）
4. fluid 而非僵硬阶段门（artifact 可随时更新）
5. **逐字节对齐 OpenSpec**（产物可被 OpenSpec 工具链直接消费）

License: MIT © Velpro
