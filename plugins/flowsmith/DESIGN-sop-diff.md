# 设计说明：为 flowsmith 增加带备注的 diff（/sop-diff）+ 老任务回补

> 写给即将合并这次改动的开发者。先读这份再读具体文件。

## 为什么要做

10x Claude Code 开发的核心瓶颈不在"让 Claude 写代码"——这件事它已经做得很好了。
真正卡人的是**反过来理解 Claude 写了什么**：

- 在 N 个 worktree 中并行跑 N 个任务，切回任一个时上下文已凉
- Claude 在某次对话中做了关键决策，但决策理由散落在几百轮对话里，git diff 看不到
- 自己的 PR review / 队友的 review，都要从代码反推意图，效率极低
- 任务做到一半被打断，第二天醒来面对 200 行 diff，要重建上下文

flowsmith 已经有 `arch.md`（架构层的 why）和 `plan.md`（任务层的 why），
但**代码层的 why** 是缺失的。这次改动把它补上。

## 解法的核心

1. **新产物 `.sop/changelog.md`**：实施阶段维护，每个**逻辑变更批次**一条 CR-N，
   显式记录"解决什么问题 / 为什么这么改 / 涉及哪些文件"。

2. **新命令 `/sop-diff`**：把 `git diff` + 未提交 + 未跟踪 + `changelog.md` 合并展示。
   每个 CR 显示备注，再列出该 CR 涉及的文件 diff。

3. **state.json 增加 `git_context`**：记录 `base_branch` / `head_branch` / `worktree_path` /
   `is_worktree`，让 `/sop-diff` 知道该比什么、当前在哪个工作区。

4. **state.json 增加 `change_records.next_id`**：CR 编号自增计数器。

5. **implementation-guide 增加"变更日志纪律"**：明确何时写、写什么、写多细。
   IMPLEMENTATION 阶段完成的检查清单中加入"`/sop-diff --unannotated` 输出为空"。

6. **`/sop-diff --backfill` 模式**：给老用户提供"升级 + 回补"一站式入口。

## /sop-diff 的范围语义（关键）

只看**当前分支自分叉点（merge-base）以来到工作树**的全部改动：

```bash
MERGE_BASE=$(git merge-base "$base_branch" HEAD)
git diff "$MERGE_BASE"                        # 全部改动（commits + 暂存 + 未暂存）
git ls-files --others --exclude-standard      # 未跟踪文件
```

为什么用 merge-base 而非 `BASE..HEAD`：

- 如果你从 main 分叉后，main 又自己往前走了几个 commit，merge-base 永远定位到**你最初分叉的那一刻**
- 这样无论你后来 pull / merge / rebase 过多少次，看到的永远只有"你这条分支自己写的代码"
- `BASE..HEAD`（两点）会受 main 的位置影响，可能把别人的代码也算成你的工作

## worktree 友好性

不需要任何特殊适配。原因：
- 每个 worktree 是独立工作目录，自带独立的 `.sop/`
- `state.json.git_context.base_branch` 在 `/sop-init` 时按需写入，自然分离
- 切到任一 worktree 跑 `/sop-diff`，命令自动读该 worktree 的 `.sop/`，输出该任务的备注

## 老用户回补：`/sop-diff --backfill`

### 触发场景

- 升级到本版本前已经在用 flowsmith 的人：state.json 是 1.0，没有 git_context、没有 changelog
- 实施阶段中断了纪律，攒了一批改动没记录 CR
- 从其他分支 cherry-pick / merge 过来的改动，没有对应的 CR

### 一站式做的事

1. **schema 升级（1.0 → 1.1）**：纯增量、幂等
   - 添加 `git_context`（自动探测）
   - 添加 `change_records: { next_id: 1, log_file: ".sop/changelog.md" }`
   - 升级 version 字段
   - **不修改任何已有字段**
   - 重跑无副作用

2. **CR 提议（启发式聚类）**：
   - 优先级 1：同一个 commit 内的文件 → 同一 CR（commit 边界是逻辑批次的天然近似）
   - 优先级 2：同一目录前缀 → 同一 CR
   - 优先级 3：文件路径关键词命中 plan.md 子任务 → 自动关联 subtask
   - 优先级 4：diff 内容引用 arch.md 接口名 → 自动关联 ADR

3. **占位符与可追溯性**：
   - "为什么这么改"留作 `[需用户补充]` 占位符
   - 每条 backfilled CR 带 `source_commits: [...]` 字段，commit 哈希足够任何人定位原始上下文
   - 不强制用户立即填全所有"为什么"——能让人先跑起来才是关键

4. **两种粒度**：
   - `/sop-diff --backfill`：预览模式，提议后等用户确认
   - `/sop-diff --backfill --auto`：直接写入，跳过预览（适合改动量大、commit message 已经够清楚的场景）

### 设计取舍

