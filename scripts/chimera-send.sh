#!/bin/bash

# 🚀 Chimera Engine - エージェント間メッセージ送信システム
# リファクタリング版: モジュール化されたメッセージングシステムを使用

# スクリプトディレクトリ取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHIMERA_SCRIPT_DIR="$SCRIPT_DIR"  # Preserve original script directory

# 共通ライブラリ読み込み
if [[ -f "$CHIMERA_SCRIPT_DIR/lib/common.sh" ]]; then
    source "$CHIMERA_SCRIPT_DIR/lib/common.sh"
    source "$CHIMERA_SCRIPT_DIR/lib/messaging.sh"
    source "$CHIMERA_SCRIPT_DIR/lib/error-handler.sh"
    source "$CHIMERA_SCRIPT_DIR/lib/plan-manager.sh"
    # Disabled for compatibility with older bash
    # source "$CHIMERA_SCRIPT_DIR/lib/structured-messaging.sh" || echo "Warning: structured-messaging.sh not found"
    # source "$CHIMERA_SCRIPT_DIR/lib/parallel-optimizer.sh" || echo "Warning: parallel-optimizer.sh not found"
    # source "$CHIMERA_SCRIPT_DIR/lib/agent-health-monitor.sh" || echo "Warning: agent-health-monitor.sh not found"
    # source "$CHIMERA_SCRIPT_DIR/lib/agent-identity.sh" || echo "Warning: agent-identity.sh not found"
else
    echo "Error: Cannot find lib directory at $CHIMERA_SCRIPT_DIR/lib/"
    echo "Script directory: $CHIMERA_SCRIPT_DIR"
    exit 1
fi
# source "$SCRIPT_DIR/lib/config-loader.sh"  # macOS bash互換性のため一時的に無効化

# Disable strict mode for compatibility
set +euo pipefail

# エラーハンドリング初期化（非厳密モード - tmuxとの連携のため）
init_error_handling 0 0

# フォールバック関数（config-loader.sh無効化のため）
get_config_value() {
    local key="$1"
    local default="${2:-}"
    
    case "$key" in
        "chimera_version") echo "${CHIMERA_VERSION:-0.0.1}" ;;
        *) echo "$default" ;;
    esac
}

# 使用方法表示
show_usage() {
    cat << EOF
🦁 Chimera Engine v$(get_config_value 'chimera_version' '0.0.1') - エージェント間メッセージ送信

使用方法:
  $0 [エージェント名] [メッセージ]
  $0 [PM専用コマンド] [パラメータ]
  $0 [オプション]

エージェント:
  pm              - プロダクトマネージャー（指示者）
  coder           - フルスタック開発者（Frontend/Backend/Mobile）  
  qa-functional   - 機能テスト担当（個別機能の詳細テスト）
  qa-lead         - QA総合判定担当（品質管理・リリース判定）
  monitor         - モニター（ステータス監視）

PM専用コマンド:
  check-dev           - Dev作業状況確認
  status-all          - 全体ステータス確認
  wait-qa "タスク名"  - Dev完了後にQA自動指示

計画管理コマンド:
  add-task <ID> <担当> <内容> [優先度] [依存]  - タスク追加
  update-task <ID> <状態> [担当] [進捗]         - タスク更新
  sync-plan                                     - 全エージェントに計画同期

構造化メッセージコマンド:
  task-assign <宛先> <担当> <ID> <内容>       - タスク割り当て
  task-complete <宛先> <受信> <ID> <概要>     - タスク完了報告
  error-report <宛先> <受信> <エラー内容>  - エラー報告
  status-update <宛先> <受信> <ID> <進捗%>  - ステータス更新

並列最適化コマンド:
  parallel-analyze                              - 並列実行可能タスク分析
  parallel-execute                              - 並列実行プラン実行
  parallel-report                               - 並列実行レポート生成

エージェントヘルスコマンド:
  health-check                                  - 全エージェントヘルスチェック
  health-start                                  - ヘルスモニターデーモン開始
  health-stop                                   - ヘルスモニターデーモン停止
  health-report                                 - ヘルスレポート生成

エージェント身元確認コマンド:
  role-recognition <エージェント>               - 個別エージェントに役割確認送信
  role-recognition-all                          - 全エージェントに役割確認送信
  project-init <名前> <説明>                  - プロジェクト初期化メッセージ
  identity-status                               - エージェント身元確認状態表示
  emergency-resync                              - 緊急エージェント再認識

基本使用例:
  $0 pm "あなたはPMです。指示書に従って"
  $0 coder "ログイン機能を実装してください"
  $0 qa-functional "実装されたログイン機能をテストしてください"
  
PMワークフロー例:
  $0 coder "実装指示"
  $0 check-dev              # Dev状況確認
  $0 qa-functional "テスト指示"  # 完了確認後

オプション:
  --list          利用可能なエージェント一覧表示
  --stats         通信統計表示
  --recent [N]    最新N件のアクティビティ表示（デフォルト: 10）
  --search WORD   メッセージ検索
  --config        メッセージング設定表示
  --broadcast MSG エージェント一斉送信
  --msg-stats     構造化メッセージ統計表示
  --msg-search    構造化メッセージ検索
  --help          このヘルプを表示

高度な使用例:
  $0 --broadcast "緊急：全エージェント状況報告"
  $0 --search "エラー"
  $0 --recent 20
EOF
}

