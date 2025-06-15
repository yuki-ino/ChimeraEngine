#!/bin/bash

# 🖥️ Chimera Engine - セッション管理モジュール
# tmuxセッションの作成、設定、管理を統括

SESSION_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SESSION_LIB_DIR/common.sh"

# セッション作成
create_chimera_session() {
    log_info "Chimera統合ワークスペース作成開始..."
    
    # 既存セッションクリーンアップ
    cleanup_existing_sessions
    
    # ワークスペースディレクトリ準備
    prepare_workspace
    
    # メインセッション作成
    tmux new-session -d -s "$CHIMERA_SESSION_NAME" -n "chimera-dev"
    log_success "メインセッション作成完了"
    
    # マウス操作有効化
    tmux set-option -g mouse on
    log_info "マウス操作を有効化"
    
    # ペイン分割とレイアウト設定
    setup_pane_layout
    
    # 各ペインの設定
    configure_all_panes
    
    log_success "✅ 統合ワークスペース作成完了"
}

# 既存セッションクリーンアップ
cleanup_existing_sessions() {
    local sessions_to_clean=(
        "$CHIMERA_SESSION_NAME"
        "pmproject"
        "deveng"
        "devqa"
    )
    
    cleanup_sessions "${sessions_to_clean[@]}"
}

