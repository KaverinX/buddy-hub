# buddy-hub

**[English](./README.md)** | **[中文](./README_zh.md)** | **[使用指南](./USAGE_zh.md)**

> Velpro 的 Claude Code Plugin Marketplace

专注于**规格驱动开发**、**工程纪律（测试先行）**、**开发者工作流自动化**与**多 Agent 协作**的 Claude Code 插件集合——全部构建在一套共享的事件溯源知识图谱之上。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

---

## 快速开始

### 安装 / 更新 / 卸载 Marketplace

```bash
claude plugin marketplace add    KaverinX/buddy-hub
claude plugin marketplace update KaverinX/buddy-hub
claude plugin marketplace remove KaverinX/buddy-hub
```

---

## 插件管理

```bash
claude plugin install   flowsmith@buddy-hub   # 安装插件
claude plugin update    flowsmith@buddy-hub   # 更新插件
claude plugin uninstall flowsmith@buddy-hub   # 卸载插件
claude plugin list                            # 查看已安装插件
```

> 第一次用？看 **[USAGE_zh.md](./USAGE_zh.md)** 的端到端走查——从一个需求，经澄清、设计，到完成；外加排查问题、小需求、生成整体规格的轻量化用法。

---

## 当前可用插件

### 🔨 [flowsmith](./plugins/flowsmith) — 状态机驱动的开发 SOP 工作流

**角色：核心编排器** | `v1.3.0` | 10 命令，4 agents，7 技能

强制执行严谨的开发周期，并内建测试先行纪律：
**PLANNING → ARCHITECTURE → TEST_FIRST → IMPLEMENTATION → OPTIMIZATION → REVIEW → DONE**。
用"每阶段都有明确输入/输出契约"杜绝"跳过思考直接写码"，再用"测试不绿不准前进"杜绝"跳过测试"。

**核心特性：**
- FSM 强制阶段迁移——不允许跳步
- **TEST_FIRST 阶段 + 绿灯门禁**——先写失败测试（红），测试未全绿不得离开 IMPLEMENTATION（由 PostToolUse hook 强制）
- **Iron Law + 红旗清单**贯穿所有技能——反自我开脱的硬规则，阻止 AI 把自己说服去跳过测试、根因定位或需求澄清
- **需求澄清门禁**（`/sop-brainstorm`）——需求模糊时，规划前先做苏格拉底式澄清
- **TDD**（先红后绿）与**系统化调试**（先根因后修复）技能
- **可自演进**——`writing-skills` 元技能 + `/skill-scaffold` 按规范创作新技能
- 4 个独立上下文 subagent：优化器 + 架构 / 安全 / 逻辑 审查员
- 通过 `.sop/lessons.md` 跨任务沉淀经验
- 与 spec-keeper 深度集成：把规格变更作为规划硬约束，`/sop-close` 时自动落地 delta

```bash
claude plugin install flowsmith@buddy-hub
```

---

### 📐 [spec-keeper](./plugins/spec-keeper) — 规格驱动开发（SDD）

**角色：规格真相维护者** | `v1.2.0` | 7 命令，1 技能

把**规格**做成一等公民：按能力组织、长期存活、与代码同步的 living spec，配合 `proposal → apply → archive` 三动作与 `ADDED/MODIFIED/REMOVED` 行为级 delta。动手前先对齐"做什么"，且这份对齐长期可 diff、可复审。

**核心特性：**
- **living spec**（`spec/capabilities/<id>/spec.md`）——按能力组织的系统行为真相，而非随任务消失的临时产物
- **行为级 delta**（`ADDED/MODIFIED/REMOVED`）——相对现有真相的 brownfield 友好 diff
- **正向 + 反向全流程：**
  - `/spec-propose` —— 正向：先写 delta 再实现
  - `/spec-bootstrap` —— 反向·全量：为已有项目捕获整体规格基线
  - `/spec-sync` —— 反向·增量：用当前分支的实际改动互补规格
  - `/spec-apply` —— 把已评审 delta 合并进 living spec（唯一改写"真相"的动作）
  - `/spec-archive` · `/spec-check`（漂移检测）· `/spec-status`
- 与 flowsmith、context-keeper 深度集成——每个动作 emit SkillBus 事件，规格变更天然进入知识图谱（"规格 + 事件溯源"组合）

```bash
claude plugin install spec-keeper@buddy-hub
```

---

### 🔍 [code-archaeologist](./plugins/code-archaeologist) — 老代码考古与重构辅助

**角色：遗留代码分析师** | `v1.0.0` | 6 命令，3 agents，1 技能

在重构、拆分、删除老代码前，派出三个独立考古学家从三个维度做深度尽调——避免 90% 的重构事故。

