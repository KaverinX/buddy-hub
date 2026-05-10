---
description: 查询事件流。支持按类型 / actor / 任务过滤，按时间倒序输出
argument-hint: [--type=X] [--actor=Y] [--task=Z] [--limit=N]
---

# /context-query — 查询上下文事件流

从 `.context/events.jsonl` 中按条件检索事件，是排查协同问题、回溯任务历史的主要工具。

参数：$ARGUMENTS

## 执行步骤

### Step 1 — 调用 CLI

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" query $ARGUMENTS
```

### Step 2 — 解读输出

CLI 返回 JSON 数组（最多 limit 条，默认 100）。每条事件包含：
- `id` / `ts` / `type` / `actor`
- `task_id`（关联的 flowsmith 任务，可能为 null）
- `entity`（事件主语：task / red_line / lesson / ...）
- `evidence`（推断依据）
- `ext`（plugin 特定扩展）

## 用法示例

| 场景 | 命令 |
|------|------|
| 看某任务全过程 | `/context-query --task=a3f8c1d2` |
| 找所有红线设立 | `/context-query --type=red_line.set` |
| 看 co-review 输出 | `/context-query --actor=co-review --limit=20` |
| 找已被违反的红线事件 | `/context-query --type=red_line.violated` |
| 最近 50 条 | `/context-query --limit=50` |

## 列出实体（替代查询）

如果要看"所有任务"、"所有红线"这种实体级别，用 list-entities：

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" list-entities --type=task
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" list-entities --type=red_line
```

或获取单个实体详情：

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" get-entity --type=task --id=a3f8c1d2
```
