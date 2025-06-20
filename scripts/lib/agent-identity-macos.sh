#!/bin/bash

# 🎭 Agent Identity & Role Recognition System for Chimera Engine (macOS Compatible)
# エージェント身元確認・役割認識システム（macOS bash 3.x対応版）

AGENT_IDENTITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${AGENT_IDENTITY_DIR}/common.sh"
source "${AGENT_IDENTITY_DIR}/plan-manager.sh"
source "${AGENT_IDENTITY_DIR}/messaging.sh"

# エージェント身元情報取得（macOS compatible）
get_agent_identity() {
    local agent="$1"
    case "$agent" in
        "pm") echo "Agent 1 - Product Manager" ;;
        "coder") echo "Agent 2 - Full-Stack Developer" ;;
        "qa-functional") echo "Agent 3 - Functional QA Specialist" ;;
        "qa-lead") echo "Agent 4 - QA Lead & Release Manager" ;;
        "monitor") echo "Agent 5 - System Monitor & Reporter" ;;
        *) echo "Unknown Agent" ;;
    esac
}

# エージェント身元初期化
init_agent_identity() {
    log_info "🎭 エージェント身元認識システム初期化中..."
    
    local identity_dir="${CHIMERA_WORKSPACE_DIR}/agent_identity"
    safe_mkdir "$identity_dir"
    safe_mkdir "${identity_dir}/roles"
    safe_mkdir "${identity_dir}/context"
    safe_mkdir "${identity_dir}/session_state"
    
    # 各エージェントの身元ファイル作成
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    for agent in "${agents[@]}"; do
        create_agent_identity_file "$agent"
    done
    
    log_success "エージェント身元認識システム初期化完了"
}

# エージェント身元ファイル作成
create_agent_identity_file() {
    local agent="$1"
    local identity=$(get_agent_identity "$agent")
    local identity_file="${CHIMERA_WORKSPACE_DIR}/agent_identity/roles/${agent}_identity.md"
    
    # エージェント詳細情報
    local role_description=""
    local responsibilities=""
    local context_requirements=""
    
    case "$agent" in
        "pm")
            role_description="プロダクトマネージャー - プロジェクト全体の統括管理"
            responsibilities="要件定義、タスク管理、進捗監視、品質判定"
            context_requirements="CHIMERA_PLAN.md、全エージェント状況、プロジェクト目標"
            ;;
        "coder")
            role_description="フルスタック開発者 - 機能実装とコード作成"
            responsibilities="実装、コーディング、技術的決定、成果物作成"
            context_requirements="CHIMERA_PLAN.md、技術仕様、実装タスク"
            ;;
        "qa-functional")
            role_description="機能テスト専門家 - 個別機能の詳細テスト"
            responsibilities="機能テスト、バグ検出、テストケース作成"
            context_requirements="CHIMERA_PLAN.md、実装状況、テスト対象"
            ;;
        "qa-lead")
            role_description="QAリード - 品質管理とリリース判定"
            responsibilities="品質基準管理、最終承認、リリース判定"
            context_requirements="CHIMERA_PLAN.md、全テスト結果、品質メトリクス"
            ;;
        "monitor")
            role_description="システムモニター - 状況監視と報告"
            responsibilities="進捗監視、状況報告、システム健康度チェック"
            context_requirements="CHIMERA_PLAN.md、全エージェント活動、システム状態"
            ;;
    esac
    
    cat > "$identity_file" << EOF
# 🎭 ${identity} - 身元確認書

## あなたの身元
**役割**: ${identity}
**説明**: ${role_description}

## 責任範囲
${responsibilities}

## 必要なコンテキスト
${context_requirements}

## 初期化メッセージ
あなたは **${identity}** です。

以下の手順で役割を確認してください：

1. **身元確認**: 「私は${identity}です」と宣言
2. **CHIMERA_PLAN.md読み込み**: 最新の計画状況を確認
3. **現在の状況把握**: 自分に関連するタスクを特定
4. **準備完了報告**: 作業準備完了を報告

## 現在時刻
$(date '+%Y-%m-%d %H:%M:%S')

## セッション情報
- セッション開始: $(date)
- ワークスペース: ${CHIMERA_WORKSPACE_DIR:-"未設定"}
- プロジェクトルート: ${CHIMERA_PROJECT_ROOT:-$(pwd)}

---
Generated by Chimera Engine Agent Identity System v${CHIMERA_VERSION}
EOF

    log_debug "エージェント身元ファイル作成: $agent -> $identity_file"
}

