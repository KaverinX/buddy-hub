#!/usr/bin/env bash
# context-keeper · entities 子模块
# 负责：把单条事件应用到实体物化层。
# 设计：每种 entity.type 有一个 reducer。未知类型直接跳过，保证 forward-compat。

# 假设调用方已 source common.sh。

# ---------- 写入单个实体 ----------
# 参数：$1 = entity_type, $2 = entity_id, $3 = entity JSON 内容
# 自动加上 envelope 字段（_v, _type, _id, _last_event, _updated_at）
ck_entity_write() {
    local etype="$1" eid="$2" content="$3" event_id="${4:-}"
    local dir="$(ck_entities_dir)/$etype"
    mkdir -p "$dir"
    local file="$dir/$eid.json"

    # 如已存在，保留 _first_event；否则新建
    local first_event
    if [[ -f "$file" ]]; then
        first_event=$(jq -r '._first_event // empty' "$file")
    fi
    [[ -z "${first_event:-}" ]] && first_event="$event_id"

    local merged
    merged=$(jq -n \
        --arg type "$etype" --arg id "$eid" \
        --arg first "$first_event" --arg last "$event_id" \
        --arg ts "$(ck_now_iso)" \
        --argjson content "$content" \
        '$content + {_v:1, _type:$type, _id:$id, _first_event:$first, _last_event:$last, _updated_at:$ts}')

    echo "$merged" > "$file"
}

