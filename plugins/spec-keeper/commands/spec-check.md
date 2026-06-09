---
description: 校验真相 spec 的 OpenSpec 一致性与健康度：格式合规（Purpose/Requirements、每需求 ≥1 Scenario、RFC2119）、悬挂提案、规格自洽、R↔测试覆盖（drift）
argument-hint: [--domain=<domain>] [--strict]
---

# /spec-check — OpenSpec 一致性 + 规格健康度 + 漂移检测

参数：$ARGUMENTS

## 检查项

### 1. OpenSpec 格式一致性（等价 openspec validate）
对每份 `openspec/specs/<domain>/spec.md` 与活跃变更的 `changes/<id>/specs/<domain>/spec.md`：
- 真相 spec 含 `## Purpose` 与 `## Requirements`；delta 含 `## ADDED|MODIFIED|REMOVED Requirements`。
- 每条 `### Requirement:` 下 ≥1 个 `#### Scenario:`（否则报 `requirement must have at least one scenario`）。
- 需求正文含 RFC2119 关键字（`SHALL|MUST|SHOULD|MAY`）；Scenario 用 GIVEN/WHEN/THEN。
- `--strict`：Purpose 过短（<50 字符）、Scenario 缺 THEN 等也报。
- 若环境有 `openspec` CLI：附带执行 `openspec validate --strict` 交叉验证。

### 2. 悬挂提案
列出 `.openspec.yaml.status = proposed` 但长期未 apply 的 change（要么实现并 `/spec-apply`，要么 `/spec-archive` 撤销）。

### 3. 规格自洽
- 不可判定（写不成 Scenario）的 Requirement → 标记需细化。
- ADDED/MODIFIED 后相互矛盾的 Requirement → 标记。

### 4. 规格 ↔ 实现漂移（drift）
- 对每条 Requirement 的 Scenario，检查是否有对应测试（用 flowsmith `test_gate.command` 测试集或命名约定匹配）。
- 无测试覆盖 → 报 drift，建议补测试或修订规格。emit `spec.drift.detected`。

## 输出
```
OpenSpec 校验：{通过 / 失败 v 项（文件:行 + 原因）}
domain 数：{n}  Requirement：{m}  有测试覆盖：{p}（{p/m}）
悬挂提案：{k}   漂移项：{d}（详见列表）
```
