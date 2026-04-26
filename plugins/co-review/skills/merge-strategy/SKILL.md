---
name: merge-strategy
description: 合并策略生成器。综合 contribution-analyzer / completion-analyzer / collab-risk-analyzer 三份报告，应用决策矩阵生成最终团队报告（report.md）。同时根据 options 决定是否生成评分报告（scores.md）和私聊反馈（private/<author>.md）。由 /scope-review 命令触发。
---

# 合并策略生成（merge-strategy）

## 前置读取

按顺序读取：
1. `${CLAUDE_PLUGIN_ROOT}/schemas/co-review-schema.md` — 状态机规则
2. `${CLAUDE_PLUGIN_ROOT}/schemas/report-schemas.md` — 报告格式
3. `reference/scoring-rubric.md` — 评分维度定义（仅 --with-scores 时使用）
4. `reference/merge-decision-tree.md` — 合并策略决策树
5. `reference/private-feedback-tone.md` — 私聊反馈语气与边界规范
6. `.team-scope/state.json` — 当前审查上下文
7. `.team-scope/contributions.md`
8. `.team-scope/completion.md`
9. `.team-scope/risks.md`

---

## Phase 1 — 主报告生成（必做）

### Step 1 — 团队健康度判定

依据 `reference/merge-decision-tree.md` 中的规则：

**优先级评估顺序**（取第一个匹配的等级）：

| 条件 | team_health |
|------|------------|
| 存在 ⛔ critical 风险（违反考古红线）| ⛔ critical |
| 完成度 = 🔴 低 OR 协作风险 ≥ 3 条 🔴 高 | 🔴 unhealthy |
| 完成度 = 🟡 中 OR 协作风险 ≥ 1 条 🔴 高 OR 重蹈覆辙 ≥ 1 条 | 🟡 warning |
| 其他 | 🟢 healthy |

### Step 2 — 合并策略推荐

依据 `reference/merge-decision-tree.md` 的决策树：

| team_health | 其他条件 | merge_strategy |
|-------------|---------|---------------|
| ⛔ critical | 任何情况 | block-and-discuss |
| 🔴 unhealthy | 涉及多人 + 接口契约不一致 | coordinate-first |
| 🔴 unhealthy | 仅单人完成度低 | escalate（或 staged-merge 视情况） |
| 🟡 warning | 改动可拓扑排序 | staged-merge |
| 🟡 warning | 改动相互独立 | merge-now-all（带检查项）|
| 🟢 healthy | 完全独立 | merge-now-all |

### Step 3 — 推荐合并顺序（拓扑排序）

将每个 PR/作者作为节点，构造依赖关系：
- A 改了的接口被 B 调用 → A 的合并优先于 B
- A 引入新模块，B 引用了该模块 → A 的合并优先于 B
- A 与 B 改动完全无交集 → 任意顺序

输出拓扑排序结果。若有环，标记为"循环依赖，需要协调"，建议 `coordinate-first`。

### Step 4 — 合并前检查清单

根据 merge_strategy 生成可执行的检查项。每项必须：
- 可打勾（明确的完成标准）
- 可归因（指明谁负责）
- 必要（不做就有重大风险）

示例：
- [ ] @Bob 修复 IDOR 漏洞 [R-1]（违反考古红线，最高优先级）
- [ ] @Alice 和 @Carol 共同 review types/user.ts 第 12-18 行
- [ ] @Bob 完成 src/notification/email.ts 中的 5 处 TODO 或转化为追踪 issue
- [ ] @Bob 删除 src/notification/router.ts:23 的 console.log

### Step 5 — 个人行动建议（针对每位开发者）

**这是你强调的关键点：行动建议是针对个人的**。

但**约束**：
- 仅描述事实和具体行动项
- 不评判态度
- 不做横向对比
- 不下"做得好/不好"的判断

格式（在主报告中）：

```markdown
### {author_name} — 建议
- {做得到位的事实，1-2 条，客观描述}
- {可改进的事实，0-3 条，客观描述}
- **行动项**：
  - {具体可执行的行动，每条独立可打勾}
```

### Step 6 — 写入 report.md

按 `report-schemas.md` 中 `report.md` 格式生成完整报告，写入 `.team-scope/report.md`。

### Step 7 — 回写 state.json

更新 `state.json`：
```json
{
  "report": {
    "status": "done",
    "merge_strategy": "<策略名>",
    "team_health": "<等级>"
  }
}
```

---

## Phase 2 — 维度评分报告（仅 options.with_scores = true）

### Step 1 — 读取评分规则

读取 `reference/scoring-rubric.md`，获取 4 个评分维度的具体规则。

### Step 2 — 对每位开发者打分

四个维度独立评分，每个维度只有 🟢/🟡/🔴 三档（不给数值评分）：

1. **完成度**：从 completion.md 的等级直接映射
2. **协作健康**：基于 risks.md 中该作者参与的风险数量与等级
3. **边界遵守**：基于 contributions.md 中该作者的越界提交比例
4. **经验吸收**：基于 risks.md 中该作者重蹈覆辙的次数

### Step 3 — 评分依据必须有证据

每项打分都附**具体证据**。禁止"没有理由的分数"。

示例：
> Alice
> - 完成度 🟢 高：4/4 改动文件有测试 + 0 TODO + 0 调试遗留
> - 协作健康 🟢 高：接口变更通知了所有调用方
> - ...

### Step 4 — 写入 scores.md

按 `report-schemas.md` 中 `scores.md` 格式输出，写入 `.team-scope/scores.md`。

**强制声明**：
- 文件头必须包含"⚠️ 仅供团队回顾参考，不应用于个人绩效考核"
- 文件尾必须包含"评分局限性声明"

---

## Phase 3 — 私聊反馈（仅 options.with_private_feedback = true）

### Step 1 — 读取语气规范

读取 `reference/private-feedback-tone.md`，严格遵循：
- 中立 + 建设性基调
- 不做横向对比
- 不评判态度
- 不出现其他作者信息

### Step 2 — 创建 private 目录

```bash
mkdir -p .team-scope/private
```

### Step 3 — 对每位作者生成独立文件

文件名清理规则（`scope-review.md` 中已说明）：
- 转小写
- 空格替换为下划线
- 删除特殊字符（保留 a-z、0-9、_、-）

文件路径：`.team-scope/private/<sanitized-name>.md`

### Step 4 — 内容生成

按 `report-schemas.md` 中 `private/<author>.md` 格式生成。

**严格约束**：
- 文件头强制包含三条警告（不应公开传播 / 仅个人参考 / 自动生成局限性）
- "做得到位的地方"：客观事实，不煽动表扬
- "可以改进的地方"：基于客观证据的具体行动项，不评判态度
- "与他人的协调点"：仅描述需要协调的事实，**禁止出现他人评价**
- "历史经验参考"：从 lessons.md 筛选与该作者本次工作相关的经验
- 文件尾再次强制声明三条警告

### Step 5 — 输出确认

向调用方报告：
```
✅ 私聊反馈生成完成

文件位置：.team-scope/private/
- alice_wong.md
- bob_smith.md
- carol_chen.md

⚠️ 提示：建议将 .team-scope/private/ 加入 .gitignore，
   避免私聊反馈被提交到代码库。
```

---

## 重要约束

- Phase 1（主报告）必做
- Phase 2 仅在 with_scores = true 时执行
- Phase 3 仅在 with_private_feedback = true 时执行
- 所有评分必须有证据
- 所有行动项必须可执行
- 私聊反馈严格隔离，不包含他人对比
- 不修改任何源代码
