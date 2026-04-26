# 考古报告格式契约（Report Schemas）

定义所有考古文档的统一格式，确保 agent 输出可被命令汇总，被 flowsmith 引用。

---

## history.md 格式（history-archaeologist 输出）

```markdown
# 历史考古报告
> archaeology_id: {id}
> target: {target.path}
> agent: history-archaeologist
> generated_at: {ISO8601}

## 概览
- 文件首次提交：{commit hash} | {date} | {author}
- 累计 commit 数：{N}
- 涉及作者数：{M}
- 最近修改：{date}（{days_ago} 天前）
- 修改频率分布：🔥 热点 / 🌡️ 温热 / ❄️ 沉睡

## 关键时间线（按重要性排序，最多 10 条）

### {date} — {one-line commit message}
- **commit**：`{hash}`
- **作者**：{author}
- **变更类型**：架构重构 | 功能新增 | bug 修复 | 性能优化 | 安全修复 | 重命名/移动
- **影响行数**：+{added} / -{removed}
- **设计意图**（从 commit message + 实际改动反推）：
  {2-3 句话描述这次提交的真实意图，包括 commit message 没明说的}
- **遗留至今的痕迹**：
  {这次提交留下了什么仍然影响今天的代码？哪些设计决策延续到现在？}

## 修改热点
列出本次考古目标内变更最频繁的代码段（top 5）：
| 代码段 | 修改次数 | 最后修改 | 备注 |
|-------|---------|---------|------|
| `findById` 方法 | 12 次 | 2025-08-12 | 反复优化查询性能 |

## 沉睡区
列出超过 18 个月未变更的代码段：
- `validateLegacyToken()` — 自 2023-01 后未动，可能是历史包袱

## 作者贡献分布
| 作者 | commit 数 | 累计行数 | 主要贡献时段 | 是否仍活跃 |
|------|----------|---------|------------|-----------|
| 张三 | 18 | +850/-320 | 2024-01 ~ 2024-08 | ❌ 已离职 |

## 关键发现（必填）
{2-3 条最值得注意的历史事实，例如：
- 该模块 90% 的复杂度来自一次匆忙的 hotfix（commit abc123）
- 原作者已离职，无人完全理解当初的设计动机
- 6 个月前刚做过一轮重构，再次重构需要谨慎
}
```

---

## blast-radius.md 格式（dependency-archaeologist 输出）

```markdown
# 影响范围考古报告
> archaeology_id: {id}
> target: {target.path}
> agent: dependency-archaeologist
> generated_at: {ISO8601}

## 静态调用方分析

### 直接调用方（一跳依赖）
| 调用方文件 | 调用位置 | 调用方式 | 调用方所属模块 |
|----------|---------|---------|--------------|
| src/order/OrderService.java:42 | `userService.findById(id)` | 同步方法调用 | order |

### 间接调用方（二跳依赖，仅核心路径）
{展示从直接调用方延伸出去的调用链，最多 3 层}

## 隐式依赖（容易被遗漏）

以下依赖**不会被 IDE 重构工具检测到**，是重构事故的高发区：

### 反射调用
- {文件:行号}：`Class.forName("...UserService")` 字符串引用

### 序列化协议
- {文件:行号}：通过 JSON/Protobuf 等被外部消费的字段
- 影响：字段重命名会破坏外部协议

### 配置文件引用
- {文件:行号}：在 application.yml / spring xml 中被 bean 名称引用

### 字符串拼接构造
- {文件:行号}：`"com.x.y." + className` 动态构造

### 测试 Mock 中的隐式契约
- {文件:行号}：测试中 mock 了某个方法的特定行为，反映了调用方的行为假设

## 跨模块边界分析
- 是否暴露为外部 API？（HTTP / RPC / SDK）{是/否}
- 是否被其他 git 仓库依赖？{是/否，列出已知依赖方}
- 修改后是否需要发版本？{是/否，向后兼容性评估}

## 影响半径量化
| 维度 | 数值 | 风险评级 |
|------|------|---------|
| 直接调用方 | {N} | 🟢/🟡/🔴 |
| 间接调用方（2 跳）| {N} | 🟢/🟡/🔴 |
| 隐式依赖项 | {N} | 🟢/🟡/🔴 |
| 跨模块依赖数 | {N} | 🟢/🟡/🔴 |
| **综合 Blast Radius** | - | 🟢 低 / 🟡 中 / 🔴 高 / ⛔ 极高 |

## 关键发现（必填）
{2-3 条最高风险的依赖项及其原因}
```

