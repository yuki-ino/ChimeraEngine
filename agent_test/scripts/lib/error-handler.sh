#!/bin/bash

# 🚨 Chimera Engine - 統一エラーハンドリングシステム
# 全スクリプトで一貫したエラー処理、ログ記録、クリーンアップを提供

ERROR_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ERROR_LIB_DIR/common.sh"

# エラーハンドリング有効化フラグ
CHIMERA_ERROR_HANDLING_ENABLED=0
CHIMERA_CLEANUP_ON_EXIT=1
CHIMERA_DEBUG_MODE=0

# エラー統計（macOS bash互換のため関数ベース）
total_errors=0
critical_errors=0
warnings=0
recoverable_errors=0

# エラーハンドリング初期化
init_error_handling() {
    local enable_strict="${1:-1}"
    local enable_debug="${2:-0}"
    
    CHIMERA_ERROR_HANDLING_ENABLED=1
    CHIMERA_DEBUG_MODE="$enable_debug"
    
    if [[ "$enable_strict" == "1" ]]; then
        # 厳密なエラーハンドリング
        set -euo pipefail
        
        # エラートラップ設定
        trap 'handle_error $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "%s " "${FUNCNAME[@]}")' ERR
        trap 'handle_exit $?' EXIT
        trap 'handle_signal INT' INT
        trap 'handle_signal TERM' TERM
        
        log_debug "厳密なエラーハンドリングを有効化"
    else
        # 基本的なエラーハンドリング
        set -e
        trap 'handle_basic_error $? $LINENO' ERR
        
        log_debug "基本的なエラーハンドリングを有効化"
    fi
    
    # エラーログディレクトリ作成
    ensure_directories
    safe_mkdir "$LOGS_DIR/errors"
    
    log_debug "エラーハンドリング初期化完了"
}

# 詳細エラーハンドラー
handle_error() {
    local exit_code=$1
    local line_number=$2
    local bash_line_number=$3
    local last_command="$4"
    local function_stack="$5"
    
    # エラー統計更新
    ((total_errors++))
    
    # 重大エラー判定
    local severity="ERROR"
    if [[ $exit_code -ge 125 ]]; then
        severity="CRITICAL"
        ((critical_errors++))
    fi
    
    # エラー情報記録
    local error_id=$(generate_error_id)
    local timestamp=$(timestamp)
    local script_name="${BASH_SOURCE[1]##*/}"
    
    # エラーログ作成
    local error_log="$LOGS_DIR/errors/error_${error_id}.log"
    cat > "$error_log" << EOF
Error ID: $error_id
Timestamp: $timestamp
Severity: $severity
Script: $script_name
Exit Code: $exit_code
Line: $line_number (bash: $bash_line_number)
Command: $last_command
Function Stack: $function_stack
Working Directory: $(pwd)
User: $(whoami)
Shell: $SHELL
Chimera Version: $CHIMERA_VERSION

Environment Variables:
$(env | grep -E '^(CHIMERA|TMUX)' | sort)

Process Information:
PID: $$
PPID: $PPID

EOF
    
    # コンソール出力
    log_error "=========================================="
    log_error "🚨 $severity エラーが発生しました"
    log_error "エラーID: $error_id"
    log_error "スクリプト: $script_name:$line_number"
    log_error "終了コード: $exit_code"
    log_error "コマンド: $last_command"
    
    if [[ "$CHIMERA_DEBUG_MODE" == "1" ]]; then
        log_error "関数スタック: $function_stack"
        log_error "詳細ログ: $error_log"
    fi
    
    log_error "=========================================="
    
    # エラー通知
    notify_error "$severity" "$error_id" "$script_name" "$last_command"
    
    # 回復試行
    if attempt_recovery "$exit_code" "$last_command"; then
        log_success "エラーから回復しました"
        ((recoverable_errors++))
        return 0
    fi
    
    # クリーンアップ実行
    cleanup_on_error "$exit_code"
    
    # エラー統計表示
    show_error_summary
    
    exit $exit_code
}

# 基本エラーハンドラー
handle_basic_error() {
    local exit_code=$1
    local line_number=$2
    
    ((total_errors++))
    
    log_error "エラー発生: 終了コード $exit_code (行 $line_number)"
    
    # 基本的なクリーンアップ
    cleanup_on_error "$exit_code"
    
    exit $exit_code
}

# 終了ハンドラー
handle_exit() {
    local exit_code=$1
    
    if [[ "$CHIMERA_CLEANUP_ON_EXIT" == "1" ]]; then
        cleanup_on_exit "$exit_code"
    fi
    
    if [[ "$CHIMERA_DEBUG_MODE" == "1" ]]; then
        log_debug "スクリプト終了: 終了コード $exit_code"
        show_error_summary
    fi
}

