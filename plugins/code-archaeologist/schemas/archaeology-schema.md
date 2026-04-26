# 考古工作流契约（Archaeology Schema）

本文件定义 code-archaeologist 插件运行时的所有数据结构。
所有 command / agent / skill 读写时必须遵循此契约。

---

## `.archaeology/state.json` 结构

```json
{
  "version": "1.0",
  "archaeology_id": "<8 字符随机>",
  "target": {
    "type": "file | module | symbol",
    "path": "src/auth/UserService.java",
    "symbol": "UserService.findById",
    "scope": "single-file | recursive | symbol-only"
  },
  "context": {
    "trigger": "manual | flowsmith-recommended",
    "flowsmith_task_id": null,
    "intent": "refactor | extract | rename | delete | understand"
  },
  "agents": {
    "history-archaeologist":   { "status": "pending|running|done|skipped", "output": ".archaeology/history.md",      "started_at": null, "completed_at": null },
    "dependency-archaeologist":{ "status": "pending|running|done|skipped", "output": ".archaeology/blast-radius.md", "started_at": null, "completed_at": null },
    "intent-archaeologist":    { "status": "pending|running|done|skipped", "output": ".archaeology/intent.md",       "started_at": null, "completed_at": null }
  },
  "report": {
    "status": "pending|done",
    "output": ".archaeology/report.md",
    "risk_level": null,
    "recommended_strategy": null
  },
  "created_at": "<ISO8601>",
  "archived_at": null
}
```

## 合法状态迁移

```
INIT                    → DISCOVERING        条件：/arch-init 执行
DISCOVERING             → ANALYZING          条件：3 个考古 agent 全部启动
ANALYZING               → SYNTHESIZING       条件：3 个考古 agent 全部 done 或 skipped
SYNTHESIZING            → DONE               条件：report.md 生成
DONE                    → ARCHIVED           条件：/arch-close 执行
```

## 合法 risk_level

- `low`     — 修改影响范围小（< 5 个调用方），无外部 API 变更
- `medium`  — 中等影响（5-20 调用方）或涉及内部 API 契约
- `high`    — 大范围影响（> 20 调用方）或涉及外部公开 API
- `critical`— 涉及核心数据模型、跨模块状态、或反射/序列化协议

## 合法 recommended_strategy

- `safe-refactor`         — 可直接重构，影响可控
- `staged-refactor`       — 分阶段重构，每阶段有明确兼容点
- `parallel-rewrite`      — 旧代码保留，新代码并行实现，灰度切换
- `freeze-and-document`   — 不重构，仅补文档（历史包袱大于改造收益）
- `escalate`              — 风险过高，需要人工架构评审

## report.md 字段映射

报告中以下字段会被回写到 `state.json`：

| report.md 字段 | state.json 字段 |
|---------------|-----------------|
| Risk Level    | report.risk_level |
| Strategy      | report.recommended_strategy |
| Generated At  | report.completed_at（隐式）|

## 与 flowsmith 的字段互通

当考古由 flowsmith 触发时（`context.trigger = "flowsmith-recommended"`）：

- `context.flowsmith_task_id` 存储 flowsmith 的 `task_id`
- 考古完成后，`report.md` 的 risk_level 和 recommended_strategy 应被注入到 flowsmith 的 `.sop/plan.md` 的"约束与前提"段落
- 见 `commands/arch-handoff.md` 中的回传逻辑
