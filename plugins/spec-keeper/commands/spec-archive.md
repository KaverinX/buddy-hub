---
description: 归档一个已落地的变更，把 change 文件夹移入 openspec/changes/archive/<日期>-<id>/（真相 spec 此时已是新状态）
argument-hint: <change-id>
---

# /spec-archive — 归档变更

参数：$ARGUMENTS

## 执行步骤
1. 校验 `.openspec.yaml.status = applied`（未 apply 的不可归档，提示先 `/spec-apply`）。
2. 把整个 `openspec/changes/<change-id>/` 移到 `openspec/changes/archive/<YYYY-MM-DD>-<change-id>/`（日期取归档当日）。
3. `.openspec.yaml.status` → `archived`。
4. emit `spec.archived`（evidence 指向归档前后路径；若 context-keeper 未定义该事件则跳过，遵守"只追加"演进规则）。
5. 汇报：该变更已归档至 `changes/archive/`，真相 spec 已反映其结果。

## 注意
- 归档目录带**日期前缀**（与 OpenSpec 一致），便于审计时间线。
- 归档不等于删除——delta 历史在 archive 文件夹与 context-keeper 事件流里永久可查。
