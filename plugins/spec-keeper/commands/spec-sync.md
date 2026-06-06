---
description: 用【当前分支相对基线的实际改动】反向互补 living spec。把分支 diff 推断为行为级 delta（ADDED/MODIFIED/REMOVED），补齐"代码已变但 spec 没跟上"的缺口。适用于直接在分支编码、实现超出原提案、或热修复后的规格回填
argument-hint: [--base=<基线分支>] [--change-id=<复用已有变更>] [--apply]
---

# /spec-sync — 用分支改动互补 spec

参数：$ARGUMENTS

> 定位（与其他 spec 命令的关系）：
> - `/spec-propose`：**正向**——先写 delta 再实现（先对齐）
> - `/spec-bootstrap`：**反向·全量**——为已有项目首次捕获整体 living spec 基线
> - `/spec-sync`：**反向·增量**——用当前分支的实际改动，把 living spec 补齐到与代码一致（本命令）
> - `/spec-check`：只检测漂移、不修改
>
> 何时用：正向流程没走全（直接在分支上改了代码 / 实现时超出原提案范围 / 紧急热修复），导致 living spec 落后于代码现实时。

## 前置读取
1. `../../schemas/spec-schema.md` — delta 与 living spec 格式
2. `../skills/spec-authoring/SKILL.md` — 撰写纪律（描述行为不描述实现、行为可判定、不臆造）
3. `spec/capabilities/`（现有真相；不存在则提示先 `/spec-bootstrap` 建基线，或本命令把全部改动当作 ADDED）

## ⚖️ 关键纪律
- 推断的是**行为变化**，不是文件 diff 的复述
- 吃不准的推断标 `[待确认]`，**绝不臆造**
- 生成的 delta 是**待核对草稿**；未经人工确认不写入 living spec

## 执行步骤

### Step 1 — 确定基线与改动范围
- `base`：优先 `--base=`；否则读 flowsmith `.sop/state.json` 的 `git_context.base_branch`；再否则探测 origin/HEAD→main/master/develop
- `head`：当前分支（`git rev-parse --abbrev-ref HEAD`）
- 非 git 仓库 → 停止并提示（本命令依赖 diff）
- 取改动：`git diff <base>...<head> --stat` 概览 + 按需读取关键文件的 diff

### Step 2 — 把 diff 推断为行为级变化
逐改动判断它对**外部可观测行为**意味着什么：
- 新增路由/接口/分支逻辑/校验/配置项 → 候选 **ADDED**
- 改了已有接口的入参/返回/校验/默认值/错误码 → 候选 **MODIFIED**（写"改前→改后"）
- 删除接口/功能/分支 → 候选 **REMOVED**（含兼容性影响）
- 纯重构/格式化/无行为变化 → **不产生 delta**（仅在汇报里说明"无行为变化的改动 N 处，已忽略"）

### Step 3 — 与现有 living spec 比对，归类到能力
- 把每条候选变化挂到对应 `capabilities/<id>`；涉及全新能力则提议新建能力
- 反向也查：living spec 里某条 R 已无对应代码 → 标记为疑似 REMOVED 或 drift，列入 `[待确认]`
- emit `spec.drift.detected`（每条 spec 与代码不一致项）

### Step 4 — 产出（默认生成待评审 delta，不直接改真相）
- 生成 `spec/changes/sync-<head>-<短hash>/proposal.md`（reverse delta，格式同 /spec-propose），`status=proposed`
  - 若 `--change-id=` 指定，把 delta 并入该已有变更（用于"实现超出原提案范围"的回填场景）
- 列出所有 `[待确认]` 项请用户逐条确认
- emit `spec.synced`（汇总，evidence 指向 `git diff <base>...<head>` 与受影响文件）

### Step 5 —（可选）`--apply` 直接落地
- 仅当带 `--apply` 且用户确认 `[待确认]` 后：直接调用 `/spec-apply` 把 delta 合并进 living spec
- 默认**不**自动 apply——保留"先评审 reverse delta 再成为真相"的把关

### Step 6 — 汇报
```
基线 {base} → 当前 {head}：改动 {n} 文件
推断行为变化：+{a} 新增 / ~{m} 修改 / -{r} 移除（{x} 处无行为变化已忽略）
受影响能力：{caps}
[待确认]：{k}（请核对）
产出：spec/changes/sync-.../proposal.md  {已 --apply 落地 / 待 /spec-apply}
```

## 注意
- 推断来自阅读 diff，是**辅助**，需人工核对 `[待确认]`；带调用链证据的精确提取是 atlas 插件目标，当前未实现。
- 与 flowsmith 协同：`/sop-close` 后若发现实现超出了原 proposal，可对该分支跑 `/spec-sync --change-id=<原变更>` 把额外行为回填进同一变更。
- 不创建 `.sop/` 任务，可独立运行。
