---
description: 恢复中断的考古任务（重启失败的 agent 或继续未完成的工作）
---

# /arch-resume — 考古恢复

## 执行步骤

### Step 1 — 读取状态

读取 `.archaeology/state.json`。
若不存在：
> "未找到考古状态文件，无法恢复。请执行 /arch-init 开始新考古。"
> 停止。

### Step 2 — 识别中断点

扫描三个 agent 的 status，分类：

- **pending**：从未启动，需重新派遣
- **running**：可能因会话中断而停滞，需重启
- **done**：已完成，跳过
- **failed**：失败，需重启

### Step 3 — 输出恢复计划

```
🔄 考古恢复

ID：{archaeology_id}
目标：{target.path}

需要重新派遣的考古员：
  📜 history-archaeologist     {status}
  🕸️  dependency-archaeologist  {status}
  💭 intent-archaeologist      {status}

是否继续？(Y/n)
```

### Step 4 — 重新派遣未完成的 agent

对每个 status 不是 `done` 或 `skipped` 的 agent：

1. 将其 status 重置为 `running`
2. 清空 started_at（设为新的 ISO8601）
3. 触发对应 subagent，任务指令：
   > "请对 .archaeology/state.json 中定义的考古目标执行 {agent} 考古。
   > 严格遵循你的 SOP。完成后将报告写入对应的 output 文件，
   > 更新 state.json 中你对应的 status 字段。"

### Step 5 — 输出恢复结果

```
✅ 考古员已重新派遣

完成后建议执行 /arch-status 查看进度，或等待自动完成提示。
```

### Step 6 — 边界情况处理

**情况 1：所有 agent 已完成但 report 未生成**

> "三个考古员都已完成，但报告未生成。
> 可直接执行 /arch-report 生成综合报告。"

**情况 2：report 已完成但未注入 flowsmith**

> "考古报告已完成。
> {若 trigger == flowsmith-recommended：'但未注入 flowsmith。可执行 /arch-handoff 注入。'}"

**情况 3：考古已归档**

> "本次考古（archaeology_id: {id}）已归档于 {archived_at}。
> 如需新考古，请执行 /arch-init。"
