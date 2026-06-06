---
description: 把已实现的变更 delta 合并进 living spec，使 capabilities/ 成为新的系统真相
argument-hint: <change-id> [--from-sop]
---

# /spec-apply — 落地 delta 进 living spec

参数：$ARGUMENTS

## 前置读取
1. `schemas/spec-schema.md`
2. `spec/changes/<change-id>/proposal.md` — 待落地的 delta
3. 对应 `spec/capabilities/<id>/spec.md`

## 执行步骤

### Step 1 — 校验
- change `status` 应为 `proposed`（已被 archive 的拒绝）
- 若 `--from-sop`：由 flowsmith `/sop-close` 触发，校验对应 task 已到 DONE

### Step 2 — 合并 delta（逐能力）
对 proposal.md 的每个能力 delta：
- **ADDED** → 把新增 R 追加进 `capabilities/<id>/spec.md` 的「行为规格」
- **MODIFIED** → 用"改后"重写对应 R（保留 R 编号）
- **REMOVED** → 从 living spec 删除对应 R（在能力的「非目标」可留一句"曾支持 X，已于 <change-id> 移除"）
- 若是新能力，按 schema 第 2 节新建 `capabilities/<new-id>/spec.md`
- 更新能力的 `last_change` 字段

### Step 3 — 技术方案毕业（若 change 含 design.md 的接口/数据节）
把稳定的接口契约 / 数据契约抽取进 living spec 对应小节（其余实现细节留在 change 文件夹归档）。

### Step 4 — 标记与事件
- change `status` → `applied`
- emit `spec.applied`（entity=spec_change，evidence 指向被改的 spec.md + hash）

### Step 5 — 汇报合并结果
列出每个能力新增/修改/删除了哪些 R。

## 注意
living spec 是真相，合并要保证它**自洽可读**——不是把 delta 原样粘贴，而是让能力规格读起来像"系统现在就是这样"。
