---
description: 查看当前考古任务的进度与各 agent 状态
---

# /arch-status — 考古状态查询

## 执行步骤

### Step 1 — 读取状态

读取 `.archaeology/state.json`。
若不存在：
> "未找到 .archaeology/state.json，当前无进行中的考古任务。
> 执行 /arch-init <目标> 开始新考古。"
> 停止。

### Step 2 — 输出状态报告

```
🔍 考古任务状态
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID：{archaeology_id}
目标：{target.path}{若有 symbol：'#'+symbol}
意图：{context.intent}
范围：{target.scope}
触发：{context.trigger}
{若 flowsmith_task_id 非空：'关联 flowsmith：{flowsmith_task_id}'}

─── 考古员进度 ───

  📜 history-archaeologist     {icon}  {status}  {duration 或 -}
  🕸️  dependency-archaeologist  {icon}  {status}  {duration 或 -}
  💭 intent-archaeologist      {icon}  {status}  {duration 或 -}

─── 报告状态 ───

  状态：{report.status}
  风险评级：{report.risk_level 或 '待生成'}
  推荐策略：{report.recommended_strategy 或 '待生成'}

─── 产出文件 ───

  {对每个 .archaeology/*.md 输出存在性、大小、最后修改时间}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
下一步：{根据当前状态给出引导}
```

状态图标对照：
- `pending`  → ⬜
- `running`  → ⏳
- `done`     → ✅
- `skipped`  → ⏭️
- `failed`   → 🔴

### Step 3 — 引导下一步

| 当前情况 | 引导 |
|---------|------|
| 任一 agent 状态为 running | "等待 agent 完成，或检查进程是否卡住" |
| 所有 agent done，report pending | "执行 /arch-report 生成综合报告" |
| report done，未关联 flowsmith | "可执行 /arch-handoff 将结论注入 flowsmith 任务" |
| report done，已关联 flowsmith | "回到 flowsmith 流程继续。完成后执行 /arch-close 归档" |
| report archived | "本次考古已归档" |

### Step 4 — 健康检查

附加在末尾，若发现：
- agent status = "running" 但已超过 30 分钟 → ⚠️ 可能卡住
- report.status = "done" 但 .archaeology/report.md 不存在 → ⚠️ 状态与产出不一致
- linked_archaeologies 引用的 flowsmith task 已不存在 → ⚠️ flowsmith 任务可能已被删除
