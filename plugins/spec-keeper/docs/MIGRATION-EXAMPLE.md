# /spec-align 迁移示例（旧版 native → OpenSpec）

本文用一个真实的「通知」能力 + 一个「加邮件渠道」变更，演示 `/spec-align --migrate` 的逐字节转换结果。
可当 `/spec-align` 的参照样本，也可当转换正确性的回归基准。

---

## A. 真相 spec

### A1. 迁移前（旧版 `spec/capabilities/notification/spec.md`）

```markdown
# 能力：通知
> capability_id: notification
> status: active
> last_change: bootstrap

## 目的
向用户发送系统通知。

## 行为规格（Requirements）

### R-1 站内信通知
- **当** 触发了一个需通知用户的事件
- **则** 系统在站内信中生成一条未读通知
- **除非** 用户关闭了该类通知
- 验收：事件触发后用户站内信出现对应未读条目

## 非目标（Out of Scope）
- 不支持邮件 / 短信渠道
```

### A2. 迁移后（OpenSpec `openspec/specs/notification/spec.md`）

```markdown
# Notification Specification

## Purpose
向用户发送系统通知。

## Requirements

### Requirement: 站内信通知
The system SHALL 在触发需通知用户的事件时生成一条站内未读通知。

#### Scenario: 事件触发生成未读通知
- GIVEN 一个需通知用户的事件被触发
- WHEN 系统处理该事件
- THEN 用户站内信出现对应的未读通知条目

#### Scenario: 用户已关闭该类通知
- GIVEN 用户关闭了该类通知
- WHEN 对应事件被触发
- THEN 系统不生成站内通知

> Note（Out of scope）: 暂不支持邮件 / 短信渠道。
```

**转换要点**：标题 `能力：X` → `X Specification`；删元数据块；`目的`→`Purpose`；`R-1 站内信通知`→`### Requirement: 站内信通知`；当/则→规范性句(SHALL)+ Scenario(GIVEN/WHEN/THEN)；除非→独立例外 Scenario；非目标→非规范性 Note（或入 change 的 Out of scope）。

---

## B. 变更（delta 从 proposal 内联 → 独立文件）

### B1. 迁移前（旧版 `spec/changes/notify-email-a1b2/proposal.md`，delta 内联）

```markdown
# 变更提案：通知支持邮件渠道
> change_id: notify-email-a1b2
> status: proposed
> capabilities: notification
> linked_sop_task: t-0007

## 为什么（Why）
用户希望离线时也能收到重要通知。

## Delta（相对现有 living spec 的行为变化）

### 能力 notification

#### ADDED
- R-2: 当用户启用邮件通知且事件触发，则系统发送一封邮件到用户邮箱

#### MODIFIED
- R-1: 改前=仅站内信；改后=站内信生成的同时，若用户启用邮件则并发邮件

## 影响与兼容性
向后兼容；默认不开启邮件。

## 验收
启用邮件后触发事件能收到邮件。
```

### B2. 迁移后

`openspec/changes/add-notify-email/proposal.md`（**去 delta**）：

```markdown
# Proposal: 通知支持邮件渠道

## Intent
用户希望离线时也能收到重要通知。

## Scope
In scope:
- 新增邮件通知渠道
- 站内信与邮件并发

Out of scope:
- 短信渠道

## Approach
在通知分发处增加邮件渠道适配器，按用户偏好并发。默认不开启邮件。
```

`openspec/changes/add-notify-email/specs/notification/spec.md`（**独立 delta**）：

```markdown
# Notification Delta

## ADDED Requirements

### Requirement: 邮件通知
The system MUST 在用户启用邮件通知且事件触发时，发送一封邮件到用户邮箱。

#### Scenario: 启用邮件后收到邮件
- GIVEN 用户已启用邮件通知
- WHEN 一个需通知的事件被触发
- THEN 系统向用户邮箱发送对应通知邮件

## MODIFIED Requirements

### Requirement: 站内信通知
The system MUST 在事件触发时生成站内未读通知；若用户启用邮件，则同时并发邮件。
(Previously: 仅生成站内信，不涉及邮件)

#### Scenario: 站内信与邮件并发
- GIVEN 用户启用了邮件通知
- WHEN 事件被触发
- THEN 系统生成站内未读通知
- AND 同时发送一封通知邮件
```

`openspec/changes/add-notify-email/.openspec.yaml`（生态元数据，OpenSpec 允许的可选 sidecar）：

```yaml
change_id: add-notify-email
status: proposed
capabilities: [notification]
linked_sop_task: t-0007
legacy_id: notify-email-a1b2
```

`tasks.md` → `# Tasks` + `- [ ] N.M …` checkbox。

**转换要点**：proposal 拆成纯 Intent/Scope/Approach（非目标进 Out of scope）；`## Delta` 下每个 `### 能力 X` 落成独立 `specs/X/spec.md`，首行 `# X Delta`；`#### ADDED/MODIFIED`→`## ADDED/MODIFIED Requirements`；每条 `- R-n:` → `### Requirement:` + SHALL/MUST + Scenario；MODIFIED 补 `(Previously: …)`；元数据/status 进 `.openspec.yaml`；change-id `notify-email-a1b2` → `add-notify-email`（动词起头，原 id 记 legacy_id）。

---

## C. 归档

`/spec-archive add-notify-email` → 整个文件夹移到
`openspec/changes/archive/2026-06-09-add-notify-email/`（带日期前缀，与 OpenSpec 一致）。

---

## D. 校验

迁移后产物可直接：
```
openspec validate --strict        # 每条 Requirement 有 Scenario、含 SHALL/MUST、Purpose/Requirements 齐全
openspec list                     # 列出 active changes
openspec show add-notify-email    # 查看变更详情
```
或用插件内 `/spec-check`（含同等一致性校验 + drift）。