**核心特性：**
- 三维并行分析：历史 + 依赖 + 意图
- 检测 IDE 看不见的隐藏依赖（反射、配置驱动调用、序列化契约）
- 生成"不可逾越的红线"防止重构回归
- 考古结论自动注入 flowsmith 的规划约束
- 决策矩阵产出可执行的重构策略建议

```bash
claude plugin install code-archaeologist@buddy-hub
```

---

### 👥 [co-review](./plugins/co-review) — 团队协作审查工具

**角色：团队健康度巡检员** | `v1.0.0` | 4 命令，3 agents，1 技能

面向多人协作的横向审查。不审个人代码质量（那是 flowsmith 的事），而是分析团队协作健康度、接口冲突与完成度信号。

**核心特性：**
- 三层架构：贡献画像 + 完成度评估 + 协作风险检测
- 独立上下文 subagent 防止分析污染
- 纯终端 TUI 看板（`bash scripts/tui/dashboard.sh`）
- 隐私优先：每人反馈严格隔离——无横向比较、无态度评判
- 五级合并策略：`merge-now` → `staged` → `coordinate` → `block` → `escalate`

```bash
claude plugin install co-review@buddy-hub
```

---

### 🎨 [formatter](./plugins/formatter) — 代码风格守卫

**角色：代码风格守卫** | `v1.0.0` | 1 命令，2 hooks，1 技能

编辑时自动格式化 + 会话结束风格门禁。把团队编码规约注入 Claude 的编辑动作，消除风格争论。

**核心特性：**
- 内置蚂蚁/阿里 Java 编码规约（约 270 条 Eclipse JDT 规则）
- PostToolUse hook：每次编辑文件自动格式化
- Stop hook：会话结束前对所有改动文件做全局风格检查
- 一键支持 Maven 与 Gradle 项目
- 可扩展 profile 架构——放入新 XML 即可支持新语言

```bash
claude plugin install formatter@buddy-hub
```

---

### 📚 [context-keeper](./plugins/context-keeper) — 事件溯源知识图谱（地基）

**角色：共享地基** | `v1.0.0` | 5 命令，1 技能

整个生态赖以构建的基础设施层。append-only 事件流 + 物化视图，给每个插件一份可查询、可审计、可追溯的记忆——SkillBus 协议让插件互相观测而无需紧耦合。

**核心特性：**
- **append-only `events.jsonl`** 作为单一可信源 + 可完全重建的**物化视图**（`entities/`）
- **SkillBus v0 事件协议**——经本次升级，现已承载 `spec.*`（提案/捕获/同步/落地/漂移）与 `test.*`（红/绿/门禁/调试）事件
- **非侵入 mirror hook**——在写入瞬间捕获状态变更，不改动插件逻辑
- 每条事件带 **provenance/evidence**；通过 `ext.<plugin>.<field>` 子树向前兼容（只追加、不重命名）

```bash
claude plugin install context-keeper@buddy-hub
```

---

## 插件生态架构

插件不是孤立工具，而是互联生态。所有新能力都长在 context-keeper 地基上：

```
   📐 spec-keeper（SDD）                              🔨 flowsmith（核心编排器）
   living spec + delta                ── 关联 ──▶     BRAINSTORM(门禁) → PLAN → ARCH
   propose / bootstrap / sync          约束注入        → TEST_FIRST(红) → IMPL → OPT → REVIEW → DONE
        ▲   │ /sop-close 自动 /spec-apply             │             │ 绿灯门禁
        │   ▼                                         │             │
   把 delta 合并进 living 真相                         │ Hook:重构意图 │ Hook:多人协作
                                                       ▼              ▼
                         ┌────────────────┐  ┌────────────────┐   ┌────────────────┐
                         │ 🔍 code-       │  │ 👥 co-review   │   │ 🎨 formatter   │
                         │ archaeologist  │  │ 团队健康度      │   │ 风格守卫        │
                         │ 注入 plan.md   │  │ 读 .sop/*       │   │ 正交无耦合      │
                         └────────────────┘  └────────────────┘   └────────────────┘
                                         │          │
                                         ▼          ▼
                         ┌───────────────────────────────────────────────┐
                         │  📚 context-keeper —— 事件溯源地基               │
                         │  events.jsonl(append-only) + 物化视图           │
                         │  SkillBus 协议 · spec.* / test.* 事件            │
                         │  所有插件共享并向其 emit 的知识图谱              │
                         └───────────────────────────────────────────────┘
```

### 插件关联关系

