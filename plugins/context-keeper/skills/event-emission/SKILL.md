---
name: event-emission
description: 在合适时机主动 emit SkillBus 事件到 context-keeper。当你执行某个 plugin 的命令时（特别是 flowsmith 的 phase 转移、code-archaeologist 的报告生成、co-review 的审查结束、任何"产生新决策/红线/风险/教训"的瞬间），调用本 skill 决定是否 emit 以及 emit 什么。也用于手动补录、跨 plugin 协作的标准事件协议。
---

# Skill: Event Emission

把"什么时候 emit、emit 什么"这件事从各 plugin 的命令文件里抽出来，作为一个 Claude 主线程可以主动触发的能力。

## 何时触发本 skill

当你正在执行任意一个 buddy-hub plugin 的命令、且其中某一步产生了**有语义的状态变更**或**新沉淀**时：

| 情景                                    | 应 emit 的事件类型              |
|-----------------------------------------|--------------------------------|
| `/sop-init` 完成                        | `task.created`                 |
| `/sop-step` 切换阶段                    | `task.phase.entered` / `.completed` |
| `/sop-review` 启动                      | `review.started`               |
| review 找出 critical                    | `review.found.critical`        |
| `/sop-review` 完成                      | `review.completed`             |
| `/sop-close` 关闭任务                   | `task.closed` + 任意新 lesson 各一条 `lesson.recorded` |
| `/arch-init` 启动考古                   | `archaeology.started`          |
| `/arch-report` 生成报告                 | `archaeology.report.generated` + 每条红线一条 `red_line.set` |
| `/scope-review` 完成                    | `team_review.completed`        |
| co-review 检测到考古红线被违反          | `red_line.violated`            |
| plan/arch 中产生 ADR                    | `decision.recorded`            |
| 识别新风险                              | `risk.identified`              |
| 用户明确接受某风险                      | `risk.accepted`                |

> mirror hook 已经覆盖**状态文件层**（state.json）的 created/closed/phase 转移，所以 flowsmith / archaeology / co-review 的"骨架事件"通常自动产生。
> 本 skill 主要补全**内容层**事件——即从 markdown / 自由文本中识别出来的细粒度沉淀（具体的 decision、risk、red_line、lesson 文本），这些 mirror 看不到。

## 不要 emit 的场景

- 仅仅读取文件、没产生新状态
- 普通的代码 Edit / Write（这是 mirror hook 的工作）
- 调试输出、临时验证

## 如何 emit

调用 plugin 命令：

```
/context-emit --type=<X> --actor=<plugin> --entity-type=<T> --entity-id=<I> [--task=<id>] --evidence='[...]' --ext='{...}'
```

或直接调用 CLI（脚本场景）：

```bash
bash "${CLAUDE_PLUGIN_ROOT}/../context-keeper/scripts/context-cli.sh" emit \
  --type=red_line.set \
  --actor=code-archaeologist \
  --task="$TASK_ID" \
  --entity-type=red_line \
  --entity-id="rl_$(date +%s)" \
  --evidence="$EVIDENCE" \
  --ext="$EXT_JSON"
```

> 上面的相对路径假设 plugin 与 context-keeper 同时安装在 buddy-hub marketplace。生产路径请用绝对或 `${CLAUDE_PLUGIN_ROOT}` 配合。

## 必读：事件 schema 与实体定义

写 evidence / ext 之前，**务必先查阅**：
- `schemas/event-schema.md` — 字段约束、命名规范、类型清单
- `schemas/entity-schema.md` — 各实体类型的 ext 字段约定

不要把内容塞进 `evidence`（evidence 是审计线索，不是数据），新字段一律放 `ext.<plugin_name>.<field>`。

## 失败处理

`emit` 校验失败时，CLI 返回非零退出码并打印错误到 stderr。要点：
- **不要重试同样的参数**，先看错误
- 校验通过但物化失败（罕见）：用 `/context-status` 检查，必要时 `bash .../context-cli.sh rebuild` 从事件流重建

## Reference 文件

- `${CLAUDE_PLUGIN_ROOT}/schemas/event-schema.md` — 事件协议
- `${CLAUDE_PLUGIN_ROOT}/schemas/entity-schema.md` — 实体物化视图
