---
description: 把已有的 .sop/ .archaeology/ .team-scope/ 状态回填为 SkillBus 事件
---

# /context-migrate — 历史数据迁移

把项目里已经存在的 flowsmith / code-archaeologist / co-review 状态文件，
扫描并合成等效的 SkillBus 事件追加到 `.context/events.jsonl`。

**适用场景**：在已有项目里**首次安装 context-keeper** 时执行一次。

## 执行步骤

### Step 1 — 前置检查

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" status
```

确认 `.context/` 已初始化。如未初始化先执行 `/context-init`。

### Step 2 — 调用迁移

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" migrate
```

### Step 3 — 解读输出

迁移脚本会扫描以下文件，命中即生成事件：

| 源文件                       | 生成事件                                        |
|------------------------------|------------------------------------------------|
| `.sop/state.json`           | `task.created` + 每个 done 阶段一条 `task.phase.completed` + 当前阶段 `task.phase.entered` 或 `task.closed` |
| `.archaeology/state.json`   | `archaeology.started` + 报告 done 时 `archaeology.report.generated` |
| `.team-scope/state.json`    | `team_review.completed`（仅 status=done） |
| `.sop/lessons.md`           | `lesson.recorded`（粗粒度，仅记一条 snapshot） |

时间戳会**尽量从源文件元数据反推**（state.json 内的 created_at/completed_at），保证回填出的时间线接近真实历史。

### Step 4 — 幂等保证

- 同一个源文件（按 sha1 哈希）已迁移过则跳过，不重复 emit
- 多次运行 `/context-migrate` 安全
- 旧状态文件不会被修改、删除——双轨并存

### Step 5 — 后置动作

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" status
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" list-entities --type=task
```

## 注意事项

**迁移不解析 lessons.md / plan.md / arch.md / report.md 的内容**——它们是自由 markdown，
精细的实体抽取（具体 lesson、ADR、red_line）应当通过将来在各 plugin 的 close 命令里主动 emit
事件来完成（Phase 2 工作）。当前迁移只把"状态文件"映射成事件骨架。

**若需重做**：删除 `.context/events.jsonl` 中相关迁移事件后重新运行——但更推荐保留原迁移，
让事件流忠实保存"曾经做过这次迁移"的事实。
