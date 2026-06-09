---
description: 把规格产物对齐到 OpenSpec 规范。默认【迁移】：将旧版原生格式（spec/capabilities、内联 delta、R-n + 当/则/除非）改造为 OpenSpec 布局与格式（openspec/specs + changes/<id>/specs 独立 delta + Requirement/Scenario），产出可通过 `openspec validate --strict` 的目录树。解决"产出文档位置与格式和 OpenSpec 不一致"的缺口。
argument-hint: [--migrate(默认) | --project | --check] [--change-id=<id>] [--out=openspec]
---

# /spec-align — 把规格对齐到 OpenSpec 规范

参数：$ARGUMENTS

> 用途：项目里现有的 spec 产物（无论是旧版 `spec/` 原生格式，还是手写得不规范）与 OpenSpec 有出入时，
> 一键对齐为**逐字节符合 OpenSpec** 的 `openspec/` 目录树。对齐后：流程中产出的 spec、归档后的 spec，都与 OpenSpec 一模一样。

## 前置读取
1. `schemas/spec-schema.md` — OpenSpec 对齐版格式（唯一格式来源；本命令的目标态）
2. `../skills/spec-authoring/SKILL.md` — 撰写纪律（Requirement/Scenario、RFC2119、不臆造）
3. 现有规格：优先 `openspec/`；否则旧版 `spec/`（`capabilities/` + `changes/`）

## 三种模式（只决定写不写、写哪里）
- **`--migrate`（默认）**：把旧版 `spec/` 就地改造为 `openspec/`，迁移完成后删除旧 `spec/`（保留一行指针 `spec/MIGRATED.md` 指向 `openspec/`）。
- **`--project`**：在 `--out`（默认 `openspec/`）生成对齐副本，**保留**原 `spec/` 不动（适合不想动现有 flowsmith/context-keeper 集成时先验证产物）。
- **`--check`**：只在内存里做转换并跑 §5 校验，**不写任何文件**，输出违规清单（当 CI 闸门用，等价 `openspec validate`）。

## ⚖️ 关键纪律
- 对齐是**格式/位置转换 + 补全 Scenario**，不是重写需求语义。原有行为含义必须保留。
- 旧版缺失 OpenSpec 必需要素（如无 Scenario、无 RFC2119 动词）时**补全**，吃不准的标 `[待确认]`，**绝不臆造**新行为。
- `--migrate` 删除旧目录前，先确认 `openspec/` 已写成功且通过 §5 校验。

## 执行步骤

### Step 1 — 识别源格式与范围
- 若已有 `openspec/`：只做 §5 校验/补全（幂等），不重复迁移。
- 若是旧版 `spec/`：进入转换。`--change-id=` 可只对齐单个变更（否则全量）。
- 非上述结构：提示先 `/spec-bootstrap` 建基线，或本命令把现有 md 当作待规范化对象逐文件处理。

### Step 2 — 目录与命名映射
| 旧版（native） | OpenSpec（目标） |
|---|---|
| `spec/` | `openspec/` |
| `spec/capabilities/<id>/spec.md` | `openspec/specs/<domain>/spec.md`（`<domain>` = 原 `<id>`） |
| `spec/changes/<id>/proposal.md`（内联 delta） | 拆成 `openspec/changes/<id>/proposal.md`（去 delta） + `openspec/changes/<id>/specs/<domain>/spec.md`（delta） |
| `spec/changes/<id>/tasks.md` | `openspec/changes/<id>/tasks.md`（转 checkbox 清单） |
| `spec/changes/<id>/design.md` | `openspec/changes/<id>/design.md`（原样） |
| `spec/changes/<id>/status`（单行文件） | 写入 `openspec/changes/<id>/.openspec.yaml` 的 `status` 字段 |
| `spec/changes/_archived/<id>/` | `openspec/changes/archive/<YYYY-MM-DD>-<id>/`（日期取归档时间，缺失则用 git 最后提交日或今日） |
| change-id 含 4 位随机后缀 | 规整为动词起头短 kebab（如 `notify-email-a1b2` → `add-notify-email`）；在 `.openspec.yaml` 记 `legacy_id` 备查 |

### Step 3 — 真相 spec 转换（capabilities/<id>/spec.md → specs/<domain>/spec.md）
对每份旧 living spec：
1. 标题：`# 能力：{名}` → `# {名} Specification`；**删除** `> capability_id/status/last_change` 元数据块（域名即 domain；状态/last_change 不进真相 spec）。
2. `## 目的` → `## Purpose`（保留正文）。
3. `## 行为规格（Requirements）` → `## Requirements`。
4. 每条 `### R-{n} {标题}` → `### Requirement: {标题}`，并把 当/则/除非/验收 转为「规范性句 + Scenario」：
   - 规范性句：`The system MUST {则的内容}。`（绝对要求用 MUST/SHALL；推荐用 SHOULD）——**RFC2119 关键字用英文**，validate 才识别。
   - `#### Scenario: {happy path 名}`
     - `- GIVEN {当}`
     - `- WHEN {触发}`
     - `- THEN {则}`
   - 「除非 {例外}」→ 追加一个 `#### Scenario: {例外名}`（GIVEN 例外条件 / THEN 例外行为），或在主场景加 `- AND` 例外分支。
   - 「验收」已隐含在 Scenario（Scenario 即可测断言）；额外断言并入 THEN/AND。
   - **每条 Requirement 必须 ≥1 个 Scenario**；旧版没给场景的，依据「当/则」综合出一个最小 happy-path 场景，无法判定的标 `[待确认]`。
