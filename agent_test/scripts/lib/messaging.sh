#!/bin/bash

# 📡 Chimera Engine - メッセージングシステム
# エージェント間の通信、ログ記録、ステータス管理を統括

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# エージェント間メッセージ送信
send_agent_message() {
    local agent_name="$1"
    local message="$2"
    
    # 引数確認
    if [[ -z "$agent_name" || -z "$message" ]]; then
        log_error "使用方法: send_agent_message <agent> <message>"
        return 1
    fi
    
    # エージェント存在確認
    local target=$(get_agent_target "$agent_name")
    if [[ -z "$target" ]]; then
        log_error "不明なエージェント: $agent_name"
        show_available_agents
        return 1
    fi
    
    # セッション存在確認
    validate_target_session "$target" || return 1
    
    # 特別なコマンド処理
    if handle_special_commands "$agent_name" "$message"; then
        return $?
    fi
    
    # 通常のメッセージ送信
    execute_message_send "$target" "$message"
    
    # ログ記録とステータス更新
    log_agent_message "$agent_name" "$message"
    update_agent_status "$agent_name" "$message"
    
    log_success "送信完了: $agent_name に '$message'"
    return 0
}

# エージェントターゲット取得（互換性のため関数ベース）
get_agent_target() {
    local agent_name="$1"
    
    # エージェントマッピング確認
    local target=$(get_agent_pane "$agent_name")
    if [[ -n "$target" ]]; then
        echo "$target"
        return 0
    fi
    
    return 1
}

# ターゲットセッション確認
validate_target_session() {
    local target="$1"
    local session_name="${target%%:*}"
    
    if ! session_exists "$session_name"; then
        log_error "セッション '$session_name' が見つかりません"
        log_info "ヒント: 以下を実行してワークスペースを作成してください"
        echo "  chimera start  # または"
        echo "  ./setup-chimera.sh"
        return 1
    fi
    
    if ! pane_exists "$target"; then
        log_error "ペイン '$target' にアクセスできません"
        return 1
    fi
    
    return 0
}

# 特別なコマンド処理
handle_special_commands() {
    local agent_name="$1"
    local message="$2"
    
    case "$message" in
        START_DEVELOPMENT*)
            handle_start_development "$message"
            return $?
            ;;
        "check-dev"|"status-all"|"wait-qa")
            handle_pm_workflow_command "$message"
            return $?
            ;;
        *)
            return 1  # 通常のメッセージとして処理
            ;;
    esac
}

# 開発開始コマンド処理
handle_start_development() {
    local message="$1"
    local timestamp=$(timestamp)
    
    log_info "🎯 PM内部コマンド: 開発開始指示"
    
    ensure_directories
    echo "[$timestamp] 企画確定、開発開始: $message" >> "$LOGS_DIR/pm_workflow.log"
    touch "$STATUS_DIR/planning_complete.txt"
    
    cat << EOF
🚀 開発フェーズを開始します
企画が確定しました。チームに指示を送信します。

💡 次のステップ:
  1. chimera send coder "開発指示"
  2. chimera send qa-functional "テスト準備指示"
EOF
    
    return 0
}

# PMワークフローコマンド処理
handle_pm_workflow_command() {
    local command="$1"
    local controller_script="$(get_root_dir)/pm-workflow-controller.sh"
    
    if [[ -f "$controller_script" ]]; then
        "$controller_script" "$command"
    else
        log_error "PMワークフローコントローラーが見つかりません: $controller_script"
        return 1
    fi
}

# メッセージ送信実行
execute_message_send() {
    local target="$1"
    local message="$2"
    
    log_info "📤 送信中: $target ← '$message'"
    
    # Claude Codeのプロンプトクリア
    tmux send-keys -t "$target" C-c
    sleep 0.3
    
    # メッセージ送信
    tmux send-keys -t "$target" "$message"
    sleep 0.1
    
    # エンター押下
    tmux send-keys -t "$target" C-m
    sleep 0.5
}

# エージェントメッセージログ記録
log_agent_message() {
    local agent_name="$1"
    local message="$2"
    local timestamp=$(timestamp)
    
    ensure_directories
    
    # 統合通信ログ
    echo "[$timestamp] $agent_name: SENT - \"$message\"" >> "$LOGS_DIR/communication.log"
    
    # エージェント別ログ
    local agent_log_file="$LOGS_DIR/${agent_name}_log.txt"
    echo "[$timestamp] $agent_name: \"$message\"" >> "$agent_log_file"
    
    # 役割別ログ
    case "$agent_name" in
        "pm"|"pm-self")
            echo "[$timestamp] PM指示: \"$message\"" >> "$LOGS_DIR/pm_activity.log"
            ;;
        "coder")
            echo "[$timestamp] 開発: \"$message\"" >> "$LOGS_DIR/development.log"
            ;;
        "qa-functional")
            echo "[$timestamp] 機能テスト: \"$message\"" >> "$LOGS_DIR/qa_functional.log"
            ;;
        "qa-lead")
            echo "[$timestamp] QA総合: \"$message\"" >> "$LOGS_DIR/qa_lead.log"
            ;;
        "monitor")
            echo "[$timestamp] 監視: \"$message\"" >> "$LOGS_DIR/monitoring.log"
            ;;
    esac
}

