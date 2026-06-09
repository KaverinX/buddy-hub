---
description: 为【已有项目】反向捕获当前行为，生成 OpenSpec 格式的整体真相 spec（openspec/specs/<domain>/spec.md）。brownfield：不重写代码，只把"系统现在做什么"沉淀为按 domain 组织、带 Requirement/Scenario 的规格
argument-hint: [--domain=<区域，如 auth/notification>] [--from=<目录或入口，如 src/api>]
---

# /spec-bootstrap — 反向生成项目整体规格（OpenSpec 格式）

参数：$ARGUMENTS

> 与 `/spec-propose` 相反：propose 是"打算怎么改"（forward），bootstrap 是"现在是什么样"（reverse capture）。
> 与 `/spec-align` 互补：bootstrap 从**代码**捕获新真相；align 从**旧版 spec/** 转格式。

## 前置读取
1. `schemas/spec-schema.md` — OpenSpec 真相 spec 格式（唯一来源）
2. `../skills/spec-authoring/SKILL.md` — 撰写纪律
3. 已有 `openspec/specs/`（若有，bootstrap 只补缺失 domain，不覆盖已有真相；若只有旧版 `spec/`，先 `/spec-align --migrate`）

## ⚖️ 关键纪律
- 写**实然**（代码当前真实做什么），不是应然。
- 推断不确定的行为标 `[待确认]`，**绝不臆造**。
- 描述**行为**（可写成 Scenario），不抄实现细节。

## 执行步骤

### Step 1 — 圈定范围（建议分区域，别一次扫全仓库）
- 若 `--domain=` / `--from=` 指定，只处理该区域；否则先列"候选 domain 清单"给用户确认再逐个生成。
- domain 信号：入口点（HTTP 路由 / CLI / 定时任务 / MQ 消费者）、对外模块/服务、独立功能域。

### Step 2 — 逐 domain 生成 openspec/specs/<domain>/spec.md（按 schema §2）
- `# <Domain> Specification`
- `## Purpose`：为谁解决什么问题。
- `## Requirements`：从代码与测试反推每条可判定行为 → `### Requirement: {名}` + `The system SHALL/MUST …`（RFC2119 英文关键字）+ ≥1 个 `#### Scenario:`（GIVEN/WHEN/THEN，覆盖 happy path 与关键边界）。
- 接口 → 带 SHALL 的 Requirement + 覆盖 method/path/resp/error 的 Scenario；数据约束 → 约束类 Requirement + 校验 Scenario。
- 不确定的标 `[待确认]`。

### Step 3 — 标注证据与待确认项
- 每个 domain 末尾附非规范性 `> 来源: {文件/目录}`（不影响 validate）。
- 汇总所有 `[待确认]`，请用户逐条确认。

### Step 4 — 校验、事件与汇报
- 跑 OpenSpec 一致性自查（Purpose + Requirements + 每需求 ≥1 Scenario + RFC2119）。
- emit `spec.bootstrapped`（每个 domain 一条，evidence 指向来源文件）。
```
✅ 已捕获 {n} 个 domain → openspec/specs/
domain：{列表}
待确认项：{k}（请逐条核对，确认后即为系统真相基线）
后续：新变更走 /spec-propose；该基线即作为 delta 的对比对象
```

## 注意
- bootstrap 产物是**待核对的草稿基线**，人工确认 `[待确认]` 后才可信。
- 与 flowsmith 无关，不创建 `.sop/`，可独立运行。
