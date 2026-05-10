---
description: 触发三层并行审查（架构/安全/逻辑），合并报告，更新问题追踪
---

# /sop-review — 三层并行审查

## 执行步骤

### Step 1 — 状态校验

读取 `.sop/state.json`：
- 若 `OPTIMIZATION.status` 不是 `"done"`，输出：
  > "代码优化尚未完成。请先调用 @optimizer 完成优化阶段。"
  > 停止执行。
- 若 `REVIEW.status` 为 `"running"`，提示：
  > "上次审查未完成，是否重置审查状态并重新开始？"

### Step 2 — 更新状态

将 `state.json` 中：
- `REVIEW.status` 更新为 `"running"`
- `current_phase` 更新为 `"REVIEW"`

若 `iteration > 1`，在 `.sop/review.md` 文件末尾追加分隔符（不覆盖历史审查）：
```markdown

---

# 第 {iteration} 轮审查（{ISO8601 时间戳}）
```

### Step 3 — 并行触发三个审查 subagent

依次（或并行）调用：

1. **@arch-reviewer** — 任务指令：
   > "请读取 .sop/plan.md、.sop/arch.md 和 .sop/changelog.md，对本次任务的源代码进行架构符合性审查。
   > changelog.md 中每条 CR 显式声明了'解决什么问题'和'为什么这么改'，请用它判断代码意图，
   > 而不是仅从代码本身猜测意图。重点检查：CR 中声明的设计是否真的落地、是否有改动绕过了 ADR。
   > 将审查结论追加写入 .sop/review.md。
   > 若这是第 {iteration} 轮审查，请对照上轮审查中属于你职责范围的问题，
   > 检查是否真正修复（不是绕过或隐藏），并在审查报告中标注对应的修复 CR 编号。"

2. **@security-reviewer** — 任务指令：同上读取范围与对照要求，但执行 STRIDE 安全审查
3. **@logic-reviewer** — 任务指令：同上读取范围与对照要求，但执行逻辑正确性与边界条件审查

### Step 4 — 合并 Critical 问题

等待三个 subagent 完成后：

1. 读取 `.sop/review.md`，提取本轮所有 Critical 问题
2. 将 Critical 问题写入 `state.json` 的 `open_issues` 数组：
   ```json
   {
     "id": "C-1",
     "level": "critical",
     "description": "...",
     "location": "src/file.ts:42",
     "source_reviewer": "security-reviewer",
     "status": "open",
     "fixed_at": null,
     "found_in_iteration": 1
   }
   ```
3. 写入 `.sop/fixes.md` 修复追踪表：
   ```markdown
   # 修复任务追踪（第 {iteration} 轮审查发现）

   | ID | 级别 | 描述 | 位置 | 来源 Reviewer | 状态 | 修复时间 | 修复 CR |
   |----|------|------|------|--------------|------|---------|--------|
   | C-1 | Critical | ... | src/file.ts:42 | security-reviewer | open | - | - |
   ```

### Step 5 — 状态决策

**若存在 Critical 问题**：

更新 `state.json`：
```json
{
  "REVIEW": { "status": "failed", "completed_at": "<ISO8601>" },
  "current_phase": "IMPLEMENTATION",
  "iteration": <当前 iteration + 1>
}
```

输出：
```
🔴 审查未通过（第 {iteration} 轮）

Critical 问题：{N} 个
{逐条列出，含 ID、描述、位置、来源 Reviewer}

以上问题已写入 .sop/fixes.md。
请修复 Critical 问题后，再次执行 /sop-review 进行第 {iteration+1} 轮审查。

提示：每修复一个 Critical 问题，按 implementation-guide 的"变更日志纪律"
追加一条新 CR 到 changelog.md，并在 fixes_issue 字段标注 C-x。
```

**若无 Critical 问题**：

更新 `state.json`：
```json
{
  "REVIEW": { "status": "done", "completed_at": "<ISO8601>" },
  "current_phase": "DONE"
}
```

输出：
```
✅ 审查通过（第 {iteration} 轮）

Warning：{N} 个（已记录，可在后续迭代处理）
Info：{M} 个

任务 {task_id} 完成。
变更记录共 {CR 总数} 条，可通过 /sop-diff 查看完整带备注 diff。
建议执行 /sop-close 沉淀经验后正式归档。
```
