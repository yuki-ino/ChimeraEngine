#!/bin/bash

# 🔍 CHIMERA_PLAN.md監視デーモン
# 各エージェントがバックグラウンドで計画変更を監視

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/plan-manager.sh"

# 使用方法
show_usage() {
    cat << EOF
CHIMERA_PLAN.md監視デーモン

使用方法:
  $0 start <agent>    指定エージェントの監視開始
  $0 stop <agent>     指定エージェントの監視停止
  $0 status           全エージェントの監視状態表示
  $0 start-all        全エージェント監視開始
  $0 stop-all         全エージェント監視停止

例:
  $0 start coder      # Coderエージェントの監視開始
  $0 status           # 監視状態確認
EOF
}

# PIDファイルパス取得
get_pid_file() {
    local agent="$1"
    echo "${CHIMERA_WORKSPACE_DIR}/run/watcher_${agent}.pid"
}

# 監視開始
start_watcher() {
    local agent="$1"
    local interval="${2:-10}"
    local pid_file=$(get_pid_file "$agent")
    
    # 既に実行中かチェック
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            log_warn "Agent $agent の監視は既に実行中です (PID: $pid)"
            return 0
        fi
    fi
    
    # バックグラウンドで監視開始
    log_info "Agent $agent の監視を開始します (間隔: ${interval}秒)"
    
    safe_mkdir "${CHIMERA_WORKSPACE_DIR}/run"
    
    # 監視プロセスをバックグラウンドで起動
    (
        while true; do
            watch_plan "$agent" "$interval"
        done
    ) &
    
    local watcher_pid=$!
    echo "$watcher_pid" > "$pid_file"
    
    log_success "監視開始完了 (PID: $watcher_pid)"
}

# 監視停止
stop_watcher() {
    local agent="$1"
    local pid_file=$(get_pid_file "$agent")
    
    if [[ ! -f "$pid_file" ]]; then
        log_warn "Agent $agent の監視は実行されていません"
        return 0
    fi
    
    local pid=$(cat "$pid_file")
    
    if kill -0 "$pid" 2>/dev/null; then
        log_info "Agent $agent の監視を停止します (PID: $pid)"
        kill "$pid"
        sleep 1
        
        # 強制終了が必要な場合
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid"
        fi
    fi
    
    rm -f "$pid_file"
    log_success "監視停止完了"
}

# 監視状態表示
show_status() {
    echo "📊 CHIMERA_PLAN.md 監視状態:"
    echo "=============================="
    
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    
    for agent in "${agents[@]}"; do
        local pid_file=$(get_pid_file "$agent")
        
        if [[ -f "$pid_file" ]]; then
            local pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                echo "✅ $agent: 監視中 (PID: $pid)"
            else
                echo "⚠️  $agent: PIDファイルあり、プロセスなし"
            fi
        else
            echo "❌ $agent: 停止中"
        fi
    done
}

# 全エージェント監視開始
start_all() {
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    
    log_info "全エージェントの監視を開始します..."
    
    for agent in "${agents[@]}"; do
        start_watcher "$agent"
    done
}

# 全エージェント監視停止
stop_all() {
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    
    log_info "全エージェントの監視を停止します..."
    
    for agent in "${agents[@]}"; do
        stop_watcher "$agent"
    done
}

# メイン処理
case "${1:-}" in
    "start")
        if [[ -z "$2" ]]; then
            log_error "エージェント名が必要です"
            show_usage
            exit 1
        fi
        start_watcher "$2" "${3:-10}"
        ;;
    "stop")
        if [[ -z "$2" ]]; then
            log_error "エージェント名が必要です"
            show_usage
            exit 1
        fi
        stop_watcher "$2"
        ;;
    "status")
        show_status
        ;;
    "start-all")
        start_all
        ;;
    "stop-all")
        stop_all
        ;;
    *)
        show_usage
        exit 1
        ;;
esac