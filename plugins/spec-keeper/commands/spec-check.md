---
description: 校验 living spec 的健康度：未落地的悬挂提案、能力规格自洽性、R 条目是否有对应测试覆盖（drift 检测）
argument-hint: [--capability=<id>]
---

# /spec-check — 规格健康度与漂移检测

参数：$ARGUMENTS

## 检查项

### 1. 悬挂提案
列出 `status = proposed` 但长期未 apply 的 change（提示：要么实现并 /spec-apply，要么 /spec-archive 撤销）。

### 2. 能力规格自洽
对每个 `capabilities/<id>/spec.md`：
- 是否有 R 条目无法判定（不能写成测试）→ 标记需细化
- ADDED/MODIFIED 后是否存在相互矛盾的 R

### 3. 规格 ↔ 实现漂移（drift）
- 对每条 R 的「验收」，检查是否存在对应测试（用 flowsmith `test_gate.command` 的测试集或按命名约定匹配）
- 无测试覆盖的 R → 报 drift，建议补测试或修订规格
- emit `spec.drift.detected`（每条漂移一条，evidence 指向 R 与缺失的测试）

> 完整的"实现实然"对比将在引入 atlas 插件后由其代码图谱提供；本期先做"规格 ↔ 测试"维度的漂移检测。

## 输出
```
能力数：{n}  R 条目：{m}  有测试覆盖：{p}（{p/m}）
悬挂提案：{k}
漂移项：{d}（详见列表）
```
