#!/usr/bin/env bash
# ============================================================================
#  co-review — TUI Dashboard
#
#  纯终端可视化看板，无依赖（仅 bash + tput）。
#  数据源：.team-scope/state.json + .team-scope/*.md
#
#  用法：
#    bash <plugin-root>/scripts/tui/dashboard.sh
#
#  快捷键：
#    1-5  切换面板（概览/贡献/完成度/风险/合并策略）
#    r    刷新
#    q    退出
# ============================================================================
set -uo pipefail

# 解析 plugin root（脚本所在目录的上两级）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# 加载共享库
# shellcheck source=../lib/git-helpers.sh
source "${PLUGIN_ROOT}/scripts/lib/git-helpers.sh"
# shellcheck source=tui-renderer.sh
source "${SCRIPT_DIR}/tui-renderer.sh"

# ---------- 前置校验 ----------
if [[ ! -f ".team-scope/state.json" ]]; then
    echo "❌ 未找到 .team-scope/state.json"
    echo "   请先在项目根目录执行 /scope-review 完成审查"
    exit 1
fi

# 检查 jq
if ! command -v jq >/dev/null 2>&1; then
    echo "❌ TUI 看板需要 jq 解析 JSON"
    echo "   安装：brew install jq (macOS) | apt install jq (Ubuntu)"
    exit 1
fi

# ---------- 全局状态 ----------
CURRENT_PANEL="overview"
NEED_REDRAW=1

# ---------- 信号处理 ----------
cleanup() {
    tput cnorm  # 恢复光标
    tput sgr0   # 重置颜色
    clear
    echo "TUI 看板已退出。"
    exit 0
}
trap cleanup INT TERM EXIT

# ---------- 主循环 ----------
tput civis  # 隐藏光标

while true; do
    if [[ $NEED_REDRAW -eq 1 ]]; then
        clear
        render_header
        case "$CURRENT_PANEL" in
            overview)    render_overview ;;
            contribution) render_contribution ;;
            completion)  render_completion ;;
            risks)       render_risks ;;
            strategy)    render_strategy ;;
        esac
        render_footer
        NEED_REDRAW=0
    fi

    # 读取单字符输入（500ms 超时，让其他事件可以触发）
    if read -rsn1 -t 0.5 key; then
        case "$key" in
            1) CURRENT_PANEL="overview"; NEED_REDRAW=1 ;;
            2) CURRENT_PANEL="contribution"; NEED_REDRAW=1 ;;
            3) CURRENT_PANEL="completion"; NEED_REDRAW=1 ;;
            4) CURRENT_PANEL="risks"; NEED_REDRAW=1 ;;
            5) CURRENT_PANEL="strategy"; NEED_REDRAW=1 ;;
            r|R) NEED_REDRAW=1 ;;
            q|Q) cleanup ;;
        esac
    fi
done
