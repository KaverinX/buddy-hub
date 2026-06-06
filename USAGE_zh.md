# buddy-hub 使用指南（v1.3，对标升级后）

> 从一个需求出发，走完 **需求澄清 → 方案设计 → 实现 → 审查 → 完成 → 规格沉淀** 的全过程。
> 本指南与升级后的真实命令/产物一一对应。多宿主不在本指南范围内。

---

## 0. 先理解交互模型（重要）

buddy-hub 的阶段推进是**对话 + 技能驱动**，不是每步都敲一个命令：

- **少数关键节点用显式命令**：`/sop-brainstorm`、`/sop-init`、`/sop-test`、`/sop-review`、`/sop-close`（规格驱动还有 `/spec-propose`、`/spec-apply`）。
- **其余阶段靠"确认推进"**：一个阶段产物生成后，Claude 会问"是否确认，进入下一阶段？"，你回"确认/继续"，Claude 就更新 `state.json` 的 `current_phase`，对应阶段的 **Skill 自动接管**（技能按 `current_phase` 触发）。
- **门禁是硬的**：测试不绿，`IMPLEMENTATION → OPTIMIZATION` 会被 hook 拦截；模糊需求未澄清，brainstorming 的 IRON LAW 不让进 PLANNING。
- **后台自动发生**：formatter 在每次编辑后自动格式化；context-keeper 的 mirror hook 自动把状态变更记进事件流；plan 里出现"重构/拆分"会被提示 `/arch-init`（考古），review 后检测到多人协作会被提示 `/scope-review`（协作审查）。

---

## 1. 升级后的完整生命周期

```
（可选 规格驱动）/spec-propose ──┐  写 spec/changes/<id>/proposal.md（delta）
                                  │
   /sop-brainstorm  ── 需求澄清 ──┤  写 .sop/brainstorm.md
                                  ▼
   /sop-init ── 建任务(v1.2 state) ── PLANNING
        │ task-planning skill：读 brainstorm + lessons + living spec → 写 plan.md
        ▼ 你确认
   ARCHITECTURE  arch-design skill → 写 arch.md（含 ADR）   〔含重构? 提示 /arch-init 考古〕
        ▼ 你确认
   /sop-test ── TEST_FIRST  tdd skill：先写【失败】测试(red) → tests-plan.md
        ▼ 确认测试为红
   IMPLEMENTATION  implementation-guide skill：最小实现让测试转绿；写 changelog CR
        │  〔formatter 自动格式化｜绿灯门禁：测试不绿不准走〕
        ▼ 测试全绿
   OPTIMIZATION  @optimizer subagent 优化
        ▼
   /sop-review ── REVIEW  arch/security/logic 三审并行 → review.md   〔多人? 提示 /scope-review〕
        │   有 Critical → 回 IMPLEMENTATION（iteration+1）
        ▼   无 Critical → DONE
   /sop-close ── 写 lessons.md；若关联 spec 变更，自动 /spec-apply 落地 delta
        ▼（规格驱动）
   /spec-archive ── 归档变更（living spec 已是新真相）
```

---

## 2. 三种使用档位：先选你这次走多重的流程

| 档位 | 适用 | 流程 |
|------|------|------|
| **轻量档** | 单行 typo / 改配置 / 纯文档 | 直接改；最多 `/sop-init` 后把 PLANNING/ARCH/TEST_FIRST 显式标 `skipped`+理由 |
| **标准档** | 常规 feature / fix / 重构 | brainstorm（需求模糊才用）→ init → plan → arch → test → impl → opt → review → close |
| **规格驱动档** | 重要能力、需长期维护、对外接口 | 标准档之外，前面加 `/spec-propose`，收尾 `/sop-close` 自动 `/spec-apply` + `/spec-archive` |

> 门禁可按档位降级（沿用 flowsmith 既有 `skipped + 理由` 机制），避免小改动被重流程拖累。热修复可跳 PLANNING/ARCH/TEST_FIRST，但 **REVIEW 不可跳**，且事后须补回归测试。

---

## 3. 逐步交互详解

