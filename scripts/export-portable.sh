#!/usr/bin/env bash
# buddy-hub 可移植导出器（P4b 多宿主）
# 只导出【无状态方法论】——把各 plugin 的 skills/ 与 commands/ 的 markdown
# 汇集为一个 host-agnostic 的 portable bundle，供 Cursor / Codex / Gemini CLI 等手动接入。
#
# 明确不导出（这些强绑定 Claude Code 运行时，无法跨宿主）：
#   - hooks/（PostToolUse/Stop 等运行时钩子）
#   - context-keeper 事件总线 / mirror（依赖 Claude Code hook 触发）
#   - co-review TUI、state 校验脚本等
#
# 用法：bash scripts/export-portable.sh [输出目录，默认 ./portable]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/portable}"
PLUGINS_DIR="$ROOT/plugins"

rm -rf "$OUT"
mkdir -p "$OUT/skills" "$OUT/commands"

INDEX="$OUT/INDEX.md"
{
  echo "# buddy-hub 可移植方法论 bundle"
  echo
  echo "> 由 export-portable.sh 生成。仅含无状态方法论（skills + commands 的 markdown）。"
  echo "> 运行时能力（hooks/事件总线/TUI）未包含，见 MULTI-HOST.md 能力矩阵。"
  echo
  echo "## Skills"
} > "$INDEX"

skill_count=0
cmd_count=0

for plugin_path in "$PLUGINS_DIR"/*/; do
  plugin_path="${plugin_path%/}"
  plugin="$(basename "$plugin_path")"

  # 导出 skills
  if [ -d "$plugin_path/skills" ]; then
    while IFS= read -r -d '' sk; do
      rel="${sk#"$plugin_path"/skills/}"
      dest="$OUT/skills/$plugin/$rel"
      mkdir -p "$(dirname "$dest")"
      cp "$sk" "$dest"
      [ "$(basename "$sk")" = "SKILL.md" ] && {
        name=$(grep -m1 '^name:' "$sk" | sed 's/name: *//')
        echo "- \`$plugin/$name\` — skills/$plugin/$rel" >> "$INDEX"
        skill_count=$((skill_count+1))
      }
    done < <(find "$plugin_path/skills" -name '*.md' -print0)
  fi

  # 导出 commands（去掉 Claude Code 专有 argument-hint 留作说明）
  if [ -d "$plugin_path/commands" ]; then
    while IFS= read -r -d '' cmd; do
      base="$(basename "$cmd")"
      mkdir -p "$OUT/commands/$plugin"
      cp "$cmd" "$OUT/commands/$plugin/$base"
      cmd_count=$((cmd_count+1))
    done < <(find "$plugin_path/commands" -name '*.md' -print0)
  fi
done

{
  echo
  echo "## Commands"
  echo
  echo "各宿主接入方式不同（Cursor 用 .mdc / Codex 用自定义指令 / Gemini CLI 用 prompts），"
  echo "本 bundle 提供原始 markdown，由各宿主的转换约定手动映射为其 slash command 形式。"
} >> "$INDEX"

echo "导出完成：$OUT"
echo "  skills: $skill_count 个 SKILL.md"
echo "  commands: $cmd_count 个"
echo "  索引：$INDEX"
