#!/bin/bash

# 🎯 PM モードコントローラー
# PMの企画検討モードと開発指示モードを管理

PROJECT_DIR="${1:-.}"
STATUS_DIR="$PROJECT_DIR/status"
LOG_DIR="$PROJECT_DIR/logs"

# ディレクトリ作成
mkdir -p "$STATUS_DIR" "$LOG_DIR"

# 色付きログ
log_info() { echo -e "\033[1;32m[INFO]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_success() { echo -e "\033[1;34m[SUCCESS]\033[0m $1"; }

# 現在のPMモード取得
get_pm_mode() {
    if [ -f "$STATUS_DIR/planning_complete.txt" ]; then
        echo "DEVELOPMENT"
    elif [ -f "$STATUS_DIR/planning_started.txt" ]; then
        echo "PLANNING"
    else
        echo "INITIAL"
    fi
}

# PMモード設定
set_pm_mode() {
    local mode="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$mode" in
        "PLANNING")
            touch "$STATUS_DIR/planning_started.txt"
            echo "[$timestamp] PM企画検討モード開始" >> "$LOG_DIR/pm_log.txt"
            log_info "🎯 PM企画検討モードを開始しました"
            ;;
        "DEVELOPMENT")
            touch "$STATUS_DIR/planning_complete.txt"
            echo "[$timestamp] 企画確定、開発モード開始" >> "$LOG_DIR/pm_log.txt"
            log_success "🚀 企画が確定し、開発モードを開始しました"
            ;;
        "RESET")
            rm -f "$STATUS_DIR/planning_"*.txt
            echo "[$timestamp] PMモードリセット" >> "$LOG_DIR/pm_log.txt"
            log_warn "🔄 PMモードをリセットしました"
            ;;
    esac
}

# PMダッシュボード表示
show_pm_dashboard() {
    local current_mode=$(get_pm_mode)
    
    echo "🎯 PM ダッシュボード"
    echo "===================="
    echo "現在のモード: $current_mode"
    echo "日時: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    case "$current_mode" in
        "INITIAL")
            echo "📋 ステータス: 初期状態"
            echo "次のアクション: 企画検討を開始してください"
            echo ""
            echo "💡 コマンド:"
            echo "  $0 start-planning    # 企画検討開始"
            ;;
        "PLANNING")
            echo "🤔 ステータス: 企画検討中"
            echo "説明: コーダー・テスターには指示を送信していません"
            
            # 企画検討時間の表示
            planning_start=$(stat -f %Sm -t %s "$STATUS_DIR/planning_started.txt" 2>/dev/null)
            if [ -n "$planning_start" ]; then
                current_time=$(date +%s)
                elapsed=$((current_time - planning_start))
                elapsed_hours=$((elapsed / 3600))
                elapsed_minutes=$(((elapsed % 3600) / 60))
                echo "検討時間: ${elapsed_hours}時間${elapsed_minutes}分"
            fi
            
            echo ""
            echo "📝 企画検討チェックリスト:"
            show_planning_checklist
            echo ""
            echo "💡 コマンド:"
            echo "  $0 add-note \"検討内容\"     # 検討メモ追加"
            echo "  $0 finalize-planning      # 企画確定・開発開始"
            echo "  $0 reset                  # 企画をリセット"
            ;;
        "DEVELOPMENT")
            echo "🚀 ステータス: 開発モード"
            echo "説明: チームに開発指示を送信済み"
            
            # 開発状況の表示
            echo ""
            echo "📊 開発状況:"
            show_development_status
            echo ""
            echo "💡 コマンド:"
            echo "  $0 check-progress        # 進捗確認"
            echo "  $0 send-message          # チームへメッセージ"
            ;;
    esac
    
    echo ""
    echo "📄 最近のPMログ:"
    tail -5 "$LOG_DIR/pm_log.txt" 2>/dev/null || echo "  (ログなし)"
}