# PM専用コマンド処理
handle_pm_command() {
    local command="$1"
    local param="$2"
    
    case "$command" in
        "check-dev")
            log_info "🔍 Dev作業状況を確認中..."
            if [[ -f "$SCRIPT_DIR/pm-workflow-controller.sh" ]]; then
                "$SCRIPT_DIR/pm-workflow-controller.sh" check-dev
            else
                log_error "PMワークフローコントローラーが見つかりません"
                return 1
            fi
            ;;
        "status-all")
            log_info "📊 全体ステータスを確認中..."
            if [[ -f "$SCRIPT_DIR/pm-workflow-controller.sh" ]]; then
                "$SCRIPT_DIR/pm-workflow-controller.sh" status-all
            else
                log_error "PMワークフローコントローラーが見つかりません"
                return 1
            fi
            ;;
        "wait-qa")
            if [[ -z "$param" ]]; then
                log_error "エラー: タスク名が必要です"
                echo "使用例: $0 wait-qa \"ログイン機能実装\""
                return 1
            fi
            log_info "⏳ Dev完了を待機してQAに指示..."
            if [[ -f "$SCRIPT_DIR/pm-workflow-controller.sh" ]]; then
                "$SCRIPT_DIR/pm-workflow-controller.sh" wait-for-qa "$param"
            else
                log_error "PMワークフローコントローラーが見つかりません"
                return 1
            fi
            ;;
        *)
            log_error "不明なPM専用コマンド: $command"
            echo "利用可能コマンド: check-dev, status-all, wait-qa"
            return 1
            ;;
    esac
}

# オプション処理
handle_options() {
    local option="$1"
    local param="$2"
    
    case "$option" in
        "--list")
            show_available_agents
            return 0
            ;;
        "--stats")
            get_communication_stats
            return 0
            ;;
        "--recent")
            local count="${param:-10}"
            show_recent_activity "$count"
            return 0
            ;;
        "--search")
            if [[ -z "$param" ]]; then
                log_error "検索ワードが必要です"
                echo "使用例: $0 --search \"エラー\""
                return 1
            fi
            search_messages "$param"
            return 0
            ;;
        "--config")
            show_messaging_config
            return 0
            ;;
        "--broadcast")
            if [[ -z "$param" ]]; then
                log_error "ブロードキャストメッセージが必要です"
                echo "使用例: $0 --broadcast \"緊急メッセージ\""
                return 1
            fi
            broadcast_message "$param"
            return 0
            ;;
        "--msg-stats")
            show_messaging_stats
            return 0
            ;;
        "--msg-search")
            if [[ -z "$param" ]]; then
                log_error "検索ワードが必要です"
                echo "使用例: $0 --msg-search \"エラー\""
                return 1
            fi
            search_message_history "$param"
            return 0
            ;;
        "--help")
            show_usage
            return 0
            ;;
        *)
            return 1  # オプションではない
            ;;
    esac
}

