# buddy-hub 多宿主能力说明（P4b）

> 诚实声明：buddy-hub 的核心护城河强绑定 Claude Code 运行时，**无法**完整跨宿主。
> 可跨宿主的只有"无状态方法论"——即 skills/commands 的 markdown 纪律本身。

## 为什么不能完整多宿主

OpenSpec / Superpowers 之所以易多宿主，是因为它们主体是 markdown 方法论。
buddy-hub 的差异化能力恰恰建立在 Claude Code 的**运行时机制**上：

- **hooks**（PostToolUse 自动格式化、Stop 风格门禁、绿灯测试门禁、状态校验）
- **context-keeper 事件总线 + mirror**（靠 hook 在文件写入瞬间捕获状态变更）
- **co-review TUI**、state.json 校验脚本等

这些在 Cursor / Codex / Gemini CLI 上没有等价的稳定钩子点，强行移植会得到一个"残缺且会误导"的版本。因此本方案选择**分层导出**而非假装对等。

## 能力矩阵：什么能移植，什么不能

| 能力 | Claude Code（原生） | 其他宿主（导出后） |
|------|---------------------|--------------------|
| 方法论纪律（plan/arch/TDD/调试/澄清/规格撰写 等 Skill） | ✅ 自动触发 | ✅ 可用（手动引用为指令） |
| 命令流程说明（/sop-*、/spec-* 的步骤） | ✅ slash command | △ 需按宿主格式手动映射 |
| Iron Law + 红旗行为约束 | ✅ | ✅ 纯文本，完全可移植 |
| 状态机门禁（阶段迁移、绿灯拦截） | ✅ hook 强制 | ❌ 无 hook，降级为"人工自律遵循" |
| 自动格式化 / 风格门禁 | ✅ hook | ❌ |
| 事件总线 / 知识图谱 / 物化视图 | ✅ | ❌ |
| co-review TUI 看板 | ✅ | ❌ |

> △ = 部分可用且需手动适配；❌ = 不可移植（运行时强相关）。

## 如何导出

```bash
bash scripts/export-portable.sh ./portable
```

生成 `portable/`：汇集所有 plugin 的 skills/commands markdown + `INDEX.md`。
把它接入目标宿主的"项目指令/规则"机制即可获得**无状态方法论部分**：

- Cursor：转为 `.cursor/rules/*.mdc`
- Codex / Gemini CLI：作为自定义指令 / prompts 引用
- 任意 LLM：直接作为系统提示的纪律附录

## 定位建议

把多宿主导出当作**获客入口与方法论传播**，而非能力对等承诺：
让其他宿主用户先尝到 buddy-hub 的纪律（TDD/澄清/规格/红旗），需要门禁强制、知识图谱、协作 TUI 等"带运行时的真本事"时，再回到 Claude Code。
