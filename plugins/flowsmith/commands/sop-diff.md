---
description: 查看当前工作区/分支相对基线分支的代码改动，并附加每条改动的"为什么"备注；支持回补
argument-hint: [CR-id | --unannotated | --staged | --since=<commit> | --files | --base=<branch> | --backfill [--auto]]
---

# /sop-diff — 带备注的 diff

> 解决 worktree 流的核心痛点：`git diff` 看得到 **what**，看不到 **why**。
> 本命令把 `git diff` 和 `.sop/changelog.md` 中的变更备注合并展示。

## 范围

`/sop-diff` **只看当前分支自分叉点以来的全部改动**：
- 包含本分支的所有 commit
- 包含暂存区与未暂存的改动
- 包含未跟踪（且未被 .gitignore 忽略）的新文件
- **不包含** base_branch 自分叉以来的独立提交（用 merge-base 三点语义保证）

每个 worktree 是独立工作目录，自带独立的 `.sop/`，`/sop-diff` 在哪个 worktree 跑就只看哪个的内容。

## 用法

```bash
/sop-diff                       # 显示本次任务的全部改动 + 全部备注
/sop-diff CR-3                  # 只显示某条变更记录及其涉及的 hunk（不折叠）
/sop-diff --unannotated         # 只显示尚未写进 changelog 的改动（自检）
/sop-diff --staged              # 只比较暂存区改动
/sop-diff --since=abc1234       # 用指定 commit 作为对比基线（覆盖 state.json）
/sop-diff --base=develop        # 用指定分支作为对比基线（覆盖 state.json）
/sop-diff --files               # 只列出改动的文件清单 + 各自归属的 CR

/sop-diff --backfill            # 回补：基于已有 diff 提议 CR 分组（预览，不写入）
/sop-diff --backfill --auto     # 回补：直接写入，"为什么"用占位符 [需用户补充]
```

参数为 `$ARGUMENTS`。无参数时执行默认行为。

---

## 执行步骤（默认模式）

### Step 1 — 前置检查

读取 `.sop/state.json`：
- 若不存在 → 提示：
  > "未找到 .sop/state.json。/sop-diff 是 SOP 流程内的命令，请先 /sop-init 启动任务。
  > 若你只是想看普通 git diff，直接用 git 即可。"
  > 停止执行。

- **若 `version` 缺失或为 `1.0`**（缺少 `git_context` 和 `change_records`）：
  > "本任务 state.json 是 1.0 版本，缺少 git_context 和 changelog 支持。
  > 推荐执行 /sop-diff --backfill 升级 schema 并回补 changelog。
  > 如果只想临时看 diff，请加 --base=<branch> 显式指定基线。"
  > 若用户加了 `--base=`，可以降级到"无 changelog 模式"继续；否则停止。

读取 `.sop/changelog.md`：
- 若不存在但 `state.json.current_phase` 已进入或越过 `IMPLEMENTATION` → 提示：
  > "本任务尚无 changelog.md。这次先按裸 git diff 输出（无备注）。
  > 推荐：执行 /sop-diff --backfill 把已有改动回补成 CR 记录。"

### Step 2 — 解析参数与基线

确定对比基线 `BASE`，按优先级：
1. `$ARGUMENTS` 中的 `--base=<X>` 或 `--since=<X>`
2. `state.json.git_context.base_branch`
3. 自动探测（按顺序尝试）：
   - `git symbolic-ref refs/remotes/origin/HEAD --short`
   - `main` / `master` / `develop`
   - 失败则提示用户用 `--base=` 显式指定，停止。

### Step 3 — 收集改动（核心 git 命令）

计算 merge-base 一锅端拿到"本分支自分叉以来到工作树"的全部改动：

```bash
MERGE_BASE=$(git merge-base "$BASE" HEAD)
git diff "$MERGE_BASE" --name-status        # 全部改动文件清单（含暂存+未暂存）
git diff "$MERGE_BASE" --shortstat          # 总统计
git diff "$MERGE_BASE"                      # 完整 diff
git ls-files --others --exclude-standard    # 未跟踪文件（也算"本分支的工作"）
```