下面以**规格驱动档**为主线（标准档就是去掉规格相关两步）。

### 步骤 ①（可选）发起规格提案 —— "先对齐再动手"
```
/spec-propose "通知系统支持邮件渠道，可按用户偏好开关"
```
- Claude 读现有 `spec/capabilities/`，产出 `spec/changes/notify-email-<id>/proposal.md`：用 **ADDED/MODIFIED/REMOVED** 写出本次相对现有规格的**行为级 delta**，每条 R 可判定（能写成测试），并生成 `tasks.md`。
- 你**评审 proposal**（这是 OpenSpec 式"先对齐"的核心物）。
- 何时用：这次改动涉及长期能力/对外接口时。纯内部小改可跳过。

### 步骤 ② 需求澄清
```
/sop-brainstorm "给通知系统加邮件渠道"
```
- Claude 按 brainstorming 的 IRON LAW：**不澄清完不进规划**。它会问真正影响方案的问题（范围边界、隐性需求如重试/失败态、成功标准、约束），枚举边界与失败模式，并给 **1–2 个带取舍的设计方向**让你选。
- 你回答 + 选方向后，固化为 `.sop/brainstorm.md`（范围 / 隐性需求 / 成功标准 / 选定方向）。
- 何时用：需求模糊时。需求本就清晰可直接跳到 ③。

### 步骤 ③ 建任务，进入规划
```
/sop-init        # 走过 ①/② 时无需带描述——自动继承定稿任务
```
- **无需重复描述任务**：`/sop-init` 不带参数时，按优先级自动继承上游定稿——
  ① `.sop/brainstorm.md` 头部 `> task:`（澄清后的定稿描述，最优先）→ ② 最近一个 `status=proposed` 的 `spec/changes/<id>` 提案标题（并自动关联 `linked_change_id`）。
  继承时会回显"已继承澄清结论/规格提案：{描述}"，你可在下一句直接纠正。
- **仅在没走过 ①/② 时**才需要自己写：`/sop-init "任务描述"`；带了描述也可覆盖上游（用于精炼）。
- 创建 `.sop/state.json`（**v1.2**：含 TEST_FIRST 阶段、test_gate、spec_context），自动探测测试命令、关联 `spec/changes/<id>`、探测 git 上下文。`current_phase = PLANNING`。
- **PLANNING（task-planning skill 自动触发）**：读 `.sop/brainstorm.md`（优先采信）+ `.sop/lessons.md`（历史教训）+ 关联的 living spec（作硬约束），产出 `.sop/plan.md`：子任务分解、依赖图、影响范围、风险矩阵。
- Claude 汇报后问："是否确认规划，进入架构设计？" → 你回 **"确认"**。
- 👀 若 plan 里含"重构/拆分/迁移"关键词，会被提示先做 `/arch-init`（code-archaeologist 三维考古，把红线注入 plan）。

> 链路简化要点：澄清/提案已经把任务定稿，`/sop-init` 直接接棒，不再重复输入；信息从 `brainstorm.md` 的 `> task:` 行和 `proposal.md` 标题流过来，并通过 `spec_context.linked_change_id` 把任务与规格变更绑定。

### 步骤 ④ 方案设计（架构）
- 你确认后 Claude 把 `current_phase` 置 `ARCHITECTURE`，**arch-design skill 自动接管**，基于 plan.md 产出 `.sop/arch.md`：整体设计、模块职责与边界、关键接口契约、**ADR（架构决策记录，含考量的方案/决定/代价）**、Out of Scope。
- Claude 问："是否确认架构，进入测试设计？" → 你回 **"确认"**。
- 这是 SOP 智识密度最高的一步——接口契约和数据模型在这里定稿（规格驱动档里它们将"毕业"进 living spec）。

### 步骤 ⑤ 先写测试（TEST_FIRST，TDD 红灯）
```
/sop-test --command="npm test"        # 命令已在 init 探测到时可省略
```
- 进入 `TEST_FIRST`，**tdd skill** 针对 arch.md 的每个接口契约、plan.md 每个验收点写测试，**运行并确认它们失败（红）**，失败原因必须是"功能未实现"。失败证据写入 `.sop/tests-plan.md`。
- ⚠️ 若测试首次就全绿 → 警告：测试可能无效，要求修正。
- 确认为红后进入实现。

