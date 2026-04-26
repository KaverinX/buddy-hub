---
description: 对比两个分支之间的团队协作差异（适用于 PR review 前的对比分析）
argument-hint: <branch-a> <branch-b>
---

# /scope-compare — 跨分支协作对比

参数：$ARGUMENTS

## 用途

`/scope-review` 默认分析"当前分支 → base"。
本命令用于分析"分支 A → 分支 B"，适用于：
- PR review 前对比两个 feature 分支
- 评估"如果合并 A 进 B 会有什么协作风险"
- 对比两个候选分支选择更合适的合并目标

## 执行步骤

### Step 1 — 解析参数

必需：两个分支名 `<branch-a>` `<branch-b>`

若未提供：
> "用法：/scope-compare <branch-a> <branch-b>
>  示例：/scope-compare feature/auth feature/refactor-base"
> 停止。

### Step 2 — 校验两分支存在

```bash
git rev-parse --verify "${BRANCH_A}" >/dev/null 2>&1
git rev-parse --verify "${BRANCH_B}" >/dev/null 2>&1
```

若任一不存在：明确提示后停止。

### Step 3 — 切换到 BRANCH_A 并设置 BRANCH_B 为基线

```bash
ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git checkout "${BRANCH_A}"
```

转发到 `/scope-review --base="${BRANCH_B}"`，由它完成实际分析。

### Step 4 — 分析完成后切回原分支

```bash
git checkout "${ORIGINAL_BRANCH}"
```

### Step 5 — 输出说明

```
✅ 跨分支对比完成

对比方向：{BRANCH_A} → {BRANCH_B}
（若 {BRANCH_A} 合并进 {BRANCH_B}，团队会面临的协作情况）

报告位置：.team-scope/report.md
已切回原分支：{ORIGINAL_BRANCH}
```

## 重要约束

- 切换分支前必须确保工作区干净，否则提示用户先 stash
- 异常情况下仍要保证切回原分支（用 trap）
- 本命令本质上是 /scope-review 的封装，不重复实现分析逻辑
