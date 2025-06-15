#!/bin/bash

# 📁 Chimera Engine - 設定ローダー
# YAML設定ファイルを読み込み、環境変数として利用可能にする

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 設定ファイルパス
DEFAULT_CONFIG_FILE="$PROJECT_ROOT/config/chimera.yaml"
USER_CONFIG_FILE="${CHIMERA_CONFIG:-$HOME/.chimera/config.yaml}"

# 設定キャッシュ
declare -A CONFIG_CACHE=()
CONFIG_LOADED=0

# YAML解析関数（jq/yqが利用できない場合のフォールバック）
parse_yaml_simple() {
    local yaml_file="$1"
    local prefix="${2:-}"
    
    # コメントと空行を除去
    grep -v '^\s*#' "$yaml_file" | grep -v '^\s*$' | while IFS= read -r line; do
        # インデントレベル検出
        local indent=$(echo "$line" | sed 's/[^ ].*//' | wc -c)
        indent=$((indent - 1))
        
        # キーバリューペアの抽出
        if echo "$line" | grep -q ':'; then
            local key=$(echo "$line" | sed 's/:.*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            local value=$(echo "$line" | sed 's/[^:]*: *//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            
            # 値の処理
            if [[ "$value" =~ ^\".*\"$ ]]; then
                value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
            elif [[ "$value" =~ ^\'.*\'$ ]]; then
                value=$(echo "$value" | sed "s/^'//" | sed "s/'$//")
            fi
            
            # プレフィックス付きキー生成
            local full_key="${prefix}${key}"
            echo "${full_key}=${value}"
        fi
    done
}

# YAML設定読み込み（yqを使用）
load_config_with_yq() {
    local config_file="$1"
    
    if ! command -v yq &>/dev/null; then
        return 1
    fi
    
    # YAML to JSON変換してjqで処理
    yq eval -o=json "$config_file" | jq -r '
        def flatten(prefix):
            . as $in |
            if type == "object" then
                reduce keys[] as $key ({}; 
                    . + ($in[$key] | flatten(prefix + $key + "_"))
                )
            elif type == "array" then
                reduce range(0; length) as $i ({};
                    . + (.[$i] | flatten(prefix + ($i | tostring) + "_"))
                )
            else
                {(prefix[:-1]): .}
            end;
        flatten("") | to_entries[] | "\(.key)=\(.value)"
    ' 2>/dev/null
}

# YAML設定読み込み（jqを使用）
load_config_with_jq() {
    local config_file="$1"
    
    if ! command -v jq &>/dev/null; then
        return 1
    fi
    
    # YAMLをJSONに変換（簡易版）
    # 注意: 完全なYAML→JSON変換ではありません
    local temp_json=$(mktemp)
    
    # 簡易YAML→JSON変換
    awk '
    BEGIN {
        print "{"
        indent[0] = 0
        level = 0
    }
    /^[[:space:]]*#/ { next }  # コメント行をスキップ
    /^[[:space:]]*$/ { next }  # 空行をスキップ
    {
        # インデントレベル計算
        match($0, /^[[:space:]]*/);
        current_indent = RLENGTH
        
        # キー・値の分離
        if (match($0, /^[[:space:]]*([^:]+):[[:space:]]*(.*)/)) {
            key = substr($0, RSTART + current_indent, RLENGTH - current_indent)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
            
            value_start = RSTART + RLENGTH
            value = substr($0, value_start)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            
            # JSON形式で出力
            if (value == "") {
                printf "%s\"%s\": {\n", indent_str(current_indent), key
            } else {
                printf "%s\"%s\": \"%s\",\n", indent_str(current_indent), key, value
            }
        }
    }
    function indent_str(level) {
        return sprintf("%*s", level, "")
    }
    END {
        print "}"
    }
    ' "$config_file" > "$temp_json" 2>/dev/null
    
    # JSONから設定値抽出
    if jq -r 'paths(scalars) as $p | $p + [getpath($p)] | join("_")' "$temp_json" 2>/dev/null; then
        rm -f "$temp_json"
        return 0
    fi
    
    rm -f "$temp_json"
    return 1
}

# 設定ファイル読み込み
load_config() {
    local config_file="${1:-$DEFAULT_CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        echo "警告: 設定ファイルが見つかりません: $config_file" >&2
        return 1
    fi
    
    local config_data=""
    
    # 複数の方法で設定読み込みを試行
    if command -v yq &>/dev/null; then
        config_data=$(load_config_with_yq "$config_file")
    elif command -v jq &>/dev/null; then
        config_data=$(load_config_with_jq "$config_file")
    else
        # フォールバック: 簡易解析
        config_data=$(parse_yaml_simple "$config_file")
    fi
    
    if [[ -z "$config_data" ]]; then
        echo "エラー: 設定ファイルの解析に失敗しました: $config_file" >&2
        return 1
    fi
    
    # 設定をキャッシュに保存
    while IFS='=' read -r key value; do
        if [[ -n "$key" ]]; then
            CONFIG_CACHE["$key"]="$value"
        fi
    done <<< "$config_data"
    
    CONFIG_LOADED=1
    
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "設定ファイル読み込み完了: $config_file" >&2
        echo "読み込まれた設定項目数: ${#CONFIG_CACHE[@]}" >&2
    fi
    
    return 0
}

# 設定値取得
get_config_value() {
    local key="$1"
    local default="${2:-}"
    
    # 設定が読み込まれていない場合は読み込み
    if [[ $CONFIG_LOADED -eq 0 ]]; then
        load_config || return 1
    fi
    
    # キャッシュから取得
    if [[ -n "${CONFIG_CACHE[$key]:-}" ]]; then
        echo "${CONFIG_CACHE[$key]}"
        return 0
    fi
    
    # 代替キー形式を試行
    local alt_key
    alt_key=$(echo "$key" | tr '.' '_' | tr '-' '_')
    if [[ -n "${CONFIG_CACHE[$alt_key]:-}" ]]; then
        echo "${CONFIG_CACHE[$alt_key]}"
        return 0
    fi
    
    # デフォルト値を返す
    echo "$default"
    return 0
}

# 設定値設定（ランタイム変更）
set_config_value() {
    local key="$1"
    local value="$2"
    
    CONFIG_CACHE["$key"]="$value"
    
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "設定値変更: $key = $value" >&2
    fi
}

# エージェント設定取得
get_agent_config() {
    local agent="$1"
    local property="$2"
    local mode="${3:-current}"  # current mode
    
    local key="agents_${mode}_${agent}_${property}"
    get_config_value "$key"
}

# tmux設定取得
get_tmux_config() {
    local property="$1"
    local key="tmux_$property"
    get_config_value "$key"
}

# ワークフロー設定取得
get_workflow_config() {
    local property="$1"
    local key="workflow_$property"
    get_config_value "$key"
}

# タイムアウト設定取得
get_timeout_config() {
    local operation="${1:-default}"
    local key="timeouts_operations_$operation"
    local default_timeout=$(get_config_value "timeouts_default" "30")
    
    get_config_value "$key" "$default_timeout"
}

# ログ設定取得
get_logging_config() {
    local property="$1"
    local key="logging_$property"
    get_config_value "$key"
}

# 環境変数への設定エクスポート
export_config_to_env() {
    local prefix="${1:-CHIMERA_}"
    
    if [[ $CONFIG_LOADED -eq 0 ]]; then
        load_config || return 1
    fi
    
    for key in "${!CONFIG_CACHE[@]}"; do
        local env_key="${prefix}$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr '.' '_' | tr '-' '_')"
        local value="${CONFIG_CACHE[$key]}"
        
        # 環境変数として設定
        export "$env_key"="$value"
        
        if [[ "${DEBUG:-0}" == "1" ]]; then
            echo "環境変数設定: $env_key = $value" >&2
        fi
    done
}

# 設定ファイルのバリデーション
validate_config() {
    local config_file="${1:-$DEFAULT_CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        echo "エラー: 設定ファイルが見つかりません: $config_file" >&2
        return 1
    fi
    
    # YAML構文チェック
    if command -v yq &>/dev/null; then
        if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
            echo "エラー: YAML構文エラー in $config_file" >&2
            return 1
        fi
    elif command -v python3 &>/dev/null; then
        if ! python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
            echo "警告: YAML構文の問題の可能性があります: $config_file" >&2
        fi
    fi
    
    # 必須設定項目チェック
    local required_keys=(
        "chimera_version"
        "chimera_session_name"
        "agents_current"
        "workspace_base_dir"
    )
    
    load_config "$config_file" || return 1
    
    for key in "${required_keys[@]}"; do
        if [[ -z "$(get_config_value "$key")" ]]; then
            echo "エラー: 必須設定項目が見つかりません: $key" >&2
            return 1
        fi
    done
    
    echo "設定ファイルのバリデーション成功: $config_file" >&2
    return 0
}

# 設定のマージ（複数設定ファイル対応）
merge_configs() {
    local primary_config="$1"
    local secondary_config="$2"
    
    # プライマリ設定読み込み
    load_config "$primary_config" || return 1
    
    # セカンダリ設定が存在する場合はマージ
    if [[ -f "$secondary_config" ]]; then
        local temp_cache=()
        
        # 現在のキャッシュをバックアップ
        for key in "${!CONFIG_CACHE[@]}"; do
            temp_cache["$key"]="${CONFIG_CACHE[$key]}"
        done
        
        # セカンダリ設定読み込み（上書き）
        CONFIG_LOADED=0
        load_config "$secondary_config"
        
        # プライマリ設定で不足部分を補完
        for key in "${!temp_cache[@]}"; do
            if [[ -z "${CONFIG_CACHE[$key]:-}" ]]; then
                CONFIG_CACHE["$key"]="${temp_cache[$key]}"
            fi
        done
        
        if [[ "${DEBUG:-0}" == "1" ]]; then
            echo "設定マージ完了: $primary_config + $secondary_config" >&2
        fi
    fi
    
    return 0
}

# 設定のダンプ（デバッグ用）
dump_config() {
    local output_file="${1:-}"
    
    if [[ $CONFIG_LOADED -eq 0 ]]; then
        load_config || return 1
    fi
    
    local output=""
    output+="# Chimera Engine 設定ダンプ\n"
    output+="# 生成日時: $(date)\n"
    output+="# 総設定項目数: ${#CONFIG_CACHE[@]}\n\n"
    
    # アルファベット順でソート
    for key in $(printf '%s\n' "${!CONFIG_CACHE[@]}" | sort); do
        output+="$key=${CONFIG_CACHE[$key]}\n"
    done
    
    if [[ -n "$output_file" ]]; then
        echo -e "$output" > "$output_file"
        echo "設定ダンプ出力: $output_file" >&2
    else
        echo -e "$output"
    fi
}

# 設定リロード
reload_config() {
    local config_file="${1:-$DEFAULT_CONFIG_FILE}"
    
    # キャッシュクリア
    CONFIG_CACHE=()
    CONFIG_LOADED=0
    
    # 再読み込み
    load_config "$config_file"
    
    echo "設定リロード完了: $config_file" >&2
}

# 設定値検索
search_config() {
    local pattern="$1"
    
    if [[ $CONFIG_LOADED -eq 0 ]]; then
        load_config || return 1
    fi
    
    echo "設定検索結果: '$pattern'"
    echo "========================="
    
    for key in "${!CONFIG_CACHE[@]}"; do
        if [[ "$key" =~ $pattern ]] || [[ "${CONFIG_CACHE[$key]}" =~ $pattern ]]; then
            echo "$key = ${CONFIG_CACHE[$key]}"
        fi
    done
}

# 初期化時に自動読み込み
if [[ "${CHIMERA_AUTO_LOAD_CONFIG:-1}" == "1" ]]; then
    # ユーザー設定ファイルが存在する場合はマージ
    if [[ -f "$USER_CONFIG_FILE" ]]; then
        merge_configs "$DEFAULT_CONFIG_FILE" "$USER_CONFIG_FILE" 2>/dev/null || \
        load_config "$DEFAULT_CONFIG_FILE" 2>/dev/null || true
    else
        load_config "$DEFAULT_CONFIG_FILE" 2>/dev/null || true
    fi
fi