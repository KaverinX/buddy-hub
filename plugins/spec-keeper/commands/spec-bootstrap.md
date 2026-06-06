---
description: 为【已有项目】反向捕获当前行为，生成整体 living spec（spec/capabilities/）。OpenSpec 式 brownfield：不重写代码，只把"系统现在做什么"沉淀为按能力组织的规格文档
argument-hint: [--capability=<区域，如 auth/notification>] [--from=<目录或入口，如 src/api>]
---

# /spec-bootstrap — 反向生成项目整体规格

参数：$ARGUMENTS

> 用途：项目还没有 living spec（或只有零散变更沉淀），需要一份"系统当前具备哪些能力、各自预期行为"的整体规格文档时使用。
> 与 /spec-propose 相反：propose 是"打算怎么改"（forward），bootstrap 是"现在是什么样"（reverse capture）。

## 前置读取
1. `../../schemas/spec-schema.md` — living spec 格式（唯一格式来源）
2. `../skills/spec-authoring/SKILL.md` — 撰写纪律（描述行为不描述实现、行为可判定）
3. 已有 `spec/capabilities/`（若有，bootstrap 只补缺失能力，不覆盖已有真相）

## ⚖️ 关键纪律（务必遵守 spec-authoring 的 IRON LAW）
- 写**实然**（代码当前真实做什么），不是应然，也不是你认为它该怎样
- 推断不确定的行为，**标记 `[待确认]`**，绝不臆造填满
- 描述**行为**（可判定、能写成测试），不抄实现细节

## 执行步骤

### Step 1 — 圈定范围（强烈建议分区域，不要一次扫全仓库）
- 若 `--capability=` / `--from=` 指定，只处理该区域
- 否则先列出"候选能力清单"给用户确认后再逐个生成（一次性全仓库扫描质量差、易臆造）
- 识别能力的信号：入口点（HTTP 路由 / CLI / 定时任务 / MQ 消费者）、对外公开模块/服务、独立的功能域

### Step 2 — 逐能力生成 spec.md
对每个确认的能力，在 `spec/capabilities/<capability-id>/spec.md` 按 schema 第 2 节写：
- **目的**：为谁解决什么问题
- **行为规格（R-n）**：从代码与测试反推每条可判定行为（当/则/除非 + 验收）；不确定的标 `[待确认]`
- **接口契约**：从路由/控制器/SDK 反推（method/path/req/resp/error）
- **数据契约**：从模型/表结构反推关键约束
- **非目标**：代码明显未支持、但容易被误以为支持的，列出
- 头部 `status: active`，`last_change: bootstrap`

### Step 3 — 标注证据与待确认项
- 每条能力末尾附"来源"（主要来自哪些文件/目录），便于人工核对
- 汇总所有 `[待确认]` 项，请用户逐条确认或修正

### Step 4 — 事件与汇报
- emit `spec.bootstrapped`（每个能力一条，evidence 指向来源文件）
- 汇报：
```
✅ 已捕获 {n} 个能力 → spec/capabilities/
能力：{列表}
待确认项：{k}（请逐条核对，确认后即为系统真相基线）
后续：新变更走 /spec-propose；该基线即作为 delta 的对比对象
```

## 注意
- bootstrap 产物是**待核对的草稿基线**，不是即时真相——人工确认 `[待确认]` 后才可信。
- 全自动、带调用链证据的提取是 atlas 插件（代码图谱）的目标；本命令做"AI 辅助阅读代码捕获"，需人工复核。
- 与 flowsmith 无关，不创建 .sop/ 任务，可随时独立运行。
