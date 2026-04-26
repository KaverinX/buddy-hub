# co-review 报告格式契约

定义所有报告文档的统一格式，确保 agent 输出可被 merge-strategy skill 汇总，
并保证私聊反馈、评分报告等可选输出符合"不针对个人"或"严格隔离"的设计原则。

---

## contributions.md（contribution-analyzer 输出）

```markdown
# 贡献画像与功能边界
> review_id: {id}
> branch: {branch} → {base}
> agent: contribution-analyzer
> generated_at: {ISO8601}

## 团队贡献概览

| 开发者 | Commits | LOC (+) | LOC (-) | 改动文件数 | 主要模块 | 第一次提交 | 最后提交 |
|-------|---------|---------|---------|-----------|---------|-----------|---------|
| Alice | 12 | 854 | 142 | 18 | auth/ | 2026-04-01 | 2026-04-25 |

## 模块分布矩阵

| 模块 | Alice | Bob | Carol |
|------|-------|-----|-------|
| auth/ | 18 文件 | 0 | 0 |
| notification/ | 0 | 11 文件 | 0 |
| shared/utils/ | 0 | 0 | 7 文件 |
| types/user.ts | 3 改动 | 0 | 4 改动 |  ← 多人交集

## 子任务对应（若 .sop/plan.md 存在）

将 plan.md 中的子任务映射到实际 commits：

| plan.md 子任务 | 实际承担者 | 对应 commits | 状态 |
|---------------|-----------|-------------|------|
| 1. 用户认证模块 | Alice | a3f8c1d, b8e2f4a, ... | ✅ 完成 |
| 2. 邮件发送服务 | Bob | (未匹配到 commits) | ❌ 未启动 |
| 3. 通知偏好接口 | Bob | c1d2e3f | 🟡 进行中 |

**未匹配的子任务**：
{列出 plan.md 中有但 commits 中找不到对应实现的子任务}

**计划外的工作**：
{列出 commits 中实现了但 plan.md 中没有定义的功能}

## 边界识别（若 .sop/arch.md 存在）

基于 arch.md 的模块职责定义，识别越界提交：

### 越界标记
| 开发者 | 越界文件 | 应由谁负责 | 提交说明 |
|-------|---------|-----------|---------|
| Alice | src/notification/router.ts | Bob | "fix typing issue while passing through" |

⚠️ **警告**：越界提交不代表错误。以下是合理越界的特征：
- commit 信息说明了越界原因
- 改动是修复型（hotfix），不是功能新增
- 变更小（< 20 行）

不合理越界的特征：
- 大量改动其他人负责的模块（>100 行）
- 没有 commit 信息说明
- 改动了他人的核心逻辑

## 代码所有权地图

基于 git blame 分析，本分支改动的每个文件的"主要维护者"：

| 文件 | 主要维护者 | 本次改动者 | 关系 |
|------|-----------|-----------|------|
| src/auth/UserService.java | Alice (历史 80% 行) | Alice | ✅ 本人维护 |
| src/notification/router.ts | Bob (历史 65% 行) | Alice | ⚠️ 跨人维护 |

**信息性提示**：跨人维护本身不是问题，但建议被改动文件的主要维护者 review。

## 关键发现（必填）
{2-3 条最值得团队关注的事实，例如：
- 子任务 #2 "邮件发送服务"完全未启动，需要确认是否还在范围内
- types/user.ts 被 Alice 和 Carol 同时修改，潜在合并冲突
- Bob 的工作集中在 notification/，与 plan.md 完全一致
}
```

---

## completion.md（completion-analyzer 输出）

