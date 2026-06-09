---
description: 概览 openspec/ 当前状态：真相 domain 清单、活跃变更、与 flowsmith 任务的关联
---

# /spec-status — 规格总览

## 输出
1. **真相清单**：`openspec/specs/` 下各 domain / Requirement 条目数 / Scenario 总数。
2. **活跃变更**：`openspec/changes/`（不含 archive/）下 `.openspec.yaml.status ∈ {draft, proposed, applied}` 的变更及其受影响 domain。
3. **归档**：`openspec/changes/archive/` 下已归档变更数（按日期）。
4. **flowsmith 关联**：交叉 `.openspec.yaml.linked_sop_task` 与各任务 state.json 的 `spec_context.linked_change_id`，展示哪个任务在实现哪个变更。
5. 若 `openspec/` 不存在但有旧版 `spec/`：提示 `/spec-align --migrate` 迁移；都没有则提示 `/spec-bootstrap` 或 `/spec-propose`。
