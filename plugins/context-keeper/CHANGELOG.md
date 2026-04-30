# Changelog

本插件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 规范，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [1.0.0] — 2026-04-28

首次发布。Phase 1 落地 buddy-hub Lollapalooza 重构方案的 L1 + L2。

### 新增

- **事件流存储**：append-only `events.jsonl` + 物化 `entities/<type>/<id>.json` + `index.json`。
- **SkillBus v0 事件协议**（`schemas/event-schema.md`）：定义事件结构、字段约束、命名规范、当前 v0 事件类型清单（task / decision / risk / red_line / lesson / review / report / archaeology / team_review / format 共 19 种）。
- **实体物化层**（`schemas/entity-schema.md`）：定义 9 种实体的字段结构，重建语义。
- **核心 CLI** `scripts/context-cli.sh`：`init / status / emit / query / list-entities / get-entity / rebuild / migrate`。
- **历史链路 mirror hook**（`scripts/mirror-legacy.sh`）：PostToolUse on Write|Edit 监听 `.sop/state.json` / `.sop/lessons.md` / `.archaeology/state.json` / `.archaeology/report.md` / `.team-scope/state.json`，自动 emit 等效事件。**完全不修改其它 plugin**。
- **一次性历史迁移**（`scripts/migrate-legacy.sh`）：扫描已有 4 plugin 的状态文件，按原始时间戳合成事件回填。幂等（按 sha1 去重）。
- **5 个 slash 命令**：`/context-init`、`/context-status`、`/context-query`、`/context-migrate`、`/context-emit`。
- **Skill** `event-emission`：指导主线程在何时主动 emit 事件，覆盖 mirror 看不见的内容层事件（具体 lesson / decision 文本）。
- **关闭开关**：`BUDDY_CONTEXT_DISABLED=1` 全局禁用 mirror。
- **调试模式**：`BUDDY_CONTEXT_DEBUG=1` 打印诊断日志。

### 兼容性

- 现有 4 个 plugin（flowsmith / formatter / code-archaeologist / co-review）**无需任何修改**。本插件通过 mirror hook 单向同步，不写也不读它们的输出文件。
- 老项目装上后执行一次 `/context-init && /context-migrate` 即可获得回填。
- Schema 演进：未知事件类型 / 字段消费者必须忽略，保证向后兼容。
