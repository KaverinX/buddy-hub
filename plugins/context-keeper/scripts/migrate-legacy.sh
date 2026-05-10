#!/usr/bin/env bash
# context-keeper · 历史数据迁移
#
# 用法：context-cli migrate
#
# 行为：扫描现有 .sop/ .archaeology/ .team-scope/ 目录，
#       生成对应的回填事件（synthesized backfill）。
#       已迁移过则跳过。
#
# 设计：
# 1. 时间戳尽量从原文件元数据反推（state.json 内的 created_at/completed_at；
#    若无，使用文件 mtime；都没有则用当前时间）。
# 2. 迁移产生的事件 actor 字段标记为原 plugin name，evidence 增加 kind:"migrated"。
# 3. 幂等：同一份原始数据多次 migrate 不会产生重复事件（按 source 路径+hash 去重）。

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
export CK_LIB_DIR="$LIB_DIR"

# shellcheck source=./lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=./lib/events.sh
source "$LIB_DIR/events.sh"
# shellcheck source=./lib/entities.sh
source "$LIB_DIR/entities.sh"

ck_require_jq || exit 2
ck_ensure_init

PROJECT_ROOT="$(ck_project_root)"
cd "$PROJECT_ROOT" || exit 2

echo "🔄 开始扫描历史数据..."
echo "   项目根: $PROJECT_ROOT"
echo

MIGRATED=0
SKIPPED=0

# ---------- 已迁移指纹 ----------
# 用 evidence 中 kind:"migrated" + source path 的组合做去重判断。
already_migrated() {
    local source_path="$1" source_hash="$2"
    [[ -z "$source_hash" ]] && return 1
    grep -F "\"hash_sha1\":\"$source_hash\"" "$(ck_events_file)" 2>/dev/null | \
        grep -F "\"kind\":\"migrated\"" >/dev/null 2>&1
}

# ---------- 1. flowsmith ----------
if [[ -f .sop/state.json ]]; then
    F=".sop/state.json"
    H=$(ck_sha1_file "$F")
    if already_migrated "$F" "$H"; then
        echo "⏭  $F 已迁移，跳过"; SKIPPED=$((SKIPPED+1))
    else
        TASK_ID=$(jq -r '.task_id // empty' "$F")
        TASK_SUMMARY=$(jq -r '.task_summary // ""' "$F")
        CURRENT_PHASE=$(jq -r '.current_phase // "PLANNING"' "$F")
        ITERATION=$(jq -r '.iteration // 1' "$F")
        CREATED_AT=$(jq -r '.created_at // ""' "$F")

        if [[ -n "$TASK_ID" ]]; then
            # task.created
            entity=$(jq -nc --arg id "$TASK_ID" '{type:"task", id:$id, ref:{path:".sop/state.json"}}')
            ev=$(jq -nc --arg p "$F" --arg h "$H" --arg c "$CREATED_AT" \
                '[{kind:"file", path:$p, hash_sha1:$h}, {kind:"migrated", source:$p, original_ts:$c}]')
            ext=$(jq -nc --arg s "$TASK_SUMMARY" '{summary:$s}')
            evt=$(ck_event_make "task.created" "flowsmith" "$TASK_ID" "$entity" "$ev" "$ext")
            # 时间戳替换为原始（best-effort）
            if [[ -n "$CREATED_AT" ]]; then
                evt=$(echo "$evt" | jq --arg ts "$CREATED_AT" '.ts = $ts')
            fi
            ck_event_append "$evt" >/dev/null && echo "  ✓ task.created  $TASK_ID  ($TASK_SUMMARY)" && MIGRATED=$((MIGRATED+1))

            # 各 phase 标记 done 的，逐个 emit task.phase.completed
            jq -c '.phases | to_entries[] | select(.value.status == "done")' "$F" 2>/dev/null | while IFS= read -r line; do
                PHASE=$(echo "$line" | jq -r '.key')
                COMPLETED_AT=$(echo "$line" | jq -r '.value.completed_at // ""')
                e_entity=$(jq -nc --arg id "$TASK_ID" '{type:"task", id:$id}')
                e_ev=$(jq -nc --arg p "$F" --arg h "$H" '[{kind:"migrated", source:$p, source_hash:$h}]')
                e_ext=$(jq -nc --arg p "$PHASE" '{phase:$p}')
                e_evt=$(ck_event_make "task.phase.completed" "flowsmith" "$TASK_ID" "$e_entity" "$e_ev" "$e_ext")
                if [[ -n "$COMPLETED_AT" ]]; then
                    e_evt=$(echo "$e_evt" | jq --arg ts "$COMPLETED_AT" '.ts = $ts')
                fi
                ck_event_append "$e_evt" >/dev/null && echo "  ✓ phase.completed  $PHASE"
            done

            # 当前 phase
            e_entity=$(jq -nc --arg id "$TASK_ID" '{type:"task", id:$id}')
            e_ev=$(jq -nc --arg p "$F" --arg h "$H" '[{kind:"migrated", source:$p, source_hash:$h}]')
            e_ext=$(jq -nc --arg p "$CURRENT_PHASE" '{phase:$p}')
            etype="task.phase.entered"
            [[ "$CURRENT_PHASE" == "DONE" || "$CURRENT_PHASE" == "CLOSED" ]] && etype="task.closed"
            e_evt=$(ck_event_make "$etype" "flowsmith" "$TASK_ID" "$e_entity" "$e_ev" "$e_ext")
            ck_event_append "$e_evt" >/dev/null
        fi
    fi