# シグナルハンドラー
handle_signal() {
    local signal="$1"
    
    log_warn "シグナル受信: $signal"
    
    case "$signal" in
        INT)
            log_info "中断要求を受信しました"
            cleanup_on_signal "$signal"
            exit 130
            ;;
        TERM)
            log_info "終了要求を受信しました"
            cleanup_on_signal "$signal"
            exit 143
            ;;
    esac
}

# エラーID生成
generate_error_id() {
    echo "$(date +%Y%m%d_%H%M%S)_$$_$RANDOM"
}

# エラー通知
notify_error() {
    local severity="$1"
    local error_id="$2"
    local script_name="$3"
    local command="$4"
    
    # ステータスファイル更新
    echo "$(timestamp): $severity in $script_name - $command" >> "$STATUS_DIR/error_status.txt"
    
    # 重大エラーの場合は特別な処理
    if [[ "$severity" == "CRITICAL" ]]; then
        touch "$STATUS_DIR/critical_error.flag"
        
        # 可能であればエージェントに通知
        if command -v "$SCRIPT_DIR/../chimera-send.sh" &>/dev/null; then
            "$SCRIPT_DIR/../chimera-send.sh" monitor "CRITICAL ERROR: $error_id in $script_name" 2>/dev/null || true
        fi
    fi
}

# エラー回復試行
attempt_recovery() {
    local exit_code=$1
    local command="$2"
    
    log_info "エラー回復を試行中..."
    
    case $exit_code in
        1)
            # 一般的なエラー - 再試行してみる
            if [[ "$command" =~ ^tmux ]]; then
                return try_tmux_recovery
            fi
            ;;
        2)
            # ファイル/ディレクトリが見つからない
            if [[ "$command" =~ mkdir|touch ]]; then
                return try_directory_recovery
            fi
            ;;
        127)
            # コマンドが見つからない
            log_warn "必要なコマンドが見つかりません"
            return 1
            ;;
    esac
    
    return 1  # 回復不可
}

# tmux関連エラーの回復
try_tmux_recovery() {
    log_info "tmux関連エラーの回復を試行中..."
    
    # tmuxサーバーが応答しているか確認
    if tmux info &>/dev/null; then
        log_success "tmuxサーバーは正常です"
        return 0
    fi
    
    # tmuxサーバー再起動
    log_info "tmuxサーバーを再起動中..."
    tmux kill-server 2>/dev/null || true
    sleep 2
    
    # 再起動確認
    if tmux new-session -d -s "test-session" 2>/dev/null; then
        tmux kill-session -t "test-session" 2>/dev/null
        log_success "tmuxサーバー回復成功"
        return 0
    fi
    
    return 1
}

# ディレクトリ関連エラーの回復
try_directory_recovery() {
    log_info "ディレクトリ関連エラーの回復を試行中..."
    
    # 必要なディレクトリを再作成
    ensure_directories
    
    if [[ -d "$CHIMERA_WORKSPACE_DIR" ]]; then
        log_success "ディレクトリ回復成功"
        return 0
    fi
    
    return 1
}

# エラー時クリーンアップ
cleanup_on_error() {
    local exit_code=$1
    
    log_info "エラー時のクリーンアップを実行中..."
    
    # 一時ファイルクリーンアップ
    cleanup_temp_files
    
    # セッション状態確認と修復
    check_and_repair_sessions
    
    # ログローテーション
    rotate_error_logs
    
    log_info "エラー時クリーンアップ完了"
}

# 終了時クリーンアップ
cleanup_on_exit() {
    local exit_code=$1
    
    if [[ $exit_code -eq 0 ]]; then
        log_debug "正常終了時のクリーンアップ"
    else
        log_debug "異常終了時のクリーンアップ"
    fi
    
    # 不要な一時ファイル削除
    cleanup_temp_files
}

# シグナル時クリーンアップ
cleanup_on_signal() {
    local signal="$1"
    
    log_info "シグナル $signal によるクリーンアップ"
    
    # 進行中の処理を安全に停止
    stop_running_processes
    
    # 設定ファイルの保存
    save_current_state
    
    cleanup_temp_files
}

# 一時ファイルクリーンアップ
cleanup_temp_files() {
    local temp_patterns=(
        "/tmp/chimera_*.tmp"
        "/tmp/tmux_*.tmp"
        "$CHIMERA_WORKSPACE_DIR/tmp/*"
    )
    
    for pattern in "${temp_patterns[@]}"; do
        rm -f $pattern 2>/dev/null || true
    done
    
    log_debug "一時ファイルクリーンアップ完了"
}

