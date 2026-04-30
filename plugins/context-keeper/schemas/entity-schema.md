# Entity Schema (物化视图)

> 实体 = 事件流的物化视图。所有实体都可以由 `events.jsonl` 重建。
> 实体文件不是事实来源——它们是缓存。删了用 `context rebuild` 可以重建。

---

## 1. 存储位置

```
.context/
├── events.jsonl              # 事实来源，append-only
├── entities/
│   ├── task/<id>.json
│   ├── decision/<id>.json
│   ├── risk/<id>.json
│   ├── red_line/<id>.json
│   ├── lesson/<id>.json
│   ├── author/<id>.json
│   └── ...
├── index.json                # 实体索引（id → type → 最新 entity 文件）
└── meta.json                 # schema_version, last_event_id, last_migrated_at
```

每个实体文件包含完整状态 + 它最近一次的 `event_id` 引用。

---

## 2. 通用包装

所有实体文件都有这个 envelope：

```jsonc
{
  "_v": 1,                              // entity schema version
  "_type": "task",                      // 实体类型
  "_id": "a3f8c1d2",                    // 实体 id
  "_first_event": "evt_...",            // 最早影响此实体的事件
  "_last_event": "evt_...",             // 最近影响此实体的事件
  "_updated_at": "2026-04-28T16:30:00Z",

  // 以下是实体本身的字段
  "...": "..."
}
```

下游查询：`get-entity --type=task --id=a3f8c1d2` 直接返回这个对象。

---

## 3. 实体定义

### task

```jsonc
{
  "_type": "task", "_id": "a3f8c1d2", ...,
  "summary": "重构 UserService 的认证逻辑",
  "current_phase": "REVIEW",            // PLANNING|ARCHITECTURE|IMPLEMENTATION|OPTIMIZATION|REVIEW|DONE|CLOSED
  "iteration": 2,
  "started_at": "...",
  "closed_at": null,
  "linked_archaeology_id": "arch_x9k...",  // 若做过考古
  "linked_team_review_id": null,
  "open_critical_count": 0
}
```

**id 来源**：flowsmith `task_id`（8 位随机串）。task_id 是跨 plugin 的关联键。

### decision

```jsonc
{
  "_type": "decision", "_id": "dec_<ulid>", ...,
  "task_id": "a3f8c1d2",
  "category": "ADR" | "risk-acceptance" | "refactor-strategy" | "merge-strategy",
  "title": "采用 staged-refactor 策略",
  "rationale": "...",                    // 简短摘要，全文在源文件
  "source": { "path": ".sop/arch.md", "section": "ADR #2" },
  "made_by": "user" | "flowsmith" | "code-archaeologist"
}
```

### risk

```jsonc
{
  "_type": "risk", "_id": "rsk_<ulid>", ...,
  "task_id": "a3f8c1d2",
  "level": "high" | "medium" | "low",
  "statement": "OAuth 模块的反射调用会被破坏",
  "source": { "path": ".sop/plan.md", "section": "风险评估" },
  "status": "open" | "accepted" | "mitigated" | "materialized",
  "mitigation": "..."                    // 可选
}
```

### red_line

```jsonc
{
  "_type": "red_line", "_id": "rl_<ulid>", ...,
  "source_task_id": "a3f8c1d2",          // 设立此红线的考古所属任务
  "set_by": "code-archaeologist",
  "statement": "不得重命名 UserService.findById 方法",
  "applies_to": [
    { "kind": "file", "path": "src/auth/UserService.java" },
    { "kind": "symbol", "fqn": "com.x.UserService.findById" }
  ],
  "rationale": "OAuth 模块通过反射调用",
  "status": "active" | "violated" | "lifted",
  "violations": []                       // 引用 red_line.violated 事件 id
}
```

### lesson

```jsonc
{
  "_type": "lesson", "_id": "lsn_<ulid>", ...,
  "source_task_id": "a3f8c1d2",
  "category": "security" | "performance" | "correctness" | "process" | "design",
  "statement": "OAuth 集成测试应当覆盖反射调用路径",
  "tags": ["oauth", "auth", "reflection"],
  "evidence_path": ".sop/lessons.md#L42"
}
```

### author

```jsonc
{
  "_type": "author", "_id": "alice_at_example_com", ...,
  "name": "Alice Wong",
  "emails": ["alice@example.com", "alice.w@example.com"],
  "first_seen_at": "...",
  "last_seen_at": "...",
  "task_count": 12
}
```

**id 来源**：邮箱 local-part 规范化（`alice.w@example.com` → `alice_w_at_example_com`）。
co-review 已经按"邮箱 local-part 相同视为同人"处理同人多邮箱，这里复用其规范化规则。

### file（轻量引用）

```jsonc
{
  "_type": "file", "_id": "<sha1 of relpath>", ...,
  "path": "src/auth/UserService.java",
  "language": "java",
  "first_touched_event": "evt_...",
  "last_touched_event": "evt_...",
  "touched_by_tasks": ["a3f8c1d2", "b1e2f3d4"]
}
```

仅当 file 被红线/审查/考古"显式提及"时才创建实体。普通编辑不进 entities，避免膨胀。

### review

```jsonc
{
  "_type": "review", "_id": "rev_<ulid>", ...,
  "task_id": "a3f8c1d2",
  "kind": "sop-review" | "scope-review",
  "iteration": 1,
  "started_at": "...",
  "completed_at": "...",
  "critical_count": 2,
  "warning_count": 5,
  "findings_path": ".sop/review.md"
}
```

### report

```jsonc
{
  "_type": "report", "_id": "rep_<ulid>", ...,
  "task_id": "a3f8c1d2",
  "kind": "archaeology" | "team-scope",
  "path": ".archaeology/report.md",
  "summary": "风险评级 medium，推荐 staged-refactor",
  "generated_at": "..."
}
```

---

## 4. 索引（index.json）

```jsonc
{
  "_v": 1,
  "by_type": {
    "task":     ["a3f8c1d2", "b1e2f3d4"],
    "red_line": ["rl_01HX...", "rl_01HY..."],
    "...": "..."
  },
  "by_task": {
    "a3f8c1d2": {
      "decisions": ["dec_..."],
      "risks":     ["rsk_..."],
      "red_lines": ["rl_..."],
      "lessons":   ["lsn_..."],
      "reviews":   ["rev_..."],
      "reports":   ["rep_..."]
    }
  },
  "by_file": {
    "src/auth/UserService.java": {
      "red_lines": ["rl_..."],
      "tasks":     ["a3f8c1d2"]
    }
  }
}
```

索引由事件流物化生成，可以 `context rebuild` 重建。

---

## 5. 重建语义

任意时刻执行：

```bash
context rebuild
```

会：
1. 删除 `.context/entities/` 和 `.context/index.json`
2. 顺序重放 `.context/events.jsonl`
3. 重新物化所有实体
4. 重建索引

事件流是事实来源；实体文件是缓存。任何不一致都以事件流为准。

---

## 6. Phase 2 / Phase 3 预留

以下实体在 Phase 2+ 引入，目前 schema 不定义：

- `pattern`：lesson 聚类后的模式
- `playbook`：pattern → 主动建议
- `incident`：生产事故（field-sentinel 引入）

不预定义是为了避免空 schema 误导后续设计。
