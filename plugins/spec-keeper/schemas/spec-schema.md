# Spec Schema（规格契约）

> 单一可信来源。living spec 与变更 delta 的格式在此统一定义，所有 command/skill 对齐此文件。
> 借鉴 OpenSpec：规格是"系统当前能力的真相"，变更以相对现有规格的 delta 表达。

## 1. 目录结构

```
spec/
├── capabilities/                 # living spec：长期存活，按【能力】组织，= 系统真相
│   └── <capability-id>/
│       └── spec.md               # 该能力当前的预期行为（应然）
└── changes/                      # 变更：每个变更一个文件夹（对标 OpenSpec change folder）
    └── <change-id>/
        ├── proposal.md           # 变更意图 + delta（ADDED/MODIFIED/REMOVED）
        ├── tasks.md              # 任务拆解（可被 flowsmith 消费）
        ├── design.md             # 技术方案（可选，本期占位）
        └── status                # 单行：draft | proposed | applied | archived
```

设计原则：
1. **能力优先于任务**：`spec/` 按长期能力组织，与 flowsmith `.sop/`（任务级、关任务即弃）正交。
2. **真相与提案分离**：`capabilities/` 是当前真相，`changes/` 是打算怎么改。二者 diff 即评审对象。
3. **delta 在行为层**：变更用 ADDED/MODIFIED/REMOVED 标记**相对现有能力**的行为差异（brownfield 友好），不是文件 diff。
4. **fluid 而非僵硬阶段门**：proposal/apply/archive 是动作，artifact 可随时更新（对标 OpenSpec）。

## 2. living spec 格式（capabilities/<id>/spec.md）

```markdown
# 能力：{能力名}
> capability_id: {id}
> status: active | deprecated
> last_change: {change-id}

## 目的
{这个能力为谁解决什么问题，1-3 句}

## 行为规格（Requirements）
每条用 `R-{n}` 编号，必须可判定（能写成测试）：

### R-1 {标题}
- **当** {前置条件/触发}
- **则** {系统必须的行为}
- **除非** {例外，可选}
- 验收：{如何验证；理想情况下对应一条测试}

## 接口契约（若该能力对外暴露接口）
{从技术方案毕业而来的稳定接口；method/path/req/resp/error}

## 数据契约（若涉及持久化）
{稳定的数据结构/约束}

## 非目标（Out of Scope）
{明确不提供什么，防止范围蔓延}
```

## 3. delta 格式（changes/<id>/proposal.md）

```markdown
# 变更提案：{标题}
> change_id: {id}
> status: draft | proposed | applied | archived
> capabilities: {受影响能力 id 列表}
> linked_sop_task: {flowsmith task_id，可选}

## 为什么（Why）
{动机；引用需求/issue}

## Delta（相对现有 living spec 的行为变化）

### 能力 {capability-id}

#### ADDED
- R-{new}: {新增的行为规格，同 living spec 的 R 条目格式}

#### MODIFIED
- R-{existing}: {改前 → 改后；必须说明行为如何变化}

#### REMOVED
- R-{existing}: {移除的行为 + 移除理由 + 兼容性影响}

## 影响与兼容性
{向后兼容说明；调用方影响；迁移需求}

## 验收
{本变更完成的判定标准；对应 tasks.md 与测试}
```

> 一个 change 可同时含多个能力的 delta。无某类变更时该小节写"无"。

## 4. status 生命周期（三动作）

```
draft ──/spec-propose──▶ proposed ──/spec-apply──▶ applied ──/spec-archive──▶ archived
                                          │
                              delta 合并进 capabilities/ 成为新真相
```

- **propose**：创建/完善 change 文件夹，写 proposal.md（delta）+ tasks.md，status=proposed
- **apply**：实现完成后，把 delta 合并进 `capabilities/<id>/spec.md`（ADDED 追加 R、MODIFIED 改写 R、REMOVED 删除 R），status=applied
- **archive**：变更收尾，status=archived，living spec 已是新真相

## 5. 与 buddy-hub 生态集成

- **flowsmith**：`/sop-init` 检测 `spec/`，把关联能力的 living spec 作为硬约束注入 plan.md；`/sop-close` 触发 `/spec-apply` 把 delta 沉淀为真相。state.json `spec_context.linked_change_id` 建立双向关联。
- **context-keeper**：每个动作 emit SkillBus 事件（`spec.proposed` / `spec.delta.recorded` / `spec.applied` / `spec.drift.detected`），entity 新增 `capability` / `spec_change`。规格变更天然进入知识图谱——这是 OpenSpec 本身没有的「规格 + 事件溯源」组合。
- **code-archaeologist**：考古红线可作为 living spec 的"非目标/约束"来源。