# 企画検討チェックリスト表示
show_planning_checklist() {
    local checklist_file="$STATUS_DIR/planning_checklist.txt"
    
    if [ ! -f "$checklist_file" ]; then
        cat > "$checklist_file" << 'EOF'
□ ビジネス価値の明確化
□ ユーザーストーリーの定義
□ 技術要件の整理
□ 非機能要件の確認
□ リスクの洗い出し
□ 成功指標(KPI)の設定
□ スケジュール・予算の確認
□ チーム体制の確認
EOF
    fi
    
    cat "$checklist_file"
}

# 開発状況表示
show_development_status() {
    echo "  📁 ステータスファイル:"
    ls -la "$STATUS_DIR"/*.txt 2>/dev/null | while read line; do
        echo "    $line"
    done
    
    echo ""
    echo "  📋 開発ログ (直近5件):"
    tail -5 "$LOG_DIR/development_log.txt" 2>/dev/null | sed 's/^/    /' || echo "    (開発ログなし)"
}

# 企画検討メモ追加
add_planning_note() {
    local note="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] $note" >> "$LOG_DIR/planning_notes.txt"
    log_info "企画検討メモを追加しました: $note"
}

# 企画確定・開発開始
finalize_planning() {
    local current_mode=$(get_pm_mode)
    
    if [ "$current_mode" != "PLANNING" ]; then
        log_warn "企画検討モードではありません。現在のモード: $current_mode"
        return 1
    fi
    
    echo "🔍 企画確定前の最終チェック"
    echo "以下の項目を確認してください:"
    show_planning_checklist
    echo ""
    echo "すべて完了していますか? (y/N):"
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        set_pm_mode "DEVELOPMENT"
        
        # 開発指示の送信
        echo ""
        log_info "チームに開発指示を送信します..."
        
        # 実際のプロジェクトファイルがある場合は送信
        if command -v chimera >/dev/null 2>&1; then
            chimera send coder "あなたはcoderです。企画が確定しました。実装を開始してください。"
            chimera send tester "あなたはtesterです。開発が開始されました。テスト準備をお願いします。"
            log_success "開発指示を送信しました"
        else
            log_info "chimera コマンドが見つかりません（ドライラン）"
        fi
        
    else
        log_info "企画検討を継続します"
    fi
}

# 進捗確認
check_progress() {
    echo "📊 プロジェクト進捗確認"
    echo "======================"
    
    # ステータスファイルの確認
    if [ -f "$STATUS_DIR/coding_done.txt" ]; then
        echo "✅ コーディング: 完了"
    else
        echo "⏳ コーディング: 進行中"
    fi
    
    if [ -f "$STATUS_DIR/test_passed.txt" ]; then
        echo "✅ テスト: 合格"
    elif [ -f "$STATUS_DIR/test_failed.txt" ]; then
        echo "❌ テスト: 失敗（修正中）"
    else
        echo "⏳ テスト: 未実施"
    fi
    
    # 最新のコミュニケーションログ
    echo ""
    echo "💬 最新のチーム連絡:"
    tail -3 "$LOG_DIR/communication_log.txt" 2>/dev/null || echo "  (連絡なし)"
}

# メイン処理
main() {
    case "$1" in
        "dashboard"|"")
            show_pm_dashboard
            ;;
        "start-planning")
            set_pm_mode "PLANNING"
            show_pm_dashboard
            ;;
        "add-note")
            shift
            add_planning_note "$*"
            ;;
        "finalize-planning")
            finalize_planning
            ;;
        "check-progress")
            check_progress
            ;;
        "reset")
            set_pm_mode "RESET"
            ;;
        "help"|"-h"|"--help")
            echo "PM モードコントローラー"
            echo ""
            echo "使用方法:"
            echo "  $0 [command]"
            echo ""
            echo "コマンド:"
            echo "  dashboard           PMダッシュボードを表示（デフォルト）"
            echo "  start-planning      企画検討モードを開始"
            echo "  add-note \"内容\"     企画検討メモを追加"
            echo "  finalize-planning   企画確定・開発開始"
            echo "  check-progress      開発進捗確認"
            echo "  reset               PMモードをリセット"
            echo "  help                このヘルプを表示"
            ;;
        *)
            echo "不明なコマンド: $1"
            echo "使用方法: $0 help"
            exit 1
            ;;
    esac
}

main "$@"