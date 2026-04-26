---
description: 查看当前 SOP 任务的精确执行状态
---

# /sop-status — 任务状态报告

## 执行步骤

### Step 1 — 读取状态

读取 `.sop/state.json`。若文件不存在，输出：
> "未找到 .sop/state.json，当前没有进行中的任务。
> 执行 /sop-init <任务描述> 开始新任务。"
> 停止执行。

### Step 2 — 输出状态报告

```
📋 SOP 任务状态
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

任务：{task_summary}
ID：{task_id}    第 {iteration} 轮    版本：{version}

─── 阶段进度 ───

  [1] PLANNING       {icon}  {status}  {completed_at 或 -}
  [2] ARCHITECTURE   {icon}  {status}  {completed_at 或 -}
  [3] IMPLEMENTATION {icon}  {status}  {completed_at 或 -}
  [4] OPTIMIZATION   {icon}  {status}  {completed_at 或 -}
  [5] REVIEW         {icon}  {status}  {completed_at 或 -}

─── 问题追踪 ───

  未解决 Critical：{count} 个
  {若有，列出：
    - [C-1] {description} @ {location}（来源：{source_reviewer}）
  }

─── 产出文件 ───

  {对每个 .sop/*.md 文件，输出大小与最后修改时间}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
当前：{current_phase}
下一步：{根据 current_phase 给出的操作提示，与 sop-resume 的引导表保持一致}
```

状态图标对照：
- `pending`  → ⬜
- `running`  → ⏳
- `done`     → ✅
- `skipped`  → ⏭️
- `failed`   → 🔴

### Step 3 — 健康检查

附加在状态报告末尾，若发现以下异常情况则输出警告：

- `PLANNING.status = done` 但 `.sop/plan.md` 不存在 → ⚠️ 状态文件与产出不一致
- `current_phase = DONE` 但 `open_issues` 中有 `status = "open"` 的 Critical → ⚠️ 数据异常
- `state.json` 中 `version` 字段缺失 → ⚠️ state.json 来自旧版，建议手动迁移
