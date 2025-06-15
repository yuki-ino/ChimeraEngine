#!/bin/bash

# 🗨️ Structured Messaging System for Chimera Engine
# 構造化されたエージェント間メッセージングシステム

STRUCTURED_MSG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${STRUCTURED_MSG_DIR}/common.sh"
source "${STRUCTURED_MSG_DIR}/plan-manager.sh"

# メッセージタイプ
declare -A MESSAGE_TYPES=(
    ["TASK_ASSIGN"]="タスク割り当て"
    ["TASK_UPDATE"]="タスク更新"
    ["TASK_COMPLETE"]="タスク完了"
    ["REQUEST_INFO"]="情報要求"
    ["PROVIDE_INFO"]="情報提供"
    ["ERROR_REPORT"]="エラー報告"
    ["STATUS_UPDATE"]="ステータス更新"
    ["DEPENDENCY_READY"]="依存関係解決"
    ["BLOCK_REPORT"]="ブロッカー報告"
    ["SYNC_REQUEST"]="同期要求"
)

# 構造化メッセージ送信
send_structured_message() {
    local from_agent="$1"
    local to_agent="$2"
    local message_type="$3"
    local subject="$4"
    local content="$5"
    local task_id="${6:-}"
    local priority="${7:-medium}"
    local metadata="${8:-}"
    
    # メッセージID生成
    local msg_id="MSG$(date +%s)_$(printf "%04d" $RANDOM)"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 構造化メッセージフォーマット
    local structured_msg=$(cat << EOF
📨 構造化メッセージ
==================
🆔 ID: ${msg_id}
🕐 時刻: ${timestamp}
📤 送信者: ${from_agent}
📥 受信者: ${to_agent}
🏷️ タイプ: ${message_type} (${MESSAGE_TYPES[$message_type]:-"その他"})
📋 件名: ${subject}
$([ -n "$task_id" ] && echo "🎯 タスクID: ${task_id}")
🔥 優先度: ${priority}

📄 内容:
${content}

$([ -n "$metadata" ] && echo "📊 メタデータ: ${metadata}")
==================
EOF
)
    
    # メッセージ送信
    send_agent_message "$to_agent" "$structured_msg"
    
    # CHIMERA_PLAN.mdに通信ログ追加
    local log_entry="${from_agent} → ${to_agent}: [${message_type}] ${subject}"
    if [[ -n "$task_id" ]]; then
        log_entry="${log_entry} (${task_id})"
    fi
    add_communication_log "$from_agent" "$to_agent" "$log_entry"
    
    # メッセージ履歴保存
    save_message_history "$msg_id" "$from_agent" "$to_agent" "$message_type" "$subject" "$content" "$task_id" "$priority" "$metadata"
    
    log_success "構造化メッセージ送信完了: $msg_id"
    return 0
}

# メッセージ履歴保存
save_message_history() {
    local msg_id="$1"
    local from_agent="$2"
    local to_agent="$3"
    local message_type="$4"
    local subject="$5"
    local content="$6"
    local task_id="$7"
    local priority="$8"
    local metadata="$9"
    
    local history_dir="${CHIMERA_WORKSPACE_DIR}/message_history"
    safe_mkdir "$history_dir"
    
    local history_file="${history_dir}/${msg_id}.json"
    
    cat > "$history_file" << EOF
{
    "id": "${msg_id}",
    "timestamp": "$(date -Iseconds)",
    "from_agent": "${from_agent}",
    "to_agent": "${to_agent}",
    "message_type": "${message_type}",
    "subject": "${subject}",
    "content": $(echo "$content" | jq -R -s .),
    "task_id": "${task_id}",
    "priority": "${priority}",
    "metadata": "${metadata}",
    "status": "sent"
}
EOF
}

# タスク割り当てメッセージ
send_task_assignment() {
    local from_agent="$1"
    local to_agent="$2"
    local task_id="$3"
    local task_description="$4"
    local priority="${5:-medium}"
    local dependencies="${6:-none}"
    local deadline="${7:-}"
    
    local content=$(cat << EOF
新しいタスクが割り当てられました。

📋 タスク詳細:
- ID: ${task_id}
- 説明: ${task_description}
- 優先度: ${priority}
- 依存関係: ${dependencies}
$([ -n "$deadline" ] && echo "- 期限: ${deadline}")

🔧 実行手順:
1. CHIMERA_PLAN.mdで詳細を確認
2. 作業開始時: chimera send update-task ${task_id} active ${to_agent}
3. 完了時: chimera send update-task ${task_id} completed

📁 関連ファイル: CHIMERA_PLAN.md を参照してください
EOF
)
    
    local metadata="dependencies=${dependencies};deadline=${deadline}"
    
    send_structured_message "$from_agent" "$to_agent" "TASK_ASSIGN" "新規タスク: $task_description" "$content" "$task_id" "$priority" "$metadata"
}

