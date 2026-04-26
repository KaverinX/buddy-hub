#!/usr/bin/env bash
# ============================================================================
#  co-review — TUI Renderer
#
#  渲染各个面板的函数。被 dashboard.sh 加载。
# ============================================================================

# ---------- 颜色与样式 ----------
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'

C_RED=$'\033[31m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_BLUE=$'\033[34m'
C_MAGENTA=$'\033[35m'
C_CYAN=$'\033[36m'

C_BG_BLUE=$'\033[44m'
C_BG_GRAY=$'\033[100m'

# ---------- 工具函数 ----------

# 获取终端宽度
term_width() {
    tput cols 2>/dev/null || echo 80
}

# 居中文本
center() {
    local text="$1"
    local width=${2:-$(term_width)}
    local text_len=${#text}
    local pad=$(( (width - text_len) / 2 ))
    printf "%${pad}s%s\n" "" "$text"
}

# 打印水平线
hr() {
    local width=${1:-$(term_width)}
    local char=${2:-─}
    printf "%${width}s\n" "" | tr ' ' "$char"
}

# 健康度图标
health_icon() {
    case "$1" in
        "🟢 healthy"|"healthy") echo "${C_GREEN}● healthy${C_RESET}" ;;
        "🟡 warning"|"warning") echo "${C_YELLOW}● warning${C_RESET}" ;;
        "🔴 unhealthy"|"unhealthy") echo "${C_RED}● unhealthy${C_RESET}" ;;
        "⛔ critical"|"critical") echo "${C_RED}${C_BOLD}■ CRITICAL${C_RESET}" ;;
        *) echo "${C_DIM}○ pending${C_RESET}" ;;
    esac
}

# 状态图标
status_icon() {
    case "$1" in
        done) echo "${C_GREEN}✓${C_RESET}" ;;
        running) echo "${C_YELLOW}⟳${C_RESET}" ;;
        pending) echo "${C_DIM}○${C_RESET}" ;;
        skipped) echo "${C_DIM}⊘${C_RESET}" ;;
        failed) echo "${C_RED}✗${C_RESET}" ;;
        *) echo "?" ;;
    esac
}

# JSON 字段读取
json_get() {
    local path="$1"
    jq -r "$path // empty" .team-scope/state.json 2>/dev/null
}

# ---------- 头部 ----------
render_header() {
    local width
    width=$(term_width)
    local review_id branch base health strategy
    review_id=$(json_get '.review_id')
    branch=$(json_get '.scope.branch')
    base=$(json_get '.scope.base')
    health=$(json_get '.report.team_health')
    strategy=$(json_get '.report.merge_strategy')

    echo "${C_BG_BLUE}${C_BOLD}"
    printf "%-${width}s\n" "  co-review TUI Dashboard  |  Review: ${review_id}  |  ${branch} → ${base}"
    echo "${C_RESET}"
    echo
    printf "  Team Health: %s    Merge Strategy: ${C_BOLD}%s${C_RESET}\n" \
        "$(health_icon "$health")" "${strategy:-pending}"
    echo
    hr "$width"
}

# ---------- 底部（导航栏）----------
render_footer() {
    local width
    width=$(term_width)
    echo
    hr "$width"
    local nav_overview nav_contrib nav_compl nav_risk nav_strat
    case "$CURRENT_PANEL" in
        overview)    nav_overview="${C_BG_BLUE}${C_BOLD} 1.Overview ${C_RESET}" ;;
        *)           nav_overview=" 1.Overview " ;;
    esac
    case "$CURRENT_PANEL" in
        contribution) nav_contrib="${C_BG_BLUE}${C_BOLD} 2.Contributions ${C_RESET}" ;;
        *)            nav_contrib=" 2.Contributions " ;;
    esac
    case "$CURRENT_PANEL" in
        completion)  nav_compl="${C_BG_BLUE}${C_BOLD} 3.Completion ${C_RESET}" ;;
        *)           nav_compl=" 3.Completion " ;;
    esac
    case "$CURRENT_PANEL" in
        risks)       nav_risk="${C_BG_BLUE}${C_BOLD} 4.Risks ${C_RESET}" ;;
        *)           nav_risk=" 4.Risks " ;;
    esac
    case "$CURRENT_PANEL" in
        strategy)    nav_strat="${C_BG_BLUE}${C_BOLD} 5.Strategy ${C_RESET}" ;;
        *)           nav_strat=" 5.Strategy " ;;
    esac
    echo "${nav_overview}${nav_contrib}${nav_compl}${nav_risk}${nav_strat}    ${C_DIM}r=refresh  q=quit${C_RESET}"
}

