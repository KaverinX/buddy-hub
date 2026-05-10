---
description: 查看 context-keeper 当前状态（事件数、实体数、最近事件、最后迁移时间）
---

# /context-status — 上下文存储状态

打印项目级 context store 的当前状态摘要。

## 执行步骤

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" status
```

## 输出格式

```
context-keeper 状态
  根目录:       <project_root>
  存储:         <project_root>/.context
  schema:       1
  事件数:       42
  最后事件:     evt_xxxxxxxxxxx
  最后迁移:     2026-04-28T...
  实体快照:
    task        3
    red_line    2
    lesson      8
```

## 故障排查

- 若提示 "依赖 jq 未安装"：参考 `brew install jq` / `apt install jq`
- 若 `.context/` 不存在：先执行 `/context-init`
- 若事件数为 0 但 `.sop/` 等目录非空：执行 `/context-migrate` 回填
