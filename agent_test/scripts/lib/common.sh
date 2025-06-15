#!/bin/bash

# 🛠️ Chimera Engine - 共通関数ライブラリ
# 全スクリプトで使用する共通関数を定義

# 厳密なエラーハンドリング
set -euo pipefail

# 設定ファイル読み込み
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/config.sh"

# 色付きログ関数（統一化）
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $*" >&2
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $*" >&2
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $*" >&2
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "\033[1;37m[DEBUG]\033[0m $*" >&2
    fi
}

# プログレス表示
show_progress() {
    local message="$1"
    local current="${2:-0}"
    local total="${3:-0}"
    
    if [[ $total -gt 0 ]]; then
        local percent=$((current * 100 / total))
        echo -e "\033[1;36m[PROGRESS]\033[0m $message ($current/$total - $percent%)" >&2
    else
        echo -e "\033[1;36m[PROGRESS]\033[0m $message" >&2
    fi
}

# 環境依存性チェック
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    log_info "依存関係をチェック中..."
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            log_success "✓ $dep"
        else
            missing+=("$dep")
            log_error "✗ $dep が見つかりません"
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "以下のコマンドをインストールしてください: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# バージョン比較
version_compare() {
    local version1="$1"
    local version2="$2"
    
    if [[ "$version1" == "$version2" ]]; then
        return 0
    fi
    
    local IFS=.
    local ver1=($version1)
    local ver2=($version2)
    
    for ((i=0; i<${#ver1[@]} || i<${#ver2[@]}; i++)); do
        local v1=${ver1[i]:-0}
        local v2=${ver2[i]:-0}
        
        if ((v1 > v2)); then
            return 1
        elif ((v1 < v2)); then
            return 2
        fi
    done
    
    return 0
}

# セッション存在確認
session_exists() {
    local session_name="$1"
    tmux has-session -t "$session_name" 2>/dev/null
}

# セッションクリーンアップ
cleanup_session() {
    local session_name="$1"
    
    if session_exists "$session_name"; then
        tmux kill-session -t "$session_name" 2>/dev/null
        log_info "$session_name セッション削除完了"
    else
        log_info "$session_name セッションは存在しませんでした"
    fi
}

# 複数セッションクリーンアップ
cleanup_sessions() {
    local sessions=("$@")
    
    log_info "既存セッションクリーンアップ開始..."
    
    for session in "${sessions[@]}"; do
        cleanup_session "$session"
    done
    
    log_success "セッションクリーンアップ完了"
}

# ペイン存在確認
pane_exists() {
    local pane_target="$1"
    local session_name="${pane_target%%:*}"
    
    if ! session_exists "$session_name"; then
        return 1
    fi
    
    tmux list-panes -t "$pane_target" &>/dev/null
}

# ディレクトリ作成（安全）
safe_mkdir() {
    local dir="$1"
    local mode="${2:-755}"
    
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        chmod "$mode" "$dir"
        log_debug "ディレクトリ作成: $dir"
    fi
}

# ファイル存在確認とバックアップ
backup_if_exists() {
    local file="$1"
    local backup_suffix="${2:-.bak}"
    
    if [[ -f "$file" ]]; then
        local backup_file="${file}${backup_suffix}"
        cp "$file" "$backup_file"
        log_info "バックアップ作成: $backup_file"
        return 0
    fi
    
    return 1
}

# 文字列エスケープ
escape_string() {
    local input="$1"
    # シェル特殊文字をエスケープ
    echo "$input" | sed 's/[[\.*^$(){}?+|]/\\&/g'
}

# タイムスタンプ生成
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# ISO8601タイムスタンプ
timestamp_iso() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# 実行時間測定
time_execution() {
    local start_time=$(date +%s)
    local command=("$@")
    
    "${command[@]}"
    local exit_code=$?
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_debug "実行時間: ${duration}秒"
    return $exit_code
}

# プロセス待機（タイムアウト付き）
wait_with_timeout() {
    local timeout="$1"
    local check_command="$2"
    local interval="${3:-1}"
    
    local elapsed=0
    
    while [[ $elapsed -lt $timeout ]]; do
        if eval "$check_command" &>/dev/null; then
            return 0
        fi
        
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
    
    return 1
}

# JSON値取得（jqがある場合）
get_json_value() {
    local file="$1"
    local key="$2"
    local default="${3:-}"
    
    if command -v jq &>/dev/null && [[ -f "$file" ]]; then
        jq -r ".$key // \"$default\"" "$file" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

# 設定値取得
get_config() {
    local key="$1"
    local default="${2:-}"
    
    case "$key" in
        "version") echo "$CHIMERA_VERSION" ;;
        "session") echo "$CHIMERA_SESSION_NAME" ;;
        "workspace") echo "$CHIMERA_WORKSPACE_DIR" ;;
        "timeout") echo "$DEFAULT_TIMEOUT" ;;
        *) echo "$default" ;;
    esac
}

# エージェント情報取得（config.shの関数を使用）
# get_agent_info() は config.sh で定義されているため削除

# エージェント一覧取得（互換性のため関数ベース）
list_agents() {
    echo "pm"
    echo "coder"
    echo "qa-functional"
    echo "qa-lead"
    echo "monitor"
}

# 初期化確認
is_initialized() {
    [[ -f "./setup-chimera.sh" && -d "./instructions" ]]
}

# スクリプトディレクトリ取得
get_script_dir() {
    echo "$SCRIPT_DIR"
}

# ルートディレクトリ取得
get_root_dir() {
    echo "$(dirname "$SCRIPT_DIR")"
}

# エラー時の共通処理
common_error_handler() {
    local exit_code=$1
    local line_number=$2
    local command="$3"
    
    log_error "実行エラーが発生しました"
    log_error "終了コード: $exit_code"
    log_error "行番号: $line_number"
    log_error "コマンド: $command"
}

# 設定の妥当性確認
validate_environment() {
    log_info "環境設定を確認中..."
    
    # 設定値確認
    validate_config || return 1
    
    # 必須コマンド確認
    check_dependencies "${REQUIRED_COMMANDS[@]}" || return 1
    
    # ディレクトリ作成
    ensure_directories
    
    log_success "環境設定確認完了"
    return 0
}