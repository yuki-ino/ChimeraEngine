#!/bin/bash

# 🎯 PM Workflow Controller - PMワークフロー管理システム
# リファクタリング版: 統一されたアーキテクチャと設定管理を使用

# スクリプトディレクトリ取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 共通ライブラリ読み込み
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/messaging.sh"
source "$SCRIPT_DIR/lib/error-handler.sh"
# source "$SCRIPT_DIR/lib/config-loader.sh"  # macOS bash互換性のため一時的に無効化

# エラーハンドリング初期化
init_error_handling 1 0

# フォールバック関数（config-loader.sh無効化のため）
get_config_value() {
    local key="$1"
    local default="${2:-}"
    
    case "$key" in
        "chimera_version") echo "${CHIMERA_VERSION:-0.0.1}" ;;
        *) echo "$default" ;;
    esac
}

# devペインの最新出力を取得
get_dev_output() {
    local lines="${1:-20}"
    get_agent_output "coder" "$lines"
}

# devの作業状況を分析
analyze_dev_status() {
    local output=$(get_dev_output 20)
    local timestamp=$(timestamp)
    
    ensure_directories
    echo "[$timestamp] Dev Status Check:" >> "$LOGS_DIR/pm_workflow.log"
    echo "$output" >> "$LOGS_DIR/pm_workflow.log"
    echo "---" >> "$LOGS_DIR/pm_workflow.log"
    
    # 状況分析（messaging.shのanalyze_agent_statusを使用）
    analyze_agent_status "coder"
}

# PM向けステータス確認コマンド
check_dev_status() {
    log_info "Dev作業状況を確認中..."
    
    local status=$(analyze_dev_status)
    local output=$(get_dev_output 10)
    
    echo ""
    echo "📊 === Dev Status Report ==="
    echo "🕐 Time: $(date '+%H:%M:%S')"
    echo "📍 Status: $status"
    echo ""
    echo "📺 Dev画面の最新出力:"
    echo "----------------------------------------"
    echo "$output"
    echo "----------------------------------------"
    echo ""
    
    case "$status" in
        "completed")
            log_success "✅ Dev作業完了が検出されました"
            echo "💡 次のアクション: QAに指示を送信可能"
            echo "   コマンド例: chimera send qa-functional \"実装完了しました。テストをお願いします\""
            touch "$STATUS_DIR/dev_ready_for_qa.txt"
            return 0
            ;;
        "error")
            log_warn "❌ Devでエラーが検出されました"
            echo "💡 次のアクション: Devに追加指示またはデバッグ支援"
            echo "   コマンド例: chimera send coder \"エラーが発生しています。詳細を確認してください\""
            touch "$STATUS_DIR/dev_needs_help.txt"
            return 1
            ;;
        "waiting")
            log_info "⏳ Devが入力待機中です"
            echo "💡 次のアクション: Devに追加指示または確認"
            echo "   コマンド例: chimera send coder \"作業状況を報告してください\""
            return 2
            ;;
        "working")
            log_info "🔄 Dev作業中です"
            echo "💡 次のアクション: しばらく待ってから再確認"
            echo "   コマンド例: $0 wait-and-check"
            return 3
            ;;
        *)
            log_warn "❓ Dev状況が不明です"
            echo "💡 次のアクション: Devに状況確認を要求"
            echo "   コマンド例: chimera send coder \"現在の作業状況を報告してください\""
            return 4
            ;;
    esac
}

