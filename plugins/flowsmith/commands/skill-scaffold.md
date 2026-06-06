---
description: 按 buddy-hub 规范脚手架一个新 Skill（生成目录、SKILL.md 骨架、reference 占位），遵循 Iron Law + 红旗 + 契约外置
argument-hint: <plugin>/<skill-name> "<一句话用途>"
---

# /skill-scaffold — 脚手架新技能

参数：$ARGUMENTS（格式：`<plugin>/<skill-name> "<用途>"`）

## 执行步骤

### Step 1 — 解析与校验
- 解析出 `plugin`、`skill-name`（kebab-case）、`用途`
- 校验 `plugins/<plugin>/skills/<skill-name>/` 不存在（已存在则提示用 writing-skills 改进而非覆盖）

### Step 2 — 读取规范
遵循 `flowsmith/skills/writing-skills/SKILL.md` 与 `flowsmith/skills/_shared/skill-template.md`。

### Step 3 — 生成骨架
```
plugins/<plugin>/skills/<skill-name>/
├── SKILL.md            # 按 skill-template.md 填好 frontmatter + Iron Law/红旗占位 + 用途
└── reference/          # 契约外置目录（占位 .gitkeep）
```
SKILL.md 中 IRON LAW、红旗、执行纪律以 `{待填}` 形式给出引导，并与用户一问一答补全核心条目（至少 IRON LAW + 3 条红旗）。

### Step 4 — 收尾
- emit `skill.authored`
- 提示：如该技能要产出文档/数据，把格式写进 `plugins/<plugin>/schemas/` 后再在 SKILL.md 引用。

## 注意
脚手架只搭骨架与核心纪律，不替用户臆造完整内容——具体执行步骤需结合该技能真实场景填写。
