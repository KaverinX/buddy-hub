# 合并策略决策树

供 `merge-strategy` skill 推导 `merge_strategy` 时参考。

## 决策树（按优先级从上到下匹配）

### 节点 1：是否存在违反考古红线？

判断条件：`risks.md` 中"违反考古红线"章节有 ⛔ critical 条目

- **是** → `team_health = ⛔ critical` + `merge_strategy = block-and-discuss`
  - 行动：暂停所有合并
  - 必须召开协调会议
  - 修复后重新执行 /scope-review

- **否** → 进入节点 2

---

### 节点 2：完成度是否极差？

判断条件：≥ 1 位开发者完成度为 🔴 低 且 critical 调试遗留 ≥ 1 处

- **是** → `team_health = 🔴 unhealthy` + `merge_strategy = escalate`
  - 行动：上报 lead
  - 该开发者的代码不应直接合并
  - 需团队评估是否需要重做或仅合并部分

- **否** → 进入节点 3

---

### 节点 3：是否存在跨人接口冲突？

判断条件：`risks.md` 中"接口签名不一致"章节有 🔴 高条目

- **是** → `team_health = 🔴 unhealthy` + `merge_strategy = coordinate-first`
  - 行动：先协调接口
  - 涉及的开发者必须达成一致
  - 协调后重新评估或部分合并

- **否** → 进入节点 4

---

### 节点 4：是否存在多人改动同文件且行重叠？

判断条件：`risks.md` 中"同文件多人改动"有 🔴 高条目（行重叠 + 语义冲突）

- **是** → `team_health = 🟡 warning` + `merge_strategy = coordinate-first`
  - 行动：相关开发者必须共同 review 重叠区域
  - 解决后选择更细的策略

- **否** → 进入节点 5

---

### 节点 5：是否所有改动相互独立？

判断条件：
- 无文件交集
- 无接口依赖关系
- 完成度均 ≥ 🟡 中

**判断"独立"的方法**：
对每对作者 (A, B)，检查：
- 改动文件集合无交集
- A 改动的 public 接口未被 B 调用
- B 改动的 public 接口未被 A 调用

- **是** → `team_health = 🟢 healthy` + `merge_strategy = merge-now-all`
  - 行动：可批量合并（仍提供独立的检查清单）
  - 顺序：完成度高的优先

- **否** → 进入节点 6

---

### 节点 6：默认情况

进入 `merge_strategy = staged-merge`：
- 行动：分阶段合并
- 顺序：基于依赖关系拓扑排序

`team_health` 取决于风险与完成度的综合：
- 任一开发者完成度 🔴 → `team_health = 🔴 unhealthy`
- 存在 🟡 风险但完成度都 ≥ 🟡 → `team_health = 🟡 warning`
- 完成度均 🟢 + 仅信息级风险 → `team_health = 🟢 healthy`

---

## 拓扑排序规则（用于 staged-merge 推荐顺序）

构造作者依赖图：
- 节点：每位作者
- 边：A → B 当 B 改动了 A 引入的接口/模块

排序输出：
1. 入度为 0 的节点（无依赖，可独立合并）
2. 按依赖关系逐层合并
3. 同层内，完成度高的优先

**示例输出**：
```
推荐合并顺序：
1. Carol（独立工具函数模块）
2. Alice（auth 模块，被 notification 模块依赖）
3. Bob（notification 模块，依赖 Alice 的接口）
```

## 检查清单生成规则

不同策略对应不同的清单模板：

### merge-now-all 的清单
- [ ] 每位开发者确认 PR 描述与实际代码一致
- [ ] 自动化测试通过（CI 绿灯）
- [ ] 各 PR 至少 1 位 reviewer 批准

### staged-merge 的清单
- [ ] 按推荐顺序逐个合并
- [ ] 每次合并后，下一个 PR 必须 rebase main
- [ ] 涉及的开发者确认接口契约稳定
- [ ] 各阶段合并后跑完整 CI

### coordinate-first 的清单
- [ ] 涉及的开发者参加协调会议
- [ ] 接口签名/字段命名达成一致
- [ ] 同文件冲突区域共同 review
- [ ] 协调结果以 commit 形式落地

### block-and-discuss 的清单
- [ ] 暂停所有合并
- [ ] 召开团队会议讨论违反红线的问题
- [ ] 决定：修复 / 修改红线 / escalate
- [ ] 修复后重新执行 /scope-review

### escalate 的清单
- [ ] 通知 lead
- [ ] 准备问题清单与背景
- [ ] 等待 lead 决策

## 边界情况

### 单作者分支
- 不进入决策树
- 直接输出 "single-author analysis"，不推荐合并策略
- 主报告只展示完成度章节

### 0 commits（空分支）
- /scope-review 在 Step 4 已拦截，不应到达此 skill

### 无 plan.md / arch.md（项目未使用 flowsmith）
- 决策树节点 3 中的"接口签名不一致"仍可基于 git diff 分析
- 决策树正常工作，仅丢失"边界遵守"维度
