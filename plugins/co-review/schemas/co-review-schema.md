# co-review 工作流契约（Schema）

定义 co-review plugin 运行时的所有数据结构。
所有 command / agent / skill 读写时必须遵循此契约。

---

## `.team-scope/state.json` 结构

```json
{
  "version": "1.0",
  "review_id": "<8 字符随机>",
  "scope": {
    "branch": "<当前分支名，由 git rev-parse --abbrev-ref HEAD 自动获取>",
    "base": "main",
    "mode": "pr | commit",
    "commit_range": "<base>..<HEAD>"
  },
  "options": {
    "with_scores": false,
    "with_private_feedback": false,
    "with_rhythm": false,
    "ci_data_path": null,
    "exclude_patterns": ["*.lock", "package-lock.json", "dist/**", "target/**", "*.min.js", "*.min.css"]
  },
  "context": {
    "trigger": "manual | flowsmith-suggested",
    "flowsmith_task_id": null,
    "has_archaeology": false,
    "archaeology_id": null
  },
  "agents": {
    "contribution-analyzer":  { "status": "pending|running|done|skipped", "output": ".team-scope/contributions.md", "started_at": null, "completed_at": null },
    "completion-analyzer":    { "status": "pending|running|done|skipped", "output": ".team-scope/completion.md",    "started_at": null, "completed_at": null },
    "collab-risk-analyzer":   { "status": "pending|running|done|skipped", "output": ".team-scope/risks.md",         "started_at": null, "completed_at": null }
  },
  "report": {
    "status": "pending|done",
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

## 默认基线规则（关键）

**`scope.branch` 必须由 `git rev-parse --abbrev-ref HEAD` 自动获取，禁止用户传入。**
**`scope.base` 默认 `main`，可通过 `--base=<branch>` 显式指定**。

`/scope-review` 不接受位置参数指定分支。这是设计原则：
- 用户在哪个分支上，就分析哪个分支
- 避免误分析其他分支造成的认知偏差
- 若需对比两分支差异，使用 `/scope-compare <a> <b>`

若当前分支等于 base 分支：
> "当前在 base 分支（{branch}）上，没有未合并改动可分析。
>  请先切换到 feature 分支，或使用 --base=<其他分支> 指定不同基线。"
> 停止执行。

## 合法状态迁移

```
INIT       → ANALYZING       条件：/scope-review 执行
ANALYZING  → SYNTHESIZING    条件：3 个 analyzer 全部 done 或 skipped
SYNTHESIZING → DONE          条件：report.md 生成
DONE       → ARCHIVED        条件：/scope-close 执行（v1.1+ 提供）
```

## 合法 merge_strategy

- `merge-now-all`     — 所有人代码独立完成，无冲突，可批量合并
- `staged-merge`      — 分阶段合并，按依赖顺序
- `coordinate-first`  — 必须先解决人际协调（如 A 改了 B 的接口）
- `block-and-discuss` — 存在违反红线/重蹈覆辙，必须暂停讨论
- `escalate`          — 团队级问题，需 lead 介入

## 合法 team_health

- `🟢 healthy`    — 协作健康，无显著风险
- `🟡 warning`    — 存在协调点，需关注
- `🔴 unhealthy`  — 存在显著风险，需介入
- `⛔ critical`   — 涉及红线违反或重蹈覆辙，必须暂停

## 与 flowsmith 的字段互通

当 `/scope-review` 由 flowsmith 的 review-completion hook 建议触发时：
- `context.trigger = "flowsmith-suggested"`
- `context.flowsmith_task_id = <sop state.task_id>`

co-review 完成后**不主动修改** `.sop/state.json`。
flowsmith 的状态机由 flowsmith 自己负责，co-review 只读不写。

## 与 code-archaeologist 的字段互通

若项目存在 `.archaeology/state.json` 且 `report.status = "done"`：
- `context.has_archaeology = true`
- `context.archaeology_id = <archaeology_id>`
- collab-risk-analyzer 必须读取 `.archaeology/report.md` 中的"不可跨越的红线"

## stats 字段计算规则

**authors_count**：去重后的作者数。去重规则：
- 邮箱 case-insensitive 匹配
- 邮箱 local-part 相同视为同人（如 `alice@personal.com` 和 `alice@company.com`）

**commits_count**：排除合并 commit（父 commit > 1）后的数量

**loc_added/removed**：
- 排除 `options.exclude_patterns` 匹配的文件
- 排除合并 commit 的统计