# ---------- Panel 1: Overview ----------
render_overview() {
    echo "${C_BOLD}─── 审查概况 ───${C_RESET}"
    echo

    local trigger flowsmith_id has_arch arch_id mode
    trigger=$(json_get '.context.trigger')
    flowsmith_id=$(json_get '.context.flowsmith_task_id')
    has_arch=$(json_get '.context.has_archaeology')
    arch_id=$(json_get '.context.archaeology_id')
    mode=$(json_get '.scope.mode')

    printf "  触发方式：    %s\n" "${trigger:-manual}"
    printf "  分析模式：    %s\n" "${mode:-pr}"
    printf "  flowsmith 关联：%s\n" "${flowsmith_id:-无}"
    printf "  考古关联：    %s\n" "$( [[ "$has_arch" == "true" ]] && echo "$arch_id" || echo "无" )"
    echo

    echo "${C_BOLD}─── 数据统计 ───${C_RESET}"
    echo
    local authors commits files added removed
    authors=$(json_get '.stats.authors_count')
    commits=$(json_get '.stats.commits_count')
    files=$(json_get '.stats.files_changed')
    added=$(json_get '.stats.loc_added')
    removed=$(json_get '.stats.loc_removed')

    printf "  作者数：      %s\n" "${authors:-0}"
    printf "  Commits：     %s\n" "${commits:-0}"
    printf "  文件改动：    %s\n" "${files:-0}"
    printf "  代码量：      ${C_GREEN}+%s${C_RESET} / ${C_RED}-%s${C_RESET}\n" "${added:-0}" "${removed:-0}"
    echo

    echo "${C_BOLD}─── 分析员状态 ───${C_RESET}"
    echo
    local s1 s2 s3
    s1=$(json_get '.agents."contribution-analyzer".status')
    s2=$(json_get '.agents."completion-analyzer".status')
    s3=$(json_get '.agents."collab-risk-analyzer".status')

    printf "  $(status_icon "$s1") contribution-analyzer  %s\n" "$s1"
    printf "  $(status_icon "$s2") completion-analyzer    %s\n" "$s2"
    printf "  $(status_icon "$s3") collab-risk-analyzer   %s\n" "$s3"
    echo

    echo "${C_BOLD}─── 启用选项 ───${C_RESET}"
    echo
    local opt_scores opt_priv opt_rhy
    opt_scores=$(json_get '.options.with_scores')
    opt_priv=$(json_get '.options.with_private_feedback')
    opt_rhy=$(json_get '.options.with_rhythm')

    [[ "$opt_scores" == "true" ]] && printf "  ${C_GREEN}✓${C_RESET}" || printf "  ${C_DIM}○${C_RESET}"
    echo " 维度评分（with-scores）"
    [[ "$opt_priv" == "true" ]] && printf "  ${C_GREEN}✓${C_RESET}" || printf "  ${C_DIM}○${C_RESET}"
    echo " 私聊反馈（with-private-feedback）"
    [[ "$opt_rhy" == "true" ]] && printf "  ${C_GREEN}✓${C_RESET}" || printf "  ${C_DIM}○${C_RESET}"
    echo " 工作节奏（with-rhythm）"
}

# ---------- Panel 2: Contributions ----------
render_contribution() {
    echo "${C_BOLD}─── 贡献画像（来自 contributions.md）───${C_RESET}"
    echo

    if [[ ! -f ".team-scope/contributions.md" ]]; then
        echo "  ${C_DIM}contributions.md 尚未生成${C_RESET}"
        return
    fi

    # 提取并展示"团队贡献概览"章节
    awk '
        /^## 团队贡献概览/ { capture=1; next }
        /^## / && capture { exit }
        capture && /^\|/ { print "  " $0 }
    ' .team-scope/contributions.md

    echo
    echo "${C_BOLD}─── 子任务对应（若 plan.md 存在）───${C_RESET}"
    echo
    awk '
        /^## 子任务对应/ { capture=1; next }
        /^## / && capture { exit }
        capture && (/^\|/ || /^\*\*/) { print "  " $0 }
    ' .team-scope/contributions.md | head -20

    echo
    echo "${C_DIM}  完整内容：cat .team-scope/contributions.md${C_RESET}"
}