---

## intent.md 格式（intent-archaeologist 输出）

```markdown
# 设计意图考古报告
> archaeology_id: {id}
> target: {target.path}
> agent: intent-archaeologist
> generated_at: {ISO8601}

## 整体设计意图推断

### 这段代码当初要解决什么问题？
{综合 commit message、注释、代码结构反推。如果证据不足，明确标注"推测"}

### 当时的技术约束是什么？
{例如：当时还没有 Java 17 / 没有该框架的 X 功能 / 团队规模较小等}

### 与同时期类似代码的对比
{如果项目内有功能相似的其他代码，对比说明本代码的特殊之处}

## "看似奇怪"的设计逐项分析

对每一处不符合常规的设计，给出三种解释假设并标注可能性：

### 现象 1：{描述}
位置：{文件:行号}

**假设 A — 历史包袱（可清理）**：{描述}
- 证据：{commit/comment/issue 引用}
- 可能性：高/中/低

**假设 B — 必要的防御（不能动）**：{描述}
- 证据：{commit/comment/issue 引用}
- 可能性：高/中/低

**假设 C — 性能/兼容性优化（需保留）**：{描述}
- 证据：{commit/comment/issue 引用}
- 可能性：高/中/低

**🎯 最可能的解释**：假设 {X}（{置信度}）
**🛠️ 处理建议**：{是否可重构、需要谁评审、需要补什么测试}

## 必要复杂性 vs 意外复杂性

| 复杂点 | 类别 | 是否应保留 |
|-------|------|-----------|
| 双重 null 检查 | 必要（防御 NPE 历史 bug）| ✅ 保留 |
| 三层 try-catch 嵌套 | 意外（写得急的产物）| ❌ 可简化 |

## 与项目中类似模式的关联
- 同样的"缓存预热 + 异步刷新"模式在 {另一文件} 也有出现
- 暗示这是项目级的设计模式，重构时应统一考虑

## 关键发现（必填）
{2-3 条最关键的意图洞察，特别是"看起来可以删但不能删"的部分}
```

---

## report.md 格式（最终汇总报告）

```markdown
# 考古综合报告
> archaeology_id: {id}
> target: {target.path}
> generated_at: {ISO8601}

## 执行摘要（Executive Summary）
{3-5 句话回答："这段代码能不能重构？怎么重构最安全？"}

## 风险评级
- **Risk Level**: 🟢 low | 🟡 medium | 🔴 high | ⛔ critical
- **Blast Radius**: {dependency-archaeologist 给出的等级}
- **Knowledge Loss Risk**: 🟢 低 | 🟡 中 | 🔴 高
  （原作者是否离职、文档是否完整、是否有测试覆盖）

## 推荐策略
- **Strategy**: `safe-refactor` | `staged-refactor` | `parallel-rewrite` | `freeze-and-document` | `escalate`

### 选择理由
{2-3 句话解释为什么选这个策略}

### 不可跨越的红线
{重构时必须遵守的硬约束，违反则后果严重}

## 关键发现汇总

### 来自 history-archaeologist
{1-2 条最关键的历史事实}

### 来自 dependency-archaeologist
{1-2 条最高风险的依赖项}

### 来自 intent-archaeologist
{1-2 条最关键的意图洞察}

## 重构前置条件清单（Pre-Refactor Checklist）
- [ ] {如：补充 X 模块的单测，覆盖率达到 70%+}
- [ ] {如：与 Y 团队确认 API 兼容性方案}
- [ ] {如：在 staging 环境复现 commit abc123 修复的 bug，避免回归}

## 推荐执行路径

### 若选择 safe-refactor / staged-refactor
建议触发 flowsmith：
```
/sop-init 重构 {target.path}：基于考古结论 {archaeology_id}
```
flowsmith 会读取本报告并将"前置条件清单"和"红线"写入 plan.md 的"约束与前提"。

### 若选择 freeze-and-document
建议执行：
- 不修改代码
- 将本报告精简版作为 `{target.path}` 的同名 README 提交：`{target.path.dirname}/ARCHAEOLOGY-{filename}.md`
- 在 `.sop/lessons.md` 追加"待来日重构"标记

### 若选择 escalate
说明涉及架构层面的决策，建议：
- 召开架构评审，本报告作为评审材料
- 评审通过后再启动 flowsmith 工作流

## 引用文件
- 历史考古：`.archaeology/history.md`
- 影响分析：`.archaeology/blast-radius.md`
- 意图推断：`.archaeology/intent.md`
```
