#!/bin/bash

# 🚀 Parallel Task Execution Optimizer for Chimera Engine
# 依存関係グラフを解析し、並列実行可能なタスクを自動特定・最適化

PARALLEL_OPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${PARALLEL_OPT_DIR}/common.sh"
source "${PARALLEL_OPT_DIR}/plan-manager.sh"

# グローバル変数（macOS bash 3.x compatibility - disabled associative arrays）
# declare -A TASK_DEPENDENCIES    # Disabled for macOS compatibility
# declare -A TASK_STATUS          # Disabled for macOS compatibility
# declare -A TASK_AGENTS          # Disabled for macOS compatibility
# declare -A AGENT_WORKLOAD       # Disabled for macOS compatibility
# declare -A RESOURCE_LOCKS       # Disabled for macOS compatibility
# declare -A PARALLEL_GROUPS      # Disabled for macOS compatibility

# Note: Parallel optimization requires bash 4.x+ for associative arrays
# This feature is disabled on macOS bash 3.x systems

# 並列最適化システム初期化
init_parallel_optimizer() {
    log_info "並列タスク実行最適化システム初期化中..."
    
    # Check bash version compatibility
    if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
        log_warn "並列最適化機能は bash 4.x+ が必要です (現在: bash ${BASH_VERSION})"
        log_warn "macOS bash 3.x では並列最適化は無効化されます"
        return 0
    fi
    
    local optimizer_dir="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer"
    safe_mkdir "$optimizer_dir"
    safe_mkdir "${optimizer_dir}/graphs"
    safe_mkdir "${optimizer_dir}/workload"
    safe_mkdir "${optimizer_dir}/resource_locks"
    
    # エージェント負荷初期化
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    for agent in "${agents[@]}"; do
        AGENT_WORKLOAD["$agent"]=0
        echo "0" > "${optimizer_dir}/workload/${agent}_load.txt"
    done
    
    log_success "並列最適化システム初期化完了"
}

# CHIMERA_PLAN.mdから依存関係グラフを構築
build_dependency_graph() {
    log_info "依存関係グラフ構築中..."
    
    if [[ ! -f "${PLAN_FILE}" ]]; then
        log_error "CHIMERA_PLAN.mdが見つかりません"
        return 1
    fi
    
    # タスク情報を抽出
    while IFS='|' read -r _ task_id agent content priority deps _; do
        # 空行やヘッダーをスキップ
        [[ "$task_id" =~ ^[[:space:]]*$ ]] && continue
        [[ "$task_id" =~ ^[[:space:]]*タスクID ]] && continue
        [[ "$task_id" =~ ^[[:space:]]*- ]] && continue
        
        # 前後の空白を削除
        task_id=$(echo "$task_id" | xargs)
        agent=$(echo "$agent" | xargs)
        content=$(echo "$content" | xargs)
        priority=$(echo "$priority" | xargs)
        deps=$(echo "$deps" | xargs)
        
        # 有効なタスクIDかチェック
        if [[ "$task_id" =~ ^T[0-9]+ ]]; then
            TASK_AGENTS["$task_id"]="$agent"
            TASK_DEPENDENCIES["$task_id"]="$deps"
            
            # ステータス確認
            local status=$(get_task_status "$task_id")
            TASK_STATUS["$task_id"]="$status"
            
            log_debug "タスク登録: $task_id -> $agent (依存: $deps, 状態: $status)"
        fi
    done < <(grep "^|" "${PLAN_FILE}")
    
    # 依存関係グラフをGraphviz形式で保存
    generate_dependency_graph_viz
    
    log_success "依存関係グラフ構築完了 (${#TASK_DEPENDENCIES[@]} タスク)"
}

