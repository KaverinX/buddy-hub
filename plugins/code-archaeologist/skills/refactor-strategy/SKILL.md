---
name: refactor-strategy
description: 重构策略生成器。综合三个考古员（history/dependency/intent）的输出，应用决策矩阵生成最终的重构推荐策略与风险评级，写入 .archaeology/report.md。由 /arch-report 命令触发，不应单独使用。
---

# 重构策略生成（refactor-strategy）

## 前置读取

按顺序读取：
1. `${CLAUDE_PLUGIN_ROOT}/schemas/archaeology-schema.md` — 状态机规则
2. `${CLAUDE_PLUGIN_ROOT}/schemas/report-schemas.md` — `report.md` 格式
3. `reference/decision-matrix.md` — 风险评级与策略推荐的决策矩阵
4. `.archaeology/state.json` — 当前考古上下文
5. `.archaeology/history.md` — 历史考古结论
6. `.archaeology/blast-radius.md` — 影响范围结论
7. `.archaeology/intent.md` — 意图考古结论

## 执行指令

### Step 1 — 三维度信号提取

从三份考古报告中各自提取关键信号：

**从 history.md 提取**：
- 修改频率（高频/中频/低频）
- 原作者活跃度（活跃/不活跃/已离职）
- 最近一次大改距今时长
- 是否有未解决的历史 bug 痕迹（多次反复修复同一处）

**从 blast-radius.md 提取**：
- 综合 Blast Radius 等级
- 隐式依赖数量
- 是否暴露为外部 API
- 跨模块依赖数量

**从 intent.md 提取**：
- 是否存在"看似可删但不能删"的设计点
- 必要复杂性 vs 意外复杂性的比例
- 是否存在项目级模式（影响多处代码）
- 证据不足的设计决策数量

### Step 2 — 风险评级（应用决策矩阵）

依据 `reference/decision-matrix.md` 中的规则计算 Risk Level。

简化版规则（详见 reference 文件）：
- **Critical**：暴露外部 API + 原作者已离职 + 序列化字段被外部消费
- **High**：Blast Radius 高 OR 多个证据不足的"奇怪设计"
- **Medium**：Blast Radius 中 OR 有项目级模式关联
- **Low**：Blast Radius 低 + 意图清晰 + 历史稳定

**Knowledge Loss Risk** 单独评估：
- 高：原作者离职 + 无文档 + 测试覆盖低
- 中：满足上述 1-2 项
- 低：原作者活跃 + 有文档/测试

### Step 3 — 策略推荐（应用决策矩阵）

依据 risk_level + intent + 其他信号，从 5 个策略中选一个：

| 情境 | 推荐策略 |
|------|---------|
| Risk = Low + intent ∈ {refactor, extract, rename} | `safe-refactor` |
| Risk = Medium + intent ∈ {refactor, extract} | `staged-refactor` |
| Risk = High + 有外部 API 暴露 | `parallel-rewrite` |
| Risk = High + intent = understand + 改造收益不明 | `freeze-and-document` |
| Risk = Critical | `escalate` |
| 任何 risk + 大量"看似可删但不能删"的设计 | 至少 `staged-refactor`，倾向 `freeze-and-document` |

**重要**：策略推荐不是机械应用规则，要结合三份报告的"关键发现"做综合判断。
若决策矩阵给出 A 但综合判断倾向 B，必须在"选择理由"中说明为什么覆盖了规则。

### Step 4 — 生成"不可跨越的红线"

从三份报告的"关键发现"中提炼必须遵守的硬约束。
红线特征：违反则会引入回归 bug、破坏外部协议、丢失关键功能。

红线表达必须**具体可验证**，不接受"小心处理"这种模糊表述。

正例：
- "重构后 `findById` 必须保留对 null 入参的容错处理（commit abc123 修复过的 NPE 问题）"
- "字段 `userToken` 不可重命名（被 mobile-app v2.x 客户端硬编码引用）"

反例：
- "需要小心处理边界情况"（不可验证）
- "保留原有逻辑"（太宽泛）

### Step 5 — 生成"重构前置条件清单"

每条前置条件必须是：
- **可执行**（如 "添加单元测试" 不行，"添加覆盖 findById 边界条件的单元测试，覆盖率 ≥ 70%" 可以）
- **可检查**（完成与否能客观判断）
- **必要**（不是"最好做"，而是"不做就有重大风险"）

### Step 6 — 生成"推荐执行路径"

根据 strategy，给出具体的下一步命令：

| Strategy | 执行路径 |
|----------|---------|
| `safe-refactor` | "执行 `/sop-init 重构 {target}：基于考古结论 {id}` 启动 flowsmith" |
| `staged-refactor` | "建议拆分为多个 flowsmith 任务，每个任务覆盖一个安全的重构阶段" |
| `parallel-rewrite` | "建立新代码与旧代码的并行实现，通过 feature flag 灰度切换。建议先执行 `/sop-init` 规划新代码的整体结构" |
| `freeze-and-document` | "不修改代码。将本报告精简版作为 `{target.dirname}/ARCHAEOLOGY-{filename}.md` 提交。在 .sop/lessons.md 标记'待来日重构'" |
| `escalate` | "将 .archaeology/report.md 作为架构评审材料提交。评审通过后再启动 flowsmith" |

### Step 7 — 写入 report.md

按 `report-schemas.md` 中 `report.md` 格式生成完整报告，写入 `.archaeology/report.md`。

**质量要求**：
- 执行摘要 3-5 句话，必须直接回答"能不能重构？怎么重构最安全？"
- 风险评级必须有数值或证据支撑（不能只说"高"）
- 推荐策略必须给"选择理由"
- 红线和前置条件必须具体可验证
- 与三份子报告的关键发现一致（不矛盾，不遗漏）

### Step 8 — 不修改 state.json

state.json 的更新由调用方（/arch-report 命令）负责，本 skill 只负责生成报告。

## 重要约束

- 不修改任何源代码
- 不直接调用 flowsmith（那是 /arch-handoff 的职责）
- 推荐策略要果断，不要给出"建议你自己判断"这种推卸责任的结论
- 但若证据真的不足，明确说"证据不足，建议先做 X 补充信息"
