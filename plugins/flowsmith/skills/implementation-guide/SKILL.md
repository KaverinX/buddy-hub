---
name: implementation-guide
description: 编码实施规范 Skill。在 SOP 流程的 IMPLEMENTATION 阶段使用，规范编码纪律：架构契约遵循、错误处理标准、接口稳定性、子任务进度追踪。当 .sop/state.json 中 current_phase 为 IMPLEMENTATION 时由 Claude 主动遵循。
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

### 原则五：编码完成的定义

以下条件全部满足，才可以声明"编码完成"，进入优化阶段：

- [ ] `plan.md` 中所有非 skipped 的子任务状态均为"已完成"
- [ ] 所有公开接口均已实现（无 `// TODO: implement`）
- [ ] 所有错误路径均有处理（无空 catch 块）
- [ ] 代码可以运行（无语法错误、无明显运行时错误）

满足以上条件后，将 `IMPLEMENTATION.status` 更新为 `"done"`，并通知用户：
> "编码阶段完成。请使用 @optimizer subagent 进行代码优化（独立上下文）。"

## 修复模式（iteration > 1 时）

若 `state.json` 中 `iteration > 1` 且 `open_issues` 中有 `status = "open"` 的 Critical 问题，
说明你正在进行修复轮次，此时编码纪律有所不同：

- 优先处理 `fixes.md` 中所有 Critical 问题
- 每修复一个 Critical 问题，将 `state.json.open_issues` 中对应条目的 `status` 改为 `"fixed"`，附 `fixed_at`
- 同步更新 `fixes.md` 表格中的状态
- 修复完成后再次进入 OPTIMIZATION → REVIEW 流程
