---
name: implementation-guide
description: 编码实施规范 Skill。在 SOP 流程的 IMPLEMENTATION 阶段使用，规范编码纪律：架构契约遵循、错误处理标准、接口稳定性、子任务进度追踪、变更日志记录。当 .sop/state.json 中 current_phase 为 IMPLEMENTATION 时由 Claude 主动遵循。
---

# 编码实施规范（implementation-guide）

## 编码前的状态更新

读取 `.sop/state.json`，确认 `ARCHITECTURE.status = "done"`。
将 `IMPLEMENTATION.status` 更新为 `"running"`，`current_phase` 更新为 `"IMPLEMENTATION"`。

## 编码纪律（贯穿整个实现阶段）

### 原则一：架构是契约，不是建议

每次新建文件或函数前，先查阅 `.sop/arch.md`：
- 这个模块的职责范围是什么？
- 它可以依赖哪些其他模块？
- 它的公开接口签名是什么？

**如果发现架构设计有遗漏或不合理**，不要自行修改，而是暂停并告知用户：
> "架构文档中未覆盖 {XXX} 场景，建议先更新 arch.md 的 ADR，再继续编码。"

### 原则二：错误处理与正常逻辑同等优先

每个可能失败的操作，在写正常路径的同时就写错误处理，不留"TODO: handle error"。

错误处理质量标准：
```typescript
// ❌ 不接受
try { await db.save(record) } catch (e) { console.log(e) }

// ❌ 不接受（信息不足以 debug）
throw new Error('save failed')

// ✅ 要求
try {
  await db.save(record)
} catch (cause) {
  // 区分业务错误和系统错误，包含调试所需的上下文
  throw new DatabaseError('Failed to persist user record', {
    cause,
    context: { userId: record.id, operation: 'save' }
  })
}
```

### 原则三：接口设计的不变性（Stability of Interfaces）

一旦模块的公开接口被实现并被其他模块调用，修改接口签名必须：
1. 先在 `.sop/arch.md` 中更新接口契约
2. 同步修改所有调用方
3. 若有外部调用方，必须考虑向后兼容性（版本化或 deprecation）

### 原则四：子任务进度同步

每完成一个 `plan.md` 中的子任务，更新 `plan.md` 的"进度跟踪"表中对应子任务为"已完成"。
不需要每行代码都更新，但每个完整子任务完成后必须更新。

### 原则五：变更日志纪律（Change Log Discipline）

> 本原则的目的是：让用户在 worktree 流并行多任务时，可以随时通过 `/sop-diff` 看到"做了什么 + 为什么"，而不是从一堆 diff 里反推意图。

**核心规则**：每完成一个**逻辑变更批次**，立即追加一条 `CR-{n}` 条目到 `.sop/changelog.md`。

**什么是"逻辑变更批次"**：
- 通常对应 `plan.md` 中一个完整子任务
- 或对应 `arch.md` 中一个 ADR 的落地
- 或一个独立可解释的修复 / 重构（即使跨文件）

**反模式**（不应作为单独 CR）：
- 单独的代码格式化 / lint 修复 → 合并到最近相关 CR 的"附带改动"中
- 修一个变量名 → 同上
- 一次保存一个文件 → 太细，应攒到逻辑批次

**反模式**（CR 太粗）：
- "实现了通知系统" 涵盖 12 个文件 5 个子任务 → 必须拆成多条 CR
- 一条 CR 同时涉及"新功能 + 无关 bug 修复" → 拆开

#### 何时写

> 时机：完成一个批次的代码改动**之后**、开始下一个批次**之前**。
> 不是写完整个实施阶段再补——那时已经记不清细节。

具体触发点：
1. 一个 `plan.md` 子任务标记为"已完成"时 → 同时写一条 CR
2. 完成一个 ADR 的落地时
3. 修复一个 Critical 问题（iteration > 1 时）后

#### 怎么写

读取 `.sop/state.json` 取 `change_records.next_id`，作为本条编号 `CR-{next_id}`。
按 `task-planning/reference/document-schemas.md` 中 changelog.md 的格式追加：

```markdown
## CR-{n} — {一句话标题}

- timestamp: {当前 ISO8601}
- type: create | modify | delete | refactor | fix
- subtask: {plan.md 中子任务编号，如 1.2；无则填 -}
- adr: {arch.md 中 ADR 编号，如 ADR-2；无则填 -}
- files:
  - {path1}{( 新建 / 修改 / 删除)}
  - {path2}

### 解决什么问题
{用户视角或系统视角的问题描述。不是"我加了一个函数"，而是"原本 X 场景下会 Y，需要 Z"。}

### 为什么这么改
{方案选择理由。如果有 ADR 已经讲过，这里只点出 ADR 编号 + 落地的关键决策；
不重复抄 ADR 全文。如果是 ADR 之外的小决策，简述权衡。}

### 关联变更
- 依赖：{CR-x, ...，无则写"无"}
- 后续：{CR-y, ...，可在后续 CR 写出后回填，初次可留空}
```

写完之后，把 `.sop/state.json` 中 `change_records.next_id` 自增 1。

#### 写作质量标准

- **"为什么"必须高于"做了什么"**：diff 已经显示了"做了什么"，CR 的价值在于"为什么"。
- **每条 CR 长度控制**：rationale 总和不超过 10 行。超过说明这条 CR 太重，应拆分。
- **可被独立理解**：不依赖读者已经看过其他 CR 也能看懂这一条解决的问题。
- **避免空话**：禁止"提升代码质量""优化性能"这种没信息量的描述。要写"把 O(n²) 改成 O(n log n)，因为 X 场景下 n 会到 1e5"。

#### 与 fix 流程的关系（iteration > 1）

修复 Critical 问题时，CR 条目额外加一行：

```markdown
- fixes_issue: C-1 (来自 .sop/fixes.md)
```

这样后续审查可以对账：每个 Critical 问题是否都有对应的 CR 来修。

### 原则六：编码完成的定义

以下条件全部满足，才可以声明"编码完成"，进入优化阶段：

- [ ] `plan.md` 中所有非 skipped 的子任务状态均为"已完成"
- [ ] 所有公开接口均已实现（无 `// TODO: implement`）
- [ ] 所有错误路径均有处理（无空 catch 块）
- [ ] 代码可以运行（无语法错误、无明显运行时错误）
- [ ] **执行 `/sop-diff --unannotated` 输出为空**（所有改动都有 CR 备注覆盖）

满足以上条件后，将 `IMPLEMENTATION.status` 更新为 `"done"`，并通知用户：
> "编码阶段完成。已记录 {N} 条变更记录到 .sop/changelog.md。
> 可执行 /sop-diff 查看本次任务的完整带备注 diff。
> 请使用 @optimizer subagent 进行代码优化（独立上下文）。"

## 修复模式（iteration > 1 时）

若 `state.json` 中 `iteration > 1` 且 `open_issues` 中有 `status = "open"` 的 Critical 问题，
说明你正在进行修复轮次，此时编码纪律有所不同：

- 优先处理 `fixes.md` 中所有 Critical 问题
- 每修复一个 Critical 问题：
  - 将 `state.json.open_issues` 中对应条目的 `status` 改为 `"fixed"`，附 `fixed_at`
  - 同步更新 `fixes.md` 表格中的状态
  - **追加一条新的 CR 到 changelog.md**，并标注 `fixes_issue: C-x`（不要去改老的 CR——那会让历史记录失真）
- 修复完成后再次进入 OPTIMIZATION → REVIEW 流程
