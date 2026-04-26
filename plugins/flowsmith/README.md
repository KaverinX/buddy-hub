# flowsmith — Claude Code Plugin

> 由 [Velpro](mailto:xvelpro8@gmail.com) 开发，发布在 [buddy-hub](https://KaverinX/buddy-hub) marketplace。

状态机驱动的结构化开发 SOP（Standard Operating Procedure）工作流。一次安装，所有项目复用。

强制执行五阶段流程：**规划 → 架构 → 编码 → 优化 → 三层并行审查**，并在每个任务完成后沉淀经验到知识库，让系统随使用次数进化。

flowsmith = "Flow" + "smith"，意为"流程的铁匠"——为开发任务打造严密的执行流程。

---

## 安装

### 方式一：从 buddy-hub Marketplace 安装（推荐）

```bash
# 在 Claude Code 中执行
/plugin marketplace add KaverinX/buddy-hub
/plugin install flowsmith@buddy-hub
```

### 方式二：本地安装

```bash
git clone https://KaverinX/buddy-hub.git ~/buddy-hub
# 在 Claude Code 中
/plugin install ~/buddy-hub/plugins/flowsmith
```

### 方式三：直接从 GitHub

```bash
/plugin install KaverinX/buddy-hub
```

安装完成后，所有项目都可以使用 `/sop-init`、`/sop-review` 等命令，无需在每个项目中复制配置文件。

---

## 快速使用

### 首次接入（每个项目执行一次）

```bash
# 在项目根目录执行，生成轻量 CLAUDE.md 接入声明
/sop-bootstrap
```

此命令会在项目根目录创建（或追加）一份轻量级 CLAUDE.md，
作用是告诉 Claude "本项目使用 flowsmith"，
确保即使你忘记执行 /sop-init，Claude 也会主动引导走 SOP 流程。

### 日常使用

```bash
# 1. 开始新任务
/sop-init 实现用户通知系统：站内信 + 邮件，可配置偏好，已读未读状态

# 2-4. 跟随 Claude 完成规划、架构、编码（系统自动驱动）

# 5. 触发并行审查
/sop-review

# 6. 修复 Critical 问题（如有），再次审查
/sop-review

# 7. 归档经验
/sop-close
```

日常使用核心命令 6 个：

| 命令 | 频次 | 用途 |
|------|------|------|
| `/sop-bootstrap` | 每个项目 1 次 | 项目接入 SOP（生成 CLAUDE.md）|
| `/sop-init <任务>` | 每个任务 1 次 | 启动新任务 |
| `/sop-review` | 每轮审查 1 次 | 触发三层并行审查 |
| `/sop-close` | 每个任务 1 次 | 归档与经验沉淀 |
| `/sop-resume` | 中断时使用 | 从断点恢复 |
| `/sop-status` | 任意时刻 | 查询当前进度 |

---

## Plugin 架构

```
flowsmith/
├── .claude-plugin/
│   └── plugin.json                       # Plugin 元信息
├── commands/                             # 6 个 Slash Command
│   ├── sop-bootstrap.md                  # 项目接入：生成轻量 CLAUDE.md
│   ├── sop-init.md
│   ├── sop-review.md
│   ├── sop-resume.md
│   ├── sop-status.md
│   └── sop-close.md
├── agents/                               # 4 个 Subagent（独立上下文）
│   ├── optimizer.md                      # 代码优化专家
│   ├── arch-reviewer.md                  # 架构符合性审查
│   ├── security-reviewer.md              # STRIDE 安全审查
│   └── logic-reviewer.md                 # 逻辑正确性审查
├── skills/                               # 3 个 Skill（主线程引导）
│   ├── task-planning/
│   │   ├── SKILL.md
│   │   └── reference/
│   │       ├── state-machine.md          # FSM 契约
│   │       └── document-schemas.md       # 文档格式契约
│   ├── arch-design/
│   │   └── SKILL.md
│   └── implementation-guide/
│       └── SKILL.md
└── hooks/                                # 系统强制保障
    ├── hooks.json
    └── validate-state.sh                 # state.json 自动校验
```

项目仓库（建议纳入 git）：

```
your-project/
├── CLAUDE.md                             # 由 /sop-bootstrap 生成的轻量接入声明
└── .sop/
    ├── state.json                        # FSM 状态（机器可读）
    ├── plan.md                           # 任务规划
    ├── arch.md                           # 架构设计与 ADR
    ├── review.md                         # 多轮审查报告
    ├── fixes.md                          # Critical 问题修复追踪
    └── lessons.md                        # 跨任务经验积累
```

**CLAUDE.md 的特殊作用**：Claude Code 每次会话启动会自动加载项目根目录的 CLAUDE.md，
而 Plugin 中的命令/Skill 都是按需触发的。所以项目仍然需要一份**轻量级**的 CLAUDE.md，
作用是告诉 Claude "本项目使用 flowsmith"。详细规则、流程、agent 定义全部在 plugin 里，
项目里只保留 30 行左右的接入声明。这是 `/sop-bootstrap` 命令做的事。

---

## 设计原则

**1. 状态机驱动**：阶段流转由 `.sop/state.json` 控制，FSM 校验合法迁移，禁止跳阶段。Hook 在每次文件写入后自动校验状态合法性。

**2. 契约分离**：`state-machine.md` 和 `document-schemas.md` 是单一可信来源，所有 Skill 引用而非内嵌格式。修改格式时改一处，全局对齐。

**3. 上下文隔离**：Optimizer 和三个 Reviewer 都是 Subagent，独立上下文窗口。编码过程中积累的几百轮对话对优化和审查是噪音，独立上下文保证"新鲜眼睛"。

**4. 单一职责**：3 个专职 Reviewer 替代 1 个全包 Watchdog。架构审查、STRIDE 安全审查、逻辑审查需要完全不同的思维框架，分而治之保证每个维度的深度。

**5. 闭环追踪**：所有 Critical 问题通过 `state.json.open_issues` 追踪到 `status: fixed`，第 N 轮审查会对照第 N-1 轮的问题逐一验证修复。

**6. 知识积累**：`/sop-close` 将本次任务的 ADR、踩坑记录、典型问题写入 `lessons.md`。下次 `/sop-init` 时自动引用相关历史经验。

---

## 完整流程

```
/sop-init <任务>
    ↓ 创建 state.json { phase: PLANNING }

Skill: task-planning        → .sop/plan.md
    ↓ 用户确认 → { phase: ARCHITECTURE }

Skill: arch-design          → .sop/arch.md
    ↓ 用户确认 → { phase: IMPLEMENTATION }

主线程编码（遵循 implementation-guide）
    ↓ 编码完成 → { phase: OPTIMIZATION }

@optimizer（独立上下文）
    ↓ 优化完成 → { phase: REVIEW }

/sop-review
    ↓ 并行触发
@arch-reviewer  ┐
@security-reviewer ├─ 合并写 .sop/review.md
@logic-reviewer  ┘
    ↓
┌── 有 Critical ──────────────────────────────┐
│   写入 fixes.md → { phase: IMPLEMENTATION }  │
│   修复 → /sop-review（iteration+1，对照验证）│
└──────────────────────────────────────────────┘
    ↓ 无 Critical → { phase: DONE }

/sop-close → .sop/lessons.md（知识积累）
```

---

## 系统要求

- Claude Code（最新版本，支持 Plugin 系统）
- `jq`（用于 hooks 中的 state.json 校验，可选但推荐）
  - macOS: `brew install jq`
  - Ubuntu: `apt install jq`

---

## 团队部署

将 buddy-hub marketplace 推送到公司内部 Git 仓库：

```bash
# 团队成员一次性安装
/plugin marketplace add git@github.com:your-company/buddy-hub.git
/plugin install flowsmith@buddy-hub

# 之后所有人的 Claude Code 都拥有相同版本的 flowsmith
# 更新只需要在仓库中提交，团队成员执行 /plugin update
```

这样保证：
- 全团队 SOP 流程版本一致
- 升级 Plugin 自动推送给所有人
- 每个项目仓库只包含 `CLAUDE.md` + `.sop/` 产出，不重复存储 plugin 配置

---

## 开发与贡献

如需修改 Plugin 行为：

1. Fork 本仓库（[buddy-hub](https://KaverinX/buddy-hub)）
2. 修改对应的 `commands/` / `agents/` / `skills/` / `hooks/`
3. 本地测试：`/plugin install ./plugins/flowsmith`
4. 提交 PR

修改 SOP 流程的逻辑（如新增审查维度）：在 `agents/` 中新增 reviewer，并在 `commands/sop-review.md` 中注册触发。

修改文档格式：只需修改 `skills/task-planning/reference/document-schemas.md`，所有 Skill 自动对齐。

---

## 作者

**Velpro**
Email: [xvelpro8@gmail.com](mailto:xvelpro8@gmail.com)
Marketplace: [buddy-hub](https://KaverinX/buddy-hub)

---

## License

MIT © Velpro
