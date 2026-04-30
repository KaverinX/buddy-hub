---
description: 初始化项目的 context-keeper 存储（创建 .context/ 骨架与 meta.json）
---

# /context-init — 初始化上下文存储

执行 plugin 内置脚本初始化项目的 `.context/` 目录。这是所有 context-keeper 行为的前置条件。

## 执行步骤

### Step 1 — 调用 CLI

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/context-cli.sh" init
```

### Step 2 — 推荐后续动作

如果项目已经使用过 flowsmith / code-archaeologist / co-review，建议立即执行：

```bash
/context-migrate
```

这会一次性扫描已有的 `.sop/` `.archaeology/` `.team-scope/` 状态文件，
回填等效的 SkillBus 事件，让历史数据在新存储中可查。

### Step 3 — 输出确认

```
✅ context-keeper 已就绪

项目根：{project_root}
存储：  {project_root}/.context

下一步：
- 已有历史数据 → /context-migrate
- 全新项目     → 直接使用其他 plugin 即可，mirror hook 会自动捕获
```

## 拒绝执行的条件

- 不在 git 仓库或工作目录之内（CLI 会以 PWD 为根，但建议在 git 项目内运行）