### 步骤 ⑥ 实现（IMPLEMENTATION，TDD 绿灯）
- 你说"开始实现"（或直接让 Claude 编码），**implementation-guide skill** 约束：架构是契约不是建议、错误处理与正常逻辑同等优先、接口稳定性、每个逻辑批次写一条 `changelog.md` 的 CR 记录。
- 写**最小实现让测试转绿**，不提前实现未被测试覆盖的功能。
- 🤖 **后台自动**：每次 Edit/Write 后 formatter 自动格式化；context-keeper mirror 记录变更。
- 🚦 **绿灯门禁**：当你想推进到优化时，`validate-tests.sh` 会实跑 `test_gate.command`，**不绿就拒绝迁移**并提示看 `/tmp/flowsmith-test.log`。
- 🐞 遇到 bug：**systematic-debugging skill** 强制"先定位可复现根因，再动手"，修复时补一条会因该 bug 失败的回归测试。

### 步骤 ⑦ 优化（OPTIMIZATION）
- 测试全绿后，调用 `@optimizer`（独立上下文 subagent）做优化（可读性、重复消除、性能），优化后测试须仍绿。

### 步骤 ⑧ 审查（REVIEW）
```
/sop-review
```
- 三个**独立上下文** reviewer 并行：`@arch-reviewer`（架构符合性）、`@security-reviewer`（安全）、`@logic-reviewer`（逻辑正确性），合并产出 `.sop/review.md`，给总体评级 🟢/🟡/🔴 与问题列表。
- **有 Critical（status=open）** → 回到 IMPLEMENTATION，`iteration+1`，修完再 `/sop-review`（下一轮会对比上轮问题是否真修复）。
- **无 Critical** → `current_phase = DONE`。
- 👀 若检测到多人协作（多 author），会被提示 `/scope-review`（co-review 团队协作健康度审查，含 TUI 看板与五级合并策略）。

### 步骤 ⑨ 收尾与知识/规格沉淀
```
/sop-close
```
- 读完整任务记录，提炼经验**追加进 `.sop/lessons.md`**（架构可复用决策、踩坑根因、反复出现的问题、下次如何提前规避）——下一个任务会引用它。
- 归档 state.json。
- **规格驱动档**：若 `spec_context.linked_change_id` 非 null，自动 `/spec-apply <id> --from-sop`，把 delta 合并进 `spec/capabilities/<cap>/spec.md`（接口/数据契约一并"毕业"进 living spec），成为系统新真相。
- emit `task.closed`（+ `spec.applied`）。

### 步骤 ⑩（规格驱动档）归档变更
```
/spec-archive notify-email-<id>
```
- 变更收尾，living spec 已反映其结果。delta 历史在 change 文件夹与事件流里永久可查。

### 任何时候
- `/sop-status`：看当前任务在哪个阶段、各阶段状态。
- `/sop-resume`：中断后恢复，Claude 读 state.json 接着上次继续。
- `/sop-diff`：看带 CR 备注的 diff。
- `/spec-status`、`/spec-check`：看能力清单/活跃变更、规格健康度与漂移。

---

## 4. 一个完整的对话级范例（邮件渠道）