```markdown
# 完成度评估
> review_id: {id}
> agent: completion-analyzer
> generated_at: {ISO8601}

## 团队整体完成度
- 总 TODO/FIXME 标记：{N} 处
- 空函数体：{M} 处
- 注释掉的代码块：{K} 处
- 调试遗留（console.log 等）：{J} 处
- 测试覆盖率（仅本次改动文件）：{X}%

## 每人完成度信号

| 开发者 | 完成度 | TODO | 空实现 | 调试遗留 | 测试覆盖 |
|-------|-------|------|-------|---------|---------|
| Alice | 🟢 高 | 0 | 0 | 0 | 4/4 文件有测试 |
| Bob | 🟡 中 | 5 | 2 | 1 | 2/8 文件有测试 |

**完成度等级判定规则**：
- 🟢 高：无 TODO + 测试覆盖 ≥ 70% + 无调试遗留
- 🟡 中：有少量 TODO + 测试覆盖 30-70%
- 🔴 低：大量 TODO + 测试覆盖 < 30% 或有 critical 调试遗留

## 详细完成度信号清单（按开发者分组）

### Alice
**TODO 标记**：无
**空实现**：无
**调试遗留**：无
**测试同步性**：所有新增源文件都有对应 *.test.ts

### Bob
**TODO 标记**（5 处）：
- `src/notification/email.ts:34` — `// TODO: implement retry mechanism`
- `src/notification/email.ts:87` — `// FIXME: handle rate limit edge case`
- ...

**空实现**（2 处）：
- `src/notification/email.ts:142` — 函数 `sendBatch` 仅有 `throw new Error("not implemented")`
- ...

**调试遗留**（1 处）：
- `src/notification/router.ts:23` — `console.log(payload)` 未删除

**测试同步性**：8 个新文件中只有 2 个有对应测试

## PR 自述偏差分析（仅当 gh CLI 可用时）

对比每个开发者的 PR 描述与实际改动：

### Bob (PR #42)
**PR 描述声称完成**：
- ✅ 站内信发送
- ✅ 邮件发送（支持重试）
- ✅ 通知偏好配置

**实际代码状态**：
- ✅ 站内信发送：已完成，有测试
- ⚠️ 邮件发送：基础实现完成，但**重试机制标记为 TODO 未实现**
- ✅ 通知偏好配置：已完成

**自述偏差**：1 处（重试机制）

## 关键发现（必填）
{2-3 条最值得团队关注的完成度问题}
```

---

## risks.md（collab-risk-analyzer 输出）

```markdown
# 协作风险检测
> review_id: {id}
> agent: collab-risk-analyzer
> generated_at: {ISO8601}

## 风险评级摘要
| 风险类型 | 数量 | 最高等级 |
|---------|------|---------|
| 同文件多人改动 | {N} | 🟡 |
| 接口签名不一致 | {M} | 🔴 |
| 违反考古红线 | {K} | ⛔ |
| 重蹈历史覆辙 | {J} | 🟡 |

## 1. 同文件多人改动

### types/user.ts
- 修改者：Alice (3 次)、Carol (4 次)
- 修改行交集：第 12-18 行（同时被两人修改）
- 时间顺序：Alice 先修改（commit a3f8c1d），Carol 后修改（commit b8e2f4a）
- **风险等级**：🟡 中
- **建议**：合并前需要 Alice 和 Carol 共同确认无逻辑冲突

## 2. 接口签名不一致

### UserRepository.findById
- 在 commit a3f8c1d (Alice) 中：`findById(id: string)` 改为 `findById(id: string, options?: FindOptions)`
- 但 commit b8e2f4a (Bob) 仍在用旧签名调用：`userRepo.findById(userId)`
- 实际可用（因为 options 可选），但可能是疏忽
- **风险等级**：🔴 高
- **建议**：要求 Bob 显式确认是否需要使用新参数

## 3. 违反考古红线（仅当 .archaeology/report.md 存在）

读取 .archaeology/report.md 中的"不可跨越的红线"，逐条对照：

### ⛔ 违反红线 [R-1]
- 红线内容："字段 userToken 不可重命名（被 mobile-app v2.x 客户端硬编码引用）"
- 违反者：Bob（commit c1d2e3f）
- 违反内容：将 `userToken` 重命名为 `authToken`
- 文件位置：src/auth/UserService.java:42
- **风险等级**：⛔ 极高，必须修复才能合并
- **建议**：还原字段名或新增 `authToken` 作为别名保留 `userToken`

## 4. 重蹈历史覆辙（仅当 .sop/lessons.md 存在）

读取 lessons.md 中的"踩坑记录"，在本次 diff 中搜索相同模式：

### 🟡 重蹈覆辙 [L-1]
- 历史教训：「IDOR 检查清单」（任务 b8e2f4a1）
- 教训内容：URL 参数中的 userId 必须验证 req.user.id === params.userId
- 本次发现：Bob 在 src/notification/controller.ts:23 添加了新接口 GET /notifications/:userId，
  但**未做 IDOR 鉴权检查**