辅助上下文：
```bash
git rev-parse --show-toplevel               # 工作区根目录
git rev-parse --abbrev-ref HEAD             # 当前分支
git rev-list --count "$BASE"..HEAD          # 领先 base 的 commit 数
git status --porcelain                      # 暂存与未暂存状态摘要
```

`--staged` 模式：把 Step 3 的 `git diff "$MERGE_BASE"` 替换为 `git diff --cached`。

### Step 4 — 解析 changelog.md

每条 CR 形如：

```markdown
## CR-{n} — {标题}
- timestamp: {ISO8601}
- type: create|modify|delete|refactor|fix
- subtask: {可选}
- adr: {可选}
- backfilled: {true|false，可选}
- files:
  - {path1}
  - {path2}

### 解决什么问题
{...}
### 为什么这么改
{...}
### 关联变更
- 依赖：{...}
- 后续：{...}
```

解析为 CR 列表，建立**文件 → CR** 反向索引（同一文件可能被多个 CR 修改，按时间排序保留全部）。

### Step 5 — 改动 vs 备注的对账

把 Step 3 收集到的所有改动文件集合 `FILES_CHANGED`（含未跟踪）和 changelog 的 `FILES_LOGGED` 比对：

- `FILES_CHANGED ∩ FILES_LOGGED` → 有备注
- `FILES_CHANGED − FILES_LOGGED` → **未备注**（实施纪律有缺口）
- `FILES_LOGGED − FILES_CHANGED` → 备注但代码已不存在（可能是中途回滚）

### Step 6 — 渲染输出

#### 默认（无参数）

```
📐 SOP Annotated Diff
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

任务：{task_summary}     (task_id: {task_id})
工作区：{worktree_path}  {若 is_worktree：'(worktree)'}
分支：{HEAD_branch}  ←  基线：{BASE} (merge-base: {short_sha})
领先：{N} commits        改动：{X} files (+{ins} / -{del})
未跟踪：{若 > 0：'{count} files'}

─── 变更概览 ───

  CR-1  [feat] 实现邮件通知模块骨架     2 files   ADR-2  子任务 1.2
  CR-2  [refactor] 抽离重试公共逻辑     3 files   ADR-3  -
  ...

  ⚠️ 未备注改动：{count} 个文件
     - src/utils/format.ts
     - test/integration/notify.test.ts
  （建议：补一条 CR-{下一个序号}，或在最近相关 CR 的 files 列表中追加；
    或一次性 /sop-diff --backfill 让 Claude 提议分组）

─── 详细备注与 diff ───

╭─ CR-1 ─ 实现邮件通知模块骨架 ─────────────────────────╮
│ 类型：create        时间：2026-05-10T10:00:12Z       │
│ 关联：ADR-2 (来自 arch.md) / 子任务 1.2 (来自 plan)  │
│                                                       │
│ 解决什么问题：...                                      │
│ 为什么这么改：...                                      │
│                                                       │
│ 涉及文件：                                             │
│   ▸ src/notification/email.ts        (新建)           │
│   ▸ src/notification/index.ts        (修改)           │
╰───────────────────────────────────────────────────────╯

{对每个文件，输出对应 hunk 的 git diff，前面缩进两格}
{长 diff（>80 行）默认折叠成 "{N} 行 hunk，输入 /sop-diff CR-1 查看完整内容"}

─── 未备注改动详情 ───

  src/utils/format.ts
  {对应 diff hunk}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
共 {N} 条变更记录，覆盖 {M}/{K} 个改动文件。
```

#### 模式：`CR-{n}`

只渲染该条 CR 的备注 + 完整 diff（不折叠）。
找不到该 CR 时输出："未找到 CR-{n}，当前 changelog 中最大编号为 CR-{max}"。

#### 模式：`--unannotated`

只渲染"未备注改动"段落，并对每个未备注文件输出完整 diff。在末尾给出建议：

```
建议处理方式：
  1. 这些改动属于已有 CR 的范畴 → 在对应 CR 的 files 列表追加这些路径
  2. 这些改动是独立的逻辑批次 → 新增 CR-{下一个序号}（参考 changelog 模板）
  3. 这些改动是临时调试/格式化 → 暂时忽略，但提交前应确认
  4. 一次性回补全部 → /sop-diff --backfill
```

