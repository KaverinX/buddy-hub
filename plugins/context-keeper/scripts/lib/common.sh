#!/usr/bin/env bash
# context-keeper · common helpers
# 被所有 context-keeper 脚本 source 引用。无副作用，只暴露函数。

# ---------- 1. 项目根定位 ----------
# 以当前 git 仓库根为项目根。非 git 项目则使用 PWD。
ck_project_root() {
    local root
    if root=$(git rev-parse --show-toplevel 2>/dev/null); then
        echo "$root"
    else
        echo "$PWD"
    fi
}

# ---------- 2. .context/ 路径常量 ----------
ck_context_dir()   { echo "$(ck_project_root)/.context"; }
ck_events_file()   { echo "$(ck_context_dir)/events.jsonl"; }
ck_entities_dir()  { echo "$(ck_context_dir)/entities"; }
ck_index_file()    { echo "$(ck_context_dir)/index.json"; }
ck_meta_file()     { echo "$(ck_context_dir)/meta.json"; }
ck_mirror_state()  { echo "$(ck_context_dir)/.mirror-state.json"; }

# ---------- 3. 依赖检查 ----------
# 失败则提示并返回非零。调用方决定是否 exit。
ck_require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "🔴 [context-keeper] 依赖 jq 未安装。" >&2
        echo "    macOS: brew install jq" >&2
        echo "    Ubuntu: apt install jq" >&2
        return 1
    fi
}

# ---------- 4. ID 生成 ----------
# ULID-like：26 字符，前 10 位时间，后 16 位随机。
# 时间排序友好但不严格 ULID（不依赖 base32 库）。
ck_gen_id() {
    local prefix="${1:-evt}"
    local ts_part rand_part
    ts_part=$(printf '%010x' "$(date +%s)")
    rand_part=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 16)
    echo "${prefix}_${ts_part}${rand_part}"
}

# ---------- 5. 时间戳 ----------
ck_now_iso() {
    date -u +'%Y-%m-%dT%H:%M:%SZ'
}

# ---------- 6. SHA1（文件指纹）----------
ck_sha1_file() {
    local f="$1"
    [[ -f "$f" ]] || { echo ""; return; }
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 1 "$f" | awk '{print $1}'
    elif command -v sha1sum >/dev/null 2>&1; then
        sha1sum "$f" | awk '{print $1}'
    else
        echo ""
    fi
}

# ---------- 7. 安全初始化 ----------
# 幂等：已存在则不做事。
ck_ensure_init() {
    local ctx="$(ck_context_dir)"
    mkdir -p "$ctx" "$(ck_entities_dir)"
    [[ -f "$(ck_events_file)" ]] || touch "$(ck_events_file)"
    [[ -f "$(ck_meta_file)"  ]] || cat > "$(ck_meta_file)" <<EOF
{
  "schema_version": 1,
  "created_at": "$(ck_now_iso)",
  "last_event_id": null,
  "last_migrated_at": null
}
EOF
    [[ -f "$(ck_index_file)" ]] || echo '{"_v":1,"by_type":{},"by_task":{},"by_file":{}}' > "$(ck_index_file)"
}

# ---------- 8. 是否启用 ----------
# BUDDY_CONTEXT_DISABLED=1 关闭所有 context-keeper 行为。Hook 会读这个。
ck_is_enabled() {
    [[ "${BUDDY_CONTEXT_DISABLED:-0}" != "1" ]]
}

# ---------- 9. 调试日志 ----------
ck_debug() {
    [[ "${BUDDY_CONTEXT_DEBUG:-0}" == "1" ]] && echo "[context-keeper] $*" >&2
    return 0
}