# ワークスペース準備
prepare_workspace() {
    log_info "Chimera作業ディレクトリ準備: $CHIMERA_WORKSPACE_DIR"
    
    safe_mkdir "$CHIMERA_WORKSPACE_DIR"
    safe_mkdir "$STATUS_DIR"
    safe_mkdir "$LOGS_DIR"
    
    # 既存ステータスファイルクリア
    rm -f "$STATUS_DIR"/*.txt 2>/dev/null || true
    log_info "既存ステータスファイルをクリア"
}

# ペインレイアウト設定
setup_pane_layout() {
    log_info "ペイン分割を実行中..."
    
    # 5ペイン構成: PM(上1/3) + Coder(中1/3) + QA3つ(下1/3を3分割)
    tmux split-window -v -t "$CHIMERA_SESSION_NAME:0" -p 66    # 上1/3をPMに
    tmux split-window -v -t "$CHIMERA_SESSION_NAME:0.1" -p 50  # 残り2/3の上半分を開発者に
    tmux split-window -h -t "$CHIMERA_SESSION_NAME:0.2" -p 66  # QA1
    tmux split-window -h -t "$CHIMERA_SESSION_NAME:0.3" -p 50  # QA2, QA3
    
    log_success "ペイン分割完了"
}

# 全ペイン設定
configure_all_panes() {
    log_info "各ペインの設定中..."
    
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    local pane_index=0
    
    for agent in "${agents[@]}"; do
        configure_pane "$pane_index" "$agent"
        ((pane_index++))
    done
    
    log_success "全ペイン設定完了"
}

# 個別ペイン設定
configure_pane() {
    local pane_index="$1"
    local agent="$2"
    local pane_target="$CHIMERA_SESSION_NAME:0.$pane_index"
    
    local title=$(get_agent_info "$agent" "title")
    local color=$(get_agent_info "$agent" "color")
    local role=$(get_agent_info "$agent" "role")
    
    log_debug "ペイン${pane_index}設定: $agent ($title)"
    
    # ペインタイトル設定
    tmux select-pane -t "$pane_target" -T "$title"
    
    # 作業ディレクトリ設定
    tmux send-keys -t "$pane_target" "cd $(pwd)" C-m
    
    # プロンプト設定
    local prompt_color="\\[\\033[$color\\]"
    local prompt_reset="\\[\\033[0m\\]"
    local prompt_cmd="export PS1='($prompt_color$title$prompt_reset) \\[\\033[1;32m\\]\\w\\[\\033[0m\\]\\$ '"
    tmux send-keys -t "$pane_target" "$prompt_cmd" C-m
    
    # 役割表示
    tmux send-keys -t "$pane_target" "echo '=== 🎯 $title ($role) ==='" C-m
    
    # Claude Code起動
    start_claude_code_on_pane "$pane_target" "$agent"
}

# Claude Code起動
start_claude_code_on_pane() {
    local pane_target="$1"
    local agent="$2"
    
    log_debug "Claude Code起動: $agent"
    
    # メモリディレクトリのパスを構築
    local memory_dir="$(pwd)/.chimera/memory"
    local agent_role_file="$memory_dir/agent-roles/${agent}-role.md"
    local project_context_file="$memory_dir/project-context.md"
    
    # Claude起動コマンドを構築（memory-dirは現在のバージョンでサポートされていない）
    local claude_cmd="claude --dangerously-skip-permissions"
    
    log_debug "Claude Code起動コマンド: $claude_cmd"
    
    tmux send-keys -t "$pane_target" "echo '🤖 Claude Code起動中...'" C-m
    tmux send-keys -t "$pane_target" "$claude_cmd" C-m
}

# Claude Code認証自動化
auto_authenticate_claude() {
    log_info "Claude Code認証を自動実行中..."
    
    # 起動待機
    sleep "$CLAUDE_STARTUP_WAIT"
    
    # 全ペインに認証コマンド送信
    for i in {0..4}; do
        tmux send-keys -t "$CHIMERA_SESSION_NAME:0.$i" "2" C-m
        log_debug "ペイン $i: 認証送信完了"
    done
    
    sleep "$AUTH_RETRY_WAIT"
    
    sleep 2
    log_success "Claude Code認証完了"
}


# セッション情報表示
show_session_info() {
    echo ""
    echo "📊 セットアップ結果:"
    echo "==================="
    
    # セッション一覧
    echo "📺 Tmux Sessions:"
    tmux list-sessions 2>/dev/null || echo "セッションが見つかりません"
    echo ""
    
    # Chimeraセッション構成
    if session_exists "$CHIMERA_SESSION_NAME"; then
        show_chimera_layout
    fi
    
    # ディレクトリ情報
    echo "📁 ディレクトリ構成:"
    echo "  $STATUS_DIR  - ステータス管理ファイル"
    echo "  $LOGS_DIR    - 各種ログファイル"
    echo "  ※プロジェクトフォルダは汚しません"
}

# Chimeraレイアウト表示
show_chimera_layout() {
    echo "📋 統合ワークスペース構成:"
    echo "  ┌─────────────────────────────────┐"
    echo "  │ PM (上1/3)                      │ ← 🎯 企画・管理"
    echo "  ├─────────────────────────────────┤"
    echo "  │ Coder (中1/3)                   │ ← 👨‍💻 フルスタック開発"
    echo "  ├───────────┬───────────┬─────────┤"
    echo "  │QA-Func    │QA-Lead    │Monitor  │ ← 🧪👑📊 品質管理"
    echo "  │(下1/3左)  │(下1/3中)  │(下1/3右) │"
    echo "  └───────────┴───────────┴─────────┘"
    echo ""
}

# セッション接続
attach_to_session() {
    local session_name="${1:-$CHIMERA_SESSION_NAME}"
    local target_pane="${2:-0}"
    
    if ! session_exists "$session_name"; then
        log_error "セッション '$session_name' が見つかりません"
        return 1
    fi
    
    log_success "🚀 $session_name セッションに接続します..."
    
    # 指定ペインにフォーカス
    tmux select-pane -t "$session_name:0.$target_pane"
    
    # セッションにアタッチ
    tmux attach-session -t "$session_name"
}

# セッション状態確認
check_session_health() {
    local session_name="${1:-$CHIMERA_SESSION_NAME}"
    
    if ! session_exists "$session_name"; then
        log_error "セッション '$session_name' が存在しません"
        return 1
    fi
    
    local pane_count=$(tmux list-panes -t "$session_name" 2>/dev/null | wc -l)
    log_info "セッション '$session_name': $pane_count ペイン"
    
    # 各ペインの状態確認
    for ((i=0; i<pane_count; i++)); do
        if pane_exists "$session_name:0.$i"; then
            log_success "✓ ペイン $i: アクティブ"
        else
            log_warn "✗ ペイン $i: 問題あり"
        fi
    done
    
    return 0
}

# セッション修復
repair_session() {
    local session_name="${1:-$CHIMERA_SESSION_NAME}"
    
    log_info "セッション修復を試行中..."
    
    if session_exists "$session_name"; then
        log_info "既存セッションを削除"
        cleanup_session "$session_name"
    fi
    
    if [[ "$session_name" == "$CHIMERA_SESSION_NAME" ]]; then
        create_chimera_session
        auto_authenticate_claude
    else
        log_error "不明なセッション名: $session_name"
        return 1
    fi
    
    log_success "セッション修復完了"
}