```
你：/spec-propose "通知系统支持邮件渠道，可按用户偏好开关"
Claude：[读 spec/capabilities/notification] 已创建 spec/changes/notify-email-a1b2/
        Delta：+2 新增（R-5 邮件发送 / R-6 偏好开关）/ ~1 修改（R-2 通道选择）/ -0
        请评审 proposal.md。

你：[看完] 没问题，继续
你：/sop-brainstorm "实现邮件通知渠道"
Claude：澄清三点：①发送失败重试几次？②偏好关闭时是静默丢弃还是报错？③SMTP 配置走环境变量？
        两个方向：A 直接在业务层发邮件（简单，但加渠道要改业务）；B 抽 NotificationChannel 接口（多一层，未来加短信零改动）。
你：重试3次；静默丢弃；环境变量；选 B
Claude：已固化 .sop/brainstorm.md（选定方向 B）。下一步 /sop-init。

你：/sop-init                      # 不用再描述任务
Claude：已继承澄清结论：实现邮件通知渠道（nodemailer，重试3次，偏好开关，方向B）
        ✅ 初始化（task_id=3f9a, v1.2, 关联 change notify-email-a1b2, test_gate=npm test）
        [PLANNING] 拆 3 个子任务，主要风险：SMTP 超时。是否确认进入架构设计？
你：确认
Claude：[ARCHITECTURE] arch.md：定义 NotificationChannel 接口 + EmailChannel；ADR-1 选 B；ADR-2 选 nodemailer。确认进入测试设计？
你：确认
你：/sop-test
Claude：[TEST_FIRST] 写了 EmailChannel.send 成功/重试/偏好关闭 三组测试，运行 → 全部失败（功能未实现）✅红。进入实现？
你：开始实现
Claude：[IMPLEMENTATION] 实现 channel.ts / email.ts…（formatter 自动格式化，写 CR-1/CR-2）
        测试运行 → 全绿 🟢。绿灯门禁通过，进入优化。
        [OPTIMIZATION] @optimizer 收敛重试逻辑，测试仍绿。
你：/sop-review
Claude：[REVIEW] 架构🟢 安全🟡(SMTP密码日志泄露 C-1) 逻辑🟢 → 有 Critical，回实现。
你：修一下
Claude：[IMPLEMENTATION it.2] 脱敏日志 + 回归测试，绿。
你：/sop-review
Claude：[REVIEW it.2] C-1 已真正修复，无 open Critical → DONE。
你：/sop-close
Claude：经验已写入 lessons.md；检测到关联 change → /spec-apply notify-email-a1b2：
        R-5/R-6 已合并进 spec/capabilities/notification/spec.md，邮件渠道成为系统真相。
你：/spec-archive notify-email-a1b2
Claude：变更已归档。
```

---

## 5. 命令速查

| 命令 | 阶段/作用 |
|------|-----------|
| `/spec-propose <描述>` | （规格驱动）写变更 delta |
| `/sop-brainstorm <需求>` | 需求澄清 → brainstorm.md |
| `/sop-init [任务]` | 建任务，进 PLANNING；走过澄清/提案时**留空自动继承**定稿描述 |
| `（说"确认"）` | PLANNING→ARCHITECTURE 等阶段推进 |
| `/sop-test [--command=]` | 进 TEST_FIRST，写失败测试 |
| `（说"开始实现"）` | 进 IMPLEMENTATION |
| `@optimizer` | OPTIMIZATION 优化 |
| `/sop-review` | 三层并行审查 |
| `/sop-close` | 收尾，写 lessons，联动 spec-apply |
| `/spec-archive <id>` | （规格驱动）归档变更 |
| `/arch-init`〔考古〕 `/scope-review`〔协作〕 | 按提示触发的增强 |
| `/sop-status` `/sop-resume` `/sop-diff` `/spec-status` `/spec-check` | 查询/恢复类 |
| `/spec-bootstrap` `/spec-sync` | 反向生成/同步 spec（全量基线 / 分支增量回填） |

---

## 6. 文件落地地图

```
仓库根/
├── spec/                     # spec-keeper：长期真相（应然）
│   ├── capabilities/<cap>/spec.md     # living spec（关任务时由 spec-apply 更新）
│   └── changes/<id>/proposal.md       # 变更 delta（评审对象）
├── .sop/                     # flowsmith：本次任务工作区（关任务即归档）
│   ├── state.json   brainstorm.md   plan.md   arch.md
│   ├── tests-plan.md   changelog.md   review.md
│   └── lessons.md   # 跨任务知识库（不归档，持续追加）
└── .context/                 # context-keeper：events.jsonl + 物化视图（自动）
```

记忆口诀：**spec/ 是系统长期真相，.sop/ 是这次任务的草稿纸，.context/ 是自动记账本。**