# セッション状態確認と修復
check_and_repair_sessions() {
    if ! command -v tmux &>/dev/null; then
        return 0
    fi
    
    # 孤立セッションの検出
    local orphaned_sessions=$(tmux list-sessions 2>/dev/null | grep -E "chimera" | cut -d: -f1 || true)
    
    if [[ -n "$orphaned_sessions" ]]; then
        log_warn "孤立セッションを検出: $orphaned_sessions"
        # 必要に応じてクリーンアップ
    fi
}

# ログローテーション
rotate_error_logs() {
    local error_log_dir="$LOGS_DIR/errors"
    local max_logs=50
    
    if [[ -d "$error_log_dir" ]]; then
        local log_count=$(find "$error_log_dir" -name "error_*.log" | wc -l)
        
        if [[ $log_count -gt $max_logs ]]; then
            log_info "エラーログローテーション実行中 ($log_count > $max_logs)"
            find "$error_log_dir" -name "error_*.log" -type f | sort | head -n $((log_count - max_logs)) | xargs rm -f
        fi
    fi
}

# 実行中プロセス停止
stop_running_processes() {
    # Chimera関連のバックグラウンドプロセスを停止
    local chimera_pids=$(pgrep -f "chimera" 2>/dev/null || true)
    
    if [[ -n "$chimera_pids" ]]; then
        log_info "Chimera関連プロセスを停止中: $chimera_pids"
        kill -TERM $chimera_pids 2>/dev/null || true
        sleep 2
        kill -KILL $chimera_pids 2>/dev/null || true
    fi
}

# 現在の状態保存
save_current_state() {
    local state_file="$STATUS_DIR/last_state.json"
    
    cat > "$state_file" << EOF
{
    "timestamp": "$(timestamp_iso)",
    "chimera_version": "$CHIMERA_VERSION",
    "session_name": "$CHIMERA_SESSION_NAME",
    "workspace_dir": "$CHIMERA_WORKSPACE_DIR",
    "error_stats": {
        "total_errors": $total_errors,
        "critical_errors": $critical_errors,
        "warnings": $warnings,
        "recoverable_errors": $recoverable_errors
    }
}
EOF
    
    log_debug "状態保存完了: $state_file"
}

# エラー統計表示
show_error_summary() {
    if [[ "$total_errors" -eq 0 ]]; then
        return 0
    fi
    
    echo ""
    log_info "📊 エラー統計サマリー"
    echo "======================"
    echo "総エラー数: $total_errors"
    echo "重大エラー: $critical_errors"
    echo "警告: $warnings"
    echo "回復エラー: $recoverable_errors"
    echo ""
}

# 警告レベルのエラー処理
handle_warning() {
    local message="$1"
    local context="${2:-}"
    
    ((warnings++))
    
    log_warn "⚠️  $message"
    
    if [[ -n "$context" ]]; then
        log_debug "コンテキスト: $context"
    fi
    
    # 警告ログ記録
    echo "$(timestamp): WARNING - $message ($context)" >> "$LOGS_DIR/warnings.log"
}

# エラーハンドリング無効化
disable_error_handling() {
    CHIMERA_ERROR_HANDLING_ENABLED=0
    
    # トラップ解除
    trap - ERR EXIT INT TERM
    
    # set オプションリセット
    set +euo pipefail 2>/dev/null || set +e
    
    log_debug "エラーハンドリングを無効化"
}

# エラーハンドリング状態確認
is_error_handling_enabled() {
    [[ "$CHIMERA_ERROR_HANDLING_ENABLED" == "1" ]]
}

# デバッグモード切り替え
toggle_debug_mode() {
    if [[ "$CHIMERA_DEBUG_MODE" == "1" ]]; then
        CHIMERA_DEBUG_MODE=0
        log_info "デバッグモードを無効化"
    else
        CHIMERA_DEBUG_MODE=1
        log_info "デバッグモードを有効化"
    fi
}

# エラーハンドリング設定表示
show_error_config() {
    echo "🚨 エラーハンドリング設定:"
    echo "========================="
    echo "有効化: $(is_error_handling_enabled && echo "Yes" || echo "No")"
    echo "デバッグ: $([ "$CHIMERA_DEBUG_MODE" == "1" ] && echo "On" || echo "Off")"
    echo "終了時クリーンアップ: $([ "$CHIMERA_CLEANUP_ON_EXIT" == "1" ] && echo "On" || echo "Off")"
    echo "エラーログ: $LOGS_DIR/errors/"
    show_error_summary
}