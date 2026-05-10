#!/usr/bin/env bash
# context-keeper · 主 CLI
#
# 用法：
#   context-cli init                                     # 创建 .context/ 骨架
#   context-cli status                                   # 当前事件数、实体数、最近事件
#   context-cli emit --type=X --actor=Y [--task=Z] \
#                    --entity-type=T --entity-id=I \
#                    --evidence='[{...}]' [--ext='{...}']
#   context-cli query [--type=X] [--actor=Y] [--task=Z] [--limit=N]
#   context-cli list-entities --type=T
#   context-cli get-entity --type=T --id=I
#   context-cli rebuild                                  # 从事件流重建实体
#   context-cli migrate                                  # 扫描 .sop/.archaeology/.team-scope 回填事件
#
# 退出码：0 = 成功；1 = 用法错误；2 = 运行时错误。

set -uo pipefail

# 定位 lib/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CK_LIB_DIR="$SCRIPT_DIR/lib"

# shellcheck source=./lib/common.sh
source "$CK_LIB_DIR/common.sh"
# shellcheck source=./lib/events.sh
source "$CK_LIB_DIR/events.sh"
# shellcheck source=./lib/entities.sh
source "$CK_LIB_DIR/entities.sh"

ck_require_jq || exit 2

usage() {
    sed -n '3,17p' "$0" | sed 's/^# \?//'
}

# ---------- 子命令分发 ----------
cmd="${1:-}"
shift || true

case "$cmd" in

    init)
        ck_ensure_init
        echo "✅ context-keeper 已初始化于 $(ck_context_dir)"
        ;;

    status)
        ck_ensure_init
        local_evt_count=$(wc -l < "$(ck_events_file)" 2>/dev/null | tr -d ' ')
        local_meta=$(cat "$(ck_meta_file)" 2>/dev/null || echo '{}')
        local_last_id=$(echo "$local_meta" | jq -r '.last_event_id // "(none)"')
        local_last_mig=$(echo "$local_meta" | jq -r '.last_migrated_at // "(never)"')
        local_task_count=$(find "$(ck_entities_dir)/task" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
        local_redline_count=$(find "$(ck_entities_dir)/red_line" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
        local_lesson_count=$(find "$(ck_entities_dir)/lesson" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')

        cat <<EOF
context-keeper 状态
  根目录:       $(ck_project_root)
  存储:         $(ck_context_dir)
  schema:       $(echo "$local_meta" | jq -r '.schema_version')
  事件数:       $local_evt_count
  最后事件:     $local_last_id
  最后迁移:     $local_last_mig
  实体快照:
    task        $local_task_count
    red_line    $local_redline_count
    lesson      $local_lesson_count
EOF
        ;;

    emit)
        # 解析 emit 参数
        etype="" actor="" task_id="" entity_type="" entity_id=""
        evidence='[{"kind":"manual","note":"context-cli emit"}]'
        ext='{}'
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --type=*)        etype="${1#*=}" ;;
                --actor=*)       actor="${1#*=}" ;;
                --task=*)        task_id="${1#*=}" ;;
                --entity-type=*) entity_type="${1#*=}" ;;
                --entity-id=*)   entity_id="${1#*=}" ;;
                --evidence=*)    evidence="${1#*=}" ;;
                --ext=*)         ext="${1#*=}" ;;
                *) echo "🔴 未知参数: $1" >&2; exit 1 ;;
            esac
            shift
        done
        if [[ -z "$etype" || -z "$actor" || -z "$entity_type" || -z "$entity_id" ]]; then
            echo "🔴 必需参数: --type --actor --entity-type --entity-id" >&2
            exit 1
        fi
        # 校验 evidence/ext 是合法 JSON
        echo "$evidence" | jq empty 2>/dev/null || { echo "🔴 evidence 不是合法 JSON" >&2; exit 1; }
        echo "$ext" | jq empty 2>/dev/null      || { echo "🔴 ext 不是合法 JSON" >&2; exit 1; }

        entity_json=$(jq -nc --arg t "$entity_type" --arg i "$entity_id" '{type:$t, id:$i}')
        evt=$(ck_event_make "$etype" "$actor" "$task_id" "$entity_json" "$evidence" "$ext")
        if ck_event_append "$evt"; then
            echo "$evt" | jq -r '"✅ emitted " + .id + " (" + .type + ")"'
        else
            exit 2
        fi
        ;;

    query)
        ck_ensure_init
        ck_event_query "$@" | jq '.'
        ;;

    list-entities)
        type_filter=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --type=*) type_filter="${1#*=}" ;;
            esac
            shift
        done
        if [[ -z "$type_filter" ]]; then
            echo "🔴 缺少 --type=<entity-type>" >&2; exit 1
        fi
        local_dir="$(ck_entities_dir)/$type_filter"
        if [[ ! -d "$local_dir" ]]; then
            echo "[]"; exit 0
        fi
        # 输出所有实体的 _id, _type, summary/statement 摘要
        find "$local_dir" -maxdepth 1 -name '*.json' -print0 \
          | xargs -0 -I{} jq -c '{_id, _type, summary: (.summary // .statement // .title // null), _updated_at}' {} 2>/dev/null \
          | jq -s '.'
        ;;

    get-entity)
        type_filter="" id_filter=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --type=*) type_filter="${1#*=}" ;;
                --id=*)   id_filter="${1#*=}" ;;
            esac
            shift
        done
        [[ -z "$type_filter" || -z "$id_filter" ]] && {
            echo "🔴 必需 --type 与 --id" >&2; exit 1
        }
        f="$(ck_entities_dir)/$type_filter/$id_filter.json"
        if [[ -f "$f" ]]; then
            jq '.' "$f"
        else
            echo "🔴 实体不存在: $type_filter/$id_filter" >&2; exit 2
        fi
        ;;

    rebuild)
        ck_entities_rebuild
        ;;

    migrate)
        # 委托给独立脚本
        bash "$SCRIPT_DIR/migrate-legacy.sh" "$@"
        ;;

    -h|--help|help|"")
        usage
        ;;

    *)
        echo "🔴 未知子命令: $cmd" >&2
        usage
        exit 1
        ;;
esac
