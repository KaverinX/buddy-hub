---
description: 归档一个已落地的变更，收尾 change 文件夹（living spec 此时已是新真相）
argument-hint: <change-id>
---

# /spec-archive — 归档变更

参数：$ARGUMENTS

## 执行步骤
1. 校验 change `status = applied`（未 apply 的不可归档，提示先 /spec-apply）
2. change `status` → `archived`
3. 可选：把 change 文件夹移入 `spec/changes/_archived/`（保留可追溯，不污染活跃列表）
4. emit `spec.archived`（若 context-keeper 已定义；未定义则跳过，遵守"只追加"演进规则）
5. 汇报：该变更已归档，living spec 已反映其结果

## 注意
归档不等于删除——delta 历史在 change 文件夹与 context-keeper 事件流里永久可查。