---

## 7. 常见问题

- **卡在绿灯门禁进不去优化？** 测试没全绿。看 `/tmp/flowsmith-test.log`，修到绿；确实该跳（如纯文档）就把 TEST_FIRST 标 `skipped`+理由。
- **审查反复出 Critical？** 每轮 `/sop-review` 会对比上轮问题"是否真修复"，避免假修。修完再跑即可，iteration 自动递增。
- **中途断了？** `/sop-resume`，Claude 读 state.json 从断点继续。
- **想跳过某阶段？** 在 state.json 把该阶段 `status` 显式置 `skipped` 并在 task_summary 附理由——这是合法且被记录的，不同于"偷偷绕过"。
- **没用 spec-keeper 会怎样？** 标准档完全可用，`/sop-close` 检测到 `linked_change_id=null` 就跳过 spec-apply，其余照常。
- **需求很清晰还要 brainstorm 吗？** 不用，直接 `/sop-init`。brainstorm 是门禁不是仪式，模糊才用。

---

## 8. 场景化实践：排查问题 / 小需求 / 生成整体规格

完整生命周期（第 1–3 节）是给"常规及以上 feature"用的。下面三类场景**不要套全流程**，各有更合身的走法。

### 场景 A：排查问题（debugging）

**核心原则：这不是开发流程，不走 FSM；走 `systematic-debugging` 的纪律。**

`systematic-debugging` skill 的 IRON LAW 是"未定位到可复现根因，不得写修复代码"。所以你只要描述 bug，Claude 就该按四阶段走，而不是上来就改：

1. **复现** — 找到稳定复现的最小路径（复现不了就先解决复现，不许凭空猜改）
2. **定位根因** — 逐层缩小到确切那一行/那个状态；区分"症状出现处"和"问题产生处"
3. **最小验证** — 动手修之前，先用最小改动证明"改这个根因确实改变症状"
4. **修复 + 回归测试** — 先写一个会因该 bug 失败的测试（红），再修让它变绿，这条回归测试永久留下

**怎么实践：**
- **快速排查**：直接说 `"排查一下 X 报错/异常"`，让调试纪律接管。修完务必补回归测试（复用 tdd 的"先红"）。不需要 `/sop-init`。
- **bug 在任务过程中被发现**（REVIEW 出 Critical / 实现中踩坑）：已经在 FSM 里了，REVIEW→IMPLEMENTATION 的迭代会处理，修复同样遵循 systematic-debugging，并记一条 `type=fix` 的 changelog CR。
- **线上紧急热修**：可走"热修复档"——`/sop-init` 后把 PLANNING/ARCHITECTURE/TEST_FIRST 标 `skipped`+理由，但 **REVIEW 不可跳**，且事后补回归测试。
- **bug 在陌生/遗留代码里**：先 `/arch-init`（code-archaeologist 三维考古），搞清"为什么这么写、谁依赖它、哪些复杂是必要的"，再动手——避免修一个引发三个。
- 🚩 红旗自检：出现"先试试改这里""加个 try/catch 吞掉""重启应该就好"="你在猜，停"。

> 一句话：**排查 = 先复现+根因，后修复+回归测试；不开 SOP，开调试纪律。**

### 场景 B：小需求（small change）

**核心原则：小 ≠ 没纪律，但**要按规模"减档"，只保留有价值的门禁。**用 `skipped + 理由` 合法减档，不是偷偷绕过。**

按改动大小选择保留哪些环节：

| 改动类型 | brainstorm | spec | PLANNING | ARCHITECTURE | TEST_FIRST | REVIEW |
|----------|:--:|:--:|:--:|:--:|:--:|:--:|
| typo/配置/纯文档 | ✗ | ✗ | skip | skip | skip | 视情况 |
| 小 bug 修复 | ✗ | ✗ | skip | skip | **保留**(回归测试) | **保留** |
| 小 feature（几小时、动逻辑） | 需求清晰则✗ | ✗ | **保留**(轻) | skip 或轻 | **保留**(几个测试) | **保留** |

