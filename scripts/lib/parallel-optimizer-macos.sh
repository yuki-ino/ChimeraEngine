#!/bin/bash

# 🚀 Parallel Task Execution Optimizer for Chimera Engine (macOS Compatible)
# 依存関係グラフを解析し、並列実行可能なタスクを自動特定・最適化（macOS bash 3.x対応）

PARALLEL_OPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${PARALLEL_OPT_DIR}/common.sh"
source "${PARALLEL_OPT_DIR}/plan-manager.sh"

# 並列最適化システム初期化
init_parallel_optimizer() {
    log_info "並列タスク実行最適化システム初期化中..."
    
    local optimizer_dir="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer"
    safe_mkdir "$optimizer_dir"
    safe_mkdir "${optimizer_dir}/graphs"
    safe_mkdir "${optimizer_dir}/workload"
    safe_mkdir "${optimizer_dir}/resource_locks"
    safe_mkdir "${optimizer_dir}/tasks"
    
    # エージェント負荷初期化
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    for agent in "${agents[@]}"; do
        echo "0" > "${optimizer_dir}/workload/${agent}_load.txt"
        echo "" > "${optimizer_dir}/tasks/${agent}_tasks.txt"
    done
    
    log_success "並列最適化システム初期化完了"
}

# タスク情報を取得
get_task_info() {
    local task_id="$1"
    local field="$2"  # agent, deps, status, content
    
    if [[ ! -f "${PLAN_FILE}" ]]; then
        echo ""
        return 1
    fi
    
    # CHIMERA_PLAN.mdからタスク情報を抽出
    local task_line=$(grep "^| $task_id |" "${PLAN_FILE}" | head -1)
    
    if [[ -z "$task_line" ]]; then
        echo ""
        return 1
    fi
    
    case "$field" in
        "agent")
            echo "$task_line" | cut -d'|' -f3 | xargs
            ;;
        "content") 
            echo "$task_line" | cut -d'|' -f4 | xargs
            ;;
        "priority")
            echo "$task_line" | cut -d'|' -f5 | xargs
            ;;
        "deps")
            echo "$task_line" | cut -d'|' -f6 | xargs
            ;;
        *)
            echo "$task_line"
            ;;
    esac
}

# タスクステータス取得
get_task_status_simple() {
    local task_id="$1"
    
    if [[ ! -f "${PLAN_FILE}" ]]; then
        echo "unknown"
        return
    fi
    
    # 実行中のタスクセクションをチェック
    if grep -A 10 "### 実行中のタスク" "${PLAN_FILE}" | grep -q "^| $task_id |"; then
        echo "active"
    # 待機中のタスクセクションをチェック  
    elif grep -A 10 "### 待機中のタスク" "${PLAN_FILE}" | grep -q "^| $task_id |"; then
        echo "waiting"
    # 完了タスクセクションをチェック
    elif grep -A 10 "### 完了タスク" "${PLAN_FILE}" | grep -q "^| $task_id |"; then
        echo "completed"
    else
        echo "unknown"
    fi
}

# CHIMERA_PLAN.mdから依存関係グラフを構築
build_dependency_graph() {
    log_info "依存関係グラフ構築中..."
    
    if [[ ! -f "${PLAN_FILE}" ]]; then
        log_error "CHIMERA_PLAN.mdが見つかりません"
        return 1
    fi
    
    local graph_dir="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/graphs"
    local task_list_file="${graph_dir}/task_list.txt"
    local deps_file="${graph_dir}/dependencies.txt"
    
    # タスク一覧を抽出
    > "$task_list_file"
    > "$deps_file"
    
    # タスク情報を抽出
    while IFS='|' read -r _ task_id agent content priority deps _; do
        # 空行やヘッダーをスキップ
        [[ "$task_id" =~ ^[[:space:]]*$ ]] && continue
        [[ "$task_id" =~ ^[[:space:]]*タスクID ]] && continue
        [[ "$task_id" =~ ^[[:space:]]*- ]] && continue
        
        # 前後の空白を削除
        task_id=$(echo "$task_id" | xargs)
        agent=$(echo "$agent" | xargs)
        deps=$(echo "$deps" | xargs)
        
        # 有効なタスクIDかチェック
        if [[ "$task_id" =~ ^T[0-9]+ ]]; then
            local status=$(get_task_status_simple "$task_id")
            echo "$task_id:$agent:$status" >> "$task_list_file"
            
            # 依存関係を記録
            if [[ "$deps" != "none" && "$deps" != "-" && -n "$deps" ]]; then
                echo "$task_id:$deps" >> "$deps_file"
            fi
            
            log_debug "タスク登録: $task_id -> $agent (依存: $deps, 状態: $status)"
        fi
    done < <(grep "^|" "${PLAN_FILE}")
    
    local task_count=$(wc -l < "$task_list_file")
    log_success "依存関係グラフ構築完了 ($task_count タスク)"
}