# dev完了まで待機してからQAに指示
wait_for_dev_and_instruct_qa() {
    local task_description="$1"
    local max_checks=$(get_timeout_config "max_checks")
    local check_interval=$(get_timeout_config "check_interval")
    
    log_info "Dev完了を待機してからQAに指示します..."
    echo "📋 Task: $task_description"
    echo "⏰ 最大待機時間: $(($max_checks * $check_interval))秒"
    echo ""
    
    for i in $(seq 1 $max_checks); do
        show_progress "Dev完了確認中" "$i" "$max_checks"
        
        local status=$(analyze_dev_status)
        
        case "$status" in
            "completed")
                log_success "✅ Dev作業完了を確認!"
                echo ""
                echo "📤 QAに指示を送信します..."
                
                # メッセージング機能を使用してQAに自動指示
                if send_agent_message "qa-functional" "実装完了を確認しました。「$task_description」のテストをお願いします。"; then
                    echo "📝 ワークフロー記録を保存..."
                    echo "$(date): $task_description -> Dev完了 -> QA指示送信" >> "$STATUS_DIR/workflow_history.txt"
                    return 0
                else
                    log_error "QAへの指示送信に失敗しました"
                    return 1
                fi
                ;;
            "error")
                log_warn "❌ Devでエラーが発生しています"
                echo "💡 PMの判断が必要です。エラー内容を確認してDevに追加指示を送信してください。"
                return 1
                ;;
            *)
                echo "   Status: $status (継続監視中...)"
                sleep $check_interval
                ;;
        esac
    done
    
    log_warn "⏰ タイムアウト: Dev完了を確認できませんでした"
    echo "💡 PMの手動確認が必要です:"
    echo "   1. chimera send coder \"作業状況を報告してください\""
    echo "   2. $0 check-dev"
    return 2
}

