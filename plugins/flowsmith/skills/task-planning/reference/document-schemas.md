# 文档格式契约（Document Schemas）

所有阶段的输出文档格式在此统一定义。Skill 只负责"生成符合此格式的内容"，
不在 Skill 内部内嵌格式定义。修改格式时只改此文件，所有 Skill 自动对齐。

---

## plan.md 格式

```markdown
# 任务规划
> task_id: {state.task_id}
> phase: PLANNING
> version: {迭代次数}

## 任务描述
{原始需求的精确转述，不做解释，不添加假设}

## 约束与前提
{已知的技术栈、框架版本、不可更改的接口等硬约束}

## 子任务分解
| # | 子任务 | 类型 | 优先级 | 依赖 | 状态 |
|---|--------|------|--------|------|------|
| 1 | {描述} | feature/fix/refactor/test | P0/P1/P2 | - | pending |

## 依赖关系图（文字版）
{用缩进表示并行/串行关系}
串行链: 1 → 3 → 5
可并行: [2, 4] 均依赖 1，互不依赖

## 影响范围分析
- **新增文件**：{列表}
- **修改文件**：{列表，附修改原因}
- **删除文件**：{列表}
- **接口变更**：{内外部接口，附向后兼容性说明}

## 风险矩阵
| 风险 | 概率 | 影响 | 综合评级 | 应对策略 |
|------|------|------|----------|---------|
| {描述} | 高/中/低 | 高/中/低 | 🔴/🟡/🟢 | {策略} |

## 历史教训引用
{引用 .sop/lessons.md 中与本任务相关的条目}
若无相关教训，写"无"

## 复杂度评估
- 工作量：S(<2h) / M(2-8h) / L(8-24h) / XL(>24h)
- 主要技术挑战：{1-3 条}
- 推荐拆分策略：{若为 L/XL，建议如何拆分为多个任务}
```

---

## arch.md 格式

```markdown
# 架构设计
> task_id: {state.task_id}
> phase: ARCHITECTURE
> based_on: .sop/plan.md

## 整体设计思路
{2-4 句话说明核心设计理念，为什么这样设计，权衡了什么}

## 模块结构
{ASCII 目录树，每个文件/目录附 1 行职责注释}

## 模块职责定义
### {ModuleName}
- **单一职责**：{一句话}
- **公开接口**：{函数/类签名，含参数类型和返回类型}
- **内部依赖**：{依赖的其他模块，注明依赖方向}
- **外部依赖**：{第三方库，注明版本}
- **禁止做的事**：{明确边界，防止范围蔓延}

## 数据流
{从用户输入到系统输出的完整路径，用 → 连接节点}
{每个节点注明：转换了什么、产生了什么副作用}

## 关键接口契约
```typescript
// 跨模块边界的接口必须在此声明
interface {InterfaceName} {
  {method}({params}: {Type}): {ReturnType}
}
```

## ADR（架构决策记录）
### ADR-{n}: {决策标题}
- **状态**: 已接受 / 已废弃 / 待审查
- **背景**: {为什么需要做这个决策}
- **考量的方案**:
  - 方案 A（{名称}）: {优点} / {缺点}
  - 方案 B（{名称}）: {优点} / {缺点}
- **决定**: 选择方案 {X}
- **理由**: {具体理由，不是泛泛而谈}
- **代价**: {选择此方案放弃了什么}

## 扩展性考量
{哪些设计决策为未来扩展留有余地，哪些是有意的简化}

## Out of Scope（本次不做）
{明确边界，防止实现阶段范围蔓延}
```

---

## changelog.md 格式

> 由 implementation-guide skill 在 IMPLEMENTATION 阶段维护，每完成一个逻辑变更批次追加一条。
> 通过 /sop-diff 命令查看带备注的 diff。

### 文件头

```markdown
# 变更日志（Change Log）

> task_id: {state.task_id}
> task: {state.task_summary}
> base_branch: {state.git_context.base_branch}
> head_branch: {state.git_context.head_branch}
> worktree: {state.git_context.worktree_path}
> 由 implementation-guide 中"变更日志纪律"在实施阶段维护
> 通过 /sop-diff 查看带备注的 diff

---
```

### 单条变更记录（CR-N）

