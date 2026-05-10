# flowsmith — Claude Code Plugin

> 由 [Velpro](mailto:xvelpro8@gmail.com) 开发，发布在 [buddy-hub](https://KaverinX/buddy-hub) marketplace。

状态机驱动的结构化开发 SOP（Standard Operating Procedure）工作流。一次安装，所有项目复用。

强制执行五阶段流程：**规划 → 架构 → 编码 → 优化 → 三层并行审查**，并在每个任务完成后沉淀经验到知识库，让系统随使用次数进化。

flowsmith = "Flow" + "smith"，意为"流程的铁匠"——为开发任务打造严密的执行流程。

---

## 安装

### 方式一：从 buddy-hub Marketplace 安装（推荐）

```bash
# 1. 添加 Marketplace
claude plugin marketplace add KaverinX/buddy-hub

# 2. 安装 flowsmith 插件
claude plugin install flowsmith@buddy-hub
```

### 方式二：本地安装

```bash
git clone https://github.com/KaverinX/buddy-hub.git ~/buddy-hub
claude plugin install ~/buddy-hub/plugins/flowsmith
```

### 更新

```bash
# 更新 Marketplace（拉取最新插件列表）
claude plugin marketplace update KaverinX/buddy-hub

# 更新 flowsmith 插件
claude plugin update flowsmith@buddy-hub
```

### 卸载

```bash
claude plugin uninstall flowsmith@buddy-hub
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

日常使用核心命令 7 个：

| 命令 | 频次 | 用途 |
|------|------|------|
| `/sop-bootstrap` | 每个项目 1 次 | 项目接入 SOP（生成 CLAUDE.md）|
| `/sop-init <任务>` | 每个任务 1 次 | 启动新任务 |
| `/sop-review` | 每轮审查 1 次 | 触发三层并行审查 |
| `/sop-close` | 每个任务 1 次 | 归档与经验沉淀 |
| `/sop-resume` | 中断时使用 | 从断点恢复 |
| `/sop-status` | 任意时刻 | 查询当前进度 |
| `/sop-diff` | 实施阶段任意时刻 | 查看带备注的 diff（worktree 友好），支持 `--backfill` 老任务回补 |

---

## Plugin 架构

```
flowsmith/
├── .claude-plugin/
│   └── plugin.json                       # Plugin 元信息
├── DESIGN-sop-diff.md                    # /sop-diff 设计文档（给维护者）
├── commands/                             # 7 个 Slash Command
│   ├── sop-bootstrap.md                  # 项目接入：生成轻量 CLAUDE.md
│   ├── sop-init.md
│   ├── sop-review.md
│   ├── sop-resume.md
│   ├── sop-status.md
│   ├── sop-close.md
│   └── sop-diff.md                       # 带备注的 diff + --backfill 老任务回补
├── agents/                               # 4 个 Subagent（独立上下文）
│   ├── optimizer.md                      # 代码优化专家
│   ├── arch-reviewer.md                  # 架构符合性审查
│   ├── security-reviewer.md              # STRIDE 安全审查
│   └── logic-reviewer.md                 # 逻辑正确性审查
├── skills/                               # 3 个 Skill（主线程引导）
│   ├── task-planning/
│   │   ├── SKILL.md
│   │   └── reference/
│   │       ├── state-machine.md          # FSM 契约（含 1.0→1.1 迁移规则）
│   │       └── document-schemas.md       # 文档格式契约（含 changelog.md）
│   ├── arch-design/
│   │   └── SKILL.md
│   └── implementation-guide/
│       └── SKILL.md                      # 含"变更日志纪律"
└── hooks/                                # 系统强制保障
    ├── hooks.json
    └── validate-state.sh                 # state.json 自动校验
```

项目仓库（建议纳入 git）：

```
your-project/
├── CLAUDE.md                             # 由 /sop-bootstrap 生成的轻量接入声明
└── .sop/
    ├── state.json                        # FSM 状态（机器可读，v1.1 含 git_context）
    ├── plan.md                           # 任务规划
    ├── arch.md                           # 架构设计与 ADR
    ├── changelog.md                      # 变更日志（每条 CR 含 why）
    ├── review.md                         # 多轮审查报告
    ├── fixes.md                          # Critical 问题修复追踪
    └── lessons.md                        # 跨任务经验积累
```

**CLAUDE.md 的特殊作用**：Claude Code 每次会话启动会自动加载项目根目录的 CLAUDE.md，
而 Plugin 中的命令/Skill 都是按需触发的。所以项目仍然需要一份**轻量级**的 CLAUDE.md，
作用是告诉 Claude "本项目使用 flowsmith"。详细规则、流程、agent 定义全部在 plugin 里，
项目里只保留 30 行左右的接入声明。这是 `/sop-bootstrap` 命令做的事。

---

## 带备注的 diff（worktree 友好）

### 它解决什么问题

在 worktree 流并行多任务时，单纯 `git diff` 看得到 **what** 看不到 **why**：
- 你下班前做了一半的改动，第二天早上再切回这个 worktree，要花 20 分钟反推自己当时的意图
- 团队成员 review 你的分支，看到一堆 hunk，但 commit message 和 PR 描述都不够细
- 你切到一个 Claude Code 跑了一晚上的工作区，想知道它做了什么决定

**flowsmith 的解法**：实施阶段 Claude 按"变更日志纪律"维护 `.sop/changelog.md`，
每个**逻辑变更批次**记录一条 CR-N，包含：
- 解决什么问题
- 为什么这么改（关联到 `arch.md` 的 ADR）
- 涉及哪些文件

`/sop-diff` 把 git diff 和 changelog.md 合并展示。

### 范围

`/sop-diff` **只看当前分支自分叉点以来的全部改动**，使用 merge-base 三点语义：
- ✓ 包含本分支自分叉以来的所有 commit
- ✓ 包含暂存区与未暂存的改动
- ✓ 包含未跟踪（且未被 .gitignore 忽略）的新文件
- ✗ 不包含 base 分支自分叉以来的独立提交（即使你已 pull/merge 过）

每个 worktree 是独立工作目录，自带独立的 `.sop/`，`/sop-diff` 在哪个 worktree 跑就只看哪个的内容。

### 日常用法

```bash
/sop-diff                  # 看本次任务的全部改动 + 全部备注（默认）
/sop-diff CR-3             # 只看某条变更记录的详情
/sop-diff --unannotated    # 只看尚未备注的改动（自检 / 提交前 checklist）
/sop-diff --staged         # 只比较暂存区
/sop-diff --base=develop   # 临时换一个基线
/sop-diff --files          # 只列文件清单 + CR 归属
```

### 输出示例

```
📐 SOP Annotated Diff
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

任务：实现用户通知系统：站内信 + 邮件，可配置偏好  (task_id: a3b9c2f1)
工作区：/Users/dev/repos/buddy-feat-notification (worktree)
分支：feat/notification  ←  基线：main (merge-base: e7f2c1d)
领先：12 commits        改动：8 files (+342 / -27)

─── 变更概览 ───

  CR-1  [create]  抽离通知抽象层 NotificationChannel    2 files   ADR-1  子任务 1.1
  CR-2  [create]  实现邮件通道（基于 nodemailer）        2 files   ADR-2  子任务 1.2
  CR-3  [create]  实现站内信通道（基于现有 DB）          1 file    ADR-3  子任务 1.3
  CR-4  [refactor] 抽离重试公共逻辑                      2 files   -      子任务 1.4

  ⚠️ 未备注改动：1 个文件
     - test/integration/notify.test.ts

─── 详细备注与 diff ───

╭─ CR-1 ─ 抽离通知抽象层 NotificationChannel ──────────────────╮
│ 类型：create        时间：2026-05-10T10:00:12Z              │
│ 关联：ADR-1 / 子任务 1.1                                      │
│                                                              │
│ 解决什么问题：                                                │
│   站内信和邮件两个通道在数据结构、错误模型、重试策略上差异   │
│   很大。如果直接在业务层 if/else，后续加短信、企业微信会反复 │
│   改业务代码。                                                │
│                                                              │
│ 为什么这么改：                                                │
│   按 ADR-1 决定，定义 NotificationChannel 接口 + 通道注册表。│
│   业务层只调 channel.send()，不感知具体实现。                │
│                                                              │
│ 涉及文件：                                                    │
│   ▸ src/notification/channel.ts        (新建)                │
│   ▸ src/notification/types.ts          (新建)                │
╰──────────────────────────────────────────────────────────────╯

  diff --git a/src/notification/channel.ts b/src/notification/channel.ts
  ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
共 4 条变更记录，覆盖 7/8 个改动文件。
```

### 老任务回补（--backfill）

如果你**升级到本版本前**已经在用 flowsmith，你的任务是 schema 1.0 版本，没有 changelog。
这时直接跑 `/sop-diff` 会提示先回补：

```bash
/sop-diff --backfill          # 预览：基于已有 commit 提议 CR 分组（不写入）
/sop-diff --backfill --auto   # 直接写入：每条 CR 的"为什么"用占位符 [需用户补充]
```

回补流程做两件事：
1. **schema 自动升级**：state.json 1.0 → 1.1，纯增量、幂等、可重跑
2. **CR 提议**：基于以下启发式聚类已有 diff
   - 同一个 commit 内的文件 → 同一 CR（commit 边界 ≈ 逻辑批次）
   - 同一目录前缀 → 同一 CR
   - 文件路径关键词命中 plan.md 子任务 → 自动关联子任务
   - diff 内容引用 arch.md 的接口名 → 自动关联 ADR

每条回补的 CR 标记 `backfilled: true` 和 `source_commits: [...]`，方便日后追溯。
"为什么这么改"留作 `[需用户补充]` 占位符——不强制立即填，至少先把骨架立起来，
后续 commit 哈希足够任何人定位原始上下文自行查证。

> 维护者向：完整设计权衡与验收测试场景见 [DESIGN-sop-diff.md](./DESIGN-sop-diff.md)。

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
    ↓ 创建 state.json { phase: PLANNING, git_context: {...} }
    ↓ 创建空的 .sop/changelog.md

Skill: task-planning        → .sop/plan.md
    ↓ 用户确认 → { phase: ARCHITECTURE }

Skill: arch-design          → .sop/arch.md
    ↓ 用户确认 → { phase: IMPLEMENTATION }

主线程编码（遵循 implementation-guide）
    ↓ 每完成一个逻辑批次 → 追加一条 CR-N 到 .sop/changelog.md
    ↓ 用户随时可 /sop-diff 看带备注 diff
    ↓ 编码完成（含 /sop-diff --unannotated 为空）→ { phase: OPTIMIZATION }

@optimizer（独立上下文）
    ↓ 优化完成 → { phase: REVIEW }

/sop-review
    ↓ 并行触发（reviewer 都会读 changelog.md 判断意图）
@arch-reviewer  ┐
@security-reviewer ├─ 合并写 .sop/review.md
@logic-reviewer  ┘
    ↓
┌── 有 Critical ──────────────────────────────┐
│   写入 fixes.md → { phase: IMPLEMENTATION }  │
│   修复（每修一个加一条 CR，标注 fixes_issue）│
│   → /sop-review（iteration+1，对照验证）     │
└──────────────────────────────────────────────┘
    ↓ 无 Critical → { phase: DONE }

/sop-close → .sop/lessons.md（知识积累）

─────────────────────────────────────────────
旁路：老任务（schema 1.0）首次进入新版时

  /sop-diff --backfill
      ↓ schema 1.0 → 1.1（纯增量字段，幂等）
      ↓ 提议 CR 分组（commit 边界 + 目录聚类 + plan/arch 启发式）
      ↓ 用户确认 → 写入 .sop/changelog.md
      ↓ 不影响 phase；后续按正常纪律继续
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
claude plugin marketplace add git@github.com:your-company/buddy-hub.git
claude plugin install flowsmith@buddy-hub

# 之后所有人的 Claude Code 都拥有相同版本的 flowsmith
# 更新只需要在仓库中提交，团队成员执行：
claude plugin marketplace update your-company/buddy-hub
claude plugin update flowsmith@buddy-hub
```

这样保证：
- 全团队 SOP 流程版本一致
- 升级 Plugin 自动推送给所有人
- 每个项目仓库只包含 `CLAUDE.md` + `.sop/` 产出，不重复存储 plugin 配置

---

## 开发与贡献

如需修改 Plugin 行为：

1. Fork 本仓库（[buddy-hub](https://github.com/KaverinX/buddy-hub)）
2. 修改对应的 `commands/` / `agents/` / `skills/` / `hooks/`
3. 本地测试：`claude plugin install ./plugins/flowsmith`
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
