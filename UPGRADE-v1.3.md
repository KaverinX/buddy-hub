# buddy-hub 专项升级 v1.3 — 补全 Superpowers 全套 + 多宿主导出

承接 v1.2（TEST_FIRST 门禁 + Iron Law/红旗 + spec-keeper）。本轮落地路线图剩余项，
至此与 OpenSpec、Superpowers 的对标缺口全部补齐。

## P3 — 需求澄清前置门禁（对标 Superpowers brainstorming / OpenSpec "先对齐")

| 项 | 内容 | 文件 |
|----|------|------|
| brainstorming 技能 | IRON LAW：模糊未澄清/方向未确认，不得进 PLANNING、不得写码；苏格拉底提问→枚举边界→提 1-2 个带取舍的方向 | flowsmith/skills/brainstorming/SKILL.md |
| /sop-brainstorm 命令 | 澄清门禁，产出 `.sop/brainstorm.md` | flowsmith/commands/sop-brainstorm.md |
| brainstorm.md 契约 | 范围/隐性需求/成功标准/边界/选定方向 | document-schemas.md |
| 下游接力 | task-planning 优先采信 brainstorm.md；成功标准可喂 TEST_FIRST 与 spec 的 R 条目 | task-planning/SKILL.md |
| 事件 | `requirement.clarified` | context-keeper event-schema |

> 轻量设计：不改 state.json schema，以 `.sop/brainstorm.md` 存在为信号；需求清晰时跳过。

## P4a — 技能自演进（对标 Superpowers writing-skills）

| 项 | 内容 | 文件 |
|----|------|------|
| writing-skills 元技能 | IRON LAW：新技能须含可判定 IRON LAW + 针对性红旗；格式外置不内嵌 | flowsmith/skills/writing-skills/SKILL.md |
| skill 模板 | buddy-hub 统一骨架 + 5 条必守约定 | flowsmith/skills/_shared/skill-template.md |
| /skill-scaffold 命令 | 按规范脚手架新技能目录 | flowsmith/commands/skill-scaffold.md |
| 事件 | `skill.authored` | context-keeper event-schema |

## P4b — 多宿主导出（诚实分层，非对等承诺）

| 项 | 内容 | 文件 |
|----|------|------|
| 可移植导出器 | 把所有 plugin 的 skills/commands markdown 汇成 host-agnostic bundle + INDEX | scripts/export-portable.sh |
| 能力矩阵 | 明确什么能移植（方法论/红旗）、什么不能（hooks/事件总线/TUI 等运行时） | MULTI-HOST.md |

> 核心立场：buddy-hub 护城河强绑定 Claude Code 运行时，只导出"无状态方法论"。
> 定位为获客入口与方法论传播，而非能力对等。实测导出 12 个 SKILL.md + 31 个命令。

flowsmith 版本 1.2.0 → **1.3.0**。

## 至此对标完成度

| 对标能力 | 状态 |
|----------|------|
| OpenSpec：living spec + delta（proposal/apply/archive） | ✅ spec-keeper（v1.2） |
| OpenSpec：规格-代码漂移检测 | ✅ /spec-check（v1.2，规格↔测试维度） |
| Superpowers：TDD 先红后绿 + 绿灯门禁 | ✅ TEST_FIRST + validate-tests（v1.2） |
| Superpowers：Iron Law + 红旗反自我开脱 | ✅ _shared/iron-law + 全 skill（v1.2/v1.3） |
| Superpowers：系统化调试 | ✅ systematic-debugging（v1.2） |
| Superpowers / OpenSpec：需求澄清前置 | ✅ brainstorming（v1.3） |
| Superpowers：writing-skills 自演进 | ✅ writing-skills（v1.3） |
| 二者：多宿主 | ◐ 无状态方法论导出（v1.3，诚实分层） |
| buddy-hub 独有：事件溯源知识图谱 / 考古 / 协作审查 | ✅ 保留并被新能力复用 |

全部新能力均长在 context-keeper 事件地基上——"规格 + 测试纪律 + 事件溯源"的组合是 OpenSpec、Superpowers 各自都没有的。
