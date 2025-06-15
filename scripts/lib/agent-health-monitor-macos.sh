#!/bin/bash

# 🏥 Agent Health Monitoring & Recovery System for Chimera Engine (macOS Compatible)
# エージェント自己診断・回復システム（macOS bash 3.x対応版）

HEALTH_MONITOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${HEALTH_MONITOR_DIR}/common.sh"
source "${HEALTH_MONITOR_DIR}/plan-manager.sh"
source "${HEALTH_MONITOR_DIR}/messaging.sh"

# しきい値設定
readonly MAX_RESPONSE_TIME=30
readonly MAX_IDLE_TIME=300
readonly MAX_ERROR_COUNT=3
readonly CONTEXT_SYNC_INTERVAL=180
readonly HEALTH_CHECK_INTERVAL=60

# エージェント情報取得（macOS compatible）
get_agent_metric() {
    local agent="$1"
    local metric="$2"
    local health_dir="${CHIMERA_WORKSPACE_DIR}/health_monitor"
    local metric_file="${health_dir}/metrics/${agent}_${metric}.txt"
    
    if [[ -f "$metric_file" ]]; then
        cat "$metric_file"
    else
        echo "0"
    fi
}

# エージェント情報設定
set_agent_metric() {
    local agent="$1"
    local metric="$2"
    local value="$3"
    local health_dir="${CHIMERA_WORKSPACE_DIR}/health_monitor"
    local metric_file="${health_dir}/metrics/${agent}_${metric}.txt"
    
    # ディレクトリが存在しない場合は作成
    safe_mkdir "$(dirname "$metric_file")"
    
    echo "$value" > "$metric_file"
}

# ヘルスモニター初期化
init_health_monitor() {
    log_info "🏥 エージェント健康監視システム初期化中..."
    
    local health_dir="${CHIMERA_WORKSPACE_DIR}/health_monitor"
    safe_mkdir "$health_dir"
    safe_mkdir "${health_dir}/metrics"
    safe_mkdir "${health_dir}/diagnostics"
    safe_mkdir "${health_dir}/recovery_logs"
    safe_mkdir "${health_dir}/performance"
    
    # エージェント初期状態設定
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    local current_time=$(date +%s)
    
    for agent in "${agents[@]}"; do
        set_agent_metric "$agent" "last_activity" "$current_time"
        set_agent_metric "$agent" "errors" "0"
        set_agent_metric "$agent" "performance" "100"
        set_agent_metric "$agent" "response_time" "0"
        set_agent_metric "$agent" "context_sync" "$current_time"
    done
    
    # ヘルスチェック設定ファイル作成
    create_health_check_config
    
    log_success "エージェント健康監視システム初期化完了"
}

# ヘルスチェック設定ファイル作成
create_health_check_config() {
    local config_file="${CHIMERA_WORKSPACE_DIR}/health_monitor/health_config.yaml"
    
    cat > "$config_file" << EOF
# Chimera Engine Agent Health Configuration
health_thresholds:
  max_response_time: $MAX_RESPONSE_TIME
  max_idle_time: $MAX_IDLE_TIME
  max_error_count: $MAX_ERROR_COUNT
  context_sync_interval: $CONTEXT_SYNC_INTERVAL
  health_check_interval: $HEALTH_CHECK_INTERVAL

recovery_actions:
  context_loss: "force_plan_resync"
  high_error_rate: "agent_restart"
  performance_degradation: "optimization_suggestions"
  communication_failure: "emergency_recovery"

alert_settings:
  critical_threshold: 30
  warning_threshold: 70
  
monitoring_features:
  context_tracking: true
  performance_analysis: true
  predictive_maintenance: true
  auto_recovery: true
EOF
}

