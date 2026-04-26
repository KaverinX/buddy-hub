---
description: 团队协作审查。基于当前分支对比基线，三个 analyzer 并行分析贡献/完成度/协作风险，生成主报告与个人行动建议
argument-hint: [--base=main] [--mode=pr|commit] [--with-scores] [--with-private-feedback] [--with-rhythm] [--ci-data=<path>]
---

# /scope-review — 团队协作审查

参数：$ARGUMENTS

## 设计原则（重要）

**本命令分析的是"当前分支"对比基线的差异。**

- `branch` **不接受位置参数**，自动取 `git rev-parse --abbrev-ref HEAD`
- 用户在哪个分支上，就分析哪个分支
- 若需对比两个分支，使用 `/scope-compare <a> <b>`

## 执行步骤

### Step 1 — 解析参数

可选参数：
- `--base=<branch>`：基线分支，默认 `main`
- `--mode=pr|commit`：分析粒度，默认 `pr`
- `--with-scores`：启用维度化评分（默认关闭）
- `--with-private-feedback`：生成私聊反馈文件（默认关闭）
- `--with-rhythm`：启用工作节奏分析（默认关闭，v1 仅占位）
- `--ci-data=<path>`：CI 报告路径（v1 基础读取）

### Step 2 — 自动获取当前分支

```bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
```

校验：
- 若失败（不是 git 仓库）：
  > "co-review 需要 git 仓库环境。当前目录不在 git 仓库中。"
  > 停止。

- 若 `CURRENT_BRANCH == --base`（用户在 base 分支上）：
  > "当前在 base 分支（{branch}）上，没有未合并改动可分析。
  >  请先切换到 feature 分支，或使用 --base=<其他分支> 指定不同基线。"
  > 停止。

- 若 detached HEAD：
  > "当前处于 detached HEAD 状态。请先 checkout 到具体分支后再分析。"
  > 停止。

### Step 3 — 校验 base 分支存在

```bash
git rev-parse --verify "${BASE}" >/dev/null 2>&1 || \
    git rev-parse --verify "origin/${BASE}" >/dev/null 2>&1
```

若都不存在：
> "基线分支 {BASE} 不存在。请确认分支名或使用 --base=<其他分支>。"
> 停止。

### Step 4 — 检测 base..HEAD 是否有改动

```bash
COMMIT_COUNT=$(git rev-list --count ${BASE}..HEAD)
```

若 `COMMIT_COUNT == 0`：
> "当前分支 {CURRENT_BRANCH} 与 {BASE} 没有差异。无可分析的改动。"
> 停止。

### Step 5 — 检测是否多人协作（可选信息）

```bash
AUTHOR_COUNT=$(git log --pretty=format:'%ae' ${BASE}..HEAD | sort -u | wc -l)
```

若 `AUTHOR_COUNT == 1`：
> "⚠️ 提示：本分支只有 1 位作者的提交。co-review 主要价值在于多人协作场景。
>  仍要继续分析吗？(Y/n)"

用户确认后继续。

### Step 6 — 检测并发审查

若 `.team-scope/state.json` 存在且 `report.status != "done"`：
> "发现进行中的审查：{review_id}（branch: {branch}）。
>  是否：(1) 继续该审查 → /scope-status；(2) 放弃并重新分析 → 删除 .team-scope/ 后重试"
> 停止。

### Step 7 — 检测协同上下文

读取 `.sop/state.json`（若存在）：
- 若 `current_phase` 不是 `DONE`，记录 `flowsmith_task_id`
- 标记 `context.trigger`：
  - 若是从 flowsmith 的 hook 跳转过来（环境变量 `BUDDY_COREVIEW_TRIGGER=flowsmith` 设置）→ `"flowsmith-suggested"`
  - 否则 → `"manual"`

读取 `.archaeology/state.json`（若存在）：
- 若 `report.status = "done"`，记录 `context.has_archaeology = true` 与 `archaeology_id`

### Step 8 — 初始化目录与 state.json

```bash
mkdir -p .team-scope
```

按 `${CLAUDE_PLUGIN_ROOT}/schemas/co-review-schema.md` 写入 `.team-scope/state.json`：