# エージェント役割認識メッセージ生成
generate_role_recognition_message() {
    local agent="$1"
    local session_context="${2:-normal}"  # normal, startup, recovery
    
    local identity=$(get_agent_identity "$agent")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # CHIMERA_PLAN.mdの存在確認
    local plan_status="存在しません"
    local plan_instruction=""
    
    if [[ -f "${PLAN_FILE}" ]]; then
        plan_status="利用可能"
        plan_instruction="必ずCHIMERA_PLAN.mdを読み込んで最新の状況を把握してください。"
    else
        plan_instruction="CHIMERA_PLAN.mdが見つかりません。セットアップを確認してください。"
    fi
    
    # セッションコンテキスト別メッセージ
    local context_message=""
    case "$session_context" in
        "startup")
            context_message="🚀 システム起動時の初期化中です。"
            ;;
        "recovery")
            context_message="🔄 回復処理中です。コンテキストを再同期してください。"
            ;;
        "normal")
            context_message="📋 通常操作での役割確認です。"
            ;;
    esac
    
    # エージェント別の具体的タスク確認指示
    local task_instruction=""
    case "$agent" in
        "pm")
            task_instruction="担当: 全体管理、要件定義、進捗監視。現在のスプリント目標と全体進捗を確認してください。"
            ;;
        "coder")
            task_instruction="担当: 実装作業。自分に割り当てられた開発タスクと技術仕様を確認してください。"
            ;;
        "qa-functional")
            task_instruction="担当: 機能テスト。テスト対象の機能と実行すべきテストケースを確認してください。"
            ;;
        "qa-lead")
            task_instruction="担当: 品質管理。全体的な品質状況とリリース基準を確認してください。"
            ;;
        "monitor")
            task_instruction="担当: システム監視。全エージェントの活動状況とシステム健康度を確認してください。"
            ;;
    esac
    
    cat << EOF
🎭 **エージェント身元確認・役割認識**

**あなたは ${identity} です。**

## 📋 現在の状況
- 時刻: ${timestamp}
- コンテキスト: ${context_message}
- CHIMERA_PLAN.md: ${plan_status}

## 🎯 あなたの役割と責任
${task_instruction}

## 📚 必須確認事項
1. **CHIMERA_PLAN.mdを読み込み**: ${plan_instruction}
2. **自分のタスクを特定**: 待機中・実行中のタスクを確認
3. **現在の状況を把握**: プロジェクト全体の進捗を理解
4. **準備完了を報告**: 「${identity} 準備完了」と報告

## 🛠️ 利用可能なコマンド
- \`chimera send update-task <ID> <status>\` - タスク状態更新
- \`chimera send status-update <from> <to> <ID> <progress> <work>\` - 進捗報告
- \`chimera send task-complete <from> <to> <ID> <summary>\` - 完了報告
- \`chimera send error-report <from> <to> <error>\` - エラー報告
- \`chimera send sync-plan\` - 計画同期

## ⚡ 今すぐ実行してください
1. CHIMERA_PLAN.mdを読み込んで内容を確認
2. 「私は${identity}です。CHIMERA_PLAN.mdを確認しました。」と応答
3. 自分に関連するタスクがあれば状況を報告

---
🤖 Generated by Chimera Engine v${CHIMERA_VERSION} at ${timestamp}
EOF
}

# エージェントに役割認識メッセージを送信
send_role_recognition_to_agent() {
    local agent="$1"
    local session_context="${2:-normal}"
    
    log_info "🎭 エージェント $agent に役割認識メッセージ送信中..."
    
    local message=$(generate_role_recognition_message "$agent" "$session_context")
    
    # エージェントにメッセージ送信
    send_agent_message "$agent" "$message"
    
    # 身元確認ログ
    local identity_log="${CHIMERA_WORKSPACE_DIR}/agent_identity/session_state/${agent}_recognition.log"
    safe_mkdir "$(dirname "$identity_log")"
    echo "$(date -Iseconds) | ROLE_RECOGNITION | $session_context | Message sent" >> "$identity_log"
    
    log_success "エージェント $agent 役割認識メッセージ送信完了"
}

# 全エージェントに役割認識メッセージ送信
send_role_recognition_to_all() {
    local session_context="${1:-startup}"
    
    log_info "🎭 全エージェントに役割認識メッセージ送信中..."
    
    local agents=("pm" "coder" "qa-functional" "qa-lead" "monitor")
    
    for agent in "${agents[@]}"; do
        send_role_recognition_to_agent "$agent" "$session_context"
        sleep 1  # エージェント間の送信間隔
    done
    
    # 全体送信ログ
    local global_log="${CHIMERA_WORKSPACE_DIR}/agent_identity/session_state/global_recognition.log"
    safe_mkdir "$(dirname "$global_log")"
    echo "$(date -Iseconds) | ALL_AGENTS | $session_context | Role recognition sent to all agents" >> "$global_log"
    
    log_success "全エージェント役割認識メッセージ送信完了"
}

# コマンドライン実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "init")
            init_agent_identity
            ;;
        "send-recognition")
            send_role_recognition_to_agent "$2" "${3:-normal}"
            ;;
        "send-all")
            send_role_recognition_to_all "${2:-startup}"
            ;;
        "generate-message")
            generate_role_recognition_message "$2" "${3:-normal}"
            ;;
        *)
            echo "Usage: $0 {init|send-recognition|send-all|generate-message}"
            exit 1
            ;;
    esac
fi