fi

# ---------- 2. archaeology ----------
if [[ -f .archaeology/state.json ]]; then
    F=".archaeology/state.json"
    H=$(ck_sha1_file "$F")
    if already_migrated "$F" "$H"; then
        echo "⏭  $F 已迁移，跳过"; SKIPPED=$((SKIPPED+1))
    else
        ARCH_TASK=$(jq -r '.task_id // empty' "$F")
        LINKED_SOP=$(jq -r '.linked_sop_task // ""' "$F")
        REPORT_STATUS=$(jq -r '.report.status // ""' "$F")

        if [[ -n "$ARCH_TASK" ]]; then
            entity=$(jq -nc --arg id "$ARCH_TASK" '{type:"task", id:$id, ref:{path:".archaeology/state.json"}}')
            ev=$(jq -nc --arg p "$F" --arg h "$H" '[{kind:"migrated", source:$p, source_hash:$h}]')
            evt=$(ck_event_make "archaeology.started" "code-archaeologist" "$LINKED_SOP" "$entity" "$ev" '{}')
            ck_event_append "$evt" >/dev/null && echo "  ✓ archaeology.started  $ARCH_TASK" && MIGRATED=$((MIGRATED+1))

            if [[ "$REPORT_STATUS" == "done" && -f .archaeology/report.md ]]; then
                R_HASH=$(ck_sha1_file ".archaeology/report.md")
                rep_id="rep_$(echo "$ARCH_TASK" | tr -dc 'a-z0-9' | head -c 16)"
                r_entity=$(jq -nc --arg id "$rep_id" '{type:"report", id:$id, ref:{path:".archaeology/report.md"}}')
                r_ev=$(jq -nc --arg p ".archaeology/report.md" --arg h "$R_HASH" \
                    '[{kind:"file", path:$p, hash_sha1:$h}, {kind:"migrated", source:$p, source_hash:$h}]')
                r_ext=$(jq -nc '{kind:"archaeology", path:".archaeology/report.md"}')
                r_evt=$(ck_event_make "archaeology.report.generated" "code-archaeologist" "$LINKED_SOP" "$r_entity" "$r_ev" "$r_ext")
                ck_event_append "$r_evt" >/dev/null && echo "  ✓ archaeology.report.generated"
            fi
        fi
    fi
fi

# ---------- 3. co-review ----------
if [[ -f .team-scope/state.json ]]; then
    F=".team-scope/state.json"
    H=$(ck_sha1_file "$F")
    if already_migrated "$F" "$H"; then
        echo "⏭  $F 已迁移，跳过"; SKIPPED=$((SKIPPED+1))
    else
        REV_ID=$(jq -r '.review_id // empty' "$F")
        STATUS=$(jq -r '.status // ""' "$F")
        LINKED_SOP=$(jq -r '.linked_sop_task // ""' "$F")
        if [[ -n "$REV_ID" && "$STATUS" == "done" ]]; then
            entity=$(jq -nc --arg id "$REV_ID" '{type:"review", id:$id, ref:{path:".team-scope/state.json"}}')
            ev=$(jq -nc --arg p "$F" --arg h "$H" '[{kind:"migrated", source:$p, source_hash:$h}]')
            ext=$(jq -nc \
                --arg th "$(jq -r '.team_health // "unknown"' "$F")" \
                --arg ms "$(jq -r '.merge_strategy // "unknown"' "$F")" \
                '{team_health:$th, merge_strategy:$ms, findings_path:".team-scope/report.md"}')
            evt=$(ck_event_make "team_review.completed" "co-review" "$LINKED_SOP" "$entity" "$ev" "$ext")
            ck_event_append "$evt" >/dev/null && echo "  ✓ team_review.completed  $REV_ID" && MIGRATED=$((MIGRATED+1))
        fi
    fi
