# buddy-hub

> Velpro 的 Claude Code Plugin Marketplace

专注于开发者工作流、代码质量、多 agent 协作的 Claude Code 插件集合。

---

## 安装 Marketplace

```bash
# 在 Claude Code 中执行
/plugin marketplace add KaverinX/buddy-hub
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
/plugin install flowsmith@buddy-hub
```

详见 [flowsmith README](./plugins/flowsmith/README.md)。

---

## Marketplace 结构

```
buddy-hub/
├── .claude-plugin/
│   └── marketplace.json                  # Marketplace 元信息
└── plugins/
    └── flowsmith/                        # SOP 工作流插件
```

---

## 后续规划

更多 plugin 即将加入：
- `code-archaeologist` — 老代码考古与重构辅助（规划中）
- `release-captain` — 自动化发版流程编排（规划中）

欢迎在 issues 中提建议或贡献新 plugin。

---

## 作者

**Velpro**
Email: [xvelpro8@gmail.com](mailto:xvelpro8@gmail.com)

---

## License

MIT © Velpro