# ---------- Panel 3: Completion ----------
render_completion() {
    echo "${C_BOLD}─── 完成度评估（来自 completion.md）───${C_RESET}"
    echo

    if [[ ! -f ".team-scope/completion.md" ]]; then
        echo "  ${C_DIM}completion.md 尚未生成${C_RESET}"
        return
    fi

    # 提取"团队整体完成度"
    awk '
        /^## 团队整体完成度/ { capture=1; next }
        /^## / && capture { exit }
        capture && NF { print "  " $0 }
    ' .team-scope/completion.md

    echo
    echo "${C_BOLD}─── 每人完成度信号 ───${C_RESET}"
    echo

    awk '
        /^## 每人完成度信号/ { capture=1; next }
        /^## / && capture { exit }
        capture && /^\|/ { print "  " $0 }
    ' .team-scope/completion.md

    echo
    echo "${C_DIM}  完整内容：cat .team-scope/completion.md${C_RESET}"
}

# ---------- Panel 4: Risks ----------
render_risks() {
    echo "${C_BOLD}─── 协作风险（来自 risks.md）───${C_RESET}"
    echo

    if [[ ! -f ".team-scope/risks.md" ]]; then
        echo "  ${C_DIM}risks.md 尚未生成${C_RESET}"
        return
    fi

    # 提取风险评级摘要
    awk '
        /^## 风险评级摘要/ { capture=1; next }
        /^## / && capture { exit }
        capture && /^\|/ { print "  " $0 }
    ' .team-scope/risks.md

    echo
    echo "${C_BOLD}─── 关键发现 ───${C_RESET}"
    echo

    awk '
        /^## 关键发现/ { capture=1; next }
        /^## / && capture { exit }
        capture && NF { print "  " $0 }
    ' .team-scope/risks.md | head -20

    echo
    # 突出红线违反
    if grep -q "违反考古红线" .team-scope/risks.md; then
        if grep -q "⛔" .team-scope/risks.md; then
            echo "${C_RED}${C_BOLD}  ⛔ 检测到违反考古红线，必须修复后才能合并！${C_RESET}"
            echo
        fi
    fi

    echo "${C_DIM}  完整内容：cat .team-scope/risks.md${C_RESET}"
}

# ---------- Panel 5: Merge Strategy ----------
render_strategy() {
    echo "${C_BOLD}─── 合并策略（来自 report.md）───${C_RESET}"
    echo

    if [[ ! -f ".team-scope/report.md" ]]; then
        echo "  ${C_DIM}report.md 尚未生成（等待 merge-strategy skill 完成）${C_RESET}"
        return
    fi

    local strategy
    strategy=$(json_get '.report.merge_strategy')

    case "$strategy" in
        merge-now-all)
            echo "  ${C_GREEN}${C_BOLD}● merge-now-all${C_RESET} — 可批量合并"
            ;;
        staged-merge)
            echo "  ${C_YELLOW}${C_BOLD}● staged-merge${C_RESET} — 按推荐顺序分阶段合并"
            ;;
        coordinate-first)
            echo "  ${C_YELLOW}${C_BOLD}● coordinate-first${C_RESET} — 先解决人际协调"
            ;;
        block-and-discuss)
            echo "  ${C_RED}${C_BOLD}● block-and-discuss${C_RESET} — 暂停，召开协调会议"
            ;;
        escalate)
            echo "  ${C_RED}${C_BOLD}● escalate${C_RESET} — 上报 lead"
            ;;
        *)
            echo "  ${C_DIM}● ${strategy:-unknown}${C_RESET}"
            ;;
    esac
    echo

    echo "${C_BOLD}─── 推荐合并顺序 ───${C_RESET}"
    echo
    awk '
        /^### 推荐合并顺序/ { capture=1; next }
        /^### / && capture { exit }
        capture && NF { print "  " $0 }
    ' .team-scope/report.md

    echo
    echo "${C_BOLD}─── 合并前检查清单 ───${C_RESET}"
    echo
    awk '
        /^### 合并前检查清单/ { capture=1; next }
        /^### / && capture { exit }
        capture && NF { print "  " $0 }
    ' .team-scope/report.md

    echo
    echo "${C_DIM}  完整报告：cat .team-scope/report.md${C_RESET}"
}