5. `## 接口契约` → 拆成带 SHALL 的 Requirement（每个 endpoint 一条），Scenario 覆盖 method/path/成功响应/错误码。
6. `## 数据契约` → 写成约束类 Requirement（如「The system MUST 持久化字段 X 满足 …」）+ Scenario 校验关键约束。
7. `## 非目标（Out of Scope）` → **不进真相 spec**；若该能力有对应 active change，挪进其 `proposal.md` 的 `Out of scope`；否则在 spec 末尾留非规范性 `> Note（Out of scope）: …`（不影响 validate）。

### Step 4 — 变更转换（proposal 内联 delta → 独立 delta + 纯 proposal）
对每个 change：
1. 读旧 `proposal.md`，分离两部分：意图区（为什么/影响/验收）与 `## Delta（…）` 区。
2. 写**新 proposal.md**（OpenSpec 格式）：`# Proposal: {标题}` + `## Intent`（原「为什么」）+ `## Scope`（in/out scope，纳入原非目标）+ `## Approach`（原方案要点；细节留 design.md）。**不含 delta**。
3. 把 `## Delta` 下每个 `### 能力 {domain}` 转成 `openspec/changes/<id>/specs/<domain>/spec.md`：
   - 首行 `# {Domain} Delta`。
   - `#### ADDED` → `## ADDED Requirements`；`#### MODIFIED` → `## MODIFIED Requirements`；`#### REMOVED` → `## REMOVED Requirements`（h4→h2，补 `Requirements` 后缀）。
   - 每条 `- R-{n}: {…}` → `### Requirement: {名}` + 规范性句 + Scenario（同 Step 3.4 规则）。MODIFIED 补 `(Previously: {改前})`。REMOVED 写 `### Requirement: {名}` + `({理由 + 兼容性})`。
4. 写 `.openspec.yaml`：`change_id` / `status`（取自旧 `status` 文件）/ `capabilities`（涉及的 domain）/ `linked_sop_task`（若旧 proposal 头有 `linked_sop_task`）/ `legacy_id`。
5. `tasks.md`：转成 `# Tasks` + 分组 + `- [ ] N.M …` checkbox（已完成的勾 `[x]`）。

### Step 5 — 校验（OpenSpec 一致性；三种模式都跑）
对生成/现有的 `openspec/` 逐文件检查（等价 `openspec validate --strict`）：
- 真相与 delta 的每份 spec 含 `## Purpose`（真相）/ 正确节标题，含 `## Requirements` 或 `## ADDED|MODIFIED|REMOVED Requirements`。
- 每条 `### Requirement:` 下 ≥1 个 `#### Scenario:`。
- 需求正文含 RFC2119 关键字（`SHALL|MUST|SHOULD|MAY`）。
- Scenario 用 `GIVEN/WHEN/THEN` 结构。
- change-id 为动词起头短 kebab；归档目录带日期前缀。
- 列出所有 `[待确认]` 与每条违规（文件:行 + 原因 + 建议修法）。
- 若有命令行 `openspec` 可用，额外执行 `openspec validate --strict` 交叉验证并附其输出。

### Step 6 — 写入 / 收尾（按模式）
- `--check`：只输出报告，不写。
- `--project`：写到 `--out`，保留旧 `spec/`。
- `--migrate`（默认）：校验通过后，写 `openspec/`，删除旧 `spec/`，留 `spec/MIGRATED.md`（指向 `openspec/` + 迁移摘要 + legacy_id 对照表）。
- emit `spec.aligned`（汇总，evidence 指向源→目标路径映射与 §5 校验结果）。

### Step 7 — 汇报
```
模式：{migrate|project|check}
真相：{n} 个 domain 已对齐 → openspec/specs/
变更：{m} 个 change 已拆分（proposal ↔ 独立 delta）；归档 {k} 个 → changes/archive/
补全 Scenario：{s} 条（为缺场景的旧需求综合 happy-path）
[待确认]：{u}（请逐条核对——多为旧版信息不足处）
OpenSpec 校验：{通过 / 失败 d 项（见列表）}
change-id 规整：{旧→新 对照}
{--migrate 时附}旧 spec/ 已迁移并删除，指针见 spec/MIGRATED.md
```

## 注意
- 对齐**不改业务语义**——只换格式/位置、补 OpenSpec 必需的 Scenario 骨架。语义级的需求完善仍走 `/spec-propose`。
- `[待确认]` 是旧版信息不足的真实信号（如某需求从无可测场景），需人工补齐后才算真正达标。
- 迁移后，后续所有命令（propose/apply/archive/bootstrap/sync/check/status）已原生产出 OpenSpec 格式，**无需反复 align**；align 主要用于一次性迁移、外部导入规格的规范化、或 `--check` 当 CI 闸门。
