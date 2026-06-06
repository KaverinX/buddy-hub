---
name: brainstorming
description: 需求澄清 Skill。在写 plan.md 之前，用苏格拉底式提问消除需求模糊、枚举边界情况、提出可选设计方向，待用户确认后才进入 PLANNING。当用户需求模糊、或执行 /sop-brainstorm 时由 Claude 主动遵循。对标 Superpowers 的 brainstorming 与 OpenSpec 的"先对齐再动手"。
---

# 需求澄清（brainstorming）

## ⚖️ IRON LAW（不可协商）

**需求的关键模糊点未澄清、设计方向未经用户确认，不得进入 PLANNING、不得写任何实现代码。**

## 🚩 红旗清单（识别即停，回到 IRON LAW）

- "用户大概是想要…我先按这个做" → 停，臆测就是红旗，去问
- "需求挺清楚的，直接开干" → 停，先自检：边界态/错误态/非功能要求是否都明确
- "先写起来，不对再改" → 停，返工成本远高于一轮澄清
- "我提一个方案就够了" → 至少提 1-2 个有取舍差异的方向让用户选
- 以及共享红旗词表（见 `../_shared/iron-law.md`）

## 前置读取
1. `../_shared/iron-law.md`
2. `.sop/lessons.md`（若存在）— 历史教训可能直接点出该类需求常见的隐藏坑

## 澄清方法

### Step 1 — 提澄清问题（一次问到点子上，不要冗长清单）
聚焦真正影响方案的未知项：
- **范围边界**：这次做什么、明确不做什么？
- **隐性需求**：性能/并发、向后兼容、权限、错误与边界态（empty/loading/失败/超时）？
- **成功标准**：怎样算完成？验收点是什么？（这些将直接成为 TEST_FIRST 的测试与 spec 的 R 条目）
- **约束**：不可改的技术栈/接口/截止条件？

> 优先问"答案会改变方案"的问题；不问能自行从代码/上下文推断的。

### Step 2 — 枚举边界与失败模式
基于已知信息列出容易被忽略的边界情况和失败路径，请用户确认是否在范围内。

### Step 3 — 提出 1-2 个设计方向（带取舍）
不是一个标准答案，而是有差异的方向（如"简单直接 vs 可扩展"），点明各自代价，请用户选择。

### Step 4 — 固化为 brainstorm.md
用户确认后，按 `task-planning/reference/document-schemas.md` 的 `brainstorm.md` 格式写入 `.sop/brainstorm.md`。
emit `requirement.clarified`。

## 与下游接力
- `task-planning` skill 在 PLANNING 时若发现 `.sop/brainstorm.md` 存在，必须以其澄清结论为准来写 plan.md（澄清在前固化需求，转述在后精确落地——两者不冲突）。
- 澄清出的成功标准/验收点可被 spec-keeper `/spec-propose` 直接复用为 delta 的 R 条目。

## 合法跳过
需求本就清晰、或单行 typo/纯文档时无需澄清，直接 /sop-init 即可。澄清是门禁不是仪式——模糊才用。