| 从 | 到 | 机制 | 说明 |
|----|----|------|------|
| spec-keeper | flowsmith | 规划约束 | living spec 注入 `plan.md`；`/sop-close` 自动 `/spec-apply` |
| flowsmith | spec-keeper | `linked_change_id` | 任务关联规格变更；任务描述从提案/澄清自动继承 |
| flowsmith | code-archaeologist | Hook 触发 | 检测重构/拆分/迁移关键词 → 建议 `/arch-init` |
| flowsmith | co-review | Hook 触发 | `/sop-review` 后检测到多人协作 → 建议 `/scope-review` |
| code-archaeologist | flowsmith | `/arch-handoff` | 把结论注入 `plan.md` 的约束与前置条件 |
| co-review | flowsmith | 上下文读取 | 读取 `.sop/` 产物做更精准分析 |
| formatter | *(无)* | 正交 | 独立运行，无状态交互 |
| **全部插件** | context-keeper | SkillBus emit | 向共享知识图谱发事件（`spec.*`、`test.*`、`task.*`…） |
| **全部插件** | `lessons.md` | 共享读写 | 跨任务知识沉淀与注入 |

---

## 项目结构

```
buddy-hub/
├── .claude-plugin/marketplace.json   # Marketplace 元数据（6 个插件）
├── index.html                        # 交互式插件市场网站
├── README.md / README_zh.md          # 英文 / 中文文档
├── USAGE_zh.md                       # 端到端使用指南
├── LICENSE
└── plugins/
    ├── flowsmith/                    # SOP 工作流引擎 + 测试先行纪律
    │   ├── commands/                 # 10 个命令（含 sop-brainstorm/sop-test/skill-scaffold）
    │   ├── agents/                   # 4 个独立上下文 subagent
    │   ├── skills/                   # 7 个技能（规划/架构/tdd/调试/澄清/自演进/实施）+ _shared 模板
    │   └── hooks/                    # 状态校验 + 测试绿灯门禁
    ├── spec-keeper/                  # 规格驱动开发（SDD）
    │   ├── commands/                 # 7 个命令（propose/bootstrap/sync/apply/archive/check/status）
    │   ├── skills/                   # spec-authoring 技能
    │   └── schemas/                  # 规格与 delta 格式契约
    ├── code-archaeologist/           # 老代码考古
    ├── co-review/                    # 团队协作审查
    ├── formatter/                    # 代码风格守卫
    └── context-keeper/               # 事件溯源知识图谱（地基）
        ├── commands/  skills/  hooks/  schemas/  scripts/
```

---

## 后续规划

| 状态 | 插件 | 说明 | 关联 |
|------|------|------|------|
| 🟡 待启动 | **atlas** | 代码 wiki 与系统链路 spec。单项目可导航 wiki + 按接口契约 JOIN 的跨项目调用链图；用"实然结构"对比"应然规格"喂漂移检测。 | spec-keeper, context-keeper |
| 🟢 开发中 | **release-captain** | 标准化发布编排，多语言 Changelog 同步、语义化版本与发布门禁，衔接 flowsmith 的 DONE 到"上线"。 | flowsmith, co-review |
| 🔵 研究中 | **Project Insight UI** | 从 co-review 的 TUI 进化的 Web 仪表盘：代码演进曲线、团队健康热力图、重构风险雷达。 | co-review, code-archaeologist, flowsmith |

---

## 宏伟愿景

我们相信 AI 辅助编码不应是"更快地写出更多 bug"，而应是**"用工程纪律构建真正可靠的软件"**。

1. **规格即唯一可信源**——改系统前先对齐"做什么"。按能力组织的 living spec 与代码同步，让每次变更可 diff、可复审。
2. **过程即护栏**——状态机强制"先思考再编码、先测试再交付"，每阶段有明确契约，测试门禁是硬的，不允许跳步。
3. **纪律高于自我开脱**——每个刚性技能都带 Iron Law 和"红旗清单"，列出 AI 用来跳过规则的确切借口，阻止它把自己说服去违反纪律。
4. **知识复利**——事件溯源知识图谱 + `lessons.md`，让每次完工、每条审查发现、每个考古结论都回流，下个任务站在历史肩膀上。
5. **多 Agent 隔离**——每个分析维度独立上下文运行，安全审查不被优化建议干扰，团队分析不被偏见污染。
6. **隐私优先**——团队协作分析严格隔离每人数据，无横向比较、无态度评判。
7. **行动前先考古**——重构前先理解：为什么这么写？谁依赖它？哪些复杂是必要的？
8. **覆盖全生命周期**——从想法到上线：规格 → 澄清 → 规划 → 设计 → 测试 → 编码 → 格式化 → 考古 → 审查 → 团队协作 → 发布。

---

## 作者

**Velpro**
邮箱：[xvelpro8@gmail.com](mailto:xvelpro8@gmail.com)
GitHub：[@KaverinX](https://github.com/KaverinX)

---

## License

MIT © Velpro
