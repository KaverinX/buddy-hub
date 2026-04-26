---
description: 生成单人详细画像（仅本地查看，不输出到 private/ 反馈文件）
argument-hint: <author-name-or-email>
---

# /scope-individual — 单人画像查询

参数：$ARGUMENTS

## 用途

为指定的开发者生成一份**详细画像**，仅在终端展示，**不写入** `.team-scope/private/`。

适用于：
- 团队 lead 想了解某位开发者本次分支的工作情况
- 1:1 面谈前的快速准备
- **不**用于绩效评估（评分逻辑只在 --with-scores 时启用）

## 执行步骤

### Step 1 — 前置校验

读取 `.team-scope/state.json`：
- 若不存在或 `report.status != "done"`：
  > "请先执行 /scope-review 完成审查再查询单人画像。"
  > 停止。

### Step 2 — 模糊匹配作者名

从 `.team-scope/contributions.md` 中提取所有作者列表。
对用户输入做模糊匹配：
- 全名 case-insensitive 匹配
- 邮箱 local-part 匹配
- 邮箱完整匹配

若多匹配（如输入 "alice" 同时匹配到 "Alice Wong" 和 "Alice Chen"）：
> "找到多位匹配的作者：
>   1. Alice Wong <alice.wong@x.com>
>   2. Alice Chen <alice.chen@x.com>
>  请输入更精确的名字或邮箱。"
> 停止。

若无匹配：
> "未找到名为 '{input}' 的作者。
>  本次审查涉及的作者：
>  {列出所有作者}"
> 停止。

### Step 3 — 聚合该作者的所有信息

从三份 analyzer 报告中提取该作者的相关数据：

**从 contributions.md 提取**：
- 贡献统计（commits、LOC、文件数）
- 主要模块
- 子任务承担情况
- 越界提交

**从 completion.md 提取**：
- 完成度等级与信号
- TODO/空实现/调试遗留清单
- 测试同步率
- PR 自述偏差（若有）

**从 risks.md 提取**：
- 该作者参与的同文件冲突
- 该作者引入的接口签名变更
- 该作者违反的红线
- 该作者重蹈的覆辙

### Step 4 — 输出（仅终端，不写文件）

```markdown
👤 {author_name} 的本次分支画像
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 贡献概况
- Commits：{N}
- 代码改动：+{added}/-{removed} 行，{files} 个文件
- 主要模块：{modules}
- 时间跨度：{first} ~ {last}

## 子任务承担
{表格：plan.md 子任务对应情况}

## 完成度信号
- 等级：{level}
- TODO：{N} 处
- 空实现：{M} 处
- 调试遗留：{K} 处
- 测试同步率：{X}%

详细位置：
{逐条列出 file:line + 内容}

## 协作风险参与
{该作者涉及的所有风险}

## 边界情况
- 越界提交：{N} 处（合理 {X}，不合理 {Y}）
- 跨人维护：{M} 个文件
- 替代维护：{K} 个文件

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5 — 不持久化

明确声明：
```
ℹ️ 本画像仅在终端展示，不写入文件。
   如需生成给该开发者的私聊反馈文件，请使用：
   /scope-review --with-private-feedback
```

## 重要约束

- 不写入文件（与 --with-private-feedback 区分）
- 仅展示客观事实，不做评判
- 无评分（评分仅在 --with-scores 启用时存在于 scores.md）
- 不在终端展示其他人的对比信息（保持单人画像的纯粹性）
