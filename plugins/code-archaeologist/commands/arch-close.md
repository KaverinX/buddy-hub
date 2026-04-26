---
description: 归档考古任务，将考古经验沉淀到 flowsmith 的 lessons.md（若可用）
---

# /arch-close — 考古归档

## 执行步骤

### Step 1 — 前置检查

读取 `.archaeology/state.json`：
- `report.status` 必须为 `"done"`，否则：
  > "考古报告尚未生成。请先执行 /arch-report。"
  > 停止。

- 若已归档（`archived_at != null`）：
  > "本次考古已归档于 {archived_at}，无需重复归档。"
  > 停止。

### Step 2 — 提炼经验（内部推导，不输出）

读取以下文件，思考"本次考古最值得未来类似任务参考的经验"：

- `.archaeology/history.md`
- `.archaeology/blast-radius.md`
- `.archaeology/intent.md`
- `.archaeology/report.md`

提炼维度：
1. **方法论经验**：本次考古中哪些技巧/工具用得好？哪些不好？
2. **领域知识**：本次考古发现了哪些项目特定的设计约定？
3. **风险模式**：哪些"看似无害实则危险"的情况是这次发现的？
4. **跨任务复用**：哪些发现对未来其他模块的考古/重构有启发？

### Step 3 — 沉淀到 .sop/lessons.md（核心协同）

**前提**：`.sop/lessons.md` 存在（说明 flowsmith 已安装并被使用过）。

若不存在 `.sop/`：
- 创建空的 `.sop/lessons.md`
- 这样即使用户尚未用过 flowsmith，考古经验也能被未来的 flowsmith 任务利用
- 输出提示：
  > "💡 检测到项目尚未安装/使用 flowsmith。
  > 已为你创建 .sop/lessons.md，未来安装 flowsmith 后可自动利用本次考古经验。"

追加内容到 `.sop/lessons.md`（不覆盖历史）：

```markdown

---

## 考古归档：{archaeology_id} — {target.path}

归档时间：{ISO8601}
来源：code-archaeologist plugin
风险评级：{risk_level}
推荐策略：{recommended_strategy}
{若关联 flowsmith：'关联 flowsmith 任务：{flowsmith_task_id}'}

### 项目级设计约定（可复用到其他模块）
{从 intent.md 的"项目级模式关联"提炼}

### 风险模式记录
{每条以"模式 → 检测方法 → 应对策略"格式，方便未来快速识别}
- **模式**：{描述，如"通过反射调用的服务方法"}
  **检测方法**：{如"grep Class.forName + 类名"}
  **应对策略**：{如"重构前必须人工核查反射调用方"}

### 隐式依赖类型分布（本项目特有）
{从 blast-radius.md 中识别的隐式依赖类型，按频率排序}
- 序列化字段引用：{N} 处
- 配置文件引用：{N} 处
- 反射调用：{N} 处
- 字符串构造：{N} 处

### 历史决策记录
{从 history.md 中提炼"延续至今的关键决策"，特别是"看似可改但不能改"的}
- {decision 1}
- {decision 2}

### 考古方法论改进建议
{若本次考古发现现有方法论的不足，记录于此供 plugin 演进参考}
```

### Step 4 — 归档 state.json

更新 `.archaeology/state.json`：

```json
{
  "archived_at": "<ISO8601>",
  "archived_summary": {
    "agents_completed": 3,
    "report_generated": true,
    "lessons_written": true,
    "flowsmith_linked": <true/false>
  }
}
```

### Step 5 — 提示后续清理建议（不强制）

```
✅ 考古任务 {archaeology_id} 已归档

经验沉淀去向：
  📚 .sop/lessons.md（{若 flowsmith 安装：'flowsmith 知识库'} 否则：'已为未来 flowsmith 任务预备'}）

考古产出文件保留位置（建议提交 git）：
  - .archaeology/report.md
  - .archaeology/history.md
  - .archaeology/blast-radius.md
  - .archaeology/intent.md
  - .archaeology/state.json

清理建议：
  - 若考古结论已采纳（开始重构）：保留所有文件，作为重构决策的可追溯记录
  - 若结论是 freeze-and-document：将精简版 report.md 复制为 {target.dirname}/ARCHAEOLOGY-{filename}.md
  - 若结论是 escalate：将 report.md 提交架构评审

可执行 /arch-init 开始新考古。
```

---

## 设计说明：双向知识流的最后闭环

`code-archaeologist` 与 `flowsmith` 通过 `.sop/lessons.md` 形成**双向知识流**：

```
flowsmith 任务完成 → /sop-close → 写入 lessons.md
                                       ↓
                              code-archaeologist 启动新考古时读取
                                       ↓
                          考古发现引用历史经验，避免重复踩坑
                                       ↓
code-archaeologist 完成 → /arch-close → 写入 lessons.md
                                       ↓
                              flowsmith 启动新任务时读取
                                       ↓
                          规划阶段引用历史考古，提前识别风险
```

这种"共享知识库"模式是 plugin 协同的最高形态——
不通过临时的接口调用协同，而通过持久化的知识共享协同。
