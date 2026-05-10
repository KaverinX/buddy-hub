#!/usr/bin/env bash
# context-keeper · 历史链路 mirror hook
#
# 触发：PostToolUse on Write|Edit
# 作用：监听对现有 4 个 plugin 状态文件的写入，自动 emit 对应事件。
#       现有 plugin 不需要做任何修改——这是非侵入式集成的关键。
#
# 监听清单：
#   .sop/state.json         → flowsmith 状态机
#   .sop/lessons.md         → flowsmith 经验沉淀（追加检测）
#   .archaeology/state.json → code-archaeologist 状态
#   .archaeology/report.md  → code-archaeologist 报告生成
#   .team-scope/state.json  → co-review 状态
#
# 退出码始终 0（提示走 stderr，不阻断 Claude）。

set -uo pipefail

# ---------- 0. 引用 lib ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
[[ -d "$LIB_DIR" ]] || LIB_DIR="${CLAUDE_PLUGIN_ROOT:-$SCRIPT_DIR/..}/scripts/lib"
export CK_LIB_DIR="$LIB_DIR"

# shellcheck source=./lib/common.sh
source "$LIB_DIR/common.sh" 2>/dev/null || exit 0
# shellcheck source=./lib/events.sh
source "$LIB_DIR/events.sh" 2>/dev/null || exit 0
# shellcheck source=./lib/entities.sh
source "$LIB_DIR/entities.sh" 2>/dev/null || exit 0

ck_is_enabled || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# ============================================================
# 工具函数
# ============================================================

snap_set() {
    # $1 = jq path (e.g. ".sop"); $2 = JSON value
    local snap="$(ck_mirror_state)" tmp
    tmp=$(mktemp)
    jq --argjson v "$2" "$1 = \$v" "$snap" > "$tmp" 2>/dev/null && mv "$tmp" "$snap" || rm -f "$tmp"
}

snap_set_str() {
    # $1 = jq path; $2 = string value
    local snap="$(ck_mirror_state)" tmp
    tmp=$(mktemp)
    jq --arg v "$2" "$1 = \$v" "$snap" > "$tmp" 2>/dev/null && mv "$tmp" "$snap" || rm -f "$tmp"
}

# ============================================================
# 各文件 mirror 处理函数
# ============================================================