# Graphviz形式での依存関係グラフ生成
generate_dependency_graph_viz() {
    local graph_file="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/graphs/dependency_graph.dot"
    
    cat > "$graph_file" << 'EOF'
digraph TaskDependencies {
    rankdir=TB;
    node [shape=box, style=filled];
    
    // ステータス別の色設定
    node [fillcolor=lightgray] // waiting
    edge [color=blue];
EOF

    # ノード定義
    for task_id in "${!TASK_STATUS[@]}"; do
        local status="${TASK_STATUS[$task_id]}"
        local agent="${TASK_AGENTS[$task_id]}"
        local color
        
        case "$status" in
            "active") color="lightgreen" ;;
            "completed") color="lightblue" ;;
            "waiting") color="lightyellow" ;;
            *) color="lightgray" ;;
        esac
        
        echo "    \"$task_id\" [fillcolor=$color, label=\"$task_id\\n($agent)\\n$status\"];" >> "$graph_file"
    done
    
    # エッジ定義（依存関係）
    for task_id in "${!TASK_DEPENDENCIES[@]}"; do
        local deps="${TASK_DEPENDENCIES[$task_id]}"
        if [[ "$deps" != "none" && "$deps" != "-" && -n "$deps" ]]; then
            IFS=',' read -ra dep_array <<< "$deps"
            for dep in "${dep_array[@]}"; do
                dep=$(echo "$dep" | xargs)
                if [[ -n "$dep" && "$dep" != "none" ]]; then
                    echo "    \"$dep\" -> \"$task_id\";" >> "$graph_file"
                fi
            done
        fi
    done
    
    echo "}" >> "$graph_file"
    
    # PNG生成（dotが利用可能な場合）
    if command -v dot >/dev/null 2>&1; then
        dot -Tpng "$graph_file" -o "${graph_file%.dot}.png" 2>/dev/null || true
    fi
}

# 並列実行可能なタスクを特定
identify_parallel_tasks() {
    log_info "並列実行可能タスク特定中..."
    
    local -a ready_tasks=()
    local -a parallel_candidates=()
    
    # 実行可能タスクを特定（依存関係が満たされている）
    for task_id in "${!TASK_STATUS[@]}"; do
        local status="${TASK_STATUS[$task_id]}"
        
        # 待機中のタスクのみ対象
        if [[ "$status" == "waiting" ]]; then
            if is_dependencies_satisfied "$task_id"; then
                ready_tasks+=("$task_id")
                log_debug "実行可能タスク: $task_id"
            fi
        fi
    done
    
    # リソース競合チェックと並列グループ化
    group_parallel_tasks "${ready_tasks[@]}"
    
    log_success "並列実行可能タスク: ${#ready_tasks[@]} 個特定"
    return 0
}

# 依存関係が満たされているかチェック
is_dependencies_satisfied() {
    local task_id="$1"
    local deps="${TASK_DEPENDENCIES[$task_id]}"
    
    # 依存関係がない場合
    if [[ "$deps" == "none" || "$deps" == "-" || -z "$deps" ]]; then
        return 0
    fi
    
    # 依存タスクがすべて完了しているかチェック
    IFS=',' read -ra dep_array <<< "$deps"
    for dep in "${dep_array[@]}"; do
        dep=$(echo "$dep" | xargs)
        if [[ -n "$dep" && "$dep" != "none" ]]; then
            local dep_status="${TASK_STATUS[$dep]:-unknown}"
            if [[ "$dep_status" != "completed" ]]; then
                return 1
            fi
        fi
    done
    
    return 0
}

# 並列タスクをグループ化（リソース競合回避）
group_parallel_tasks() {
    local ready_tasks=("$@")
    local group_counter=1
    
    # 並列グループを初期化
    unset PARALLEL_GROUPS
    declare -A PARALLEL_GROUPS
    
    for task_id in "${ready_tasks[@]}"; do
        local assigned_group=""
        
        # 既存グループとの競合チェック
        for group_id in "${!PARALLEL_GROUPS[@]}"; do
            if ! has_resource_conflict "$task_id" "$group_id"; then
                # 競合なし - このグループに追加
                PARALLEL_GROUPS["$group_id"]="${PARALLEL_GROUPS[$group_id]} $task_id"
                assigned_group="$group_id"
                break
            fi
        done
        
        # 新しいグループを作成
        if [[ -z "$assigned_group" ]]; then
            PARALLEL_GROUPS["group_$group_counter"]="$task_id"
            ((group_counter++))
        fi
    done
    
    # 並列グループの結果を表示
    for group_id in "${!PARALLEL_GROUPS[@]}"; do
        log_info "並列グループ $group_id: ${PARALLEL_GROUPS[$group_id]}"
    done
}