#### 模式：`--files`

只列出文件清单，附 CR 归属：

```
src/notification/email.ts          CR-1 (create)
src/notification/index.ts          CR-1, CR-3 (modify)
src/utils/format.ts                ⚠️ 未备注 (modify)
新.txt                              ⚠️ 未跟踪
```

### Step 7 — 健康检查

输出末尾追加（若有问题）：
- changelog 中存在 `files: A` 但 git diff 中找不到 A → ⚠️ "CR-x 声明改动 A，但 diff 中无此文件，可能已回滚"
- 改动文件数 ≥ 3 倍 CR 条目数 → ⚠️ "CR 粒度可能过粗，建议在后续实施时拆得更细"
- `current_phase != "IMPLEMENTATION"` 且仍有未备注改动 → ⚠️ "已离开实施阶段但仍有未备注改动，建议执行 /sop-diff --backfill 后再进 OPTIMIZATION/REVIEW"

---

## 回补模式（--backfill）

适用场景：
- 升级到本版本前已开始的 SOP 任务（state.json version=1.0，无 changelog）
- 实施阶段曾中断纪律，攒了一批改动没记录 CR
- 从其他分支 cherry-pick / merge 过来的改动，没有对应的 CR

### Step 1 — Schema 自检与升级（幂等）

读取 `.sop/state.json`：

- 若 `version` 缺失或为 `"1.0"`：
  - 探测 git 上下文（base_branch / head_branch / worktree_path / is_worktree），写入 `git_context`
  - 增加 `change_records: { next_id: 1, log_file: ".sop/changelog.md" }`
  - 升级 `version` 为 `"1.1"`
  - 输出："✅ Schema 升级完成：1.0 → 1.1（纯增量字段，未删除任何原有数据）"

- 若 `.sop/changelog.md` 不存在：
  - 按 /sop-init 的格式创建空模板（含 task_id / task / base_branch / head_branch / worktree 元信息行）

升级是纯增量、幂等，可重复执行。

### Step 2 — 收集"未备注"代码

按默认模式 Step 3 收集 `FILES_CHANGED`，按 Step 4 解析现有 changelog（可能为空）得 `FILES_LOGGED`。

```
PENDING_FILES = FILES_CHANGED − FILES_LOGGED
```

若 `PENDING_FILES` 为空 → 输出"没有待回补的改动，changelog 已覆盖当前分支的全部差异。" 停止。

### Step 3 — 收集分组提示信号

为提高 CR 分组准确度，收集：

```bash
# 全部 commit 列表（按时间正序，用 reverse）
git log "$MERGE_BASE"..HEAD --reverse --pretty='%H|%h|%s|%an|%ai'

# 每个 commit 改了哪些文件
git show --name-only --pretty='format:COMMIT %H' "$commit_sha"

# 未跟踪文件清单
git ls-files --others --exclude-standard
```

读取：
- `.sop/plan.md` → 提取子任务编号、描述、关键词
- `.sop/arch.md` → 提取 ADR 编号、标题、关键接口名

### Step 4 — 启发式聚类

按以下优先级合并文件到 CR 桶：

1. **同一个 commit 内的文件** → 强信号，倾向放入同一 CR（commit 边界是逻辑批次的天然近似）
2. **同一目录前缀**（最长公共前缀至少到 2 级）→ 中等信号，跨 commit 但同目录的改动倾向合并
3. **文件路径关键词匹配 plan.md 子任务描述** → 自动关联 `subtask` 字段
4. **diff 文本中出现 arch.md 的 ADR 提到的接口名/类名** → 自动关联 `adr` 字段
5. **未跟踪文件**：按目录归并到最相关的 CR 桶；找不到关联则单独成桶

聚类边界冲突（一个 commit 跨多个目录）时：以 commit 边界优先，但允许把"跨域 commit"标注为多个 CR 的"共同来源"。

### Step 5 — 生成 CR 提议

每条提议的 CR：