# エージェント活動記録
record_agent_activity() {
    local agent="$1"
    local activity_type="$2"
    local details="${3:-}"
    local current_time=$(date +%s)
    
    set_agent_metric "$agent" "last_activity" "$current_time"
    
    # アクティビティログ
    local activity_log="${CHIMERA_WORKSPACE_DIR}/health_monitor/metrics/${agent}_activity.log"
    safe_mkdir "$(dirname "$activity_log")"
    echo "$(date -Iseconds) | $activity_type | $details" >> "$activity_log"
    
    log_debug "エージェント活動記録: $agent - $activity_type"
}

# エージェント応答時間測定
measure_response_time() {
    local agent="$1"
    local start_time="$2"
    local end_time=$(date +%s)
    local response_time=$((end_time - start_time))
    
    set_agent_metric "$agent" "response_time" "$response_time"
    
    # 応答時間履歴保存
    local response_log="${CHIMERA_WORKSPACE_DIR}/health_monitor/metrics/${agent}_response_time.log"
    safe_mkdir "$(dirname "$response_log")"
    echo "$(date -Iseconds) | $response_time" >> "$response_log"
    
    # パフォーマンススコア更新
    update_performance_score "$agent"
    
    log_debug "応答時間測定: $agent - ${response_time}秒"
}

# エラー記録
record_agent_error() {
    local agent="$1"
    local error_type="$2"
    local error_details="$3"
    
    # エラーカウント増加
    local current_errors=$(get_agent_metric "$agent" "errors")
    local new_errors=$((current_errors + 1))
    set_agent_metric "$agent" "errors" "$new_errors"
    
    # エラーログ
    local error_log="${CHIMERA_WORKSPACE_DIR}/health_monitor/diagnostics/${agent}_errors.log"
    safe_mkdir "$(dirname "$error_log")"
    echo "$(date -Iseconds) | $error_type | $error_details" >> "$error_log"
    
    # 緊急対応が必要かチェック
    if [[ $new_errors -ge $MAX_ERROR_COUNT ]]; then
        trigger_emergency_recovery "$agent" "high_error_rate"
    fi
    
    # パフォーマンススコア更新
    update_performance_score "$agent"
    
    log_warn "エージェントエラー記録: $agent - $error_type"
}

# パフォーマンススコア更新
update_performance_score() {
    local agent="$1"
    local score=100
    
    # 応答時間ペナルティ
    local response_time=$(get_agent_metric "$agent" "response_time")
    if [[ $response_time -gt $MAX_RESPONSE_TIME ]]; then
        score=$((score - (response_time - MAX_RESPONSE_TIME) * 2))
    fi
    
    # エラー率ペナルティ
    local error_count=$(get_agent_metric "$agent" "errors")
    score=$((score - error_count * 10))
    
    # アイドル時間ペナルティ
    local current_time=$(date +%s)
    local last_activity=$(get_agent_metric "$agent" "last_activity")
    local idle_time=$((current_time - last_activity))
    if [[ $idle_time -gt $MAX_IDLE_TIME ]]; then
        score=$((score - (idle_time - MAX_IDLE_TIME) / 10))
    fi
    
    # スコアの範囲制限
    if [[ $score -lt 0 ]]; then score=0; fi
    if [[ $score -gt 100 ]]; then score=100; fi
    
    set_agent_metric "$agent" "performance" "$score"
    
    # 警告レベルチェック
    if [[ $score -lt 30 ]]; then
        trigger_critical_alert "$agent" "$score"
    elif [[ $score -lt 70 ]]; then
        trigger_warning_alert "$agent" "$score"
    fi
}

# コンテキスト同期状態チェック
check_context_sync() {
    local agent="$1"
    local current_time=$(date +%s)
    local last_sync=$(get_agent_metric "$agent" "context_sync")
    local sync_age=$((current_time - last_sync))
    
    if [[ $sync_age -gt $CONTEXT_SYNC_INTERVAL ]]; then
        log_warn "エージェント $agent のコンテキスト同期が古い (${sync_age}秒前)"
        force_context_resync "$agent"
        return 1
    fi
    
    return 0
}