# リソース競合チェック
has_resource_conflict() {
    local new_task="$1"
    local group_id="$2"
    local group_tasks="${PARALLEL_GROUPS[$group_id]}"
    
    # 同じエージェントが担当するタスクは並列実行不可
    local new_agent="${TASK_AGENTS[$new_task]}"
    
    for existing_task in $group_tasks; do
        local existing_agent="${TASK_AGENTS[$existing_task]}"
        
        if [[ "$new_agent" == "$existing_agent" ]]; then
            return 0  # 競合あり
        fi
        
        # 他のリソース競合チェック（ファイル編集など）
        # 将来的に拡張可能
    done
    
    return 1  # 競合なし
}

# エージェント負荷監視
monitor_agent_workload() {
    log_debug "エージェント負荷監視中..."
    
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    
    for agent in "${agents[@]}"; do
        local active_tasks=0
        
        # アクティブタスク数をカウント
        for task_id in "${!TASK_STATUS[@]}"; do
            if [[ "${TASK_STATUS[$task_id]}" == "active" && "${TASK_AGENTS[$task_id]}" == "$agent" ]]; then
                ((active_tasks++))
            fi
        done
        
        AGENT_WORKLOAD["$agent"]=$active_tasks
        echo "$active_tasks" > "${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/workload/${agent}_load.txt"
        
        log_debug "エージェント $agent 負荷: $active_tasks タスク"
    done
}

