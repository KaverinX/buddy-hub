# 决策矩阵：风险评级与策略推荐

供 `refactor-strategy` skill 参考。所有规则必须在 report.md 的"选择理由"中可被引用。

---

## 一、风险评级矩阵

每个维度独立评分，最终取最高项。

### 维度 1：影响半径（来自 dependency-archaeologist）

| Blast Radius | 评分 |
|-------------|------|
| 🟢 低（直接调用 ≤ 5 + 无隐式依赖）| Low |
| 🟡 中（直接调用 6-20 OR 有少量隐式依赖）| Medium |
| 🔴 高（直接调用 > 20 OR 序列化字段被外部消费）| High |
| ⛔ 极高（暴露为外部 API + 跨仓库依赖）| Critical |

### 维度 2：知识丢失风险（来自 history-archaeologist）

| 情况 | 评分 |
|------|------|
| 原作者活跃 + 文档完整 + 测试覆盖好 | Low |
| 原作者活跃但缺一项 | Low |
| 原作者不活跃 OR 缺多项 | Medium |
| 原作者已离职 + 文档缺失 | High |
| 原作者已离职 + 文档缺失 + 测试缺失 | Critical |

### 维度 3：意图清晰度（来自 intent-archaeologist）

| 情况 | 评分 |
|------|------|
| 所有"奇怪设计"都有明确假设支撑 | Low |
| 大部分清晰，1-2 处证据不足 | Medium |
| 多处"看似可删但不能删"的设计 | High |
| 关键设计完全无法解释意图 | Critical |

### 维度 4：变更频率（来自 history-archaeologist）

| 情况 | 评分 |
|------|------|
| 长期稳定（最近 6 个月 ≤ 2 次修改）| Low |
| 适中（最近 6 个月 3-10 次）| Medium |
| 高频（最近 6 个月 > 10 次，反映需求不稳定）| High |
| 高频反复修复同一处（暗示设计有根本问题）| Critical |

### 综合评级规则

```
Final Risk = max(各维度评分)
```

**例外**：若维度 1 = Critical（外部 API 暴露），最终评级直接锁定 Critical，无论其他维度。

---

## 二、策略推荐矩阵

| Risk \ Intent | refactor | extract | rename | delete | understand |
|---------------|----------|---------|--------|--------|-----------|
| **Low**       | safe-refactor | safe-refactor | safe-refactor | safe-refactor | safe-refactor* |
| **Medium**    | staged-refactor | staged-refactor | safe-refactor | staged-refactor | freeze-and-document |
| **High**      | staged-refactor | parallel-rewrite | staged-refactor | parallel-rewrite | freeze-and-document |
| **Critical**  | escalate | escalate | escalate | escalate | escalate |

\* 仅理解意图的话，没必要做任何重构动作，但仍可输出 safe-refactor 表示"未来真要改不会有大问题"。

---

## 三、覆盖规则（高优先级，覆盖矩阵默认结果）

以下情况强制覆盖矩阵的默认推荐：

### 覆盖规则 1：序列化字段被外部消费
- 矩阵推荐 → 强制改为 `parallel-rewrite` 或 `freeze-and-document`
- 理由：字段重命名会破坏外部协议，必须有兼容路径

### 覆盖规则 2：原作者已离职 + 大量"看似可删但不能删"
- 矩阵推荐 → 强制改为 `freeze-and-document`
- 理由：缺乏可询问的人 + 隐性约束多 = 重构事故概率极高

### 覆盖规则 3：考古目标是核心数据模型（如 User、Order、Account）
- 矩阵推荐 → 至少 `parallel-rewrite`
- 理由：核心模型变更影响面深远，并行实现是最安全的演进路径

### 覆盖规则 4：项目级模式关联（同样设计在 ≥ 3 处出现）
- 矩阵推荐 → 至少 `staged-refactor`
- 理由：单点重构会造成项目内不一致，必须分阶段统一

### 覆盖规则 5：本次考古发现"必要复杂性"占比 > 70%
- 矩阵推荐 → 倾向 `freeze-and-document`
- 理由：复杂性大多是必要的，重构收益有限

---

## 四、置信度评估（附加在策略推荐上）

报告中的策略推荐应附"置信度"标注：

| 置信度 | 含义 |
|-------|------|
| 🟢 高 | 三份子报告结论一致，无矛盾，证据充分 |
| 🟡 中 | 子报告之间有 1-2 处不一致，但整体方向清晰 |
| 🔴 低 | 子报告之间有显著矛盾，或某份报告证据严重不足 |

低置信度时，必须在报告中明确建议：
> "由于置信度较低，强烈建议先补充 {具体行动} 再做最终决策。"

例如：
- "建议联系原作者 {name}（即使已离职）进行一次 30 分钟咨询"
- "建议先补充集成测试覆盖率到 60%+ 后再次评估"
- "建议查阅 issue #{number} 和 PR #{number} 了解当时讨论"

---

## 五、特殊情况兜底

### 若三份子报告任一为"分析失败"
- 不生成最终报告
- 提示用户执行 /arch-resume 重启失败的考古员

### 若考古目标实际是"已废弃但未删除的代码"
- history.md 显示长期沉睡 + blast-radius.md 显示无任何调用方
- 直接推荐 `safe-refactor`，理由 = "可安全删除"
- 这种情况报告应特别简短，避免过度分析

### 若考古目标包含敏感模块（认证、支付、加密）
- 即使矩阵给出 Low，强制升级为至少 Medium
- 推荐策略至少 `staged-refactor`
- 必须建议安全审查作为前置条件
