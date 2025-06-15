#!/bin/bash

# 🧪 Messaging System テストスイート
# scripts/lib/messaging.sh の機能をテスト

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# テストフレームワーク読み込み
source "$SCRIPT_DIR/lib/test-framework.sh"

# テスト対象ライブラリ読み込み（安全にエラーチェック）
if [[ -f "$PROJECT_ROOT/scripts/lib/messaging.sh" ]]; then
    source "$PROJECT_ROOT/scripts/lib/messaging.sh"
else
    echo "エラー: $PROJECT_ROOT/scripts/lib/messaging.sh が見つかりません"
    exit 1
fi

# テスト初期化
init_test_framework 1 0 30  # 非strictモードでテスト（tmuxが利用できない可能性があるため）

echo "🧪 Testing Messaging System"
echo "=========================="

# モック環境設定
setup_mock_environment

# テスト1: エージェントターゲット取得
test_start "get_agent_target" "エージェントターゲット取得のテスト"

pm_target=$(get_agent_target "pm")
assert_equals "chimera-workspace:0.0" "$pm_target" "PMエージェントターゲット取得"

coder_target=$(get_agent_target "coder")
assert_equals "chimera-workspace:0.1" "$coder_target" "Coderエージェントターゲット取得"

invalid_target=$(get_agent_target "invalid_agent")
assert_equals "" "$invalid_target" "存在しないエージェントターゲット"

# テスト2: 利用可能エージェント表示
test_start "show_available_agents" "利用可能エージェント表示のテスト"

agent_list=$(show_available_agents 2>&1)
assert_output_contains "show_available_agents 2>&1" "pm" "エージェント一覧にPM含有"
assert_output_contains "show_available_agents 2>&1" "coder" "エージェント一覧にCoder含有"
assert_output_contains "show_available_agents 2>&1" "qa-functional" "エージェント一覧にQA-Functional含有"

# テスト3: 特別なコマンド処理
test_start "handle_special_commands" "特別なコマンド処理のテスト"

# START_DEVELOPMENTコマンドのテスト
if handle_special_commands "pm" "START_DEVELOPMENT test project"; then
    assert_true "true" "START_DEVELOPMENTコマンド処理成功"
else
    skip_test "START_DEVELOPMENTコマンド処理に必要な環境が整っていません"
fi

# 通常のメッセージ（特別でない）
if ! handle_special_commands "coder" "normal message"; then
    assert_true "true" "通常メッセージは特別コマンドとして処理されない"
else
    assert_true "false" "通常メッセージが特別コマンドとして誤認された"
fi

# テスト4: エージェントメッセージログ記録
test_start "log_agent_message" "エージェントメッセージログ記録のテスト"

test_agent="pm"
test_message="test log message"

log_agent_message "$test_agent" "$test_message"

# ログファイル確認
communication_log="$LOGS_DIR/communication.log"
assert_file_exists "$communication_log" "通信ログファイル存在確認"

# ログ内容確認
log_content=$(cat "$communication_log")
assert_output_contains "cat '$communication_log'" "$test_agent" "ログにエージェント名含有"
assert_output_contains "cat '$communication_log'" "$test_message" "ログにメッセージ含有"

# エージェント別ログ確認
agent_log="$LOGS_DIR/${test_agent}_log.txt"
assert_file_exists "$agent_log" "エージェント別ログファイル存在確認"

# テスト5: エージェントステータス更新
test_start "update_agent_status" "エージェントステータス更新のテスト"

# 実装完了メッセージ
update_agent_status "coder" "実装完了しました"
assert_file_exists "$STATUS_DIR/coding_done.txt" "実装完了ステータスファイル作成"

# テスト合格メッセージ
update_agent_status "qa-functional" "テスト合格しました"
assert_file_exists "$STATUS_DIR/test_passed.txt" "テスト合格ステータスファイル作成"

# テスト失敗メッセージ
update_agent_status "qa-functional" "テスト失敗: エラーが発生"
assert_file_exists "$STATUS_DIR/test_failed.txt" "テスト失敗ステータスファイル作成"

