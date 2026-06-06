# buddy-hub 新技能模板

> 复制此结构创建新 Skill。所有 buddy-hub 刚性 Skill 必须遵循统一骨架：
> Iron Law + 红旗 → 前置读取 → 执行纪律 → SkillBus emit → 合法跳过。

```markdown
---
name: {kebab-case-名}
description: {一句话说明做什么 + 何时由 Claude 主动触发（写明触发条件，如"当 .sop/state.json 的 current_phase 为 X 时"）。description 决定触发准确率，要具体。}
---

# {技能中文名}（{name}）

## ⚖️ IRON LAW（不可协商）
{一条全大写、单句、可判定真假的硬规则}

## 🚩 红旗清单（识别即停，回到 IRON LAW）
- "{该技能特有的开脱话术}" → 停，{正确动作}
- 以及共享红旗词表（见 `../_shared/iron-law.md`）

## 前置读取
1. `../_shared/iron-law.md`
2. {本技能依赖的契约/schema/状态文件}

## 执行纪律
{分步骤或分原则。只写"做什么、怎么判定对错"，格式定义引用 reference 文件，不内嵌}

## 与 SkillBus 的联动
{在产生有语义的状态变更/新沉淀时 emit 哪些事件；见 context-keeper event-emission skill}

## 合法跳过
{什么场景可显式跳过，怎么标记}
```

## 必守约定（buddy-hub 风格）
1. **契约外置**：格式/schema 放 `reference/` 或 plugin 的 `schemas/`，Skill 只引用不内嵌——改格式时只改一处。
2. **行为可判定**：纪律要能判断"违反了没有"，避免"加强测试"这类空洞话。
3. **事件留痕**：有语义的状态变更走 SkillBus emit，进 context-keeper 知识图谱。
4. **反自我开脱**：红旗清单要写"Claude 最可能用来跳过本规则的话"，而非泛泛而谈。
5. **触发精准**：description 写清触发条件，避免该触发时不触发、不该触发时乱触发。