- **风险等级**：🟡 中（与历史教训完全相同）
- **建议**：添加 IDOR 检查，或参考历史 commit 的修复方式

## 关键发现（必填）
{2-3 条最严重的协作风险}
```

---

## report.md（merge-strategy skill 综合输出，主报告）

```markdown
# 团队协作审查报告
> review_id: {id}
> branch: {branch} → {base}
> generated_at: {ISO8601}
> mode: {pr|commit}

## 摘要
- 涉及 {N} 位开发者，{M} 个 PR/commit，{K} 个文件改动
- 团队健康度：{🟢 healthy | 🟡 warning | 🔴 unhealthy | ⛔ critical}
- 推荐合并策略：{merge-now-all | staged-merge | coordinate-first | block-and-discuss | escalate}

## 团队贡献概览
{从 contributions.md 摘抄概览表}

## 完成度评估
{从 completion.md 摘抄团队整体完成度 + 每人简表}

## 协作风险
{从 risks.md 摘抄风险摘要表 + 最高级别的 3 条具体风险}

## 合并策略

### 推荐策略：{strategy}

### 选择理由
{2-3 句解释为什么选这个策略}

### 推荐合并顺序
{基于依赖关系拓扑排序，列出每个 PR/分支的合并顺序}
1. Carol 的工具函数（独立、完成度高）
2. Alice 的认证改动（被其他模块依赖）
3. Bob 的通知系统（依赖 Alice 的接口）

### 合并前检查清单
{对应 strategy 的可执行检查项，每项必须可以打 ☑ }
- [ ] {如：Bob 修复 IDOR 漏洞 [R-1] 后再合并}
- [ ] {如：Alice 和 Carol 在 types/user.ts 上的改动需要共同确认}
- [ ] {如：所有 TODO 标记需在 issue 跟踪}

## 个人行动建议（针对每位开发者）

> ⚠️ 此章节是团队级报告的一部分。仅描述客观事实和具体行动项。
> 若需要更详细的私聊反馈，请使用 --with-private-feedback 参数。

### Alice — 建议
- 工作集中在 auth/ 模块，与 plan.md 分工完全一致 ✅
- 接口签名变更（UserRepository.findById）已通知到 Bob，可继续推进
- **行动项**：
  - 与 Carol 协调 types/user.ts 第 12-18 行的并发修改

### Bob — 建议
- 通知系统的整体进度符合 plan.md
- 邮件发送的重试机制 PR 描述声称完成但实际未实现
- **行动项**：
  - 修复 IDOR 漏洞 [R-1]（违反考古红线，最高优先级）
  - 完成 src/notification/email.ts 中的 5 处 TODO
  - 删除 console.log 调试遗留
  - 为新增的 6 个文件补充测试

### Carol — 建议
- 工具函数模块独立、完成度高，可优先合并
- **行动项**：
  - 与 Alice 协调 types/user.ts 第 12-18 行的并发修改

## 引用文件
- 贡献画像：`.team-scope/contributions.md`
- 完成度评估：`.team-scope/completion.md`
- 协作风险：`.team-scope/risks.md`
{若 with_scores：'- 维度评分：`.team-scope/scores.md`'}
{若 with_private_feedback：'- 私聊反馈：`.team-scope/private/<author>.md` (每人独立文件)'}
```

---

## scores.md（仅 --with-scores 时生成）

```markdown
# 维度化评分
> ⚠️ 本评分仅供团队回顾参考，不应用于个人绩效考核。
> ⚠️ 评分由 git 数据自动生成，存在局限性。

## 评分维度说明
| 维度 | 含义 | 数据来源 |
|------|------|---------|
| 完成度 | 代码是否完整可交付 | TODO 数 + 测试覆盖 + 调试遗留 |
| 协作健康 | 是否引入冲突或破坏接口 | 同文件冲突 + 接口签名变更通知 |
| 边界遵守 | 是否在 arch.md 定义的职责范围内 | 越界提交比例 |
| 经验吸收 | 是否避免了 lessons.md 中的已知坑 | 重蹈覆辙数 |

## 每人维度评分