```markdown
## CR-{n} — {一句话标题}

- timestamp: {ISO8601}
- type: create | modify | delete | refactor | fix
- subtask: {plan.md 中子任务编号，如 1.2；无则填 -}
- adr: {arch.md 中 ADR 编号，如 ADR-2；无则填 -}
- fixes_issue: {C-x（仅 iteration > 1 修复 Critical 时填）}
- backfilled: {true，仅由 /sop-diff --backfill 生成时填；正常实施写的 CR 不需要此字段}
- source_commits: {abc1234, def5678（仅 backfilled CR 用于追溯来源 commit）}
- files:
  - {path1} ({新建 / 修改 / 删除})
  - {path2} ({新建 / 修改 / 删除})

### 解决什么问题
{用户视角或系统视角的问题描述。不是"我加了一个函数"，而是"原本 X 场景下会 Y，需要 Z"。}

### 为什么这么改
{方案选择理由。如果有 ADR 已经讲过，这里只点出 ADR 编号 + 落地的关键决策；
不重复抄 ADR 全文。如果是 ADR 之外的小决策，简述权衡。
回补的 CR 在用户补全前会标记 [需用户补充]。}

### 关联变更
- 依赖：{CR-x, ...，无则写"无"}
- 后续：{CR-y, ...，可在后续 CR 写出后回填，初次可留空}

---
```

### 完整示例

```markdown
# 变更日志（Change Log）

> task_id: a3b9c2f1
> task: 实现用户通知系统：站内信 + 邮件，可配置偏好
> base_branch: main
> head_branch: feat/notification
> worktree: /Users/dev/repos/buddy-feat-notification
> 由 implementation-guide 中"变更日志纪律"在实施阶段维护
> 通过 /sop-diff 查看带备注的 diff

---

## CR-1 — 抽离通知抽象层 NotificationChannel

- timestamp: 2026-05-10T10:00:12Z
- type: create
- subtask: 1.1
- adr: ADR-1
- files:
  - src/notification/channel.ts (新建)
  - src/notification/types.ts (新建)

### 解决什么问题
站内信和邮件两个通道在数据结构、错误模型、重试策略上差异很大。如果直接在业务层 if/else，
后续加短信、企业微信会反复改业务代码。

### 为什么这么改
按 ADR-1 决定，定义 NotificationChannel 接口 + 通道注册表。业务层只调 channel.send()，
不感知具体实现。代价是当前只有两个通道时多一层间接，但符合"识别变化的维度"原则
（通道未来必然增加）。

### 关联变更
- 依赖：无（这是基础抽象）
- 后续：CR-2、CR-3 分别实现两个通道

---

## CR-2 — 实现邮件通道（基于 nodemailer）

- timestamp: 2026-05-10T10:42:55Z
- type: create
- subtask: 1.2
- adr: ADR-2
- files:
  - src/notification/email.ts (新建)
  - src/notification/index.ts (修改)

### 解决什么问题
邮件通道之前没有任何代码，需要从零搭建 SMTP 连接 + 发送 + 重试。

### 为什么这么改
ADR-2 选定 nodemailer 而非自建。把重试与日志收敛在 EmailChannel 内部，对外只暴露
send(payload)。SMTP 配置走环境变量，不写死。

### 关联变更
- 依赖：CR-1（实现 NotificationChannel 接口）
- 后续：-
```

---

## review.md 格式

```markdown
# 审查报告
> task_id: {state.task_id}
> phase: REVIEW
> iteration: {state.iteration}
> timestamp: {ISO8601}

## 审查摘要
| 审查维度 | 负责 Agent | 结论 |
|---------|-----------|------|
| 架构符合性 | arch-reviewer | 🟢/🟡/🔴 |
| 安全性 | security-reviewer | 🟢/🟡/🔴 |
| 逻辑正确性 | logic-reviewer | 🟢/🟡/🔴 |

**总体评级**: 🟢 通过 / 🟡 有条件通过 / 🔴 需返工

## 问题列表
{由各 reviewer subagent 合并写入}

## 与上次审查的对比（iteration > 1 时填写）
| 上次问题 ID | 上次状态 | 本次状态 | 是否真正修复 | 对应修复 CR |
|-----------|---------|---------|------------|------------|

## 审查结论
{2-3 句综合判断}
```