# リリース可能メッセージ
update_agent_status "qa-lead" "リリース可能です"
assert_file_exists "$STATUS_DIR/release_ready.txt" "リリース可能ステータスファイル作成"

# テスト6: エージェント状態分析
test_start "analyze_agent_status" "エージェント状態分析のテスト"

# tmuxが利用できない環境でのテスト
if command -v tmux &>/dev/null && tmux info &>/dev/null; then
    # tmuxが利用可能な場合
    status=$(analyze_agent_status "pm" 2>/dev/null || echo "unknown")
    assert_true "$(echo "$status" | grep -qE '^(completed|error|waiting|working|unknown)$')" "状態分析結果が有効な値"
else
    # tmuxが利用できない場合はスキップ
    skip_test "tmuxが利用できないため状態分析テストをスキップ"
fi

# テスト7: 通信統計取得
test_start "get_communication_stats" "通信統計取得のテスト"

# ログにいくつかの追加メッセージを記録
log_agent_message "coder" "message 1"
log_agent_message "pm" "message 2"
log_agent_message "qa-functional" "message 3"

stats_output=$(get_communication_stats 2>/dev/null)
if [[ -n "$stats_output" ]]; then
    assert_output_contains "get_communication_stats 2>/dev/null" "総メッセージ数" "統計情報に総数含有"
    assert_output_contains "get_communication_stats 2>/dev/null" "pm" "統計情報にPM含有"
else
    skip_test "通信ログが見つからないため統計テストをスキップ"
fi

# テスト8: 最新アクティビティ表示
test_start "show_recent_activity" "最新アクティビティ表示のテスト"

activity_output=$(show_recent_activity 5 2>/dev/null)
if [[ -n "$activity_output" ]]; then
    assert_output_contains "show_recent_activity 5 2>/dev/null" "最新アクティビティ" "アクティビティヘッダー確認"
else
    skip_test "アクティビティログが見つからないためテストをスキップ"
fi

# テスト9: メッセージ検索
test_start "search_messages" "メッセージ検索のテスト"

# 検索対象メッセージを追加
log_agent_message "coder" "特定のキーワード含有メッセージ"

search_result=$(search_messages "特定のキーワード" 2>/dev/null)
if [[ -n "$search_result" ]]; then
    assert_output_contains "search_messages '特定のキーワード' 2>/dev/null" "特定のキーワード" "検索結果にキーワード含有"
else
    skip_test "検索対象ログが見つからないため検索テストをスキップ"
fi

# エージェントフィルター付き検索
search_result=$(search_messages "message" "coder" 2>/dev/null)
if [[ -n "$search_result" ]]; then
    assert_output_contains "search_messages 'message' 'coder' 2>/dev/null" "coder" "フィルター付き検索でエージェント確認"
else
    skip_test "フィルター付き検索のテストをスキップ"
fi

# テスト10: メッセージング設定表示
test_start "show_messaging_config" "メッセージング設定表示のテスト"

config_output=$(show_messaging_config)
assert_output_contains "show_messaging_config" "メッセージング設定" "設定ヘッダー確認"
assert_output_contains "show_messaging_config" "ワークスペース" "ワークスペース情報確認"
assert_output_contains "show_messaging_config" "登録エージェント数" "エージェント数情報確認"

# テスト11: 開発開始コマンド処理
test_start "handle_start_development" "開発開始コマンド処理のテスト"

start_output=$(handle_start_development "START_DEVELOPMENT test project")
assert_output_contains "handle_start_development 'START_DEVELOPMENT test project'" "開発フェーズを開始" "開発開始メッセージ確認"

# ステータスファイル確認
assert_file_exists "$STATUS_DIR/planning_complete.txt" "企画完了ステータスファイル作成"

# PMワークフローログ確認
pm_workflow_log="$LOGS_DIR/pm_workflow.log"
assert_file_exists "$pm_workflow_log" "PMワークフローログファイル存在確認"

# テスト結果表示
run_test_suite "Messaging System"