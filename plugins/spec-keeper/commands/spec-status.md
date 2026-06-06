---
description: 概览 spec/ 当前状态：能力清单、活跃变更、与 flowsmith 任务的关联
---

# /spec-status — 规格总览

## 输出
1. **能力清单**：`spec/capabilities/` 下各能力 id / status / R 条目数 / last_change
2. **活跃变更**：`spec/changes/` 下 status ∈ {draft, proposed, applied} 的变更及其受影响能力
3. **flowsmith 关联**：读取各任务 state.json 的 `spec_context.linked_change_id`，展示哪个任务在实现哪个变更
4. 若 `spec/` 不存在：提示用 /spec-propose 创建首个提案
