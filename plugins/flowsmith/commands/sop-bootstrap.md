---
description: 在项目根目录生成轻量 CLAUDE.md，将本项目接入 flowsmith plugin
---

# /sop-bootstrap — 项目接入 SOP

## 用途

在项目首次使用 flowsmith 时执行此命令一次。
它会在项目根目录生成一份轻量级 `CLAUDE.md`，作用是声明"本项目遵循 SOP 流程"，
让 Claude 在每次会话启动时自动加载这份声明，确保即使用户没有显式调用 `/sop-init`，
Claude 也会主动引导走 SOP 流程。

**这份 CLAUDE.md 只是"指针"**：详细规则、流程、agent 定义都在 plugin 中，
项目里只保留最少的接入声明。

## 执行步骤

### Step 1 — 检查是否已存在 CLAUDE.md

读取项目根目录的 `CLAUDE.md`：

- **若不存在**：直接创建（见 Step 3）
- **若存在但不包含 flowsmith 标记**：询问用户：
  > "项目已有 CLAUDE.md。是否在文件末尾追加 flowsmith 接入声明？
  > （不会修改现有内容）"
  > 用户确认后，追加 Step 3 中的内容到末尾。
- **若已包含 `<!-- flowsmith:installed -->` 标记**：提示：
  > "本项目已接入 flowsmith。无需重复执行。
  > 如需更新接入声明，请手动删除 CLAUDE.md 中 flowsmith 相关部分后重新执行。"
  > 停止执行。

### Step 2 — 检查 .gitignore（可选）

提示用户：
> "建议将 .sop/state.json 中的临时字段排除版本控制吗？
> （通常 .sop/ 整个目录都应纳入 git，所以默认不排除）"

### Step 3 — 写入 CLAUDE.md

在 CLAUDE.md 末尾追加（或新建文件并写入）：

```markdown
<!-- flowsmith:installed -->
## SOP 工作流接入声明

本项目使用 [flowsmith](https://github.com/Velpro/buddy-hub) plugin 管理开发流程。

### 强制规则

收到任何**开发任务**（实现新功能、修复 bug、重构、添加测试等），**必须**：

1. **首先**检查 `.sop/state.json` 是否存在：
   - 不存在 → 提示用户执行 `/sop-init <任务描述>` 初始化
   - 存在但未完成 → 提示用户执行 `/sop-resume` 恢复任务
   - 存在且已完成（DONE 或 archived）→ 提示执行 `/sop-init` 开始新任务

2. **禁止**在没有 `.sop/state.json` 的情况下直接开始编码。

3. 任务执行过程中遵循 plugin 中定义的状态机流转规则
   （详见 flowsmith plugin 的 skills/task-planning/reference/state-machine.md）。

### 例外情况

以下场景**不需要**走 SOP 流程，可直接处理：
- 回答纯知识性问题（"如何使用 X 库的 Y 函数"）
- 解释现有代码（"这段代码做了什么"）
- 单行 typo 修复 / 配置值修改（但仍建议执行 `/sop-init` 跳过部分阶段）
- 用户明确说"不走 SOP，直接改"（用户主动豁免）

### 查询当前状态

任何时候都可以执行 `/sop-status` 查看当前任务进度。

<!-- flowsmith:end -->
```

### Step 4 — 输出确认

```
✅ flowsmith 已接入本项目

文件：./CLAUDE.md
{若是新建文件：'已创建'}
{若是追加：'已在文件末尾追加 SOP 接入声明'}

下次会话启动时，Claude 将自动加载 SOP 规则。
现在可以执行 /sop-init <任务描述> 开始第一个任务。

提示：
- 建议将 ./CLAUDE.md 和 ./.sop/ 目录都纳入 git 版本控制
- 团队其他成员只需安装 flowsmith plugin，本项目的 SOP 规则会自动生效
```