| 字段 | 取值规则 |
|------|---------|
| `id` | 从 `state.json.change_records.next_id` 起递增 |
| `title` | 取该聚类内最大 commit 的 subject；无 commit 时取目录名 + 主要 type |
| `type` | 从 `git diff --name-status` 推断：A→create / M→modify / D→delete；多种混合按主导计 |
| `subtask` | 启发式 3 命中则填，否则 `-` |
| `adr` | 启发式 4 命中则填，否则 `-` |
| `files` | 聚类内的全部文件 |
| `backfilled` | `true` |
| `source_commits` | 来源 commit 短哈希列表 |
| 解决什么问题 | 用 commit body（若有）或 subject 作为初稿 |
| 为什么这么改 | 默认 `[需用户补充] 由 --backfill 生成，可参考 ADR-X / commit {sha}: {message}` |

### Step 6 — 预览输出（默认）

```
📐 SOP Backfill 提议
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{若刚做了 schema 升级：'✅ Schema 升级完成（1.0 → 1.1）'}
{若刚创建了 changelog.md：'✅ changelog.md 模板已创建'}

📊 待回补分析
   当前分支相对 {BASE} 共 {N} commits / 改动 {X} 文件 / 未跟踪 {Y} 文件
   现有 changelog 覆盖：{已备注 count} 个文件
   待回补：{PENDING count} 个文件

🔍 提议 {K} 条 CR（基于 commit 边界 + 目录聚类 + plan/arch 启发式匹配）：

  CR-{n}  [{type}]  {title}                         {fcount} files  {subtask}  {adr}
          来源：commit {sha} "{commit subject}"
          {若多 commit 列出多行}

  {以此类推}

每条 CR 已自动填好"涉及文件 / 关联子任务 / 关联 ADR / 来源 commit"。
"解决什么问题"使用 commit message 作为初稿；"为什么这么改"标 [需用户补充]。

操作：
  • 查看某条详情     → 回复"看 CR-{n}"
  • 全部接受         → 回复"全部接受"
  • 调整某条         → 回复"CR-{n} 改成 ..." 或 "CR-{n} 拆成两条" 或 "合并 CR-{a} 和 CR-{b}"
  • 重新聚类         → 回复"按子任务重新分组" 或 "按 commit 重新分组"
  • 一键写入并跳过预览 → /sop-diff --backfill --auto

⚠️ 当前是预览，未写入 changelog.md。
```

### Step 7 — 应用（用户确认后）

收到用户确认（"全部接受"或经过若干轮调整后的"现在写入"）：

1. 在 `.sop/changelog.md` **顶部**追加（紧跟元信息行后）一段标记块：

   ```markdown
   ## ＜回补摘录＞ 由 /sop-diff --backfill 于 {ISO8601} 生成

   本节包含 CR-{a} 至 CR-{b}，对应升级前的历史改动。
   其中标记 [需用户补充] 的字段，请在合适时机手工补全（共 {N} 处）。

   ---
   ```

2. 依次追加每条 CR 到 changelog.md
3. 更新 `state.json.change_records.next_id` 为最大 CR 编号 + 1
4. 输出：
   ```
   ✅ 已写入 {K} 条 CR 到 .sop/changelog.md（CR-{a} 至 CR-{b}）

   占位符 [需用户补充]：共 {N} 处
   建议在适当时机执行 /sop-diff CR-{n} 查看单条详情后，手工补全。

   后续按 implementation-guide 的"变更日志纪律"正常维护即可，
   新写的 CR 从 CR-{next_id} 开始。
   ```

### --auto 模式

跳过 Step 6 的预览交互，直接 Step 5 → Step 7：
- 适合改动量大、commit message 已经够清楚、用户愿意事后再补"为什么"的场景
- 输出末尾额外提示："--auto 模式下未做精修；如需修正分组，可编辑 changelog.md 或执行 /sop-diff --backfill --regroup（暂不支持，请手工编辑）"

### 边界与注意

- **回补不修改 phase**：即使 current_phase 是 OPTIMIZATION/REVIEW/DONE，回补也只写 changelog，不动 state.json 的 phase 字段
- **回补不删除现有 CR**：只追加，永远不覆盖
- **失败安全**：schema 升级和 changelog 写入是两个独立步骤；中途失败可重跑
- **iteration > 1 的特殊情况**：若 open_issues 中有 `status=open` 的 Critical，且某 commit 的 message 包含 "fix C-x"，将该 CR 加上 `fixes_issue: C-x` 字段