# ---------- flowsmith state.json ----------
mirror_sop_state() {
    local file="$1"
    local cur prev
    cur=$(jq -c '{
        task_id, task_summary, current_phase, iteration,
        open_critical: ([(.open_issues // [])[] | select(.level=="critical" and .status=="open")] | length)
    }' "$file" 2>/dev/null) || return 0
    [[ -z "$cur" || "$cur" == "null" ]] && return 0

    prev=$(jq -c '.sop // null' "$(ck_mirror_state)")

    local task_id task_summary current_phase iteration
    task_id=$(echo "$cur" | jq -r '.task_id // empty')
    task_summary=$(echo "$cur" | jq -r '.task_summary // ""')
    current_phase=$(echo "$cur" | jq -r '.current_phase // empty')
    iteration=$(echo "$cur" | jq -r '.iteration // 1')
    [[ -z "$task_id" ]] && return 0

    # 1) task_id 变化 → task.created
    local prev_task_id=""
    [[ "$prev" != "null" ]] && prev_task_id=$(echo "$prev" | jq -r '.task_id // ""')

    if [[ "$prev_task_id" != "$task_id" ]]; then
        local entity ev ext new_evt
        entity=$(jq -nc --arg id "$task_id" '{type:"task", id:$id, ref:{path:".sop/state.json"}}')
        ev=$(jq -nc --arg p "$file" --arg h "$(ck_sha1_file "$file")" \
            '[{kind:"file", path:$p, hash_sha1:$h}]')
        ext=$(jq -nc --arg s "$task_summary" '{summary:$s}')
        new_evt=$(ck_event_make "task.created" "flowsmith" "$task_id" "$entity" "$ev" "$ext")
        ck_event_append "$new_evt" >/dev/null 2>&1 \
            && ck_debug "emitted task.created $task_id"
    fi

    # 2) phase 切换
    local prev_phase=""
    [[ "$prev_task_id" == "$task_id" && "$prev" != "null" ]] && \
        prev_phase=$(echo "$prev" | jq -r '.current_phase // ""')

    if [[ "$prev_phase" != "$current_phase" && -n "$current_phase" ]]; then
        local entity ev ext etype new_evt
        entity=$(jq -nc --arg id "$task_id" '{type:"task", id:$id, ref:{path:".sop/state.json"}}')
        ev=$(jq -nc --arg from "$prev_phase" --arg to "$current_phase" --arg p "$file" \
            '[{kind:"file", path:$p}, {kind:"diff", field:"current_phase", from:$from, to:$to}]')
        ext=$(jq -nc --arg p "$current_phase" '{phase:$p}')
        if [[ "$current_phase" == "DONE" || "$current_phase" == "CLOSED" ]]; then
            etype="task.closed"
        else
            etype="task.phase.entered"
        fi
        new_evt=$(ck_event_make "$etype" "flowsmith" "$task_id" "$entity" "$ev" "$ext")
        ck_event_append "$new_evt" >/dev/null 2>&1 \
            && ck_debug "emitted $etype $task_id ($prev_phase → $current_phase)"
    fi

    # 3) iteration 增加（review 进入新一轮）
    local prev_iter="1"
    [[ "$prev_task_id" == "$task_id" && "$prev" != "null" ]] && \
        prev_iter=$(echo "$prev" | jq -r '.iteration // 1')
    if (( iteration > prev_iter )); then
        local entity ev new_evt
        entity=$(jq -nc --arg id "$task_id" '{type:"task", id:$id}')
        ev=$(jq -nc --argjson f "$prev_iter" --argjson t "$iteration" \
            '[{kind:"diff", field:"iteration", from:$f, to:$t}]')
        new_evt=$(ck_event_make "task.iteration.started" "flowsmith" "$task_id" "$entity" "$ev" '{}')
        ck_event_append "$new_evt" >/dev/null 2>&1
    fi

    snap_set ".sop" "$cur"
}

# ---------- archaeology state.json ----------
mirror_arch_state() {
    local file="$1"
    local cur prev
    cur=$(jq -c '{
        task_id: (.task_id // null),
        report_status: (.report.status // null),
        linked_sop_task: (.linked_sop_task // null)
    }' "$file" 2>/dev/null) || return 0
    [[ -z "$cur" || "$cur" == "null" ]] && return 0
    prev=$(jq -c '.arch // null' "$(ck_mirror_state)")

    local arch_task linked_task report_status
    arch_task=$(echo "$cur" | jq -r '.task_id // empty')
    linked_task=$(echo "$cur" | jq -r '.linked_sop_task // empty')
    report_status=$(echo "$cur" | jq -r '.report_status // empty')
    [[ -z "$arch_task" ]] && return 0

    # 新考古启动
    local prev_arch=""
    [[ "$prev" != "null" ]] && prev_arch=$(echo "$prev" | jq -r '.task_id // ""')
    if [[ "$prev_arch" != "$arch_task" ]]; then
        local entity ev new_evt
        entity=$(jq -nc --arg id "$arch_task" '{type:"task", id:$id, ref:{path:".archaeology/state.json"}}')
        ev=$(jq -nc --arg p "$file" '[{kind:"file", path:$p}]')
        new_evt=$(ck_event_make "archaeology.started" "code-archaeologist" "$linked_task" "$entity" "$ev" '{}')
        ck_event_append "$new_evt" >/dev/null 2>&1
    fi

    # 报告状态变 done
    local prev_status=""
    [[ "$prev" != "null" ]] && prev_status=$(echo "$prev" | jq -r '.report_status // ""')
    if [[ "$prev_status" != "done" && "$report_status" == "done" ]]; then
        local rep_id entity ev ext new_evt
        rep_id="rep_$(echo "$arch_task" | tr -dc 'a-z0-9' | head -c 16)"
        entity=$(jq -nc --arg id "$rep_id" '{type:"report", id:$id, ref:{path:".archaeology/report.md"}}')
        ev=$(jq -nc '[{kind:"diff", field:"report.status", from:"running", to:"done"}]')
        ext=$(jq -nc '{path:".archaeology/report.md", kind:"archaeology"}')
        new_evt=$(ck_event_make "archaeology.report.generated" "code-archaeologist" "$linked_task" "$entity" "$ev" "$ext")
        ck_event_append "$new_evt" >/dev/null 2>&1
    fi

    snap_set ".arch" "$cur"
}

# ---------- co-review state.json ----------
mirror_team_state() {
    local file="$1"
    local cur prev
    cur=$(jq -c '{
        review_id: (.review_id // null),
        status: (.status // null),
        team_health: (.team_health // null),
        merge_strategy: (.merge_strategy // null),
        sop_task: (.linked_sop_task // null)
    }' "$file" 2>/dev/null) || return 0
    [[ -z "$cur" || "$cur" == "null" ]] && return 0
    prev=$(jq -c '.team // null' "$(ck_mirror_state)")

    local rev_id status linked_task
    rev_id=$(echo "$cur" | jq -r '.review_id // empty')
    status=$(echo "$cur" | jq -r '.status // empty')
    linked_task=$(echo "$cur" | jq -r '.sop_task // empty')
    [[ -z "$rev_id" ]] && return 0

    local prev_status=""
    [[ "$prev" != "null" ]] && prev_status=$(echo "$prev" | jq -r '.status // ""')

    if [[ "$prev_status" != "done" && "$status" == "done" ]]; then
        local entity ev ext new_evt
        entity=$(jq -nc --arg id "$rev_id" '{type:"review", id:$id, ref:{path:".team-scope/state.json"}}')
        ev=$(jq -nc --arg p "$file" '[{kind:"file", path:$p}, {kind:"diff", field:"status", from:"running", to:"done"}]')
        ext=$(jq -nc \
            --arg th "$(echo "$cur" | jq -r '.team_health // "unknown"')" \
            --arg ms "$(echo "$cur" | jq -r '.merge_strategy // "unknown"')" \
            '{team_health:$th, merge_strategy:$ms, findings_path:".team-scope/report.md"}')
        new_evt=$(ck_event_make "team_review.completed" "co-review" "$linked_task" "$entity" "$ev" "$ext")
        ck_event_append "$new_evt" >/dev/null 2>&1
    fi

    snap_set ".team" "$cur"
}

# ---------- lessons.md ----------
# 自由 markdown，不解析内容，只在哈希变化时记一条粗粒度 lesson.recorded。
mirror_lessons() {
    local file="$1"
    local cur_hash prev_hash
    cur_hash=$(ck_sha1_file "$file")
    prev_hash=$(jq -r '.lessons_hash // ""' "$(ck_mirror_state)")
    [[ -z "$cur_hash" || "$cur_hash" == "$prev_hash" ]] && return 0

    local size lid entity ev ext new_evt
    size=$(wc -c < "$file" 2>/dev/null | tr -d ' ')
    lid="lsn_$(echo "$cur_hash" | head -c 16)"
    entity=$(jq -nc --arg id "$lid" '{type:"lesson", id:$id, ref:{path:".sop/lessons.md"}}')
    ev=$(jq -nc --arg p "$file" --arg h "$cur_hash" '[{kind:"file", path:$p, hash_sha1:$h}]')
    ext=$(jq -nc --arg s "$size" '{statement:"(lessons.md updated)", category:"process", evidence_path:".sop/lessons.md", file_size:($s|tonumber)}')
    new_evt=$(ck_event_make "lesson.recorded" "context-keeper-mirror" "" "$entity" "$ev" "$ext")
    ck_event_append "$new_evt" >/dev/null 2>&1

    snap_set_str ".lessons_hash" "$cur_hash"
}

# ---------- archaeology/report.md ----------
mirror_arch_report() {
    local file="$1"
    local cur_hash prev_hash
    cur_hash=$(ck_sha1_file "$file")
    prev_hash=$(jq -r '.arch_report_hash // ""' "$(ck_mirror_state)")
    [[ -z "$cur_hash" || "$cur_hash" == "$prev_hash" ]] && return 0

    local linked_task=""
    [[ -f ".archaeology/state.json" ]] && \
        linked_task=$(jq -r '.linked_sop_task // ""' .archaeology/state.json 2>/dev/null)

    local rep_id entity ev ext new_evt
    rep_id="rep_$(echo "$cur_hash" | head -c 16)"
    entity=$(jq -nc --arg id "$rep_id" '{type:"report", id:$id, ref:{path:".archaeology/report.md"}}')
    ev=$(jq -nc --arg p "$file" --arg h "$cur_hash" '[{kind:"file", path:$p, hash_sha1:$h}]')
    ext=$(jq -nc '{kind:"archaeology", path:".archaeology/report.md"}')
    new_evt=$(ck_event_make "archaeology.report.generated" "code-archaeologist" "$linked_task" "$entity" "$ev" "$ext")
    ck_event_append "$new_evt" >/dev/null 2>&1

    snap_set_str ".arch_report_hash" "$cur_hash"
}

# ============================================================
# 入口（函数都已定义，可以分发了）
# ============================================================

# 读取 hook stdin
INPUT="$(cat 2>/dev/null || true)"
[[ -z "$INPUT" ]] && exit 0

FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[[ -z "$FILE_PATH" ]] && exit 0

# 路径相对化
PROJECT_ROOT="$(ck_project_root)"
case "$FILE_PATH" in
    "$PROJECT_ROOT"/*) REL="${FILE_PATH#$PROJECT_ROOT/}" ;;
    *)                 REL="$FILE_PATH" ;;
esac

case "$REL" in
    .sop/state.json|.archaeology/state.json|.team-scope/state.json) ;;
    .sop/lessons.md|.archaeology/report.md) ;;
    *) exit 0 ;;
esac

[[ -f "$FILE_PATH" ]] || exit 0

ck_ensure_init

SNAP_FILE="$(ck_mirror_state)"
[[ -f "$SNAP_FILE" ]] || \
    echo '{"sop":null,"arch":null,"team":null,"lessons_hash":"","arch_report_hash":""}' > "$SNAP_FILE"

ck_debug "mirror triggered for $REL"

case "$REL" in
    .sop/state.json)         mirror_sop_state         "$FILE_PATH" ;;
    .archaeology/state.json) mirror_arch_state        "$FILE_PATH" ;;
    .team-scope/state.json)  mirror_team_state        "$FILE_PATH" ;;
    .sop/lessons.md)         mirror_lessons           "$FILE_PATH" ;;
    .archaeology/report.md)  mirror_arch_report       "$FILE_PATH" ;;
esac

exit 0