| 开发者 | 完成度 | 协作健康 | 边界遵守 | 经验吸收 |
|-------|-------|---------|---------|---------|
| Alice | 🟢 高 | 🟢 高 | 🟢 高 | 🟢 高 |
| Bob   | 🟡 中 | 🟡 中 | 🟢 高 | 🔴 低 |
| Carol | 🟢 高 | 🟢 高 | 🟢 高 | 🟢 高 |

## 评分依据（必填，每项打分都要附证据）

### Alice
- **完成度 🟢 高**：4/4 改动文件有测试 + 0 TODO + 0 调试遗留
- **协作健康 🟢 高**：接口变更通知了所有调用方
- **边界遵守 🟢 高**：100% 改动在 auth/ 模块内（plan.md 定义的范围）
- **经验吸收 🟢 高**：避免了 lessons.md 中的所有已知坑

### Bob
- **完成度 🟡 中**：2/8 改动文件有测试 + 5 TODO + 1 处调试遗留
- **协作健康 🟡 中**：未确认 UserRepository.findById 新签名是否影响调用
- **边界遵守 🟢 高**：100% 改动在 notification/ 模块内
- **经验吸收 🔴 低**：未对新增的 IDOR-prone 接口做鉴权检查（lessons.md 中明确记录的坑）

### Carol
（类似格式）

## 评分局限性声明
- 本评分仅基于 git 数据，无法反映：
  - 协作沟通质量（口头讨论、远程会议中的贡献）
  - 设计决策的合理性
  - 代码评审中给出的有价值反馈
  - 跨任务的知识传承
- 评分应作为团队回顾的**参考起点**，而不是评价个人的依据
```

---

## private/<author>.md（仅 --with-private-feedback 时生成）

每个开发者一份独立文件，**严格隔离，不包含其他人对比信息**。

```markdown
# 给 {author_name} 的私聊反馈
> review_id: {id}
> branch: {branch}
> generated_at: {ISO8601}

> ⚠️ 本文件由 git 数据自动生成，仅作为个人参考。
> ⚠️ 文件不应在团队群组公开传播。
> ⚠️ 反馈以中立 + 建设性为基调，不代表对你工作的全面评价。

---

## 你在本次分支的贡献概况
- Commits：{N} 个
- 代码改动：+{added}/-{removed} 行，{files} 个文件
- 主要模块：{modules}
- 时间跨度：{first_commit_date} ~ {last_commit_date}

## 做得到位的地方

> 描述客观事实，不做煽动性表扬。

- {如：你的工作集中在 auth/ 模块，与 plan.md 的分工完全一致，没有越界提交}
- {如：你修改的所有源文件都有对应的测试文件}
- {如：你在引入 UserRepository.findById 新签名时，主动通知了所有调用方}

## 可以改进的地方

> 仅列出基于客观证据的具体行动项，不评判态度。

- {如：在 src/notification/email.ts 中有 5 处 TODO 标记需要解决}
  - 具体位置：{逐条列出文件:行号}
  - 建议：在合并前完成或转化为追踪 issue

- {如：commit c1d2e3f 中将 `userToken` 重命名为 `authToken`}
  - 风险：根据 .archaeology/report.md 中的红线 [R-1]，该字段被 mobile-app v2.x 硬编码引用
  - 建议：还原字段名，或新增 `authToken` 作为别名同时保留 `userToken`

- {如：新增的 GET /notifications/:userId 接口未做 IDOR 鉴权检查}
  - 历史背景：此问题在 .sop/lessons.md 任务 b8e2f4a1 中已被记录
  - 建议：参考历史修复方式，添加 `req.user.id === params.userId` 检查

## 与他人的协调点

> 仅描述需要协调的事实，不涉及他人评价。

- types/user.ts 第 12-18 行：你和另一位开发者都修改了这个范围
  - 建议：合并前与对方共同确认无逻辑冲突

## 历史经验参考

{从 .sop/lessons.md 中筛选与你本次工作相关的经验，作为 FYI}

- 「IDOR 检查清单」(任务 b8e2f4a1) — 与你本次的 controller 改动相关
- {其他相关经验}

---

> 本反馈基于 git 数据自动生成，不代表对你工作的全面评价。
> 如有疑问请与团队 lead 当面讨论。
> 本文件不应在团队群组公开传播。
```