# 全体ステータス確認
check_all_status() {
    echo "🦁 === Chimera Engine 全体ステータス ==="
    echo "🕐 Time: $(date)"
    echo ""
    
    # 設定情報表示
    echo "⚙️  === システム設定 ==="
    echo "バージョン: $(get_config_value 'chimera_version' 'N/A')"
    echo "セッション: $(get_config_value 'chimera_session_name' 'N/A')"
    echo "ワークスペース: $(get_config_value 'workspace_base_dir' 'N/A')"
    echo ""
    
    # Dev状況
    echo "👨‍💻 === Dev Status ==="
    check_dev_status
    echo ""
    
    # QA状況確認
    echo "🧪 === QA Status ==="
    
    # QA-Functionalの状況
    echo "QA-Functional:"
    local qa_func_output=$(get_agent_output "qa-functional" 5 2>/dev/null || echo "出力取得不可")
    echo "$qa_func_output"
    echo ""
    
    # QA-Leadの状況
    echo "QA-Lead:"
    local qa_lead_output=$(get_agent_output "qa-lead" 5 2>/dev/null || echo "出力取得不可")
    echo "$qa_lead_output"
    echo ""
    
    # ステータスファイル確認
    echo "📁 === Status Files ==="
    if [[ -d "$STATUS_DIR" ]]; then
        echo "ステータスディレクトリ: $STATUS_DIR"
        if ls "$STATUS_DIR"/*.txt >/dev/null 2>&1; then
            for status_file in "$STATUS_DIR"/*.txt; do
                local filename=$(basename "$status_file")
                local content=$(head -1 "$status_file" 2>/dev/null || echo "読み取り不可")
                echo "  $filename: $content"
            done
        else
            echo "  ステータスファイルなし"
        fi
    else
        echo "ステータスディレクトリが見つかりません"
    fi
    echo ""
    
    # 最新通信ログ
    echo "📋 === Recent Communication ==="
    show_recent_activity 5
    
    # 通信統計
    echo ""
    echo "📊 === Communication Stats ==="
    get_communication_stats
}

# エージェント健康状態確認
check_agent_health() {
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    
    echo "🏥 === エージェント健康状態 ==="
    
    for agent in "${agents[@]}"; do
        local target=$(get_agent_target "$agent")
        if [[ -n "$target" ]]; then
            if validate_target_session "$target" 2>/dev/null; then
                log_success "✅ $agent ($target): 正常"
            else
                log_error "❌ $agent ($target): 接続不可"
            fi
        else
            log_warn "⚠️  $agent: ターゲット未定義"
        fi
    done
}

# ワークフロー履歴表示
show_workflow_history() {
    local count="${1:-10}"
    local history_file="$STATUS_DIR/workflow_history.txt"
    
    echo "📜 === ワークフロー履歴 (最新${count}件) ==="
    
    if [[ -f "$history_file" ]]; then
        tail -"$count" "$history_file"
    else
        echo "履歴ファイルが見つかりません"
    fi
}

# ワークフロー設定表示
show_workflow_config() {
    echo "⚙️  === ワークフロー設定 ==="
    echo "デフォルトタイムアウト: $(get_timeout_config 'default')秒"
    echo "最大チェック回数: $(get_timeout_config 'max_checks')"
    echo "チェック間隔: $(get_timeout_config 'check_interval')秒"
    echo "自動QA通知: $(get_config_value 'workflow_automation_auto_notify_qa' 'true')"
    echo "自動ステータス更新: $(get_config_value 'workflow_automation_auto_status_update' 'true')"
}

# パフォーマンス分析
analyze_performance() {
    echo "⚡ === パフォーマンス分析 ==="
    
    # ログファイルサイズ
    if [[ -d "$LOGS_DIR" ]]; then
        echo "ログディレクトリサイズ:"
        du -sh "$LOGS_DIR" 2>/dev/null || echo "  計算不可"
    fi
    
    # 最近のレスポンス時間（簡易版）
    if [[ -f "$LOGS_DIR/communication.log" ]]; then
        local recent_messages=$(tail -10 "$LOGS_DIR/communication.log" | wc -l)
        echo "最近のメッセージ数: $recent_messages"
    fi
    
    # セッション使用メモリ（tmux情報）
    if command -v tmux &>/dev/null && session_exists "$CHIMERA_SESSION_NAME"; then
        echo "アクティブセッション数: $(tmux list-sessions 2>/dev/null | wc -l)"
        echo "アクティブペイン数: $(tmux list-panes -a 2>/dev/null | wc -l)"
    fi
}

# 使用方法表示
show_usage() {
    cat << EOF
🎯 PM Workflow Controller v$(get_config_value 'chimera_version' '0.0.1') - PMワークフロー管理

使用方法:
  $0 <command> [options]

コマンド:
  check-dev          Dev作業状況を確認
  wait-and-check     30秒待機してからDev確認
  wait-for-qa TASK   Dev完了まで待機してQAに指示
  status-all         全体ステータス確認
  health             エージェント健康状態確認
  history [N]        ワークフロー履歴表示（デフォルト: 10件）
  config             ワークフロー設定表示
  performance        パフォーマンス分析
  help               このヘルプを表示

使用例:
  $0 check-dev
  $0 wait-for-qa "ログイン機能実装"
  $0 status-all
  $0 history 20
  
💡 PMワークフロー:
  1. chimera send coder "実装指示"
  2. $0 check-dev
  3. 完了確認後 -> QAに指示
  4. エラー時 -> Devに追加指示

環境変数:
  VERBOSE=1          詳細出力モード
  DEBUG=1            デバッグモード
  CHIMERA_CONFIG     カスタム設定ファイル
EOF
}

# メイン処理
main() {
    local command="${1:-help}"
    local param="$2"
    
    case "$command" in
        "check-dev"|"check")
            check_dev_status
            ;;
        "wait-and-check")
            echo "⏳ $(get_timeout_config 'check_interval')秒待機してからDev状況を再確認..."
            sleep "$(get_timeout_config 'check_interval')"
            check_dev_status
            ;;
        "wait-for-qa")
            if [[ -z "$param" ]]; then
                log_error "タスク名が必要です"
                echo "使用例: $0 wait-for-qa \"ログイン機能実装\""
                exit 1
            fi
            wait_for_dev_and_instruct_qa "$param"
            ;;
        "status-all"|"status")
            check_all_status
            ;;
        "health")
            check_agent_health
            ;;
        "history")
            local count="${param:-10}"
            show_workflow_history "$count"
            ;;
        "config")
            show_workflow_config
            ;;
        "performance"|"perf")
            analyze_performance
            ;;
        "help"|"--help"|"")
            show_usage
            ;;
        *)
            log_error "不明なコマンド: $command"
            echo "使用方法: $0 help"
            exit 1
            ;;
    esac
}

# デバッグ情報表示
if [[ "${DEBUG:-0}" == "1" ]]; then
    log_debug "PM Workflow Controller デバッグモード"
    log_debug "引数: $*"
    log_debug "ワークスペース: $CHIMERA_WORKSPACE_DIR"
fi

# メイン実行
main "$@"