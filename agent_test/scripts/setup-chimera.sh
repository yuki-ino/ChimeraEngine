#!/bin/bash

# 🦁 Chimera Engine - Multi-Agent Development Environment Setup
# リファクタリング版: 共通ライブラリとモジュール化されたアーキテクチャを使用

# スクリプトディレクトリ取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 共通ライブラリ読み込み（config.shは common.shが読み込む）
source "$SCRIPT_DIR/lib/common.sh"
# source "$SCRIPT_DIR/lib/config-loader.sh"  # macOS bash互換性のため一時的に無効化
source "$SCRIPT_DIR/lib/session-manager.sh" 
source "$SCRIPT_DIR/lib/error-handler.sh"

# エラーハンドリング初期化（macOS互換のため厳密モード無効）
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

# メイン処理
main() {
    log_info "🦁 Chimera Engine v$(get_config_value 'chimera_version' '0.0.1') - Multi-Agent Development Environment Setup"
    echo "========================================================================="
    echo ""
    
    # 環境バリデーション
    validate_environment || {
        log_error "環境バリデーションに失敗しました"
        exit 1
    }
    
    # 設定情報表示
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        show_config
        echo ""
    fi
    
    # Chimeraセッション作成
    create_chimera_session
    
    # Claude Code認証自動化
    auto_authenticate_claude
    
    # セッション情報表示
    show_session_info
    
    # 操作説明
    show_usage_instructions
    
    # セッションに接続
    attach_to_session "$CHIMERA_SESSION_NAME" 0
}

# 使用方法説明
show_usage_instructions() {
    echo ""
    log_success "🎉 Chimera Engine 統合ワークスペース完成！"
    echo ""
    echo "📋 自動構成完了:"
    echo "  ✅ 1ウィンドウ5ペイン自動分割"
    echo "  ✅ 全ペインで Claude Code 起動中"  
    echo "  ✅ ワークスペースに自動接続"
    echo ""
    echo "🎯 ペイン操作:"
    echo "  マウスクリック      (ペイン選択)"
    echo "  Ctrl+b, ↑↓←→    (キーボードペイン移動)"
    echo "  Ctrl+b, z        (ペイン最大化/復元)"
    echo "  Ctrl+b, d        (セッションデタッチ)"
    echo ""
    echo "📤 エージェント通信:"
    echo "  chimera send pm \"指示内容\""
    echo "  chimera send coder \"実装内容\""
    echo "  chimera send qa-functional \"テスト内容\""
    echo ""
    echo "🔧 セッション管理:"
    echo "  chimera start     # 再起動"
    echo "  chimera send --list  # エージェント一覧"
    echo ""
}

# セッション修復モード
repair_mode() {
    log_info "🔧 セッション修復モードを開始"
    
    # 既存セッション確認
    if session_exists "$CHIMERA_SESSION_NAME"; then
        log_info "既存セッションの状態確認中..."
        if ! check_session_health "$CHIMERA_SESSION_NAME"; then
            log_warn "セッションに問題が検出されました"
            repair_session "$CHIMERA_SESSION_NAME"
        else
            log_success "既存セッションは正常です"
            attach_to_session "$CHIMERA_SESSION_NAME" 0
            return 0
        fi
    else
        log_info "セッションが見つかりません。新規作成します"
        main
    fi
}


# 引数処理
while [[ $# -gt 0 ]]; do
    case $1 in
        --repair)
            repair_mode
            exit $?
            ;;
        --verbose|-v)
            export VERBOSE=1
            shift
            ;;
        --debug)
            export DEBUG=1
            toggle_debug_mode
            shift
            ;;
        --help|-h)
            cat << EOF
Chimera Engine セットアップスクリプト

使用方法:
  $0 [オプション]

オプション:
  --repair      既存セッションの修復
  --verbose     詳細出力
  --debug       デバッグモード
  --help        このヘルプを表示

例:
  $0              # 標準セットアップ
  $0 --repair     # セッション修復
  $0 --verbose    # 詳細出力付きセットアップ

設定:
  環境変数 CHIMERA_CONFIG でカスタム設定ファイルを指定可能
  例: CHIMERA_CONFIG=/path/to/config.yaml $0
EOF
            exit 0
            ;;
        *)
            log_error "不明なオプション: $1"
            echo "使用方法: $0 --help"
            exit 1
            ;;
    esac
done

# メイン実行
main