---
description: 手动 emit 一条 SkillBus 事件。给其他 plugin 的命令复用，或人工补录历史
argument-hint: --type=X --actor=Y --entity-type=T --entity-id=I [--task=...] [--evidence='[...]'] [--ext='{...}']
---

# /context-emit — 手动发出事件

直接调用 context-cli 的 `emit` 子命令，把一条事件追加到 `.context/events.jsonl`。

主要用途：
- **人工补录**：mirror hook 没覆盖到的场景（例如手动设了红线、人工发现的 risk）
- **跨 plugin 调用**：其他 plugin 的命令脚本里把这一行作为标准协议
- **测试/排错**：发一条已知事件验证物化、查询链路

参数：$ARGUMENTS

## 执行步骤

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" emit $ARGUMENTS
```

## 必需参数

| 参数             | 说明                                          |
|------------------|-----------------------------------------------|
| `--type=X`       | 事件类型，见 `schemas/event-schema.md` 的清单 |
| `--actor=Y`      | 发起方（通常是 plugin name，或 `user`）       |
| `--entity-type=T`| 主语实体类型：task / decision / risk / red_line / lesson / review / report |
| `--entity-id=I`  | 主语实体 id                                   |

## 可选参数

| 参数             | 默认                                     |
|------------------|------------------------------------------|
| `--task=...`     | 关联的 flowsmith task_id（无关联留空）   |
| `--evidence=JSON`| evidence 数组，默认 `[{kind:"manual",note:"context-cli emit"}]` |
| `--ext=JSON`     | plugin 特定扩展，默认 `{}`               |

## 示例

设立红线（人工补录）：
```bash
/context-emit \
  --type=red_line.set \
  --actor=user \
  --task=a3f8c1d2 \
  --entity-type=red_line \
  --entity-id=rl_oauth_userservice \
  --evidence='[{"kind":"manual","note":"discussion in #refactor channel"}]' \
  --ext='{"statement":"不得重命名 UserService.findById","applies_to":[{"kind":"file","path":"src/auth/UserService.java"}],"rationale":"OAuth 模块通过反射调用"}'
```

记一条 lesson：
```bash
/context-emit \
  --type=lesson.recorded \
  --actor=flowsmith \
  --task=a3f8c1d2 \
  --entity-type=lesson \
  --entity-id=lsn_oauth_reflection \
  --evidence='[{"kind":"file","path":".sop/lessons.md"}]' \
  --ext='{"category":"security","statement":"OAuth 集成测试需覆盖反射调用路径","tags":["oauth","auth","reflection"]}'
```

## 校验失败时

CLI 会拒绝以下违例：
- 缺少必需字段
- `type` 命名不符合 `<ns>.<noun>.<verb>` 规范
- `evidence` 是空数组

修正后重试即可，已经写入的事件不会被自动撤销（事件流 append-only）。
