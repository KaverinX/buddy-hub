---
description: 发起一个规格变更提案（OpenSpec 格式）。创建 openspec/changes/<id>/，写 proposal.md（Intent/Scope/Approach）+ 独立 delta spec（specs/<domain>/spec.md，ADDED/MODIFIED/REMOVED + Scenario）+ tasks.md
argument-hint: <变更描述> [--domain=<domain>]
---

# /spec-propose — 发起规格变更提案

变更描述：$ARGUMENTS

## 前置读取
1. `schemas/spec-schema.md` — OpenSpec 对齐格式（delta 是独立文件，需求带 Scenario，RFC2119）
2. `../skills/spec-authoring/SKILL.md` — 撰写纪律
3. `openspec/specs/` — 现有真相（若 `openspec/` 不存在：先 `mkdir -p openspec/specs openspec/changes` 并说明这是首个提案；若只有旧版 `spec/`，提示先 `/spec-align --migrate`）

## 执行步骤

### Step 1 — 定位受影响 domain
- 若 `--domain=` 指定，用之；否则扫描 `openspec/specs/` 匹配最相关 domain。
- 全新能力：约定新 domain（kebab-case），在 delta 里新建。

### Step 2 — 生成 change 文件夹（动词起头短 kebab 命名，如 add-dark-mode）
```
openspec/changes/<change-id>/
├── proposal.md
├── tasks.md
├── .openspec.yaml                  # change_id / status=proposed / capabilities / linked_sop_task
└── specs/<domain>/spec.md          # delta（独立文件！）
```

### Step 3 — 写 delta：specs/<domain>/spec.md（核心，严格按 schema §3）
- 首行 `# <Domain> Delta`。
- `## ADDED Requirements`：新增需求，每条 `### Requirement: {名}` + `The system SHALL/MUST …` + ≥1 个 `#### Scenario:`（GIVEN/WHEN/THEN）。
- `## MODIFIED Requirements`：改后需求 + `(Previously: 改前)` + Scenario。
- `## REMOVED Requirements`：`### Requirement: {名}` + `(理由 + 兼容性影响)`。
- 无某类变更则省略对应小节。每条 Scenario 必须可测，直接复用给 TEST_FIRST。

### Step 4 — 写 proposal.md（schema §4，**不含 delta**）
`# Proposal: {标题}` + `## Intent`（动机/引用 issue）+ `## Scope`（In scope / Out of scope）+ `## Approach`（高层方案）。

### Step 5 — 写 tasks.md
`# Tasks` + 分组 + `- [ ] N.M …` checkbox（粒度对齐 flowsmith plan.md 子任务 2-4h，标依赖/可并行）。

### Step 6 — emit 事件
`spec.proposed`（entity=spec_change）+ 每条 delta 一条 `spec.delta.recorded`。

### Step 7 — 汇报
```
✅ 提案已创建：openspec/changes/<id>/
受影响 domain：{domains}
Delta：+{n} 新增 / ~{m} 修改 / -{k} 移除（独立文件 specs/<domain>/spec.md）
下一步：评审 proposal.md + delta 后，直接 /sop-init（自动继承标题、关联 change_id；flowsmith 以真相 spec 为硬约束）
```

## 注意
- 不在此阶段写代码。proposal + delta 是"先对齐再动手"的对齐物。
- delta 描述**行为**（带可测 Scenario），不是文件改动；且是**独立 spec 文件**，不内联进 proposal。