# タスク完了報告
send_task_completion() {
    local from_agent="$1"
    local to_agent="$2"
    local task_id="$3"
    local completion_summary="$4"
    local artifacts="${5:-}"
    local next_steps="${6:-}"
    
    local content=$(cat << EOF
タスクが完了しました。

✅ 完了概要:
${completion_summary}

$([ -n "$artifacts" ] && echo "📁 成果物:
${artifacts}")

$([ -n "$next_steps" ] && echo "🔄 次のステップ:
${next_steps}")

📊 CHIMERA_PLAN.mdで進捗を確認してください。
EOF
)
    
    local metadata="artifacts=${artifacts}"
    
    send_structured_message "$from_agent" "$to_agent" "TASK_COMPLETE" "タスク完了: $task_id" "$content" "$task_id" "high" "$metadata"
    
    # タスクを完了に更新
    update_task_status "$task_id" "completed" "$from_agent"
}

# エラー報告
send_error_report() {
    local from_agent="$1"
    local to_agent="$2"
    local error_description="$3"
    local task_id="${4:-}"
    local error_code="${5:-}"
    local suggested_action="${6:-}"
    
    local content=$(cat << EOF
エラーが発生しました。

🚨 エラー詳細:
${error_description}

$([ -n "$error_code" ] && echo "🔢 エラーコード: ${error_code}")

$([ -n "$suggested_action" ] && echo "💡 推奨対応:
${suggested_action}")

⚠️ 至急対応が必要です。CHIMERA_PLAN.mdのブロッカーセクションを確認してください。
EOF
)
    
    local metadata="error_code=${error_code}"
    
    send_structured_message "$from_agent" "$to_agent" "ERROR_REPORT" "エラー発生" "$content" "$task_id" "high" "$metadata"
}

# 依存関係解決通知
send_dependency_ready() {
    local from_agent="$1"
    local to_agent="$2"
    local completed_task_id="$3"
    local dependent_task_id="$4"
    local handoff_info="$5"
    
    local content=$(cat << EOF
依存関係が解決されました。作業を開始できます。

✅ 完了タスク: ${completed_task_id}
🎯 開始可能タスク: ${dependent_task_id}

📋 引き継ぎ情報:
${handoff_info}

🚀 CHIMERA_PLAN.mdで詳細を確認し、作業を開始してください。
EOF
)
    
    local metadata="completed_task=${completed_task_id};dependent_task=${dependent_task_id}"
    
    send_structured_message "$from_agent" "$to_agent" "DEPENDENCY_READY" "依存関係解決: $dependent_task_id 開始可能" "$content" "$dependent_task_id" "high" "$metadata"
}

# ステータス更新通知
send_status_update() {
    local from_agent="$1"
    local to_agent="$2"
    local task_id="$3"
    local progress_percentage="$4"
    local current_work="$5"
    local estimated_completion="${6:-}"
    local blockers="${7:-}"
    
    local content=$(cat << EOF
タスクのステータスを更新します。

📊 進捗状況:
- 進捗: ${progress_percentage}%
- 現在の作業: ${current_work}
$([ -n "$estimated_completion" ] && echo "- 完了予定: ${estimated_completion}")

$([ -n "$blockers" ] && echo "🚫 ブロッカー:
${blockers}")

📈 詳細はCHIMERA_PLAN.mdで確認できます。
EOF
)
    
    local metadata="progress=${progress_percentage};estimated_completion=${estimated_completion}"
    
    send_structured_message "$from_agent" "$to_agent" "STATUS_UPDATE" "進捗更新: $task_id ($progress_percentage%)" "$content" "$task_id" "medium" "$metadata"
}

# 情報要求
send_info_request() {
    local from_agent="$1"
    local to_agent="$2"
    local requested_info="$3"
    local context="$4"
    local urgency="${5:-medium}"
    local task_id="${6:-}"
    
    local content=$(cat << EOF
情報提供をお願いします。

📥 要求情報:
${requested_info}

📄 背景・コンテキスト:
${context}

⏰ 緊急度: ${urgency}

💡 回答は構造化メッセージ（PROVIDE_INFO）でお願いします。
EOF
)
    
    local metadata="urgency=${urgency}"
    
    send_structured_message "$from_agent" "$to_agent" "REQUEST_INFO" "情報要求: $requested_info" "$content" "$task_id" "$urgency" "$metadata"
}

# 情報提供
send_info_response() {
    local from_agent="$1"
    local to_agent="$2"
    local provided_info="$3"
    local additional_notes="${4:-}"
    local task_id="${5:-}"
    
    local content=$(cat << EOF
要求された情報を提供します。

📤 提供情報:
${provided_info}

$([ -n "$additional_notes" ] && echo "📝 補足事項:
${additional_notes}")

✅ 情報提供完了です。
EOF
)
    
    send_structured_message "$from_agent" "$to_agent" "PROVIDE_INFO" "情報提供完了" "$content" "$task_id" "medium" ""
}

# メッセージ履歴検索
search_message_history() {
    local search_term="$1"
    local agent_filter="${2:-}"
    local type_filter="${3:-}"
    local limit="${4:-10}"
    
    local history_dir="${CHIMERA_WORKSPACE_DIR}/message_history"
    
    if [[ ! -d "$history_dir" ]]; then
        log_warn "メッセージ履歴が見つかりません"
        return 1
    fi
    
    log_info "メッセージ履歴検索: '$search_term'"
    
    # JSON形式でファイルを検索
    local count=0
    for file in "$history_dir"/*.json; do
        [[ ! -f "$file" ]] && continue
        
        if grep -q "$search_term" "$file"; then
            # エージェントフィルター
            if [[ -n "$agent_filter" ]]; then
                if ! grep -q "\"from_agent\": \"$agent_filter\"\\|\"to_agent\": \"$agent_filter\"" "$file"; then
                    continue
                fi
            fi
            
            # タイプフィルター
            if [[ -n "$type_filter" ]]; then
                if ! grep -q "\"message_type\": \"$type_filter\"" "$file"; then
                    continue
                fi
            fi
            
            echo "=== $(basename "$file" .json) ==="
            jq -r '.timestamp + " | " + .from_agent + " → " + .to_agent + " | " + .message_type + " | " + .subject' "$file"
            echo ""
            
            ((count++))
            if [[ $count -ge $limit ]]; then
                break
            fi
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        log_warn "該当するメッセージが見つかりませんでした"
    else
        log_success "$count 件のメッセージが見つかりました"
    fi
}

# 使用統計表示
show_messaging_stats() {
    local history_dir="${CHIMERA_WORKSPACE_DIR}/message_history"
    
    if [[ ! -d "$history_dir" ]]; then
        log_warn "メッセージ履歴が見つかりません"
        return 1
    fi
    
    echo "📊 構造化メッセージング統計"
    echo "============================="
    
    local total_messages=$(find "$history_dir" -name "*.json" | wc -l)
    echo "総メッセージ数: $total_messages"
    echo ""
    
    # メッセージタイプ別統計
    echo "📋 メッセージタイプ別:"
    for type in "${!MESSAGE_TYPES[@]}"; do
        local count=$(grep -l "\"message_type\": \"$type\"" "$history_dir"/*.json 2>/dev/null | wc -l)
        if [[ $count -gt 0 ]]; then
            echo "  $type: $count 件"
        fi
    done
    echo ""
    
    # エージェント別統計
    echo "👥 エージェント別送信数:"
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    for agent in "${agents[@]}"; do
        local sent_count=$(grep -l "\"from_agent\": \"$agent\"" "$history_dir"/*.json 2>/dev/null | wc -l)
        local received_count=$(grep -l "\"to_agent\": \"$agent\"" "$history_dir"/*.json 2>/dev/null | wc -l)
        echo "  $agent: 送信 $sent_count 件, 受信 $received_count 件"
    done
}

# コマンドライン実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "send-task")
            send_task_assignment "$2" "$3" "$4" "$5" "${6:-medium}" "${7:-none}" "${8:-}"
            ;;
        "send-completion")
            send_task_completion "$2" "$3" "$4" "$5" "${6:-}" "${7:-}"
            ;;
        "send-error")
            send_error_report "$2" "$3" "$4" "${5:-}" "${6:-}" "${7:-}"
            ;;
        "send-dependency")
            send_dependency_ready "$2" "$3" "$4" "$5" "$6"
            ;;
        "send-status")
            send_status_update "$2" "$3" "$4" "$5" "$6" "${7:-}" "${8:-}"
            ;;
        "send-request")
            send_info_request "$2" "$3" "$4" "$5" "${6:-medium}" "${7:-}"
            ;;
        "send-response")
            send_info_response "$2" "$3" "$4" "${5:-}" "${6:-}"
            ;;
        "search")
            search_message_history "$2" "${3:-}" "${4:-}" "${5:-10}"
            ;;
        "stats")
            show_messaging_stats
            ;;
        *)
            echo "Usage: $0 {send-task|send-completion|send-error|send-dependency|send-status|send-request|send-response|search|stats}"
            exit 1
            ;;
    esac
fi