# エージェントステータス更新
update_agent_status() {
    local agent_name="$1"
    local message="$2"
    
    ensure_directories
    
    # メッセージ内容に基づいてステータスファイル更新
    case "$message" in
        *"実装完了"*|*"完了しました"*)
            if [[ "$agent_name" == "coder" ]]; then
                echo "$(timestamp): $message" > "$STATUS_DIR/coding_done.txt"
                log_debug "ステータス更新: 実装完了"
            fi
            ;;
        *"テスト合格"*|*"テスト成功"*|*"PASS"*)
            if [[ "$agent_name" == "qa-functional" ]]; then
                echo "$(timestamp): $message" > "$STATUS_DIR/test_passed.txt"
                log_debug "ステータス更新: テスト合格"
            fi
            ;;
        *"テスト失敗"*|*"FAIL"*|*"エラー"*)
            if [[ "$agent_name" == "qa-functional" ]]; then
                echo "$(timestamp): $message" > "$STATUS_DIR/test_failed.txt"
                log_debug "ステータス更新: テスト失敗"
            fi
            ;;
        *"リリース可能"*|*"品質OK"*)
            if [[ "$agent_name" == "qa-lead" ]]; then
                echo "$(timestamp): $message" > "$STATUS_DIR/release_ready.txt"
                log_debug "ステータス更新: リリース可能"
            fi
            ;;
    esac
}

# 利用可能エージェント表示（互換性のため関数ベース）
show_available_agents() {
    echo ""
    echo "📋 利用可能なエージェント:"
    echo "=========================="
    
    # 現在のエージェント
    local agents=($(list_agents))
    for agent in "${agents[@]}"; do
        local target=$(get_agent_pane "$agent")
        local title=$(get_agent_info "$agent" "title")
        local role=$(get_agent_info "$agent" "role")
        if [[ -n "$target" ]]; then
            printf "  %-15s → %-20s (%s)\n" "$agent" "$target" "$role"
        fi
    done
}

# ブロードキャストメッセージ
broadcast_message() {
    local message="$1"
    local exclude_agents=("${@:2}")
    
    log_info "📡 ブロードキャスト: '$message'"
    
    local agents=($(list_agents))
    local sent_count=0
    
    for agent in "${agents[@]}"; do
        # 除外リストにあるかチェック
        local skip=0
        for exclude in "${exclude_agents[@]}"; do
            if [[ "$agent" == "$exclude" ]]; then
                skip=1
                break
            fi
        done
        
        if [[ $skip -eq 0 ]]; then
            if send_agent_message "$agent" "$message"; then
                ((sent_count++))
            fi
        fi
    done
    
    log_success "ブロードキャスト完了: $sent_count エージェントに送信"
}

# エージェント出力取得
get_agent_output() {
    local agent_name="$1"
    local lines="${2:-20}"
    
    local target=$(get_agent_target "$agent_name")
    if [[ -z "$target" ]]; then
        log_error "不明なエージェント: $agent_name"
        return 1
    fi
    
    if ! validate_target_session "$target"; then
        return 1
    fi
    
    tmux capture-pane -t "$target" -p | tail -"$lines"
}

# エージェント状態分析
analyze_agent_status() {
    local agent_name="$1"
    local output=$(get_agent_output "$agent_name" 10)
    
    if [[ -z "$output" ]]; then
        echo "unknown"
        return 1
    fi
    
    # 完了パターン検出
    if echo "$output" | grep -qi "完了\|done\|finished\|実装完了\|コミット\|commit"; then
        echo "completed"
    elif echo "$output" | grep -qi "エラー\|error\|failed\|失敗\|例外\|exception"; then
        echo "error"
    elif echo "$output" | grep -qi "待機\|waiting\|入力\|input\|プロンプト\|>"; then
        echo "waiting"
    elif echo "$output" | grep -qi "実行中\|running\|処理中\|building\|installing"; then
        echo "working"
    else
        echo "unknown"
    fi
}

# 通信統計取得
get_communication_stats() {
    local log_file="$LOGS_DIR/communication.log"
    
    if [[ ! -f "$log_file" ]]; then
        echo "通信ログが見つかりません"
        return 1
    fi
    
    echo "📊 通信統計:"
    echo "============"
    echo "総メッセージ数: $(wc -l < "$log_file")"
    echo ""
    echo "エージェント別:"
    
    for agent in $(list_agents); do
        local count=$(grep -c "] $agent:" "$log_file" 2>/dev/null || echo "0")
        printf "  %-15s: %3d messages\n" "$agent" "$count"
    done
}

# 最新アクティビティ表示
show_recent_activity() {
    local lines="${1:-10}"
    local log_file="$LOGS_DIR/communication.log"
    
    if [[ ! -f "$log_file" ]]; then
        echo "アクティビティログが見つかりません"
        return 1
    fi
    
    echo "📋 最新アクティビティ (最新$lines件):"
    echo "=================================="
    tail -"$lines" "$log_file"
}

# メッセージ検索
search_messages() {
    local pattern="$1"
    local agent_filter="${2:-}"
    local log_file="$LOGS_DIR/communication.log"
    
    if [[ ! -f "$log_file" ]]; then
        echo "通信ログが見つかりません"
        return 1
    fi
    
    echo "🔍 メッセージ検索: '$pattern'"
    echo "=========================="
    
    if [[ -n "$agent_filter" ]]; then
        grep "$pattern" "$log_file" | grep "] $agent_filter:"
    else
        grep "$pattern" "$log_file"
    fi
}

# メッセージング設定表示（互換性のため関数ベース）
show_messaging_config() {
    echo "📡 メッセージング設定:"
    echo "===================="
    echo "ワークスペース: $CHIMERA_WORKSPACE_DIR"
    echo "ログディレクトリ: $LOGS_DIR"
    echo "ステータスディレクトリ: $STATUS_DIR"
    echo ""
    echo "登録エージェント数: 5 (pm, coder, qa-functional, qa-lead, monitor)"
}