# 強制コンテキスト再同期
force_context_resync() {
    local agent="$1"
    local current_time=$(date +%s)
    
    log_info "エージェント $agent の強制コンテキスト再同期実行中..."
    
    # CHIMERA_PLAN.mdの再読み込み指示
    local resync_message="CONTEXT_RESYNC: CHIMERA_PLAN.mdを再読み込みし、最新のタスク状況を確認してください。現在時刻: $(date)"
    send_agent_message "$agent" "$resync_message"
    
    # 同期時刻更新
    set_agent_metric "$agent" "context_sync" "$current_time"
    
    # 回復ログ
    local recovery_log="${CHIMERA_WORKSPACE_DIR}/health_monitor/recovery_logs/${agent}_recovery.log"
    safe_mkdir "$(dirname "$recovery_log")"
    echo "$(date -Iseconds) | CONTEXT_RESYNC | Forced context resynchronization" >> "$recovery_log"
    
    # アクティビティ記録
    record_agent_activity "$agent" "CONTEXT_RESYNC" "Forced resynchronization"
    
    log_success "エージェント $agent のコンテキスト再同期完了"
}

# 緊急回復処理
trigger_emergency_recovery() {
    local agent="$1"
    local recovery_type="$2"
    
    log_error "🚨 エージェント $agent 緊急回復処理開始: $recovery_type"
    
    case "$recovery_type" in
        "high_error_rate")
            emergency_agent_restart "$agent"
            ;;
        "context_loss")
            force_context_resync "$agent"
            emergency_team_sync
            ;;
        "communication_failure")
            emergency_communication_recovery "$agent"
            ;;
        "performance_degradation")
            performance_optimization_suggestions "$agent"
            ;;
        *)
            log_error "不明な回復タイプ: $recovery_type"
            ;;
    esac
    
    # 緊急回復ログ
    local emergency_log="${CHIMERA_WORKSPACE_DIR}/health_monitor/recovery_logs/emergency_recovery.log"
    safe_mkdir "$(dirname "$emergency_log")"
    echo "$(date -Iseconds) | $agent | $recovery_type | Emergency recovery triggered" >> "$emergency_log"
}

# エージェント緊急再起動
emergency_agent_restart() {
    local agent="$1"
    
    log_warn "🔄 エージェント $agent 緊急再起動中..."
    
    # エージェントペインの特定
    local pane=$(get_agent_pane "$agent")
    
    if [[ -n "$pane" ]]; then
        # 既存プロセス終了
        tmux send-keys -t "$pane" C-c
        sleep 2
        
        # Claude Code再起動
        tmux send-keys -t "$pane" "claude --dangerously-skip-permissions" C-m
        sleep 3
        
        # コンテキスト再同期
        force_context_resync "$agent"
        
        # メトリクスリセット
        set_agent_metric "$agent" "errors" "0"
        set_agent_metric "$agent" "performance" "80"  # 再起動後は80からスタート
        
        log_success "エージェント $agent 緊急再起動完了"
    else
        log_error "エージェント $agent のペインが見つかりません"
    fi
}

# チーム全体同期
emergency_team_sync() {
    log_info "🔄 チーム全体緊急同期開始..."
    
    # 全エージェントにCHIMERA_PLAN.md再読み込み指示
    broadcast_message "EMERGENCY_SYNC: システム緊急同期実行中。CHIMERA_PLAN.mdを再読み込みし、最新状況を確認してください。"
    
    # 計画ファイル同期
    update_metrics
    
    # 全エージェントのコンテキスト同期時刻更新
    local current_time=$(date +%s)
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    
    for agent in "${agents[@]}"; do
        set_agent_metric "$agent" "context_sync" "$current_time"
    done
    
    log_success "チーム全体緊急同期完了"
}

