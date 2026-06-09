---
name: spec-authoring
description: 规格撰写 Skill。撰写 OpenSpec 格式的真相 spec 与变更 delta 时遵循的纪律：按 domain 组织、需求带可测 Scenario、用 RFC2119 关键字、delta 是独立 spec 文件且表达相对真相的变化。当执行 spec-keeper 的 /spec-propose、/spec-apply、/spec-align 或编辑 openspec/ 下文件时由 Claude 主动遵循。逐字节对齐 OpenSpec 的 SDD 方法论。
---

# 规格撰写（spec-authoring）— OpenSpec 对齐

## ⚖️ IRON LAW（不可协商）

**规格描述行为（带可测 Scenario），不描述实现；变更以独立 delta 文件相对现有真相表达，不重写整份规格；规范性动词用 RFC2119 英文关键字。**

## 🚩 红旗清单（识别即停）

- "这条规格写：用 Redis 缓存…" → 停，那是实现。规格写"读取 SHALL 在 X ms 内返回" + Scenario。
- "需求写完了，没加 Scenario" → 停，OpenSpec 每条 Requirement **必须 ≥1 个 `#### Scenario:`**，否则 validate 报错。
- "需求用中文写'系统应该…'" → 停，规范性动词必须是英文 `SHALL/MUST/SHOULD/MAY`（validate 用正则识别）。
- "把 delta 写进 proposal.md" → 停，delta 是**独立文件** `changes/<id>/specs/<domain>/spec.md`；proposal 只写 Intent/Scope/Approach。
- "改个需求顺手把整份 spec 重写" → 停，用 `## ADDED/MODIFIED/REMOVED Requirements` delta。
- "R-3：系统应处理好各种情况" → 不可判定，停，写成可测的 Requirement + Scenario。
- "先写代码，规格回头补" → 停，SDD 是先对齐 spec 再动手。
- 以及共享红旗词表（见 flowsmith `skills/_shared/iron-law.md`）。

## 前置读取
1. `../../schemas/spec-schema.md` — OpenSpec 真相/delta/布局格式（唯一来源）
2. `openspec/specs/`（若存在）— 现有真相，delta 相对它表达

## 撰写纪律

### 按 domain 组织，真相与提案分离
真相在 `openspec/specs/<domain>/spec.md`（长命），提案在 `openspec/changes/<id>/`（短命）。domain 按功能域/组件/限界上下文划分。

### 每条需求 = Requirement + ≥1 Scenario
- `### Requirement: {名称}` + 一句 `The system SHALL/MUST …`（可观测行为，RFC2119 英文关键字）。
- `#### Scenario: {名}` 用 `- GIVEN / - WHEN / - THEN / - AND`（英文关键字）。
- Scenario 必须能写成自动化测试，覆盖 happy path 与关键边界/反例。
- 写不成 Scenario 的需求 = 不可判定，继续细化或标 `[待确认]`。

### delta 是独立文件，表达变化
`changes/<id>/specs/<domain>/spec.md`，首行 `# <Domain> Delta`，用 `## ADDED/MODIFIED/REMOVED Requirements`。MODIFIED 必写 `(Previously: …)`。不是文件 diff，是行为增减改。

### 真相要自洽可读
apply 合并 delta 后，真相 spec 读起来像"系统现在就是这样"，且仍通过 OpenSpec 校验（Purpose + Requirements + 每需求 ≥1 Scenario）。

## 与 flowsmith 的接力
proposal delta 里每条 Requirement 的 Scenario，是 TEST_FIRST 阶段写测试的直接依据——Scenario 与测试一一对应，是消除 drift 的根本。

## 与 OpenSpec 工具链
本格式逐字节对齐 OpenSpec，产物可直接 `openspec validate --strict` / `openspec list` / `openspec show`。存量旧版规格用 `/spec-align --migrate` 迁移。