# バリデーション
validate_message_send() {
    local agent_name="$1"
    local message="$2"
    
    # エージェント名の存在確認
    if [[ -z "$agent_name" ]]; then
        log_error "エージェント名が指定されていません"
        return 1
    fi
    
    # メッセージの存在確認
    if [[ -z "$message" ]]; then
        log_error "メッセージが指定されていません"
        return 1
    fi
    
    # メッセージ長の確認
    if [[ ${#message} -gt 1000 ]]; then
        log_warn "メッセージが長すぎます（${#message}文字）。切り詰められる可能性があります。"
    fi
    
    return 0
}

# メイン処理
main() {
    # 引数なしの場合
    if [[ $# -eq 0 ]]; then
        show_usage
        return 1
    fi
    
    # オプション処理
    if handle_options "$1" "$2"; then
        return $?
    fi
    
    # PM専用コマンド確認
    if [[ "$1" == "check-dev" ]] || [[ "$1" == "status-all" ]] || [[ "$1" == "wait-qa" ]]; then
        handle_pm_command "$1" "$2"
        return $?
    fi
    
    # 計画管理コマンド処理
    case "$1" in
        "add-task")
            # タスク追加: chimera send add-task <ID> <担当> <内容> [優先度] [依存]
            if [[ $# -lt 4 ]]; then
                log_error "使用法: chimera send add-task <タスクID> <担当> <内容> [優先度] [依存]"
                return 1
            fi
            shift  # 'add-task'を除去
            add_task "$1" "$2" "$3" "${4:-medium}" "${5:-none}"
            add_communication_log "System" "all" "新規タスク追加: $1 - $3"
            update_metrics
            return $?
            ;;
        "update-task")
            # タスク更新: chimera send update-task <ID> <状態> [担当] [進捗]
            if [[ $# -lt 3 ]]; then
                log_error "使用法: chimera send update-task <タスクID> <状態> [担当] [進捗]"
                return 1
            fi
            shift  # 'update-task'を除去
            update_task_status "$1" "$2" "${3:-}" "${4:-}"
            update_metrics
            return $?
            ;;
        "sync-plan")
            # 計画同期
            log_info "📋 CHIMERA_PLAN.mdを全エージェントに同期中..."
            broadcast_message "SYNC_PLAN: CHIMERA_PLAN.mdが更新されました。最新の状態を確認してください。"
            return $?
            ;;
        "task-assign")
            # PMからCoderへのタスク割り当て: chimera send task-assign <宛先> <タスクID> <内容>
            if [[ $# -lt 4 ]]; then
                log_error "使用法: chimera send task-assign <宛先> <タスクID> <内容>"
                return 1
            fi
            shift  # 'task-assign'を除去
            local target_agent="$1"
            local task_id="$2"
            local task_content="$3"
            
            # PMからCoderへの実装指示（CLAUDE.mdの要件に従い）
            if [[ "$target_agent" == "coder" ]] || [[ "$target_agent" == "Coder" ]]; then
                local instruction_msg="# 🚀 PMからタスク割当: ${task_content}を開始してください (ID: ${task_id})"
                log_info "🚀 PMからCoder（pane 1）にタスク指示を送信中..."
                
                # tmux send-keysでCoderペイン（pane 1）に直接指示
                if tmux send-keys -t chimera-workspace:0.1 "$instruction_msg" C-m; then
                    log_success "タスク指示送信完了: $task_id"
                    add_communication_log "PM" "Coder" "タスク割当: $task_content (ID: $task_id)"
                    return 0
                else
                    log_error "tmux send-keys でのメッセージ送信に失敗しました"
                    return 1
                fi
            else
                # 他のエージェントの場合は従来通り
                send_agent_message "$target_agent" "# タスク割当 (ID: $task_id): $task_content"
                return $?
            fi
            ;;
        "task-complete")
            # 構造化タスク完了: chimera send task-complete <宛先> <受信> <ID> <概要> [成果物] [次ステップ]
            if [[ $# -lt 5 ]]; then
                log_error "使用法: chimera send task-complete <宛先> <受信> <タスクID> <概要> [成果物] [次ステップ]"
                return 1
            fi
            shift  # 'task-complete'を除去
            send_task_completion "$1" "$2" "$3" "$4" "${5:-}" "${6:-}"
            return $?
            ;;
        "error-report")
            # 構造化エラー報告: chimera send error-report <宛先> <受信> <エラー内容> [タスクID] [エラーコード] [推奨対応]
            if [[ $# -lt 4 ]]; then
                log_error "使用法: chimera send error-report <宛先> <受信> <エラー内容> [タスクID] [エラーコード] [推奨対応]"
                return 1
            fi
            shift  # 'error-report'を除去
            send_error_report "$1" "$2" "$3" "${4:-}" "${5:-}" "${6:-}"
            return $?
            ;;
        "status-update")
            # 構造化ステータス更新: chimera send status-update <宛先> <受信> <ID> <進捗%> <作業内容> [完予定] [ブロッカー]
            if [[ $# -lt 6 ]]; then
                log_error "使用法: chimera send status-update <宛先> <受信> <タスクID> <進捗%> <作業内容> [完予定] [ブロッカー]"
                return 1
            fi
            shift  # 'status-update'を除去
            send_status_update "$1" "$2" "$3" "$4" "$5" "${6:-}" "${7:-}"
            return $?
            ;;
        "parallel-analyze")
            # 並列実行可能タスク分析
            log_info "🚀 並列タスク実行分析開始..."
            "${SCRIPT_DIR}/lib/parallel-optimizer.sh" analyze
            return $?
            ;;
        "parallel-execute")
            # 並列実行プラン実行
            log_info "🚀 並列タスク実行開始..."
            "${SCRIPT_DIR}/lib/parallel-optimizer.sh" execute
            return $?
            ;;
        "parallel-report")
            # 並列実行レポート生成
            "${SCRIPT_DIR}/lib/parallel-optimizer.sh" report
            return $?
            ;;
        "health-check")
            # 全エージェントヘルスチェック
            log_info "🏥 エージェントヘルスチェック開始..."
            "${SCRIPT_DIR}/lib/agent-health-monitor.sh" check
            return $?
            ;;
        "health-start")
            # ヘルスモニターデーモン開始
            log_info "🏥 ヘルスモニターデーモン開始..."
            "${SCRIPT_DIR}/lib/agent-health-monitor.sh" start-daemon
            return $?
            ;;
        "health-stop")
            # ヘルスモニターデーモン停止
            log_info "🏥 ヘルスモニターデーモン停止..."
            "${SCRIPT_DIR}/lib/agent-health-monitor.sh" stop-daemon
            return $?
            ;;
        "health-report")
            # ヘルスレポート生成
            "${SCRIPT_DIR}/lib/agent-health-monitor.sh" report
            return $?
            ;;
        "role-recognition")
            # 個別エージェントに役割確認送信
            if [[ $# -lt 2 ]]; then
                log_error "使用法: chimera send role-recognition <エージェント名>"
                return 1
            fi
            shift  # 'role-recognition'を除去
            log_info "🎭 エージェント $1 に役割確認メッセージ送信..."
            "${SCRIPT_DIR}/lib/agent-identity.sh" send-recognition "$1" "normal"
            return $?
            ;;
        "role-recognition-all")
            # 全エージェントに役割確認送信
            log_info "🎭 全エージェントに役割確認メッセージ送信..."
            "${SCRIPT_DIR}/lib/agent-identity.sh" send-all "normal"
            return $?
            ;;
        "project-init")
            # プロジェクト初期化メッセージ
            if [[ $# -lt 2 ]]; then
                log_error "使用法: chimera send project-init <プロジェクト名> [説明]"
                return 1
            fi
            shift  # 'project-init'を除去
            log_info "🚀 プロジェクト初期化メッセージ送信..."
            "${SCRIPT_DIR}/lib/agent-identity.sh" project-init "$1" "${2:-プロジェクト説明未設定}"
            return $?
            ;;
        "identity-status")
            # エージェント身元確認状態表示
            log_info "🎭 エージェント身元確認状態チェック..."
            "${SCRIPT_DIR}/lib/agent-identity.sh" check-status
            return $?
            ;;
        "emergency-resync")
            # 緊急エージェント再認識
            log_warn "🚨 緊急エージェント再認識実行..."
            "${SCRIPT_DIR}/lib/agent-identity.sh" emergency
            return $?
            ;;
    esac
    
    # 引数数確認
    if [[ $# -lt 2 ]]; then
        log_error "引数が不足しています"
        echo ""
        show_usage
        return 1
    fi
    
    local agent_name="$1"
    local message="$2"
    
    # バリデーション
    if ! validate_message_send "$agent_name" "$message"; then
        return 1
    fi
    
    # メッセージ送信実行
    if send_agent_message "$agent_name" "$message"; then
        # 送信成功時の追加処理
        if [[ "${VERBOSE:-0}" == "1" ]]; then
            echo ""
            echo "📊 最新アクティビティ:"
            show_recent_activity 3
        fi
        return 0
    else
        log_error "メッセージ送信に失敗しました"
        return 1
    fi
}

# デバッグ情報表示（デバッグモード時）
show_debug_info() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        log_debug "=== デバッグ情報 ==="
        log_debug "スクリプト: $0"
        log_debug "引数: $*"
        log_debug "ワークスペース: $(get_config_value 'workspace_base_dir' 'N/A')"
        log_debug "セッション: $(get_config_value 'chimera_session_name' 'N/A')"
        log_debug "==================="
    fi
}

# 緊急停止処理
emergency_stop() {
    log_warn "緊急停止が要求されました"
    
    # 進行中の送信を停止
    if [[ -n "$SEND_PID" ]]; then
        kill -TERM "$SEND_PID" 2>/dev/null || true
    fi
    
    # クリーンアップ
    cleanup_on_signal "INT"
    
    exit 130
}

# シグナルハンドラー設定
trap emergency_stop INT TERM

# デバッグ情報表示
show_debug_info

# メイン実行
main "$@"