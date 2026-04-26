---
description: 查看当前团队协作审查的进度与状态
---

# /scope-status — 审查状态

## 执行步骤

### Step 1 — 读取状态

读取 `.team-scope/state.json`。
若不存在：
> "未找到 .team-scope/state.json，当前没有进行中的审查。
>  执行 /scope-review 开始新审查。"
> 停止。

### Step 2 — 输出状态报告

```
🔍 团队协作审查状态
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID：{review_id}
分支：{scope.branch} → {scope.base}
模式：{scope.mode}

─── 协同上下文 ───

  flowsmith：{context.flowsmith_task_id 或 '无'}
  考古：{若 has_archaeology：archaeology_id 否则：'无'}
  触发：{context.trigger}

─── 启用选项 ───

  维度评分：{✅ 启用 / ❌ 关闭}
  私聊反馈：{✅ 启用 / ❌ 关闭}
  工作节奏：{✅ 启用 / ❌ 关闭（v1 仅占位）}

─── 分析员进度 ───

  📊 contribution-analyzer  {icon}  {status}  {duration 或 -}
  ✅ completion-analyzer    {icon}  {status}  {duration 或 -}
  🛡️  collab-risk-analyzer  {icon}  {status}  {duration 或 -}

─── 报告状态 ───

  状态：{report.status}
  团队健康度：{report.team_health 或 '待生成'}
  推荐合并策略：{report.merge_strategy 或 '待生成'}

─── 数据统计（若已分析）───

  作者数：{stats.authors_count}
  Commits：{stats.commits_count}
  文件改动：{stats.files_changed}
  代码量：+{stats.loc_added} / -{stats.loc_removed}

─── 产出文件 ───

  {对每个 .team-scope/*.md 输出存在性、大小、最后修改时间}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
下一步：{根据当前状态给出引导}
```

状态图标对照：
- `pending`  → ⬜
- `running`  → ⏳
- `done`     → ✅
- `skipped`  → ⏭️

### Step 3 — 引导下一步

| 当前情况 | 引导 |
|---------|------|
| 任一 analyzer 状态为 running | "等待 analyzer 完成。可执行 bash ${CLAUDE_PLUGIN_ROOT}/scripts/tui/dashboard.sh 查看实时看板" |
| 所有 analyzer done，report pending | "三个分析员已完成。merge-strategy 应正在生成最终报告" |
| report done | "查看完整报告：cat .team-scope/report.md\n或启动 TUI 看板：bash ${CLAUDE_PLUGIN_ROOT}/scripts/tui/dashboard.sh" |
| report archived | "本次审查已归档" |