# 並列実行可能なタスクを特定
identify_parallel_tasks() {
    log_info "並列実行可能タスク特定中..."
    
    local graph_dir="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/graphs"
    local task_list_file="${graph_dir}/task_list.txt"
    local deps_file="${graph_dir}/dependencies.txt"
    local ready_tasks_file="${graph_dir}/ready_tasks.txt"
    
    if [[ ! -f "$task_list_file" ]]; then
        log_error "タスク一覧ファイルが見つかりません。build_dependency_graphを先に実行してください。"
        return 1
    fi
    
    > "$ready_tasks_file"
    
    # 実行可能タスクを特定（依存関係が満たされている）
    while IFS=':' read -r task_id agent status; do
        # 待機中のタスクのみ対象
        if [[ "$status" == "waiting" ]]; then
            if is_dependencies_satisfied_simple "$task_id" "$deps_file"; then
                echo "$task_id:$agent" >> "$ready_tasks_file"
                log_debug "実行可能タスク: $task_id ($agent)"
            fi
        fi
    done < "$task_list_file"
    
    # 並列グループ化
    group_parallel_tasks_simple "$ready_tasks_file"
    
    local ready_count=$(wc -l < "$ready_tasks_file" 2>/dev/null || echo "0")
    log_success "並列実行可能タスク: $ready_count 個特定"
}

# 依存関係が満たされているかチェック（シンプル版）
is_dependencies_satisfied_simple() {
    local task_id="$1"
    local deps_file="$2"
    
    # このタスクの依存関係を取得
    local task_deps=$(grep "^$task_id:" "$deps_file" 2>/dev/null | cut -d':' -f2)
    
    # 依存関係がない場合
    if [[ -z "$task_deps" ]]; then
        return 0
    fi
    
    # 依存タスクがすべて完了しているかチェック
    local dep_task
    local old_ifs="$IFS"
    IFS=','
    for dep_task in $task_deps; do
        dep_task=$(echo "$dep_task" | xargs)
        if [[ -n "$dep_task" && "$dep_task" != "none" ]]; then
            local dep_status=$(get_task_status_simple "$dep_task")
            if [[ "$dep_status" != "completed" ]]; then
                IFS="$old_ifs"
                return 1
            fi
        fi
    done
    IFS="$old_ifs"
    
    return 0
}

