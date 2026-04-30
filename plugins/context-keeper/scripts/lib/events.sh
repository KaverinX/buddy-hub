#!/usr/bin/env bash
# context-keeper · events 子模块
# 负责：emit 校验、追加到 events.jsonl、更新 meta.last_event_id。
# 物化由 entities.sh 接管。

# 假设调用方已 source common.sh。

# ---------- 校验事件 JSON ----------
# stdin = event JSON（单行）
# stdout = 校验通过则原样输出；否则空输出。
# stderr = 错误信息。
# return = 0 通过；非 0 失败。
ck_event_validate() {
    local evt="$1"
    [[ -z "$evt" ]] && { echo "🔴 empty event" >&2; return 2; }

    # 必需字段
    local missing
    missing=$(echo "$evt" | jq -r '
        ["id","v","ts","type","actor","entity","evidence"] as $req
        | [$req[] | select(. as $k | (input_line | fromjson | has($k)) | not)]
        | join(",")
    ' 2>/dev/null) || true

    # 上面那个 jq 在 bash 里很难用，换更直接的方式：
    for f in id v ts type actor entity evidence; do
        if ! echo "$evt" | jq -e "has(\"$f\")" >/dev/null 2>&1; then
            echo "🔴 [event-validate] 缺少必需字段: $f" >&2
            return 2
        fi
    done

    # type 命名规范：lower.namespace.verb
    local etype
    etype=$(echo "$evt" | jq -r '.type')
    if ! echo "$etype" | grep -qE '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){1,3}$'; then
        echo "🔴 [event-validate] type 命名不合法: $etype" >&2
        echo "    要求形如: <ns>.<noun>.<verb>，全小写，1-3 个点分隔" >&2
        return 2
    fi

    # entity.type 必须存在
    if ! echo "$evt" | jq -e '.entity.type' >/dev/null 2>&1; then
        echo "🔴 [event-validate] entity.type 缺失" >&2
        return 2
    fi

    # evidence 必须是非空数组
    local ev_len
    ev_len=$(echo "$evt" | jq -r '.evidence | length')
    if [[ "$ev_len" == "0" || "$ev_len" == "null" ]]; then
        echo "🔴 [event-validate] evidence 必须是非空数组" >&2
        return 2
    fi

    return 0
}

# ---------- 追加事件 ----------
# 入参：$1 = 完整 event JSON 字符串
# 行为：校验 → 单行追加到 events.jsonl → 更新 meta.json → 触发实体物化
ck_event_append() {
    local evt="$1"
    ck_event_validate "$evt" || return $?

    ck_ensure_init

    # 压成单行（保险，jq -c）
    local oneline
    oneline=$(echo "$evt" | jq -c '.')

    # 原子追加
    echo "$oneline" >> "$(ck_events_file)"

    # 更新 meta.last_event_id
    local eid meta_tmp
    eid=$(echo "$oneline" | jq -r '.id')
    meta_tmp=$(mktemp)
    jq --arg eid "$eid" '.last_event_id = $eid' "$(ck_meta_file)" > "$meta_tmp"
    mv "$meta_tmp" "$(ck_meta_file)"

    ck_debug "appended event $eid"

    # 调用实体物化（同进程，避免 race）
    if [[ -n "${CK_LIB_DIR:-}" && -f "$CK_LIB_DIR/entities.sh" ]]; then
        # shellcheck source=./entities.sh
        source "$CK_LIB_DIR/entities.sh"
        ck_entity_apply "$oneline" || ck_debug "entity apply failed for $eid (continuing)"
    fi
}

# ---------- 构造事件骨架 ----------
# 给上层 emit 调用方提供便捷构造器。返回完整 JSON。
# 用法：ck_event_make TYPE ACTOR TASK_ID ENTITY_JSON EVIDENCE_JSON [EXT_JSON]
ck_event_make() {
    local etype="$1" actor="$2" task_id="$3" entity_json="$4" evidence_json="$5"
    local ext_json="${6:-{\}}"

    local eid ts
    eid=$(ck_gen_id evt)
    ts=$(ck_now_iso)

    # task_id 为空时设为 null
    local task_id_field
    if [[ -z "$task_id" || "$task_id" == "null" ]]; then
        task_id_field="null"
    else
        task_id_field=$(printf '%s' "$task_id" | jq -R '.')
    fi

    jq -nc \
        --arg id "$eid" --arg ts "$ts" --arg type "$etype" --arg actor "$actor" \
        --argjson task_id "$task_id_field" \
        --argjson entity "$entity_json" \
        --argjson evidence "$evidence_json" \
        --argjson ext "$ext_json" \
        '{id:$id, v:1, ts:$ts, type:$type, actor:$actor, task_id:$task_id, entity:$entity, evidence:$evidence, ext:$ext}'
}

# ---------- 查询事件 ----------
# 用法：ck_event_query [--type=X] [--actor=Y] [--task=Z] [--limit=N]
ck_event_query() {
    local type_filter="" actor_filter="" task_filter="" limit=100
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type=*)   type_filter="${1#*=}" ;;
            --actor=*)  actor_filter="${1#*=}" ;;
            --task=*)   task_filter="${1#*=}" ;;
            --limit=*)  limit="${1#*=}" ;;
        esac
        shift
    done

    local f="$(ck_events_file)"
    [[ -f "$f" ]] || { echo "[]"; return 0; }

    # 构建 jq filter
    local filter='.'
    [[ -n "$type_filter"  ]] && filter+=" | select(.type == \"$type_filter\")"
    [[ -n "$actor_filter" ]] && filter+=" | select(.actor == \"$actor_filter\")"
    [[ -n "$task_filter"  ]] && filter+=" | select(.task_id == \"$task_filter\")"

    # jsonl → array → tail-N → output
    # 注意：jq 里的 $n 在 bash 双引号中需转义，避免 set -u 把它当 bash 变量展开
    jq -s --argjson n "$limit" "[.[] | $filter] | .[-(\$n):]" "$f"
}
