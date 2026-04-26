---
description: 启动一次代码考古，对指定文件/模块/符号进行三维深度分析（历史/依赖/意图）
argument-hint: <file-or-module-or-symbol> [--scope=single-file|recursive|symbol-only] [--intent=refactor|extract|rename|delete|understand]
---

# /arch-init — 启动考古

参数：$ARGUMENTS

## 执行步骤

### Step 1 — 解析参数

从 `$ARGUMENTS` 中解析：
- 必需：考古目标（文件路径、模块路径、或 `ClassName.methodName` 格式的符号）
- 可选 `--scope`：默认 `single-file`
- 可选 `--intent`：默认 `understand`

若未提供目标，输出：
> "用法：/arch-init <目标> [--scope=...] [--intent=...]
> 示例：
>   /arch-init src/auth/UserService.java
>   /arch-init src/auth/ --scope=recursive --intent=refactor
>   /arch-init UserService.findById --scope=symbol-only --intent=rename"
> 停止执行。

### Step 2 — 前置检查

**检查项目是 git 仓库**：
```bash
git rev-parse --is-inside-work-tree
```
若失败：
> "考古需要 git 历史。当前目录不在 git 仓库中。"
> 停止执行。

**检查目标存在**：
- 文件/目录路径：`ls -la <target>`
- 符号：用 `grep` 在项目中搜索符号定义

**检查并发考古**：
- 若 `.archaeology/state.json` 存在且 `report.status != "done"`，提示：
  > "发现进行中的考古：{archaeology_id} 目标 {target.path}。
  > 是否：(1) 继续该考古 → /arch-resume；(2) 放弃并开始新考古 → 删除 .archaeology/ 后重试"
  > 停止执行。

### Step 3 — 检测 flowsmith 上下文

读取 `.sop/state.json`（若存在）：

- 若存在且 `current_phase = PLANNING`：
  > "检测到 flowsmith 任务正在规划阶段（task_id: {flowsmith_task_id}）。
  > 本次考古结果将被自动注入到 .sop/plan.md 的'约束与前提'。"
  > 设置 `context.trigger = "flowsmith-recommended"`，`context.flowsmith_task_id = <id>`

- 否则：
  > 设置 `context.trigger = "manual"`，`context.flowsmith_task_id = null`

### Step 4 — 初始化目录与 state.json

```bash
mkdir -p .archaeology
```

按 `${CLAUDE_PLUGIN_ROOT}/schemas/archaeology-schema.md` 创建 `.archaeology/state.json`：

```json
{
  "version": "1.0",
  "archaeology_id": "<8 字符随机>",
  "target": {
    "type": "<file|module|symbol，根据参数推断>",
    "path": "<解析后的相对路径>",
    "symbol": "<若为 symbol 类型>",
    "scope": "<--scope 参数>"
  },
  "context": {
    "trigger": "<step 3 的判断结果>",
    "flowsmith_task_id": "<step 3 的判断结果>",
    "intent": "<--intent 参数>"
  },
  "agents": {
    "history-archaeologist":   { "status": "pending", "output": ".archaeology/history.md", "started_at": null, "completed_at": null },
    "dependency-archaeologist":{ "status": "pending", "output": ".archaeology/blast-radius.md", "started_at": null, "completed_at": null },
    "intent-archaeologist":    { "status": "pending", "output": ".archaeology/intent.md", "started_at": null, "completed_at": null }
  },
  "report": {
    "status": "pending",
    "output": ".archaeology/report.md",
    "risk_level": null,
    "recommended_strategy": null
  },
  "created_at": "<ISO8601>",
  "archived_at": null
}
```

### Step 5 — 输出考古计划摘要

```
🔍 考古任务已启动

ID：{archaeology_id}
目标：{target.path}{若有 symbol：'#'+symbol}
意图：{context.intent}
范围：{target.scope}
触发：{context.trigger}
{若 flowsmith-recommended：'关联 flowsmith 任务：{flowsmith_task_id}'}

将启动三个独立考古员（独立上下文，并行执行）：
  📜 history-archaeologist     — 时间维度，git 历史追溯
  🕸️  dependency-archaeologist — 空间维度，影响范围分析
  💭 intent-archaeologist      — 意图维度，设计动机反推

预计耗时：{根据 target 大小估算，单文件 2-5 分钟，模块 10-20 分钟}

开始派遣考古员...
```

### Step 6 — 派遣三个 subagent

按以下顺序触发（或并行，视 Claude Code 能力而定）：

1. **@history-archaeologist** — 任务指令：
   > "请对 .archaeology/state.json 中定义的考古目标执行历史考古。
   > 严格遵循你的 SOP。完成后将报告写入 .archaeology/history.md，
   > 更新 state.json 中你对应的 status 字段，并向我返回简短摘要。"

2. **@dependency-archaeologist** — 任务指令：同上，但执行影响范围分析

3. **@intent-archaeologist** — 任务指令：同上，但执行意图反推
   > "注意：你可以等待 history-archaeologist 完成后读取 .archaeology/history.md 作为参考。"

### Step 7 — 等待考古员完成

监控 `.archaeology/state.json`，直到三个 agent 的 status 全部为 `done` 或 `skipped`。

### Step 8 — 汇报阶段完成，引导下一步

```
✅ 三维考古完成

📜 history-archaeologist：{摘要}
🕸️  dependency-archaeologist：{摘要}
💭 intent-archaeologist：{摘要}

下一步：执行 /arch-report 生成综合考古报告与重构策略建议。
```