```json
{
  "version": "1.0",
  "review_id": "<8 字符随机>",
  "scope": {
    "branch": "${CURRENT_BRANCH}",
    "base": "${BASE}",
    "mode": "${MODE}",
    "commit_range": "${BASE}..HEAD"
  },
  "options": {
    "with_scores": <bool>,
    "with_private_feedback": <bool>,
    "with_rhythm": <bool>,
    "ci_data_path": "<path 或 null>",
    "exclude_patterns": ["*.lock", "package-lock.json", "dist/**", "target/**", "*.min.js", "*.min.css"]
  },
  "context": {
    "trigger": "<step 7 的判断>",
    "flowsmith_task_id": "<step 7 的判断>",
    "has_archaeology": <bool>,
    "archaeology_id": "<step 7 的判断>"
  },
  "agents": {
    "contribution-analyzer":  { "status": "pending", "output": ".team-scope/contributions.md", "started_at": null, "completed_at": null },
    "completion-analyzer":    { "status": "pending", "output": ".team-scope/completion.md",    "started_at": null, "completed_at": null },
    "collab-risk-analyzer":   { "status": "pending", "output": ".team-scope/risks.md",         "started_at": null, "completed_at": null }
  },
  "report": {
    "status": "pending",
    "output": ".team-scope/report.md",
    "merge_strategy": null,
    "team_health": null
  },
  "stats": {
    "authors_count": 0,
    "commits_count": 0,
    "files_changed": 0,
    "loc_added": 0,
    "loc_removed": 0
  },
  "created_at": "<ISO8601>",
  "archived_at": null
}
```

### Step 9 — 输出审查计划

```
🔍 团队协作审查启动

ID：{review_id}
分支：{branch} → {base}
模式：{mode}
作者数：{author_count}（暂估）
Commits：{commit_count}

可选选项：
  {若 with_scores：'✅ 维度评分'}
  {若 with_private_feedback：'✅ 私聊反馈（每人独立文件）'}
  {若 has_archaeology：'🔗 关联考古：{archaeology_id}'}
  {若 flowsmith_task_id：'🔗 关联 flowsmith 任务：{task_id}'}

将派遣三个独立分析员（独立上下文，并行执行）：
  📊 contribution-analyzer  — 贡献画像 + 边界识别
  ✅ completion-analyzer    — 完成度评估
  🛡️  collab-risk-analyzer  — 协作风险检测

预计耗时：5-15 分钟（视改动量而定）

开始派遣分析员...
```

### Step 10 — 派遣三个 subagent

依次（或并行）触发：

1. **@contribution-analyzer** — 任务指令：
   > "请对 .team-scope/state.json 中定义的范围执行贡献画像分析。
   > 严格遵循你的 SOP。完成后将报告写入 .team-scope/contributions.md，
   > 更新 state.json 中你对应的 status 字段，并向我返回简短摘要。
   > 同时更新 state.json 的 stats 字段。"

2. **@completion-analyzer** — 任务指令：同上，但执行完成度评估
   > "注意：你可以等待 contribution-analyzer 完成后读取其输出作为作者列表的输入。"

3. **@collab-risk-analyzer** — 任务指令：同上，但执行协作风险检测
   > "注意：必须读取 .archaeology/report.md（若存在）和 .sop/lessons.md（若存在）。"

### Step 11 — 等待 analyzer 完成

监控 `.team-scope/state.json`，直到三个 agent 全部 done。

### Step 12 — 触发 merge-strategy skill

调用 `merge-strategy` skill 综合三份报告，生成 `.team-scope/report.md`。

### Step 13 — 可选输出生成

#### 13a. 维度评分（仅 --with-scores）

调用 `merge-strategy` skill 的"评分模式"，生成 `.team-scope/scores.md`。

#### 13b. 私聊反馈（仅 --with-private-feedback）

对每位作者，调用 `merge-strategy` skill 的"私聊模式"，生成 `.team-scope/private/<sanitized-name>.md`。

**作者名清理规则**（避免文件名特殊字符）：
- 转小写
- 空格替换为下划线
- 删除特殊字符（保留 a-z、0-9、_、-）
- 例：`"Alice Wong"` → `alice_wong.md`

### Step 14 — 输出报告摘要

```
✅ 团队协作审查完成

文件：.team-scope/report.md
{若 with_scores：'      .team-scope/scores.md'}
{若 with_private_feedback：'      .team-scope/private/ ({N} 位开发者)'}

🎯 团队健康度：{team_health}
🛠️  推荐合并策略：{merge_strategy}

关键风险：
{从 report.md 摘抄前 3 条最高级别风险}

下一步：
{根据 merge_strategy 给出引导}
- merge-now-all：可批量合并
- staged-merge：按推荐顺序分阶段合并
- coordinate-first：先解决人际协调
- block-and-discuss：暂停，召开协调会议
- escalate：上报 lead

📺 启动 TUI 看板查看完整报告：
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/tui/dashboard.sh
   （或执行 /scope-status 查看状态摘要）
```

### Step 15 — flowsmith 协同回写（不修改 .sop/state.json）

co-review **不修改 flowsmith 的状态文件**。
若 `context.flowsmith_task_id` 不为 null，仅在终端输出提示：

```
🔗 关联 flowsmith 任务：{task_id}
   合并完成后建议执行 /sop-close 归档 flowsmith 任务，
   将团队协作经验沉淀到 .sop/lessons.md
```
