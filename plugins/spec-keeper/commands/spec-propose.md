---
description: 发起一个规格变更提案。创建 spec/changes/<id>/，基于现有 living spec 写出 ADDED/MODIFIED/REMOVED delta 与任务拆解
argument-hint: <变更描述> [--capability=<id>]
---

# /spec-propose — 发起规格变更提案

变更描述：$ARGUMENTS

## 前置读取
1. `schemas/spec-schema.md` — delta 与 living spec 格式
2. `spec/capabilities/` — 现有能力真相（若 `spec/` 不存在，先 `mkdir -p spec/capabilities spec/changes` 并说明这是首个提案）

## 执行步骤

### Step 1 — 定位受影响能力
- 若 `--capability=` 指定，用之；否则扫描 `spec/capabilities/` 匹配最相关能力
- 若是全新能力，约定新 capability_id（kebab-case），在 delta 的 ADDED 里同时新建该能力

### Step 2 — 生成 change 文件夹
```
spec/changes/<change-id>/   # change-id = 简短 kebab 描述 + 4 位随机后缀
├── proposal.md
├── tasks.md
└── status   # 内容：proposed
```

### Step 3 — 写 proposal.md（核心：delta）
严格按 `schemas/spec-schema.md` 第 3 节：
- **ADDED**：本次新增、现有 spec 没有的行为规格（R 条目）
- **MODIFIED**：现有 R 的行为如何改变（必须写"改前→改后"）
- **REMOVED**：移除哪些行为 + 理由 + 兼容性影响
- 每条 R 必须**可判定**（能写成测试），为后续 TEST_FIRST 直接复用

### Step 4 — 写 tasks.md
把 delta 拆成可执行任务（粒度对齐 flowsmith plan.md 子任务，2-4h），标注依赖与可并行项。

### Step 5 — emit 事件
emit `spec.proposed`（entity=spec_change）+ 每条 delta 一条 `spec.delta.recorded`（见 context-keeper event-emission skill）。

### Step 6 — 汇报
```
✅ 提案已创建：spec/changes/<id>/
受影响能力：{caps}
Delta：+{n} 新增 / ~{m} 修改 / -{k} 移除
下一步：评审 proposal.md 后，直接 /sop-init（无需重复描述——会自动继承本提案标题并关联本变更 change_id；flowsmith 将以 living spec 为硬约束）
```

## 注意
- 不在此阶段写代码。proposal 是"先对齐再动手"的对齐物（对标 OpenSpec）。
- delta 描述的是**行为**，不是文件改动。
