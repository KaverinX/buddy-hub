---
name: spec-authoring
description: 规格撰写 Skill。在写 living spec 与变更 delta 时遵循的纪律：能力优先、行为可判定、delta 表达相对现有真相的变化。当执行 spec-keeper 的 /spec-propose、/spec-apply 或编辑 spec/ 下文件时由 Claude 主动遵循。对标 OpenSpec 的 SDD 方法论。
---

# 规格撰写（spec-authoring）

## ⚖️ IRON LAW（不可协商）

**规格描述行为（行为可判定、能写成测试），不描述实现；变更以相对现有 living spec 的 delta 表达，不重写整份规格。**

## 🚩 红旗清单（识别即停）

- "这条规格写：用 Redis 缓存…" → 停，那是实现。规格应写"读取应在 X ms 内返回"
- "改个需求顺手把整份 spec 重写一遍" → 停，用 ADDED/MODIFIED/REMOVED delta
- "R-3：系统应该处理好各种情况" → 不可判定，停，写成可测的具体行为
- "先写代码，规格回头补" → 停，SDD 是先对齐 spec 再动手（对标 OpenSpec）
- 以及共享红旗词表（见 flowsmith `skills/_shared/iron-law.md`）

## 前置读取
1. `../../schemas/spec-schema.md` — living spec 与 delta 格式（唯一格式来源）
2. `spec/capabilities/`（若存在）— 现有真相，delta 相对它表达

## 撰写纪律

### 能力优先于任务
spec 按"系统具备哪些长期能力"组织，不按"这次做了什么任务"组织。任务是短命的，能力是长命的。

### 行为可判定
每条 R 必须能回答"怎么验证它成立"。模板：**当**{触发}**则**{行为}**除非**{例外}。无法写成测试的 R 要继续细化。

### delta 表达变化，不是文件 diff
ADDED/MODIFIED/REMOVED 描述的是**行为**相对现有能力的增减改，不是"改了哪个文件"。MODIFIED 必须写"改前→改后"。

### 真相要自洽可读
apply 合并 delta 后，living spec 要读起来像"系统现在就是这样"，而非提案残片堆叠。

## 与 flowsmith 的接力
proposal 的每条 R 的「验收」是 TEST_FIRST 阶段写测试的直接依据——规格与测试一一对应，是消除 drift 的根本。