# 通信回復処理
emergency_communication_recovery() {
    local agent="$1"
    
    log_info "📡 エージェント $agent 通信回復処理中..."
    
    # tmuxセッション確認
    if ! session_exists "$CHIMERA_SESSION_NAME"; then
        log_error "Chimeraセッションが存在しません。再作成が必要です。"
        return 1
    fi
    
    # エージェントペインの健康状態確認
    local pane=$(get_agent_pane "$agent")
    if ! pane_exists "$pane"; then
        log_error "エージェント $agent のペインが存在しません"
        return 1
    fi
    
    # 通信テスト
    tmux send-keys -t "$pane" "echo 'HEALTH_CHECK_$(date +%s)'" C-m
    sleep 2
    
    # 通信回復ログ
    local recovery_log="${CHIMERA_WORKSPACE_DIR}/health_monitor/recovery_logs/${agent}_recovery.log"
    safe_mkdir "$(dirname "$recovery_log")"
    echo "$(date -Iseconds) | COMMUNICATION_RECOVERY | Communication recovery attempted" >> "$recovery_log"
    
    log_success "エージェント $agent 通信回復処理完了"
}

# 重要アラート
trigger_critical_alert() {
    local agent="$1"
    local score="$2"
    
    log_error "🚨 CRITICAL: エージェント $agent パフォーマンス重要警告 (スコア: $score)"
    
    # 緊急対応実行
    trigger_emergency_recovery "$agent" "performance_degradation"
    
    # 重要アラートログ
    local alert_log="${CHIMERA_WORKSPACE_DIR}/health_monitor/diagnostics/critical_alerts.log"
    safe_mkdir "$(dirname "$alert_log")"
    echo "$(date -Iseconds) | CRITICAL | $agent | Performance score: $score" >> "$alert_log"
}

# 警告アラート
trigger_warning_alert() {
    local agent="$1"
    local score="$2"
    
    log_warn "⚠️ WARNING: エージェント $agent パフォーマンス警告 (スコア: $score)"
    
    # 警告レベルの自動対応
    check_context_sync "$agent"
    
    # 警告ログ
    local warning_log="${CHIMERA_WORKSPACE_DIR}/health_monitor/diagnostics/warnings.log"
    safe_mkdir "$(dirname "$warning_log")"
    echo "$(date -Iseconds) | WARNING | $agent | Performance score: $score" >> "$warning_log"
}