**为什么把"升级"和"回补"绑在一起？**
绝大多数老用户的实际诉求是"我想看带备注的 diff"——他们不会单独想"升级 schema"。
绑在一起避免了"升级了却看不到效果"的尴尬。同时升级是纯增量，没有副作用。

**为什么不强制用户填完"为什么"才能写入？**
现实中老任务的"为什么"已经在 commit message 或对话里散落，强制让用户当场回忆是反人性的。
占位符 + commit 哈希给了"先跑起来再优化"的台阶。

**为什么不在 `/sop-init` 里也支持回补？**
`/sop-init` 是开新任务的，与"分析已有改动"是两件事。混在一起会让命令语义模糊。
保持单一职责：`/sop-init` 只开新任务，`/sop-diff --backfill` 只处理已有改动。

## 改动清单

### 新增文件

- **`commands/sop-diff.md`** — 新命令本体，含默认模式 + `--backfill` 模式
- **`README-sop-diff-addendum.md`**（已合并到主 README）

### 修改文件

- **`commands/sop-init.md`**：探测 git 上下文，写入 state.json；初始化空 changelog.md
- **`commands/sop-status.md`**：报告中加 Git 上下文段、变更记录段
- **`commands/sop-resume.md`**：恢复报告中加 changelog 摘要；提示先用 /sop-diff 找回上下文
- **`commands/sop-review.md`**：reviewer 任务指令中要求读 changelog.md 判断代码意图
- **`skills/implementation-guide/SKILL.md`**：新增"原则五：变更日志纪律"
- **`skills/task-planning/reference/state-machine.md`**：加 `git_context` / `change_records` 字段；version 升到 1.1；新增 1.0→1.1 迁移规则段
- **`skills/task-planning/reference/document-schemas.md`**：新增 changelog.md 格式契约，含 `backfilled` / `source_commits` 字段
- **`README.md`**：命令表加 `/sop-diff`、架构图更新、新增"带备注的 diff"章节、流程图标注 changelog 触发点和 backfill 旁路

### 未修改

- **`hooks/validate-state.sh`**：现有校验对新字段无感知，不会报错
- **`commands/sop-bootstrap.md`** / **`commands/sop-close.md`**：不需要变更

## 兼容老任务（version 1.0）

任何 1.0 的 state.json：
- 只读型命令（`/sop-status`、`/sop-resume`、`/sop-review`、`/sop-close`）跳过 Git 上下文段、变更记录段，正常输出
- `/sop-diff` 提示"本任务 state.json 是 1.0 版本。推荐执行 /sop-diff --backfill"
- `/sop-diff --backfill` 自动升级 + 回补，一步到位

不会破坏已存在的任务。

## 验收测试场景

1. **新任务全流程**：`/sop-init → 走完 PLANNING/ARCHITECTURE → 进入 IMPLEMENTATION 后
   修改 3 个文件、写 2 条 CR → /sop-diff` 应输出 2 个 CR + 0 个未备注。

2. **未备注检测**：场景 1 基础上再改第 4 个文件不写 CR → `/sop-diff --unannotated`
   应只输出第 4 个文件的 diff。

3. **修复轮**：模拟 REVIEW 出 Critical → 进入修复 → 写 CR 标注 fixes_issue → /sop-diff
   应在该 CR 备注块中显示 fixes_issue。

4. **worktree 隔离**：在两个 worktree 各自跑 `/sop-init`，分别添加改动 →
   在任一 worktree 跑 `/sop-diff` 应只看到自己的内容。

5. **merge-base 语义**：分叉后 main 又新增 commit；在 feat 分支跑 `/sop-diff` →
   不应出现 main 那些 commit 引入的改动；即使 feat 分支已经 pull/merge 过 main 也是如此。

6. **未跟踪文件**：在工作区添加一个新文件但没 git add → `/sop-diff` 应在"未备注改动"
   段中显示该文件，标记 ⚠️ 未跟踪。

7. **老任务兼容**：构造一个 version=1.0 的 state.json + 已有 5 个 commits 的 feat 分支 →
   `/sop-diff` 提示需要回补 → `/sop-diff --backfill` 应：
   - 自动升级 state.json 到 1.1（保留所有原字段）
   - 创建 changelog.md
   - 提议合理的 CR 分组（基于 commit 边界）
   - 不修改 phase 字段

8. **--auto 模式**：场景 7 基础上跑 `/sop-diff --backfill --auto` →
   应直接写入 CR，跳过预览交互。

9. **回补幂等**：连续两次跑 `/sop-diff --backfill` →
   第二次应识别 changelog 已有 CR，PENDING 集合为空，提示无需回补。

10. **非 git 项目**：在没有 .git 的目录下 /sop-init → state.json.git_context 全 null →
    `/sop-diff` 提示"本任务非 git 项目，命令不可用"。
