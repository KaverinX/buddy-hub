---
name: writing-skills
description: 元技能：撰写/改进 buddy-hub 风格的 Skill。当用户想新增一个 plugin 技能、把重复的纪律沉淀为 Skill、或改进现有 Skill 的触发与约束时使用。确保新技能遵循 Iron Law + 红旗、契约外置、SkillBus emit 等 buddy-hub 统一规范。对标 Superpowers 的 writing-skills 自演进能力。
---

# 撰写技能（writing-skills）

## ⚖️ IRON LAW（不可协商）

**新技能必须含可判定的 IRON LAW 与针对性红旗清单；格式定义一律外置到 reference/schema，不内嵌进 Skill。**

## 🚩 红旗清单（识别即停）

- "这个 Skill 写一堆'应该尽量…'就行" → 停，纪律必须可判定真假
- "红旗就写'要认真'吧" → 停，红旗要写 Claude 真实会用来开脱的具体话术
- "格式直接写在 Skill 里方便" → 停，外置到 reference/，否则多处格式会漂移
- "description 写'处理各种情况'" → 停，触发条件要具体，否则触发不准
- 以及共享红旗词表（见 `../_shared/iron-law.md`）

## 前置读取
1. `../_shared/iron-law.md` — Iron Law + 红旗规范
2. `../_shared/skill-template.md` — 新技能骨架与必守约定
3. 目标 plugin 已有的 Skill（保持风格一致）与其 `schemas/`（契约外置目标）

## 撰写流程

### Step 1 — 定位"重复纪律"
一个 Skill 值得存在，是因为某条纪律会被反复违反或反复手动叮嘱。先说清：它防的是什么具体失误？

### Step 2 — 提炼 IRON LAW
把纪律压成一句可判定真假的硬规则。判据：能否对任意一次执行回答"它违反了没有"。

### Step 3 — 写针对性红旗
列出 Claude 在这件事上最可能用来给自己开脱的 3-5 句话，每句配"停 + 正确动作"。再引用共享红旗词表。

### Step 4 — 外置契约
任何输出文档/数据格式，写进目标 plugin 的 `schemas/` 或技能的 `reference/`，Skill 里只引用路径。

### Step 5 — 接 SkillBus
若技能会产生有语义的状态变更/新沉淀，写明 emit 哪些事件（必要时先在 context-keeper event-schema.md 按"只追加不重命名"登记新事件类型）。

### Step 6 — 校准 description
description 决定触发准确率：写清"做什么 + 何时由 Claude 主动触发"，给出可识别的触发条件。

## 与 SkillBus 的联动
新技能落地后 emit `skill.authored`（actor=writing-skills 所在 plugin，entity=报告/文件引用）。

## 合法跳过
一次性、不会重复的纪律，写进当次任务说明即可，不必沉淀为 Skill——避免 Skill 膨胀。
