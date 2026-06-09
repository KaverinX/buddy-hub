---
description: 把已实现的变更 delta 合并进真相 spec，使 openspec/specs/ 成为新的系统真相（ADDED 追加 / MODIFIED 替换 / REMOVED 删除）
argument-hint: <change-id> [--from-sop]
---

# /spec-apply — 落地 delta 进真相 spec

参数：$ARGUMENTS

## 前置读取
1. `schemas/spec-schema.md`
2. `openspec/changes/<change-id>/specs/<domain>/spec.md` — 待落地的 delta（逐 domain）
3. 对应 `openspec/specs/<domain>/spec.md`

## 执行步骤

### Step 1 — 校验
- `.openspec.yaml.status` 应为 `proposed`（已 archived 的拒绝）。
- 校验 delta 自身合规（每条 Requirement 带 Scenario、含 RFC2119 动词）；不合规先提示修。
- 若 `--from-sop`：由 flowsmith `/sop-close` 触发，校验对应 task 已到 DONE。

### Step 2 — 合并 delta（逐 domain，对每个 changes/<id>/specs/<domain>/spec.md）
- **ADDED** → 把整条 `### Requirement:`（含其 Scenario）追加进 `openspec/specs/<domain>/spec.md` 的 `## Requirements`。
- **MODIFIED** → 用改后版本**整条替换**真相里同名 `### Requirement:`（含 Scenario）；去掉 `(Previously: …)` 注记。
- **REMOVED** → 从真相 spec 删除同名 `### Requirement:` 整块。
- 若是新 domain，按 schema §2 新建 `openspec/specs/<new-domain>/spec.md`（补 `## Purpose`）。

### Step 3 — 技术方案毕业（若 change 含 design.md 的稳定接口/数据契约）
把稳定契约抽成真相 spec 里的 Requirement + Scenario（其余实现细节留 change 文件夹归档）。

### Step 4 — 标记与事件
- `.openspec.yaml.status` → `applied`。
- emit `spec.applied`（entity=spec_change，evidence 指向被改的 specs/<domain>/spec.md + hash）。

### Step 5 — 汇报
列出每个 domain 新增/替换/删除了哪些 `### Requirement:`。

## 注意
- 合并后真相 spec 要**自洽可读**——读起来像"系统现在就是这样"，而非 delta 残片堆叠。
- 合并后真相 spec 仍须通过 OpenSpec 校验（Purpose + Requirements + 每需求 ≥1 Scenario）；可顺手 `/spec-check`。
