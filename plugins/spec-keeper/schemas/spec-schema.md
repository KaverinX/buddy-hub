# Spec Schema（规格契约）— OpenSpec 对齐版

> **唯一可信来源**。living spec、变更 delta、目录布局的格式在此统一定义，所有 command/skill 对齐此文件。
> 本版本与 [OpenSpec](https://github.com/Fission-AI/OpenSpec) 的产物格式**逐字节对齐**：
> 产出物可直接通过 `openspec validate --strict`。buddy-hub 生态所需的额外元数据，
> 全部放进 OpenSpec 允许的可选 sidecar（`.openspec.yaml`），不污染 spec.md / proposal.md / delta。

## 0. 与旧版（native）的区别

旧版（`spec/capabilities/...`、delta 内联在 proposal、`R-n` + 当/则/除非）**已废弃**。
存量项目用 `/spec-align --migrate` 一键迁移到本格式。映射规则见 `commands/spec-align.md`。

## 1. 目录结构（= OpenSpec）

```
openspec/
├── specs/                          # 真相（source of truth）：系统当前行为，按【domain】组织
│   └── <domain>/
│       └── spec.md
├── changes/                        # 变更：每个变更一个自包含文件夹
│   └── <change-id>/
│       ├── proposal.md             # 为什么 + 是什么（Intent / Scope / Approach）
│       ├── design.md               # 怎么做（技术方案，可选）
│       ├── tasks.md                # 实现清单（checkbox）
│       ├── .openspec.yaml          # 变更元数据（可选；buddy-hub 生态钩子放这里）
│       └── specs/                  # delta spec：本次相对真相的变化（独立文件！）
│           └── <domain>/
│               └── spec.md
└── changes/archive/                # 归档：已落地变更
    └── <YYYY-MM-DD>-<change-id>/
```

设计原则（同 OpenSpec）：
1. **真相与提案分离**：`specs/` 是当前真相，`changes/` 是打算怎么改。
2. **delta 是独立 spec 文件**：放在 `changes/<id>/specs/<domain>/spec.md`，**不内联进 proposal.md**（这是与旧版最大的结构差异）。
3. **delta 在行为层**：用 `## ADDED/MODIFIED/REMOVED Requirements` 标记相对真相的变化（brownfield 友好）。
4. **fluid 而非僵硬阶段门**：propose/apply/archive 是动作，artifact 可随时更新。

## 2. 真相 spec 格式（specs/<domain>/spec.md）

```markdown
# <Domain> Specification

## Purpose
{该 domain 解决什么问题，1-3 句；validate 要求 ≥50 字符更佳}

## Requirements

### Requirement: {需求名称}
The system SHALL {可观测行为}。            ← 规范性动词必须是 RFC2119 英文关键字

#### Scenario: {场景名}
- GIVEN {前置条件}
- WHEN {触发动作}
- THEN {系统必须的结果}
- AND {附加结果，可选}
```

**硬性规则（否则 `openspec validate` 报错）：**
- 必须含 `## Purpose` 与 `## Requirements` 两节。
- 每条需求用 `### Requirement: {名称}`（不是 `R-n`）。
- 需求正文可用中文，但**规范性动词必须是英文 RFC2119 关键字**：`SHALL` / `MUST`（绝对要求）、`SHOULD`（推荐）、`MAY`（可选）。validate 用正则 `SHALL|MUST` 识别。
- **每条需求至少一个 `#### Scenario:` 块**（缺场景 = `requirement must have at least one scenario` 报错）。
- 场景关键字 `GIVEN / WHEN / THEN / AND` 保持英文、用 `- ` 列表项。

> 接口契约 / 数据契约 → 写成带 SHALL 的 Requirement + 覆盖 method/path/resp/error 的 Scenario。
> 「非目标 / Out of scope」**不进真相 spec**，放进对应 change 的 `proposal.md` 的 Scope 小节。

## 3. delta 格式（changes/<id>/specs/<domain>/spec.md）

```markdown
# <Domain> Delta

## ADDED Requirements

### Requirement: {新需求名}
The system MUST {新增行为}。

#### Scenario: {场景名}
- GIVEN ...
- WHEN ...
- THEN ...

## MODIFIED Requirements

### Requirement: {既有需求名}
The system MUST {改后行为}。
(Previously: {改前行为})

#### Scenario: {场景名}
- GIVEN ...
- WHEN ...
- THEN ...

## REMOVED Requirements

### Requirement: {被移除需求名}
({移除理由 + 兼容性影响})
```

**规则：**
- 节标题固定为 `## ADDED Requirements` / `## MODIFIED Requirements` / `## REMOVED Requirements`（h2，带 `Requirements` 后缀）。
- 每个 delta 文件首行 `# <Domain> Delta`。
- ADDED / MODIFIED 里的需求**同样必须带 ≥1 个 `#### Scenario:`**。
- MODIFIED 用 `(Previously: ...)` 标明改前。
- 一个 change 可有多个 domain 的 delta（多个 `specs/<domain>/spec.md` 文件）。某 domain 无该类变更时省略对应小节。

## 4. proposal.md 格式（changes/<id>/proposal.md）

```markdown
# Proposal: {标题}

## Intent
{动机：为谁解决什么问题；引用需求/issue}

## Scope
In scope:
- ...

Out of scope:
- ...

## Approach
{高层方案；细节留给 design.md}
```

> proposal.md **只写意图/范围/方案**，不含 ADDED/MODIFIED/REMOVED——delta 在 `specs/` 子目录里。

## 5. 变更元数据（changes/<id>/.openspec.yaml，可选）

OpenSpec 允许每个 change 带可选 `.openspec.yaml`。buddy-hub 把所有**生态专属字段**收进这里，
从而让 spec.md / proposal.md / delta 保持与 OpenSpec 逐字节一致：

```yaml
change_id: {id}
status: draft | proposed | applied | archived   # 生命周期（位置仍是权威：archive/ = archived）
capabilities: [{domain}, ...]                    # 受影响 domain
linked_sop_task: {flowsmith task_id 或 null}     # 与 flowsmith 双向关联
```

## 6. status 生命周期（三动作，同 OpenSpec）

```
draft ──/spec-propose──▶ proposed ──/spec-apply──▶ applied ──/spec-archive──▶ archived
                                          │
                          delta 合并进 openspec/specs/ 成为新真相
```

- **propose**：建 change 文件夹，写 proposal.md + `specs/<domain>/spec.md`(delta) + tasks.md，`.openspec.yaml.status=proposed`。
- **apply**：实现完成后把 delta 合并进 `specs/<domain>/spec.md`（ADDED 追加、MODIFIED 替换、REMOVED 删除），status=applied。
- **archive**：把整个 change 文件夹移到 `changes/archive/<YYYY-MM-DD>-<id>/`，status=archived，真相已是新状态。

## 7. change-id 命名（同 OpenSpec）

动词起头的短 kebab-case：`add-dark-mode`、`refactor-media-pipeline`、`fix-auth-timeout`。
**不再用** 旧版的「描述 + 4 位随机后缀」。

## 8. 与 buddy-hub 生态集成

- **flowsmith**：`/sop-init` 检测 `openspec/`，把关联 domain 的真相 spec 作为硬约束注入 plan.md；`/sop-close` 触发 `/spec-apply`。双向关联写在 `.openspec.yaml.linked_sop_task` ↔ state.json `spec_context.linked_change_id`。
- **context-keeper**：每个动作 emit SkillBus 事件（`spec.proposed` / `spec.delta.recorded` / `spec.applied` / `spec.archived` / `spec.drift.detected` / `spec.aligned`），entity 含 `capability`(=domain) / `spec_change`。这是 OpenSpec 本身没有的「规格 + 事件溯源」组合。
- **code-archaeologist**：考古红线可作为某 Requirement 的约束来源（写成 SHALL NOT 的需求 + 反例 Scenario）。
