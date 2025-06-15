#!/bin/bash

# 🚀 Chimera Engine - エージェント間メッセージ送信システム
# リファクタリング版: モジュール化されたメッセージングシステムを使用

# スクリプトディレクトリ取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 共通ライブラリ読み込み
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/messaging.sh"
source "$SCRIPT_DIR/lib/error-handler.sh"
source "$SCRIPT_DIR/lib/config-loader.sh"

# エラーハンドリング初期化（非厳密モード - tmuxとの連携のため）
init_error_handling 0 0

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