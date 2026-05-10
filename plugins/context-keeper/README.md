# context-keeper — Claude Code Plugin

> 由 [Velpro](mailto:xvelpro8@gmail.com) 开发，发布在 [buddy-hub](https://github.com/Velpro/buddy-hub) marketplace。

**buddy-hub 的"地基"插件**。给所有 plugin 共享一张项目知识图谱，外加一套标准化事件协议（SkillBus v0），把分散插件织成一个可查询、可追溯、可组合的能力星系。

context-keeper 自身**不直接产出工作流**——它是另外几个 plugin 的"上下文层"。它做三件事：

1. **事件流（events.jsonl）**：所有 plugin 把自己的关键节点写进同一条 append-only 流。
2. **物化视图（entities/）**：从事件流里聚合出 `task / decision / risk / red_line / lesson / review` 等可直接 query 的实体。
3. **历史链路 mirror**：通过非侵入式 hook，把现有 flowsmith / code-archaeologist / co-review 的状态文件写入自动同步成事件，**无需改动那 3 个 plugin**。

---

## 设计哲学

> 你不是在装第 5 个 plugin，你是在给前 4 个装一根总线。

之前 4 个 plugin 各自维护 `.sop/`、`.archaeology/`、`.team-scope/`，互相通过文件名约定串联。能 work，但每加一个 plugin 协同复杂度就 O(n²) 增长。

context-keeper 把"协同"这件事**外置**到一个共享层：所有 plugin 只跟事件流说话，不跟彼此说话。结果就是任何一个新 plugin 接入只需做两件事——发它产生的事件、订阅它关心的事件。这就是 Lollapalooza 效应能形成的前提：**乘法效应建立在标准化的接口之上**。

---

## 安装

### 方式一：从 buddy-hub Marketplace 安装（推荐）

```bash
# 1. 添加 Marketplace
claude plugin marketplace add Velpro/buddy-hub

# 2. 安装 context-keeper 插件
claude plugin install context-keeper@buddy-hub
```

### 方式二：本地安装

```bash
git clone https://github.com/Velpro/buddy-hub.git ~/buddy-hub
claude plugin install ~/buddy-hub/plugins/context-keeper
```

### 更新 / 卸载

```bash
claude plugin update context-keeper@buddy-hub
claude plugin uninstall context-keeper@buddy-hub
```

---

## 系统要求

- **bash** ≥ 4.0
- **jq**（必须）：macOS `brew install jq`，Ubuntu `apt install jq`
- **git**（推荐，用于项目根定位）

无其它依赖——纯 jsonl + jq，对齐其它 buddy-hub 插件的依赖足迹。

---

## 快速使用

### 全新项目

```bash
# 1. 初始化存储
/context-init

# 2. 之后正常使用其它插件即可（mirror hook 自动捕获状态变更）
/sop-init 重构通知系统
```

### 已有项目（已用过 flowsmith / 考古 / co-review）

```bash
# 1. 初始化
/context-init

# 2. 一次性回填历史
/context-migrate

# 3. 查看效果
/context-status
```

迁移会扫描 `.sop/`、`.archaeology/`、`.team-scope/`，按时间反推合成事件流。**不改动**也**不删除**任何旧文件——双轨并存。

### 日常查询

```bash
# 看某任务全过程
/context-query --task=a3f8c1d2

# 看所有红线
/context-query --type=red_line.set
bash $CLAUDE_PLUGIN_ROOT/scripts/context-cli.sh list-entities --type=red_line

# 看 co-review 输出
/context-query --actor=co-review --limit=20
```

---

## 命令清单

| 命令                      | 用途                                            |
|---------------------------|-------------------------------------------------|
| `/context-init`           | 初始化项目的 `.context/` 骨架                   |
| `/context-status`         | 当前事件数、实体数、最近事件                    |
| `/context-query`          | 按类型/actor/任务查询事件流                     |
| `/context-migrate`        | 一次性扫描旧 plugin 状态文件，回填事件          |
| `/context-emit`           | 手动 emit 一条事件（人工补录或脚本调用）        |

底层 CLI 还有 `list-entities`、`get-entity`、`rebuild` 三个子命令，直接 `bash ${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh <subcommand>` 调用。

---

## 与现有 plugin 的协同（兼容历史链路）

零改动接入。这是非侵入式集成的核心保证——

| 旧 plugin           | 旧产出                  | mirror hook 监听后自动 emit 的事件                 |
|---------------------|-------------------------|---------------------------------------------------|
| flowsmith           | `.sop/state.json`       | `task.created` / `task.phase.entered` / `task.phase.completed` / `task.iteration.started` / `task.closed` |
| flowsmith           | `.sop/lessons.md`       | `lesson.recorded`（粗粒度 snapshot）              |
| code-archaeologist  | `.archaeology/state.json` | `archaeology.started` / `archaeology.report.generated` |
| code-archaeologist  | `.archaeology/report.md`  | `archaeology.report.generated`（哈希去重）       |
| co-review           | `.team-scope/state.json`  | `team_review.completed`                          |

旧 plugin 不需要做任何改动。mirror hook 通过 `PostToolUse on Write|Edit` 监听写入，对状态文件做 diff 后 emit 等效事件。

进阶（Phase 2 后续工作）——让旧 plugin 在 `/sop-close`、`/arch-report`、`/scope-review` 内部主动调用 `/context-emit`，可以替代/补强 mirror hook，emit 更结构化的内容层事件（具体的 lesson/decision/red_line 而非状态 snapshot）。本期不做改动。

---

## 设计原则

1. **事件流是事实来源**。`events.jsonl` 是 append-only。`entities/` 和 `index.json` 都是缓存，可以 `rebuild` 重建。
2. **Forward-compat**。未知事件类型只追加不物化（不报错），保证旧 context-keeper 能消费新 plugin 发的事件。
3. **不接管、不替代**。不替代 Claude Code 自身的 hooks；不替代各 plugin 的 SOP 文件结构；不要求改动其它 plugin。
4. **依赖足迹对齐**。bash + jq，跟现有插件一样，没引入 SQLite / Node.js / Python。
5. **关闭开关**：`BUDDY_CONTEXT_DISABLED=1` 环境变量临时关闭所有 mirror 行为。

---

## 文档

- [`schemas/event-schema.md`](./schemas/event-schema.md) — SkillBus v0 事件协议（**必读**）
- [`schemas/entity-schema.md`](./schemas/entity-schema.md) — 物化视图与重建语义
- [`skills/event-emission/SKILL.md`](./skills/event-emission/SKILL.md) — 何时 / 如何主动 emit

---

## 路线图

| Phase | 内容                                                      | 状态     |
|-------|-----------------------------------------------------------|---------|
| 1     | L1 上下文层 + L2 SkillBus（本插件）                       | ✅ 当前 |
| 2     | field-sentinel（生产数据回流）+ lessons → patterns        | 规划中   |
| 3     | intent-router（自然语言 → plugin 编排）+ skill-composer   | 规划中   |
| 4     | team-pulse / release-captain / dynamic-agentic-ui         | 待评估   |

---

## License

MIT — 详见 [LICENSE](./LICENSE)。
