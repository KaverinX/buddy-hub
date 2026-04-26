# Changelog — co-review

All notable changes to the `co-review` plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this plugin adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-04-26

### Added
- Initial release.
- **Three independent analyzer subagents**:
  - `contribution-analyzer` — 贡献画像、子任务匹配、模块边界识别、代码所有权地图
  - `completion-analyzer` — TODO/空实现/调试遗留/测试覆盖扫描，PR 自述偏差分析
  - `collab-risk-analyzer` — 4 类协作风险检测：同文件冲突、接口不一致、违反考古红线、重蹈历史覆辙
- **`merge-strategy` skill** — 综合 3 份 analyzer 报告，应用决策树生成最终合并策略
- **4 commands**: `/scope-review`, `/scope-status`, `/scope-compare`, `/scope-individual`
- **TUI 可视化看板**：纯 bash 实现，无 Web 依赖，5 个面板键盘切换
  - Overview / Contributions / Completion / Risks / Strategy
- **5 种合并策略**：merge-now-all / staged-merge / coordinate-first / block-and-discuss / escalate
- **可选输出**：
  - `--with-scores` 启用维度化评分（4 维度独立 🟢🟡🔴，不给综合分）
  - `--with-private-feedback` 生成私聊反馈（每人独立文件、严格隔离、中立+建设性）
- **flowsmith 集成**：
  - PostToolUse hook 检测 flowsmith review 完成 + 多人协作时主动建议
  - 自动读取 `.sop/plan.md`、`.sop/arch.md`、`.sop/lessons.md` 作为分析上下文
- **archaeology 集成**：
  - 自动读取 `.archaeology/report.md` 中的"不可跨越的红线"
  - collab-risk-analyzer 逐条对照红线检测违反
- **设计原则强化**：
  - `/scope-review` 自动取当前分支为目标，不接受位置参数（避免误分析）
  - 评分与私聊默认关闭，需显式启用
  - 私聊反馈强制三大边界：不评判态度 / 不横向对比 / 不出现他人信息
  - 主报告中"个人行动建议"针对个人，但仍不做横向对比
- 完整的 schema 契约：`co-review-schema.md`、`report-schemas.md`
- 共享工具库 `scripts/lib/git-helpers.sh`
- 配置开关：`BUDDY_COREVIEW_AUTO_SUGGEST`

### Design notes
- 三个 analyzer 独立上下文：避免分析维度互相污染
- co-review 只读不写其他 plugin 的状态文件：plugin 间通过共享文件协同
- TUI 优先于 Web：v1 验证数据模型，v2 再做 Web 看板