# 最適な並列実行プランを生成
generate_execution_plan() {
    log_info "最適並列実行プラン生成中..."
    
    local plan_file="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/execution_plan.md"
    
    cat > "$plan_file" << EOF
# 並列実行プラン
生成日時: $(date)

## 📊 現在の状況
EOF

    # エージェント負荷状況
    echo "### エージェント負荷" >> "$plan_file"
    for agent in "${!AGENT_WORKLOAD[@]}"; do
        echo "- $agent: ${AGENT_WORKLOAD[$agent]} タスク実行中" >> "$plan_file"
    done
    echo "" >> "$plan_file"
    
    # 並列実行プラン
    echo "### 🚀 並列実行プラン" >> "$plan_file"
    local total_parallel_tasks=0
    
    for group_id in "${!PARALLEL_GROUPS[@]}"; do
        local group_tasks="${PARALLEL_GROUPS[$group_id]}"
        local task_count=$(echo "$group_tasks" | wc -w)
        total_parallel_tasks=$((total_parallel_tasks + task_count))
        
        echo "#### $group_id (同時実行: $task_count タスク)" >> "$plan_file"
        for task_id in $group_tasks; do
            local agent="${TASK_AGENTS[$task_id]}"
            echo "- **$task_id**: $agent が担当" >> "$plan_file"
        done
        echo "" >> "$plan_file"
    done
    
    # 効率性分析
    echo "### 📈 効率性分析" >> "$plan_file"
    echo "- 並列実行可能タスク: $total_parallel_tasks 個" >> "$plan_file"
    
    if [[ $total_parallel_tasks -gt 1 ]]; then
        local efficiency=$((total_parallel_tasks * 100 / ${#TASK_STATUS[@]}))
        echo "- 並列化効率: $efficiency%" >> "$plan_file"
        echo "- 推定時間短縮: ~${total_parallel_tasks}x faster" >> "$plan_file"
    fi
    
    log_success "実行プラン生成完了: $plan_file"
}

# 並列実行開始
execute_parallel_plan() {
    log_info "並列実行プラン実行開始..."
    
    local execution_log="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/execution.log"
    echo "$(date): 並列実行開始" >> "$execution_log"
    
    # 各並列グループを順次実行
    for group_id in "${!PARALLEL_GROUPS[@]}"; do
        local group_tasks="${PARALLEL_GROUPS[$group_id]}"
        
        log_info "並列グループ $group_id 実行開始: $group_tasks"
        
        # グループ内タスクを並列で開始
        for task_id in $group_tasks; do
            local agent="${TASK_AGENTS[$task_id]}"
            
            # タスクをアクティブに更新
            update_task_status "$task_id" "active" "$agent"
            
            # エージェントに構造化メッセージで通知
            local task_content=$(get_task_content_from_plan "$task_id")
            send_task_assignment "parallel-optimizer" "$agent" "$task_id" "$task_content" "high" "none"
            
            log_success "タスク $task_id を $agent に並列割り当て"
            echo "$(date): $task_id -> $agent (並列実行)" >> "$execution_log"
        done
        
        log_info "並列グループ $group_id: ${#group_tasks[@]} タスク同時実行中"
    done
    
    # 実行統計を更新
    update_parallel_execution_stats
}

# タスク内容をプランから取得
get_task_content_from_plan() {
    local task_id="$1"
    
    # CHIMERA_PLAN.mdからタスク内容を抽出
    grep "^| $task_id |" "${PLAN_FILE}" | cut -d'|' -f4 | xargs
}

# 並列実行統計更新
update_parallel_execution_stats() {
    local stats_file="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/stats.json"
    local timestamp=$(date -Iseconds)
    local total_groups=${#PARALLEL_GROUPS[@]}
    local total_tasks=0
    
    for group_id in "${!PARALLEL_GROUPS[@]}"; do
        local group_tasks="${PARALLEL_GROUPS[$group_id]}"
        total_tasks=$((total_tasks + $(echo "$group_tasks" | wc -w)))
    done
    
    cat > "$stats_file" << EOF
{
    "timestamp": "$timestamp",
    "parallel_groups": $total_groups,
    "parallel_tasks": $total_tasks,
    "agent_workload": {
$(for agent in "${!AGENT_WORKLOAD[@]}"; do
    echo "        \"$agent\": ${AGENT_WORKLOAD[$agent]},"
done | sed '$ s/,$//')
    },
    "efficiency_metrics": {
        "parallelization_ratio": $(( total_tasks > 0 ? total_tasks * 100 / ${#TASK_STATUS[@]} : 0 )),
        "estimated_speedup": "${total_tasks}x"
    }
}
EOF
}

# 並列最適化レポート生成
generate_optimization_report() {
    local report_file="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/optimization_report.md"
    
    cat > "$report_file" << EOF
# 🚀 並列タスク実行最適化レポート

生成日時: $(date)

## 📊 システム概要

### 検出されたタスク
- 総タスク数: ${#TASK_STATUS[@]}
- 実行可能タスク: $(count_ready_tasks)
- 並列グループ数: ${#PARALLEL_GROUPS[@]}

### エージェント状況
$(for agent in pm coder qa-functional qa-lead monitor; do
    echo "- **$agent**: ${AGENT_WORKLOAD[$agent]:-0} タスク実行中"
done)

## 🎯 並列実行計画

### 最適化の利点
1. **速度向上**: 最大 ${#PARALLEL_GROUPS[@]}x の並列実行
2. **リソース効率**: エージェント負荷分散
3. **依存関係管理**: 自動的な実行順序最適化

### 並列グループ詳細
$(for group_id in "${!PARALLEL_GROUPS[@]}"; do
    echo "#### $group_id"
    echo "タスク: ${PARALLEL_GROUPS[$group_id]}"
    echo ""
done)

## 📈 期待される効果

参考記事の「4x faster progress」を上回る、最大 ${#PARALLEL_GROUPS[@]}x の高速化が期待されます。

---
Generated by Chimera Engine Parallel Optimizer v${CHIMERA_VERSION}
EOF

    log_success "最適化レポート生成: $report_file"
}

# 実行可能タスク数をカウント
count_ready_tasks() {
    local count=0
    for task_id in "${!TASK_STATUS[@]}"; do
        if [[ "${TASK_STATUS[$task_id]}" == "waiting" ]] && is_dependencies_satisfied "$task_id"; then
            ((count++))
        fi
    done
    echo "$count"
}

# メイン並列最適化実行
run_parallel_optimization() {
    log_info "🚀 並列タスク実行最適化を開始します..."
    
    init_parallel_optimizer
    build_dependency_graph
    monitor_agent_workload
    identify_parallel_tasks
    generate_execution_plan
    generate_optimization_report
    
    local ready_count=$(count_ready_tasks)
    if [[ $ready_count -gt 0 ]]; then
        log_info "並列実行可能なタスクが $ready_count 個見つかりました"
        read -p "並列実行を開始しますか？ (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            execute_parallel_plan
        else
            log_info "並列実行はスキップされました"
        fi
    else
        log_warn "現在並列実行可能なタスクはありません"
    fi
    
    log_success "並列最適化処理完了"
}

# コマンドライン実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "init")
            init_parallel_optimizer
            ;;
        "analyze")
            build_dependency_graph
            identify_parallel_tasks
            generate_execution_plan
            ;;
        "execute")
            run_parallel_optimization
            ;;
        "report")
            generate_optimization_report
            ;;
        "workload")
            monitor_agent_workload
            ;;
        *)
            echo "Usage: $0 {init|analyze|execute|report|workload}"
            exit 1
            ;;
    esac
fi