# 並列タスクをグループ化（シンプル版）
group_parallel_tasks_simple() {
    local ready_tasks_file="$1"
    local groups_dir="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/graphs/groups"
    
    safe_mkdir "$groups_dir"
    
    # 既存グループファイルをクリア
    rm -f "$groups_dir"/group_*.txt
    
    local group_counter=1
    local current_agents=()
    
    # エージェント別にグループ化
    while IFS=':' read -r task_id agent; do
        # 同じエージェントが既に現在のグループにいるかチェック
        local agent_in_group=false
        local i
        for ((i=0; i<${#current_agents[@]}; i++)); do
            if [[ "${current_agents[i]}" == "$agent" ]]; then
                agent_in_group=true
                break
            fi
        done
        
        if [[ "$agent_in_group" == "true" ]]; then
            # 新しいグループを作成
            ((group_counter++))
            current_agents=("$agent")
        else
            # 現在のグループに追加
            current_agents+=("$agent")
        fi
        
        echo "$task_id:$agent" >> "$groups_dir/group_${group_counter}.txt"
        
    done < "$ready_tasks_file"
    
    # グループ情報をログ出力
    local group_file
    for group_file in "$groups_dir"/group_*.txt; do
        if [[ -f "$group_file" ]]; then
            local group_name=$(basename "$group_file" .txt)
            local task_count=$(wc -l < "$group_file")
            log_info "並列グループ $group_name: $task_count タスク"
        fi
    done
}

# エージェント負荷監視
monitor_agent_workload() {
    log_debug "エージェント負荷監視中..."
    
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    local workload_dir="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/workload"
    
    for agent in "${agents[@]}"; do
        local active_tasks=0
        
        # アクティブタスク数をカウント
        if [[ -f "${PLAN_FILE}" ]]; then
            active_tasks=$(grep -A 20 "### 実行中のタスク" "${PLAN_FILE}" | grep "| [^|]* | $agent |" | wc -l)
        fi
        
        echo "$active_tasks" > "${workload_dir}/${agent}_load.txt"
        log_debug "エージェント $agent 負荷: $active_tasks タスク"
    done
}

# 最適な並列実行プランを生成
generate_execution_plan() {
    log_info "最適並列実行プラン生成中..."
    
    local plan_file="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/execution_plan.md"
    local groups_dir="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/graphs/groups"
    
    cat > "$plan_file" << EOF
# 並列実行プラン
生成日時: $(date)

## 📊 現在の状況
EOF

    # エージェント負荷状況
    echo "### エージェント負荷" >> "$plan_file"
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    for agent in "${agents[@]}"; do
        local load_file="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/workload/${agent}_load.txt"
        local load=0
        if [[ -f "$load_file" ]]; then
            load=$(cat "$load_file")
        fi
        echo "- $agent: $load タスク実行中" >> "$plan_file"
    done
    echo "" >> "$plan_file"
    
    # 並列実行プラン
    echo "### 🚀 並列実行プラン" >> "$plan_file"
    local total_parallel_tasks=0
    local group_count=0
    
    for group_file in "$groups_dir"/group_*.txt; do
        if [[ -f "$group_file" ]]; then
            local group_name=$(basename "$group_file" .txt)
            local task_count=$(wc -l < "$group_file")
            total_parallel_tasks=$((total_parallel_tasks + task_count))
            ((group_count++))
            
            echo "#### $group_name (同時実行: $task_count タスク)" >> "$plan_file"
            while IFS=':' read -r task_id agent; do
                echo "- **$task_id**: $agent が担当" >> "$plan_file"
            done < "$group_file"
            echo "" >> "$plan_file"
        fi
    done
    
    # 効率性分析
    echo "### 📈 効率性分析" >> "$plan_file"
    echo "- 並列実行可能タスク: $total_parallel_tasks 個" >> "$plan_file"
    echo "- 並列グループ数: $group_count" >> "$plan_file"
    
    if [[ $total_parallel_tasks -gt 1 ]]; then
        echo "- 推定時間短縮: ~${group_count}x faster" >> "$plan_file"
    fi
    
    log_success "実行プラン生成完了: $plan_file"
}

# 並列実行開始
execute_parallel_plan() {
    log_info "並列実行プラン実行開始..."
    
    local execution_log="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/execution.log"
    local groups_dir="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/graphs/groups"
    
    echo "$(date): 並列実行開始" >> "$execution_log"
    
    # 各並列グループを順次実行
    for group_file in "$groups_dir"/group_*.txt; do
        if [[ -f "$group_file" ]]; then
            local group_name=$(basename "$group_file" .txt)
            
            log_info "並列グループ $group_name 実行開始"
            
            # グループ内タスクを並列で開始
            while IFS=':' read -r task_id agent; do
                # タスクをアクティブに更新
                update_task_status "$task_id" "active" "$agent"
                
                # エージェントに構造化メッセージで通知
                local task_content=$(get_task_info "$task_id" "content")
                if [[ -n "$task_content" ]]; then
                    send_task_assignment "parallel-optimizer" "$agent" "$task_id" "$task_content" "high" "none"
                fi
                
                log_success "タスク $task_id を $agent に並列割り当て"
                echo "$(date): $task_id -> $agent (並列実行)" >> "$execution_log"
                
            done < "$group_file"
            
            local task_count=$(wc -l < "$group_file")
            log_info "並列グループ $group_name: $task_count タスク同時実行中"
        fi
    done
}

# 並列最適化レポート生成
generate_optimization_report() {
    local report_file="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/optimization_report.md"
    local ready_tasks_file="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/graphs/ready_tasks.txt"
    local groups_dir="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/graphs/groups"
    
    local ready_count=0
    local group_count=0
    
    if [[ -f "$ready_tasks_file" ]]; then
        ready_count=$(wc -l < "$ready_tasks_file")
    fi
    
    group_count=$(ls "$groups_dir"/group_*.txt 2>/dev/null | wc -l)
    
    cat > "$report_file" << EOF
# 🚀 並列タスク実行最適化レポート

生成日時: $(date)

## 📊 システム概要

### 検出されたタスク
- 実行可能タスク: $ready_count
- 並列グループ数: $group_count

### エージェント状況
$(for agent in pm coder qa-functional qa-lead monitor; do
    local load_file="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/workload/${agent}_load.txt"
    local load=0
    if [[ -f "$load_file" ]]; then
        load=$(cat "$load_file")
    fi
    echo "- **$agent**: $load タスク実行中"
done)

## 🎯 並列実行計画

### 最適化の利点
1. **速度向上**: 最大 ${group_count}x の並列実行
2. **リソース効率**: エージェント負荷分散
3. **依存関係管理**: 自動的な実行順序最適化

### 並列グループ詳細
$(for group_file in "$groups_dir"/group_*.txt; do
    if [[ -f "$group_file" ]]; then
        local group_name=$(basename "$group_file" .txt)
        echo "#### $group_name"
        while IFS=':' read -r task_id agent; do
            echo "- $task_id ($agent)"
        done < "$group_file"
        echo ""
    fi
done)

## 📈 期待される効果

参考記事の「4x faster progress」を上回る、最大 ${group_count}x の高速化が期待されます。

---
Generated by Chimera Engine Parallel Optimizer v${CHIMERA_VERSION}
EOF

    log_success "最適化レポート生成: $report_file"
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
    
    local ready_tasks_file="${CHIMERA_WORKSPACE_DIR}/parallel_optimizer/graphs/ready_tasks.txt"
    local ready_count=0
    
    if [[ -f "$ready_tasks_file" ]]; then
        ready_count=$(wc -l < "$ready_tasks_file")
    fi
    
    if [[ $ready_count -gt 0 ]]; then
        log_info "並列実行可能なタスクが $ready_count 個見つかりました"
        echo "並列実行を開始しますか？ (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
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