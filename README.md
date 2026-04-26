# buddy-hub

> Velpro 的 Claude Code Plugin Marketplace

专注于开发者工作流、代码质量、多 agent 协作的 Claude Code 插件集合。

---

## 快速开始

### 安装 Marketplace

```bash
claude plugin marketplace add KaverinX/buddy-hub
```

### 更新 Marketplace

```bash
claude plugin marketplace update KaverinX/buddy-hub
```

### 卸载 Marketplace

```bash
claude plugin marketplace remove KaverinX/buddy-hub
```

---

## 插件管理

安装 Marketplace 后，可以管理其中的单个插件：

```bash
# 安装插件
claude plugin install flowsmith@buddy-hub

# 更新插件
claude plugin update flowsmith@buddy-hub

# 卸载插件
claude plugin uninstall flowsmith@buddy-hub

# 查看已安装插件
claude plugin list
```

---

## 当前可用插件

### 🔨 [flowsmith](./plugins/flowsmith) — 状态机驱动的开发 SOP 工作流

强制执行五阶段开发流程：**规划 → 架构 → 编码 → 优化 → 三层并行审查**，支持知识沉淀与跨任务经验积累。

**核心特性**：
- 状态机驱动，禁止跳阶段
- 4 个 Subagent（独立上下文）：optimizer + 3 个专职 reviewer
- 3 个 Skill 引导规划/架构/编码阶段
- Hook 自动校验状态合法性
- 跨任务经验沉淀到 `.sop/lessons.md`

**安装**：
```bash
claude plugin install flowsmith@buddy-hub
```

详见 [flowsmith README](./plugins/flowsmith/README.md)。

### 🔍 [code-archaeologist](./plugins/code-archaeologist) — 老代码考古与重构辅助

在重构、拆分或删除遗留代码前，派遣三个独立考古员（时间、空间、意图）进行深度尽调，识别隐式依赖与历史设计动机。

**核心特性**：
- 三维度并行分析：History + Dependency + Intent
- 自动识别反射、配置驱动等隐式调用
- 考古结论自动注入 flowsmith 任务约束
- 经验沉淀至 lessons.md，防止重蹈覆辙

**安装**：
```bash
claude plugin install code-archaeologist@buddy-hub
```

### 👥 [co-review](./plugins/co-review) — 团队协作审查工具

针对多人协作场景的横向审查。当多位开发者在同一分支工作时，分析团队协作健康度、接口冲突风险与完成度。

**核心特性**：
- 3 个 Subagent 独立审视：贡献画像、完成度、协作风险
- 自动识别跨人接口签名变更通知
- 纯终端 TUI 看板，支持私聊反馈模式
- 输出可执行的合并策略建议

**安装**：
```bash
claude plugin install co-review@buddy-hub
```

---

## Marketplace 结构

```
buddy-hub/
├── .claude-plugin/
│   └── marketplace.json                  # Marketplace 元信息
└── plugins/
    ├── flowsmith/                        # SOP 工作流插件
    ├── code-archaeologist/               # 老代码考古插件
    ├── co-review/                        # 团队协作审查插件
    └── formatter/                        # 代码格式化插件
```

---

## 后续规划

更多 plugin 即将加入：
- `release-captain` — 自动化发版流程编排（规划中）
- `knowledge-base-v2` — 增强型跨项目经验检索（规划中）

欢迎在 issues 中提建议或贡献新 plugin。

---

## 作者

**Velpro**
Email: [xvelpro8@gmail.com](mailto:xvelpro8@gmail.com)

---

## License

MIT © Velpro
