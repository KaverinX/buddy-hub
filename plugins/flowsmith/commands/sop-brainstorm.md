---
description: 在进入 PLANNING 前澄清模糊需求：苏格拉底式提问、枚举边界、提出可选设计方向，确认后固化为 .sop/brainstorm.md
argument-hint: <粗略需求描述>
---

# /sop-brainstorm — 需求澄清门禁

需求：$ARGUMENTS

## 执行步骤

### Step 1 — 判断是否需要澄清
若需求已足够清晰（边界、成功标准、约束都明确），直接告知用户"需求已清晰，可执行 /sop-init"，不强行澄清。

### Step 2 — 遵循 brainstorming skill
按 `skills/brainstorming/SKILL.md`：提澄清问题 → 枚举边界与失败模式 → 提 1-2 个设计方向（带取舍）。
一轮不够可多轮，但每轮聚焦、不冗长。

### Step 3 — 用户确认后固化
将澄清结论写入 `.sop/brainstorm.md`（若 `.sop/` 不存在则先 `mkdir -p .sop`）。
emit `requirement.clarified`。

### Step 4 — 引导下一步
```
✅ 需求已澄清并固化到 .sop/brainstorm.md
关键决定：{1-3 条}
选定方向：{方向名 + 一句话理由}
下一步：直接执行 /sop-init（无需重复描述——会自动继承本次澄清的定稿任务；如需调整可在 /sop-init 后传入新描述覆盖）
```

## 注意
- 本命令可在 /sop-init 之前独立运行；也可在已 init、处于 PLANNING 且发现需求模糊时补做。
- 不在此阶段写代码或写 plan.md，只澄清。