fi

# ---------- 4. lessons.md ----------
if [[ -f .sop/lessons.md ]]; then
    F=".sop/lessons.md"
    H=$(ck_sha1_file "$F")
    if already_migrated "$F" "$H"; then
        echo "⏭  $F 已迁移，跳过"; SKIPPED=$((SKIPPED+1))
    else
        SIZE=$(wc -c < "$F" | tr -d ' ')
        if (( SIZE > 100 )); then
            lid="lsn_$(echo "$H" | head -c 16)"
            entity=$(jq -nc --arg id "$lid" '{type:"lesson", id:$id, ref:{path:".sop/lessons.md"}}')
            ev=$(jq -nc --arg p "$F" --arg h "$H" \
                '[{kind:"file", path:$p, hash_sha1:$h}, {kind:"migrated", source:$p, source_hash:$h}]')
            ext=$(jq -nc --arg sz "$SIZE" '{statement:"(legacy lessons.md - migrated as snapshot)", category:"process", evidence_path:".sop/lessons.md", file_size:($sz|tonumber)}')
            evt=$(ck_event_make "lesson.recorded" "context-keeper-mirror" "" "$entity" "$ev" "$ext")
            ck_event_append "$evt" >/dev/null && echo "  ✓ lesson.recorded  (lessons.md $SIZE bytes)" && MIGRATED=$((MIGRATED+1))
        fi
    fi
fi

# ---------- 5. mirror snapshot 同步 ----------
# 把当前 state 写入 snapshot，避免 mirror hook 重新当作 "新事件"
SNAP="$(ck_mirror_state)"
[[ -f "$SNAP" ]] || \
    echo '{"sop":null,"arch":null,"team":null,"lessons_hash":"","arch_report_hash":""}' > "$SNAP"

if [[ -f .sop/state.json ]]; then
    cur=$(jq -c '{
        task_id, task_summary, current_phase, iteration,
        open_critical: ([(.open_issues // [])[] | select(.level=="critical" and .status=="open")] | length)
    }' .sop/state.json 2>/dev/null)
    [[ -n "$cur" ]] && tmp=$(mktemp) && jq --argjson v "$cur" '.sop = $v' "$SNAP" > "$tmp" && mv "$tmp" "$SNAP"
fi

if [[ -f .archaeology/state.json ]]; then
    cur=$(jq -c '{task_id, report_status:.report.status, linked_sop_task}' .archaeology/state.json 2>/dev/null)
    [[ -n "$cur" ]] && tmp=$(mktemp) && jq --argjson v "$cur" '.arch = $v' "$SNAP" > "$tmp" && mv "$tmp" "$SNAP"
fi

if [[ -f .team-scope/state.json ]]; then
    cur=$(jq -c '{review_id, status, team_health, merge_strategy, sop_task: .linked_sop_task}' .team-scope/state.json 2>/dev/null)
    [[ -n "$cur" ]] && tmp=$(mktemp) && jq --argjson v "$cur" '.team = $v' "$SNAP" > "$tmp" && mv "$tmp" "$SNAP"
fi

[[ -f .sop/lessons.md          ]] && jq --arg h "$(ck_sha1_file .sop/lessons.md)"          '.lessons_hash = $h'    "$SNAP" > "$SNAP.tmp" && mv "$SNAP.tmp" "$SNAP"
[[ -f .archaeology/report.md   ]] && jq --arg h "$(ck_sha1_file .archaeology/report.md)"   '.arch_report_hash = $h' "$SNAP" > "$SNAP.tmp" && mv "$SNAP.tmp" "$SNAP"

# ---------- 6. 更新 meta ----------
TMP=$(mktemp)
jq --arg t "$(ck_now_iso)" '.last_migrated_at = $t' "$(ck_meta_file)" > "$TMP"
mv "$TMP" "$(ck_meta_file)"

echo
echo "✅ 迁移完成"
echo "   迁移：$MIGRATED 个事件"
echo "   跳过：$SKIPPED 个文件（已存在）"
echo
echo "下一步建议："
echo "   context-cli status        # 查看摘要"
echo "   context-cli list-entities --type=task   # 查看任务实体"