# 総合ヘルスチェック実行
run_comprehensive_health_check() {
    log_info "🏥 総合ヘルスチェック実行中..."
    
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    local overall_health=100
    local unhealthy_agents=()
    
    for agent in "${agents[@]}"; do
        log_info "エージェント $agent ヘルスチェック中..."
        
        # 各種チェック実行
        check_context_sync "$agent"
        update_performance_score "$agent"
        
        local agent_score=$(get_agent_metric "$agent" "performance")
        overall_health=$((overall_health + agent_score))
        
        if [[ $agent_score -lt 70 ]]; then
            unhealthy_agents+=("$agent")
        fi
        
        record_agent_activity "$agent" "HEALTH_CHECK" "Comprehensive health check"
    done
    
    # 全体健康度計算
    overall_health=$((overall_health / (${#agents[@]} + 1)))
    
    # ヘルスレポート生成
    generate_health_report "$overall_health" "${unhealthy_agents[@]}"
    
    log_success "総合ヘルスチェック完了 (全体スコア: $overall_health)"
}

# ヘルスレポート生成
generate_health_report() {
    local overall_score="$1"
    shift
    local unhealthy_agents=("$@")
    
    local report_file="${CHIMERA_WORKSPACE_DIR}/health_monitor/health_report.md"
    
    cat > "$report_file" << EOF
# 🏥 Chimera Engine Health Report

生成日時: $(date)
全体健康度: $overall_score/100

## 📊 エージェント別健康状態

$(for agent in pm coder qa-functional qa-lead monitor; do
    local score=$(get_agent_metric "$agent" "performance")
    local status="正常"
    if [[ $score -lt 30 ]]; then status="🚨 重要"; 
    elif [[ $score -lt 70 ]]; then status="⚠️ 警告"; fi
    
    local last_activity=$(get_agent_metric "$agent" "last_activity")
    local error_count=$(get_agent_metric "$agent" "errors")
    local response_time=$(get_agent_metric "$agent" "response_time")
    
    echo "### $agent"
    echo "- スコア: $score/100 ($status)"
    echo "- 最後の活動: $(date -d "@$last_activity" 2>/dev/null || echo "不明")"
    echo "- エラー回数: $error_count"
    echo "- 応答時間: ${response_time}秒"
    echo ""
done)

## ⚡ システム推奨事項

### 即座の対応が必要
$(if [[ ${#unhealthy_agents[@]} -gt 0 ]]; then
    echo "以下のエージェントで問題が検出されました:"
    for agent in "${unhealthy_agents[@]}"; do
        local score=$(get_agent_metric "$agent" "performance")
        echo "- $agent (スコア: $score)"
    done
else
    echo "現在、即座の対応が必要な問題はありません。"
fi)

### 予防的メンテナンス
1. 定期的なCHIMERA_PLAN.md同期確認
2. エージェント間通信の最適化
3. パフォーマンス監視の継続

---
Generated by Chimera Health Monitor v${CHIMERA_VERSION}
EOF

    log_success "ヘルスレポート生成完了: $report_file"
}

# ヘルスモニターデーモン開始
start_health_daemon() {
    local daemon_pid_file="${CHIMERA_WORKSPACE_DIR}/health_monitor/daemon.pid"
    
    # ディレクトリ確保
    safe_mkdir "$(dirname "$daemon_pid_file")"
    
    # 既存デーモンチェック
    if [[ -f "$daemon_pid_file" ]]; then
        local pid=$(cat "$daemon_pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            log_warn "ヘルスモニターデーモンは既に実行中です (PID: $pid)"
            return 0
        fi
    fi
    
    log_info "🏥 ヘルスモニターデーモン開始中..."
    
    # バックグラウンドでデーモン実行
    (
        while true; do
            run_comprehensive_health_check
            sleep $HEALTH_CHECK_INTERVAL
        done
    ) &
    
    local daemon_pid=$!
    echo "$daemon_pid" > "$daemon_pid_file"
    
    log_success "ヘルスモニターデーモン開始完了 (PID: $daemon_pid)"
}

# ヘルスモニターデーモン停止
stop_health_daemon() {
    local daemon_pid_file="${CHIMERA_WORKSPACE_DIR}/health_monitor/daemon.pid"
    
    if [[ ! -f "$daemon_pid_file" ]]; then
        log_warn "ヘルスモニターデーモンは実行されていません"
        return 0
    fi
    
    local pid=$(cat "$daemon_pid_file")
    
    if kill -0 "$pid" 2>/dev/null; then
        log_info "ヘルスモニターデーモン停止中 (PID: $pid)..."
        kill "$pid"
        sleep 2
        
        # 強制終了が必要な場合
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid"
        fi
    fi
    
    rm -f "$daemon_pid_file"
    log_success "ヘルスモニターデーモン停止完了"
}

# コマンドライン実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "init")
            init_health_monitor
            ;;
        "check")
            run_comprehensive_health_check
            ;;
        "start-daemon")
            start_health_daemon
            ;;
        "stop-daemon")
            stop_health_daemon
            ;;
        "record-activity")
            record_agent_activity "$2" "$3" "$4"
            ;;
        "record-error")
            record_agent_error "$2" "$3" "$4"
            ;;
        "force-sync")
            force_context_resync "$2"
            ;;
        "emergency")
            trigger_emergency_recovery "$2" "$3"
            ;;
        "report")
            generate_health_report "100"
            ;;
        *)
            echo "Usage: $0 {init|check|start-daemon|stop-daemon|record-activity|record-error|force-sync|emergency|report}"
            exit 1
            ;;
    esac
fi