**怎么实践：**
- **极小改动**（typo/配置）：直接改即可，formatter 会自动格式化；想留痕就 `/sop-init` 后把前几个阶段标 skipped。
- **小 feature/fix**：`/sop-init "小需求描述"` → PLANNING 里 Claude 通常会建议"本任务可跳过 ARCHITECTURE"，你确认；**保留 TEST_FIRST 写一两个测试 + 绿灯门禁 + 一次 /sop-review**——这两个是小改动里性价比最高的护栏，挡住"小改动引大故障"。
- **不要做的**：小需求不必 `/spec-propose`（除非它其实在改一个长期能力/对外接口——那它就不算"小需求"了）。
- 需求清晰时**跳过 brainstorm**，直接 init。

> 一句话：**小需求走标准档的"瘦身版"——砍掉 brainstorm/spec/架构，留住"小测试 + 绿灯 + 一次审查"。**

### 场景 C：生成项目的整体规格文档（brownfield 反向捕获）

**核心原则：这是**反向**用法——不是"打算怎么改"，而是"把系统现在做什么"沉淀成 living spec。用 `/spec-bootstrap`（OpenSpec 式 brownfield，不重写代码）。**

```
/spec-bootstrap --capability=notification        # 强烈建议分区域，一次一块
/spec-bootstrap --from=src/api                   # 或按入口目录
```

**怎么实践（分区域、可迭代）：**
1. **先列能力清单**：不带参数跑一次，让 Claude 按入口点（HTTP 路由 / CLI / 定时任务 / MQ 消费者 / 公开模块）和功能域，**列出候选能力清单给你确认**——别一次性扫全仓库，那样质量差、易臆造。
2. **逐个区域捕获**：确认后用 `--capability=` 逐块生成 `spec/capabilities/<id>/spec.md`，每块含：目的、可判定的行为规格 R 条目（当/则/除非+验收）、接口契约、数据契约、非目标。
3. **核对 `[待确认]`**：Claude 对吃不准的行为会标 `[待确认]` 并附"来源文件"，**绝不臆造填满**。你逐条确认/修正——确认后这份基线才算系统真相。
4. **此后正向演进**：基线建好后，新需求一律走 `/spec-propose`，它的 delta 就以这份基线为对比对象；`/sop-close` 自动 `/spec-apply` 让基线持续跟代码同步。

**两点诚实说明：**
- bootstrap 是 **AI 辅助阅读代码的捕获**，产物是**待核对草稿**，不是即时真相——一定要核对 `[待确认]`。
- 全自动、带调用链证据的提取（单/多项目代码图谱）是规划中的 `atlas` 插件的目标，当前未实现；`/spec-bootstrap` 先满足"快速拿到一份可核对的整体规格基线"。

> 一句话：**整体规格 = `/spec-bootstrap` 分区域反向捕获 → 人工核对 `[待确认]` → 形成真相基线，此后用 /spec-propose 增量演进。**

**补充：代码已经改了、spec 没跟上怎么办？** 用 `/spec-sync` 反向回填——
它读**当前分支相对基线的实际改动**（git diff），推断为行为级 delta，生成一份待评审的 reverse proposal，核对 `[待确认]` 后 `/spec-apply` 即可让 spec 追上代码。典型场景：直接在分支上改了代码没走 propose、实现时超出了原提案范围（`/spec-sync --change-id=<原变更>` 并回原变更）、或紧急热修复后补规格。

```
/spec-sync --base=main            # 用当前分支改动互补 spec（默认产出待评审 delta）
/spec-sync --base=main --apply    # 核对无误后直接落地 living spec
```

### 三场景速记

| 场景 | 入口 | 走什么 | 不走什么 |
|------|------|--------|----------|
| 排查问题 | "排查 X" | systematic-debugging 四阶段 + 回归测试 | FSM 全流程 |
| 小需求 | `/sop-init` | 瘦身标准档（留 TEST_FIRST + 绿灯 + REVIEW） | brainstorm/spec/架构 |
| 整体规格 | `/spec-bootstrap` | 分区域反向捕获 + 核对待确认 | flowsmith 任务流 |
