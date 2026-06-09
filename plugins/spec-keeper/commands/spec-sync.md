---
description: 用【当前分支相对基线的实际改动】反向互补真相 spec。把分支 diff 推断为 OpenSpec 行为级 delta（独立 specs/<domain>/spec.md，ADDED/MODIFIED/REMOVED + Scenario），补齐"代码已变但 spec 没跟上"的缺口
argument-hint: [--base=<基线分支>] [--change-id=<复用已有变更>] [--apply]
---

# /spec-sync — 用分支改动互补 spec（OpenSpec 格式）

参数：$ARGUMENTS

> - `/spec-propose`：正向——先写 delta 再实现
> - `/spec-bootstrap`：反向·全量——首次捕获整体真相基线
> - `/spec-sync`：反向·增量——用当前分支实际改动把真相补齐到与代码一致（本命令）
> - `/spec-check`：只检测漂移、不修改
> - `/spec-align`：换格式/位置（旧版 spec/ → openspec/），不读代码

## 前置读取
1. `schemas/spec-schema.md` — OpenSpec delta 与真相格式
2. `../skills/spec-authoring/SKILL.md` — 撰写纪律
3. `openspec/specs/`（不存在则提示先 `/spec-bootstrap`；只有旧版则先 `/spec-align`）

## ⚖️ 关键纪律
- 推断**行为变化**，不是文件 diff 复述。吃不准标 `[待确认]`，绝不臆造。
- 生成的 delta 是**待核对草稿**，未经人工确认不写入真相。

## 执行步骤

### Step 1 — 确定基线与改动范围
- `base`：优先 `--base=`；否则读 flowsmith `.sop/state.json` 的 `git_context.base_branch`；再否则探测 origin/HEAD→main/master/develop。
- `head`：`git rev-parse --abbrev-ref HEAD`。非 git 仓库 → 停止提示。
- 取改动：`git diff <base>...<head> --stat` 概览 + 按需读关键文件 diff。

### Step 2 — 把 diff 推断为行为级变化
- 新增路由/接口/分支/校验/配置 → 候选 **ADDED**
- 改已有接口入参/返回/校验/默认值/错误码 → 候选 **MODIFIED**（写改前→改后）
- 删接口/功能/分支 → 候选 **REMOVED**（含兼容性影响）
- 纯重构/格式化/无行为变化 → 不产生 delta（仅在汇报里说明已忽略 N 处）

### Step 3 — 归类到 domain，反向也查漂移
- 把每条候选变化挂到对应 `openspec/specs/<domain>`；涉及全新能力则提议新 domain。
- 真相里某 Requirement 已无对应代码 → 标疑似 REMOVED 或 drift，列入 `[待确认]`。
- emit `spec.drift.detected`（每条 spec↔代码 不一致项）。

### Step 4 — 产出（默认生成待评审 delta，独立文件）
- 生成 `openspec/changes/sync-<head>-<短hash>/`，含 `proposal.md`（Intent/Scope/Approach）+ `specs/<domain>/spec.md`（reverse delta，格式同 §3）+ `.openspec.yaml`(status=proposed)。
  - 若 `--change-id=` 指定，把 delta 并入该已有变更的 `specs/<domain>/spec.md`。
- 每条 ADDED/MODIFIED 需求补 ≥1 个 Scenario（依据 diff 综合 happy path）。
- 列出所有 `[待确认]`。emit `spec.synced`（evidence 指向 `git diff <base>...<head>`）。

### Step 5 —（可选）`--apply` 直接落地
仅当带 `--apply` 且用户确认 `[待确认]` 后，调用 `/spec-apply` 把 delta 合并进真相。默认**不**自动 apply。

### Step 6 — 汇报
```
基线 {base} → 当前 {head}：改动 {n} 文件
推断行为变化：+{a} 新增 / ~{m} 修改 / -{r} 移除（{x} 处无行为变化已忽略）
受影响 domain：{domains}
[待确认]：{k}（请核对）
产出：openspec/changes/sync-.../（proposal + 独立 delta）  {已 --apply 落地 / 待 /spec-apply}
```

## 注意
- 推断来自阅读 diff，需人工核对 `[待确认]`。
- 与 flowsmith：`/sop-close` 后若实现超出原 proposal，可对该分支跑 `/spec-sync --change-id=<原变更>` 回填进同一变更。
