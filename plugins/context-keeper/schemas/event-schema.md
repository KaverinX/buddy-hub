# Event Schema (SkillBus v0)

> 单一可信来源。所有 plugin emit 事件、所有 plugin 消费事件都遵循此契约。
> 修改格式时**只改这里**，不在各 plugin 内部内嵌格式。

---

## 1. 设计原则

1. **Append-only**：事件流只追加，不修改、不删除。物化视图可重建。
2. **Self-describing**：事件本身包含足够信息，不依赖外部上下文即可解析。
3. **Forward-compatible**：未知字段忽略；新字段进 `ext` 子树，不入侵核心 schema。
4. **Plugin-agnostic**：事件的语义不绑定具体 plugin。flowsmith 关闭任务和 archaeology 关闭考古，都是 `task.closed`，差异在 `actor`。
5. **Provenance over inference**：每个事件必须给出 `evidence`。下游消费者要能审计这个事件是怎么来的。

---

## 2. 核心结构

```jsonc
{
  "id":      "evt_<26位ULID-style>",   // 全局唯一，按时间单调
  "v":       1,                         // schema 版本
  "ts":      "2026-04-28T16:30:00Z",    // ISO8601 UTC
  "type":    "task.phase.entered",      // 事件类型，命名空间 . 分隔
  "actor":   "flowsmith",               // 发送方 plugin name
  "task_id": "a3f8c1d2",                // 可选，关联 flowsmith task；无关联则 null
  "entity":  {                          // 事件主语
    "type": "task",
    "id":   "a3f8c1d2",
    "ref":  { "path": ".sop/state.json" }
  },
  "evidence": [                         // 事件如何被推断出来的
    { "kind": "file", "path": ".sop/state.json", "hash_sha1": "..." },
    { "kind": "diff", "field": "current_phase", "from": "PLANNING", "to": "ARCHITECTURE" }
  ],
  "ext":     {}                         // plugin-specific 扩展字段
}
```

### 字段约束

| 字段       | 必需 | 类型           | 说明 |
|------------|------|----------------|------|
| `id`       | ✅   | string         | `evt_` + 26 位 ULID-like（时间排序友好） |
| `v`        | ✅   | int            | 当前 v=1，破坏性变更才 +1 |
| `ts`       | ✅   | string         | ISO8601，必须 UTC（带 Z） |
| `type`     | ✅   | string         | 见下"事件类型清单" |
| `actor`    | ✅   | string         | plugin name，必须与 `.claude-plugin/plugin.json` 的 name 一致 |
| `task_id`  | ⚠️   | string \| null | 与 flowsmith 任务关联时填入；独立行为填 null |
| `entity`   | ✅   | object         | 见下"实体引用" |
| `evidence` | ✅   | array          | 至少一条，下游审计用 |
| `ext`      | ❌   | object         | 任意 plugin-specific 字段，消费方未知字段必须忽略 |

### entity 字段

```jsonc
{
  "type": "task" | "decision" | "risk" | "red_line" | "lesson" |
          "author" | "file" | "module" | "review" | "report",
  "id":   "<entity-specific id>",       // 见 entity-schema.md
  "ref":  {                             // 可选，物理引用
    "path": "...",                      // 文件系统路径
    "url":  "...",                      // 远程引用（PR 链接等）
    "hash": "..."                       // git commit hash 等
  }
}
```

### evidence 字段

每条 evidence 是一个独立可验证的依据：

```jsonc
{ "kind": "file",   "path": ".sop/plan.md", "hash_sha1": "..." }
{ "kind": "diff",   "field": "current_phase", "from": "...", "to": "..." }
{ "kind": "git",    "commit": "abc123", "author": "alice@x.com" }
{ "kind": "match",  "pattern": "重构|拆分", "match_text": "...", "location": "plan.md:L23" }
{ "kind": "manual", "note": "由用户在 /sop-review 中确认" }
```

不强制 evidence 类型枚举——上述是当前已使用的种类，新种类可以加。

---

## 3. 事件类型清单（v0 已定义）

命名约定：`<namespace>.<noun>.<verb>`，全小写，`.` 分隔。

### 任务生命周期（flowsmith 主域）

| 类型                       | 触发                              | 必需 entity.type |
|----------------------------|-----------------------------------|------------------|
| `task.created`             | `/sop-init` 完成                  | `task`           |
| `task.phase.entered`       | flowsmith FSM 进入新阶段          | `task`           |
| `task.phase.completed`     | 某阶段标记 done                   | `task`           |
| `task.iteration.started`   | review 出 critical, 进新一轮      | `task`           |
| `task.closed`              | `/sop-close`                      | `task`           |

### 决策与风险

| 类型                       | 触发                              | 必需 entity.type |
|----------------------------|-----------------------------------|------------------|
| `decision.recorded`        | plan/arch 中产生 ADR              | `decision`       |
| `risk.identified`          | plan 阶段识别风险                 | `risk`           |
| `risk.accepted`            | 用户明确接受某风险                | `risk`           |
| `risk.materialized`        | 已识别风险变成实际事故            | `risk`           |

### 考古域（code-archaeologist）

| 类型                          | 触发                              | 必需 entity.type |
|-------------------------------|-----------------------------------|------------------|
| `refactor.intent.detected`    | hook 检测到 plan 含重构关键词     | `task`           |
| `archaeology.started`         | `/arch-init`                      | `task`           |
| `archaeology.report.generated`| `/arch-report`                    | `report`         |
| `red_line.set`                | 考古报告写入红线                  | `red_line`       |
| `archaeology.closed`          | `/arch-close`                     | `task`           |

### 审查域（flowsmith review + co-review）

| 类型                       | 触发                              | 必需 entity.type |
|----------------------------|-----------------------------------|------------------|
| `review.started`           | `/sop-review`                     | `review`         |
| `review.found.critical`    | reviewer 发现 critical            | `review`         |
| `review.completed`         | review 整体结束                   | `review`         |
| `team_review.started`      | `/scope-review`                   | `review`         |
| `red_line.violated`        | co-review 检测到违反考古红线      | `red_line`       |
| `team_review.completed`    | scope-review 完成                 | `review`         |

### 知识沉淀

| 类型                       | 触发                              | 必需 entity.type |
|----------------------------|-----------------------------------|------------------|
| `lesson.recorded`          | 任意 plugin emit lesson           | `lesson`         |
| `pattern.detected`         | (Phase 2) 多 lesson 聚类形成 pattern | `lesson`      |

### 格式化（formatter）

| 类型                       | 触发                              | 必需 entity.type |
|----------------------------|-----------------------------------|------------------|
| `format.applied`           | spotless:apply 完成               | `file`           |
| `format.check.failed`      | Stop hook 检查失败                | `file`           |

---

## 4. 演进规则

- **新增事件类型**：只追加，不重命名。命名后即冻结。
- **新增字段**：必须放进 `ext.<plugin>.<field>`。核心 schema 字段冻结。
- **破坏性变更**：唯一方式是 `v: 2`，并在 `meta.json.schema_version` 标记。`v: 1` 事件永久可读。
- **未知字段**：消费者**必须**忽略，不报错。这是 forward-compatible 的根本保证。

---

## 5. 不在事件层做的事

- **不存储完整文档内容**。`.sop/plan.md` 的全文不进事件，只放 path + hash。文档内容在文件系统里。
- **不做权限控制**。事件流是项目内部的，由 git 提交权限决定。
- **不做实时 push**。事件是 pull 模型——消费者主动查询。L2 总线的"实时性"由 hook 在写入瞬间触发查询保证。

这些边界明确划定，避免 schema 蔓延。
