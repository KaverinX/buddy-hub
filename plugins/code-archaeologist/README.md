# code-archaeologist — Claude Code Plugin

> 由 [Velpro](mailto:xvelpro8@gmail.com) 开发，发布在 [buddy-hub](https://github.com/KaverinX/buddy-hub) marketplace。

**遗留代码考古工具**。在你重构、拆分、改名、删除任何遗留代码之前，
先派遣三个独立考古员对它做一次彻底的尽调。

> "你不是不能动它——你是不知道它**为什么**长这样。"

---

## 设计哲学

重构事故 90% 来自三类错误判断：

1. **历史盲点**：不知道这段代码当初为什么这么写
2. **依赖盲点**：以为没人用，结果某个反射调用炸了
3. **意图盲点**：删掉一段"看起来冗余"的代码，结果是历史 bug 的修复

`code-archaeologist` 用三个**独立上下文**的 subagent，分别从这三个维度做尽调：

```
┌─────────────────────────────────┐
│  📜 history-archaeologist       │  时间维度：git 演化追溯
│  🕸️  dependency-archaeologist   │  空间维度：影响半径分析
│  💭 intent-archaeologist        │  意图维度：设计动机反推
└─────────────────────────────────┘
              ↓
   refactor-strategy skill 综合
              ↓
        report.md 推荐策略
```

输出一份**可执行的尽调报告**——不只是"有这些风险"，而是"该怎么办"。

---

## 与 flowsmith 的深度协同

这是 buddy-hub 生态的核心价值：**plugin 不是孤立工具，而是协同工作流**。

### 主动检测：flowsmith 写规划时自动提示

当 flowsmith 的 `/sop-init` 任务描述中包含"重构 / 拆分 / 迁移"等关键词时，
本插件的 `PostToolUse` hook 会自动提示：

> 💡 检测到重构关键词。强烈建议先执行 `/arch-init <目标>` 做考古。

### 双向回传：考古结论自动注入 plan.md

`/arch-report` 完成后，若检测到 flowsmith 任务上下文，会自动调用 `/arch-handoff`：
- 风险评级、推荐策略、不可跨越的红线、前置条件清单
- 全部注入到 `.sop/plan.md` 的"约束与前提"章节
- flowsmith 后续的架构、编码、审查阶段都能感知这些约束

### 共享知识库：lessons.md 的双向沉淀

```
flowsmith /sop-close ─┐
                      ├──→ .sop/lessons.md ←──┬─ /arch-init 启动时读取
code-archaeologist /arch-close ─┘             └─ /sop-init 启动时读取
```

每次考古完成后，项目级设计约定、风险模式、隐式依赖类型分布等经验
全部沉淀到 flowsmith 的 lessons.md，下次任意 plugin 启动新任务都能引用。

---

## 安装

### 方式一：从 buddy-hub Marketplace 安装（推荐）

```bash
claude plugin marketplace add KaverinX/buddy-hub
claude plugin install code-archaeologist@buddy-hub
```

### 方式二：本地安装

```bash
git clone https://github.com/KaverinX/buddy-hub.git ~/buddy-hub
claude plugin install ~/buddy-hub/plugins/code-archaeologist
```

---

## 命令清单

| 命令 | 用途 |
|------|------|
| `/arch-init <target>` | 启动考古，派遣三个 agent |
| `/arch-status` | 查看考古进度 |
| `/arch-resume` | 恢复中断的考古 |
| `/arch-report` | 综合三个 agent 输出，生成最终报告 |
| `/arch-handoff` | 将考古结论注入 flowsmith plan.md（通常自动触发）|
| `/arch-close` | 归档考古，沉淀经验到 lessons.md |

---

## 使用示例

### 场景 1：独立使用（无 flowsmith）

```bash
# 1. 启动考古
/arch-init src/auth/UserService.java --intent=refactor

# Claude 会派遣三个考古员，等待完成后...

# 2. 生成报告
/arch-report

# 输出：
#   🎯 风险评级：🟡 medium
#   🛠️  推荐策略：staged-refactor
#   关键发现：
#   - findById 方法被反射调用，重命名会破坏 OAuth 模块
#   - 原作者已离职，缺乏对 commit abc123 的修复历史的了解
#   - 与 OrderService 共享一套缓存预热模式，重构需统一考虑

# 3. 归档
/arch-close

# 经验自动写入 .sop/lessons.md（即使未安装 flowsmith 也会创建）
```

### 场景 2：与 flowsmith 协同

```bash
# 1. 启动 flowsmith 任务（用了"重构"关键词）
/sop-init 重构 UserService 的认证逻辑，拆分为独立的 AuthService

# 进入 PLANNING 阶段，Claude 写入 .sop/plan.md
# code-archaeologist 的 hook 触发：
#   💡 检测到重构关键词。建议先执行 /arch-init src/auth/UserService.java

# 2. 听从建议，做考古
/arch-init src/auth/UserService.java --intent=extract

# 三个考古员完成后...

# 3. 生成报告
/arch-report

# 因为检测到 flowsmith 上下文，自动调用 arch-handoff：
#   🔗 已自动注入到 flowsmith 任务 a3f8c1d2 的 plan.md

# 4. 回到 flowsmith 流程
# .sop/plan.md 的"约束与前提"章节已包含考古结论
# 后续的 arch-design、implementation 阶段都会引用这些约束
# reviewer 会按照"不可跨越的红线"检查实现

# 5. 双归档
/arch-close   # 考古经验 → lessons.md
/sop-close    # flowsmith 经验 → lessons.md（追加）
```

---

## 目录结构

```
code-archaeologist/
├── .claude-plugin/plugin.json
├── README.md / LICENSE
├── commands/                          # 6 个命令
│   ├── arch-init.md
│   ├── arch-status.md
│   ├── arch-resume.md
│   ├── arch-report.md
│   ├── arch-handoff.md                # ⭐ flowsmith 集成
│   └── arch-close.md
├── agents/                            # 3 个独立上下文 subagent
│   ├── history-archaeologist.md       # 📜 时间维度
│   ├── dependency-archaeologist.md    # 🕸️ 空间维度
│   └── intent-archaeologist.md        # 💭 意图维度
├── skills/
│   └── refactor-strategy/             # 综合策略生成器
│       ├── SKILL.md
│       └── reference/
│           └── decision-matrix.md     # 风险评级与策略推荐规则
├── schemas/                           # 数据契约
│   ├── archaeology-schema.md          # state.json 结构
│   └── report-schemas.md              # 各报告格式
├── hooks/
│   └── hooks.json                     # ⭐ flowsmith 协同的主动检测
└── scripts/
    └── detect-refactor-intent.sh      # PostToolUse hook 实现
```

项目仓库产出（建议纳入 git）：

```
your-project/
└── .archaeology/
    ├── state.json                     # 考古状态
    ├── history.md                     # 历史考古报告
    ├── blast-radius.md                # 影响范围报告
    ├── intent.md                      # 意图考古报告
    └── report.md                      # 综合报告 ⭐
```

---

## 配置开关

| 环境变量 | 默认 | 作用 |
|---------|-----|------|
| `BUDDY_ARCH_AUTO_SUGGEST` | `1` | flowsmith plan.md 包含重构关键词时自动提示。设为 `0` 关闭 |

---

## 设计原则

**1. 多 agent 独立上下文**
三个考古员独立运行，避免相互思路污染。意图考古员可读历史考古结果作为参考。

**2. 三假设分析法**
意图考古强制使用"历史包袱 / 必要防御 / 性能优化"三假设，避免单一推断的偏误。

**3. 隐式依赖优先**
依赖考古重点找 IDE 检测不到的反射、序列化、配置、字符串构造——这才是事故源头。

**4. 决策矩阵 + 覆盖规则**
策略推荐既有矩阵化的快速规则，也有覆盖规则处理特殊情况（如外部 API 暴露强制 escalate）。

**5. 协同但不依赖**
本 plugin 可独立使用。安装 flowsmith 后获得深度集成，但不安装也能工作。

---

## 系统要求

- Claude Code v2.1+
- Git（必需，考古的核心数据源）
- jq（推荐，用于 hook 中解析 JSON）
- 项目必须是 git 仓库

---

## License

MIT © Velpro