# ---------- 索引更新 ----------
# 把 entity_id 加入 by_type[type] / by_task[task_id].<bucket>
ck_index_add() {
    local etype="$1" eid="$2" task_id="${3:-}"
    local idx="$(ck_index_file)"
    local tmp; tmp=$(mktemp)

    # 桶名（多数情况是复数化）
    local bucket
    case "$etype" in
        decision) bucket="decisions" ;;
        risk)     bucket="risks" ;;
        red_line) bucket="red_lines" ;;
        lesson)   bucket="lessons" ;;
        review)   bucket="reviews" ;;
        report)   bucket="reports" ;;
        *)        bucket="${etype}s" ;;
    esac

    jq \
        --arg type "$etype" --arg id "$eid" \
        --arg tid "$task_id" --arg bucket "$bucket" \
        '
        .by_type[$type] = ((.by_type[$type] // []) + [$id] | unique)
        | if $tid != "" and $tid != "null" then
            .by_task[$tid] = (
              (.by_task[$tid] // {decisions:[],risks:[],red_lines:[],lessons:[],reviews:[],reports:[]})
              | .[$bucket] = ((.[$bucket] // []) + [$id] | unique)
            )
          else . end
        ' "$idx" > "$tmp"
    mv "$tmp" "$idx"
}

# ---------- 主分发：根据事件类型更新实体 ----------
# 入参：$1 = 完整事件 JSON
ck_entity_apply() {
    local evt="$1"
    local etype actor task_id entity_type entity_id event_id
    etype=$(echo "$evt" | jq -r '.type')
    actor=$(echo "$evt" | jq -r '.actor')
    task_id=$(echo "$evt" | jq -r '.task_id // ""')
    entity_type=$(echo "$evt" | jq -r '.entity.type')
    entity_id=$(echo "$evt" | jq -r '.entity.id')
    event_id=$(echo "$evt" | jq -r '.id')

    [[ -z "$entity_type" || "$entity_type" == "null" ]] && return 0
    [[ -z "$entity_id"   || "$entity_id"   == "null" ]] && return 0

    case "$etype" in
        # ---- task lifecycle ----
        task.created)
            local content
            content=$(echo "$evt" | jq -c '{
                summary: (.ext.summary // "(no summary)"),
                current_phase: "PLANNING",
                iteration: 1,
                started_at: .ts,
                closed_at: null,
                linked_archaeology_id: null,
                open_critical_count: 0
            }')
            ck_entity_write task "$entity_id" "$content" "$event_id"
            ck_index_add task "$entity_id" "$entity_id"
            ;;
        task.phase.entered|task.phase.completed)
            local file="$(ck_entities_dir)/task/$entity_id.json"
            [[ -f "$file" ]] || return 0
            local new_phase tmp
            new_phase=$(echo "$evt" | jq -r '.ext.phase // empty')
            [[ -n "$new_phase" ]] || return 0
            tmp=$(mktemp)
            jq --arg p "$new_phase" --arg eid "$event_id" --arg ts "$(ck_now_iso)" \
                '.current_phase = $p | ._last_event = $eid | ._updated_at = $ts' \
                "$file" > "$tmp"
            mv "$tmp" "$file"
            ;;
        task.iteration.started)
            local file="$(ck_entities_dir)/task/$entity_id.json"
            [[ -f "$file" ]] || return 0
            local tmp; tmp=$(mktemp)
            jq --arg eid "$event_id" --arg ts "$(ck_now_iso)" \
                '.iteration = (.iteration // 1) + 1 | ._last_event = $eid | ._updated_at = $ts' \
                "$file" > "$tmp"
            mv "$tmp" "$file"
            ;;
        task.closed)
            local file="$(ck_entities_dir)/task/$entity_id.json"
            [[ -f "$file" ]] || return 0
            local tmp; tmp=$(mktemp)
            jq --arg eid "$event_id" --arg ts "$(ck_now_iso)" \
                '.closed_at = $ts | .current_phase = "CLOSED" | ._last_event = $eid | ._updated_at = $ts' \
                "$file" > "$tmp"
            mv "$tmp" "$file"
            ;;

        # ---- decision / risk / red_line / lesson ----
        decision.recorded)
            local content
            content=$(echo "$evt" | jq -c '{
                task_id: .task_id,
                category: (.ext.category // "ADR"),
                title: (.ext.title // ""),
                rationale: (.ext.rationale // ""),
                source: (.ext.source // {}),
                made_by: .actor
            }')
            ck_entity_write decision "$entity_id" "$content" "$event_id"
            ck_index_add decision "$entity_id" "$task_id"
            ;;
        risk.identified|risk.accepted|risk.materialized)
            local file="$(ck_entities_dir)/risk/$entity_id.json"
            local content tmp
            if [[ -f "$file" ]]; then
                local new_status
                case "$etype" in
                    risk.accepted)     new_status="accepted" ;;
                    risk.materialized) new_status="materialized" ;;
                    *)                 new_status="open" ;;
                esac
                tmp=$(mktemp)
                jq --arg s "$new_status" --arg eid "$event_id" --arg ts "$(ck_now_iso)" \
                    '.status = $s | ._last_event = $eid | ._updated_at = $ts' \
                    "$file" > "$tmp"
                mv "$tmp" "$file"
            else
                content=$(echo "$evt" | jq -c '{
                    task_id: .task_id,
                    level: (.ext.level // "medium"),
                    statement: (.ext.statement // ""),
                    source: (.ext.source // {}),
                    status: "open",
                    mitigation: (.ext.mitigation // null)
                }')
                ck_entity_write risk "$entity_id" "$content" "$event_id"
                ck_index_add risk "$entity_id" "$task_id"
            fi
            ;;
        red_line.set)
            local content
            content=$(echo "$evt" | jq -c '{
                source_task_id: .task_id,
                set_by: .actor,
                statement: (.ext.statement // ""),
                applies_to: (.ext.applies_to // []),
                rationale: (.ext.rationale // ""),
                status: "active",
                violations: []
            }')
            ck_entity_write red_line "$entity_id" "$content" "$event_id"
            ck_index_add red_line "$entity_id" "$task_id"
            ;;
        red_line.violated)
            local file="$(ck_entities_dir)/red_line/$entity_id.json"
            [[ -f "$file" ]] || return 0
            local tmp; tmp=$(mktemp)
            jq --arg eid "$event_id" --arg ts "$(ck_now_iso)" \
                '.status = "violated" | .violations += [$eid] | ._last_event = $eid | ._updated_at = $ts' \
                "$file" > "$tmp"
            mv "$tmp" "$file"
            ;;
        lesson.recorded)
            local content
            content=$(echo "$evt" | jq -c '{
                source_task_id: .task_id,
                category: (.ext.category // "process"),
                statement: (.ext.statement // ""),
                tags: (.ext.tags // []),
                evidence_path: (.ext.evidence_path // null)
            }')
            ck_entity_write lesson "$entity_id" "$content" "$event_id"
            ck_index_add lesson "$entity_id" "$task_id"
            ;;

        # ---- archaeology / review ----
        archaeology.report.generated)
            local content
            content=$(echo "$evt" | jq -c '{
                task_id: .task_id,
                kind: "archaeology",
                path: (.ext.path // ".archaeology/report.md"),
                summary: (.ext.summary // ""),
                generated_at: .ts
            }')
            ck_entity_write report "$entity_id" "$content" "$event_id"
            ck_index_add report "$entity_id" "$task_id"
            # 关联到 task
            if [[ -n "$task_id" && "$task_id" != "null" ]]; then
                local tfile="$(ck_entities_dir)/task/$task_id.json"
                if [[ -f "$tfile" ]]; then
                    local tmp; tmp=$(mktemp)
                    jq --arg aid "$entity_id" '.linked_archaeology_id = $aid' "$tfile" > "$tmp"
                    mv "$tmp" "$tfile"
                fi
            fi
            ;;
        review.completed|team_review.completed)
            local content kind
            kind=$(echo "$evt" | jq -r '.actor')
            [[ "$etype" == "team_review.completed" ]] && kind="scope-review" || kind="sop-review"
            content=$(echo "$evt" | jq -c --arg k "$kind" '{
                task_id: .task_id,
                kind: $k,
                iteration: (.ext.iteration // 1),
                started_at: (.ext.started_at // .ts),
                completed_at: .ts,
                critical_count: (.ext.critical_count // 0),
                warning_count: (.ext.warning_count // 0),
                findings_path: (.ext.findings_path // null)
            }')
            ck_entity_write review "$entity_id" "$content" "$event_id"
            ck_index_add review "$entity_id" "$task_id"
            ;;

        # 未知事件类型：仅追加事件，不物化。这是 forward-compat 保证。
        *)
            ck_debug "unknown event type $etype, skipping materialization"
            ;;
    esac
}

# ---------- 重建：清空 entities/index, 顺序重放 ----------
ck_entities_rebuild() {
    local ctx="$(ck_context_dir)"
    rm -rf "$ctx/entities" "$ctx/index.json"
    mkdir -p "$ctx/entities"
    echo '{"_v":1,"by_type":{},"by_task":{},"by_file":{}}' > "$(ck_index_file)"

    local count=0
    local f="$(ck_events_file)"
    [[ -f "$f" ]] || return 0

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        ck_entity_apply "$line"
        count=$((count+1))
    done < "$f"

    echo "✅ 重建完成：处理 $count 个事件"
}
