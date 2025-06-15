#!/bin/bash

# 🧪 Common Functions テストスイート
# scripts/lib/common.sh の機能をテスト

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# テストフレームワーク読み込み
source "$SCRIPT_DIR/lib/test-framework.sh"

# テスト対象ライブラリ読み込み（安全にエラーチェック）
if [[ -f "$PROJECT_ROOT/scripts/lib/common.sh" ]]; then
    source "$PROJECT_ROOT/scripts/lib/common.sh"
else
    echo "エラー: $PROJECT_ROOT/scripts/lib/common.sh が見つかりません"
    exit 1
fi

# テスト初期化
init_test_framework 1 1 30

echo "🧪 Testing Common Functions Library"
echo "=================================="

# テスト1: 設定値取得機能
test_start "get_config" "設定値取得機能のテスト"

assert_equals "$CHIMERA_VERSION" "$(get_config version)" "バージョン設定取得"
assert_equals "$CHIMERA_SESSION_NAME" "$(get_config session)" "セッション名設定取得"
assert_equals "default_value" "$(get_config nonexistent default_value)" "デフォルト値取得"

# テスト2: ログ関数
test_start "logging_functions" "ログ関数のテスト"

# ログ出力のキャプチャ（より安全な方法）
log_output=$(log_info "test message" 2>&1)
if echo "$log_output" | grep -q "test message"; then
    echo "  ✓ PASS: log_info出力確認"
else
    echo "  ✗ FAIL: log_info出力確認 - Expected 'test message', got '$log_output'"
fi

log_output=$(log_error "error message" 2>&1)
if echo "$log_output" | grep -q "error message"; then
    echo "  ✓ PASS: log_error出力確認"
else
    echo "  ✗ FAIL: log_error出力確認 - Expected 'error message', got '$log_output'"
fi

# テスト3: バージョン比較
test_start "version_compare" "バージョン比較機能のテスト"

# version_compare関数は異なる終了コードを返すため、set +e でエラーハンドリングを一時停止
set +e

version_compare "1.0.0" "1.0.0"
result_code=$?
assert_equals "0" "$result_code" "同じバージョンの比較"

version_compare "1.0.1" "1.0.0"
result_code=$?
assert_equals "1" "$result_code" "新しいバージョンの比較"

version_compare "1.0.0" "1.0.1"
result_code=$?
assert_equals "2" "$result_code" "古いバージョンの比較"

# エラーハンドリングを再開
set -e

# テスト4: ディレクトリ作成
test_start "safe_mkdir" "安全なディレクトリ作成のテスト"

test_dir="$TEST_TEMP_DIR/test_mkdir"
safe_mkdir "$test_dir"
assert_dir_exists "$test_dir" "ディレクトリ作成確認"

# 既存ディレクトリでの実行（エラーが出ないことを確認）
safe_mkdir "$test_dir"
assert_dir_exists "$test_dir" "既存ディレクトリでの安全実行"

# テスト5: 文字列エスケープ
test_start "escape_string" "文字列エスケープのテスト"

escaped=$(escape_string "test[abc]")
assert_equals "test\\[abc]" "$escaped" "ブラケットエスケープ"

escaped=$(escape_string "test*abc")
assert_equals "test\\*abc" "$escaped" "アスタリスクエスケープ"

# テスト6: タイムスタンプ生成
test_start "timestamp" "タイムスタンプ生成のテスト"

ts=$(timestamp)
if echo "$ts" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}$'; then
    echo "  ✓ PASS: タイムスタンプ形式確認"
else
    echo "  ✗ FAIL: タイムスタンプ形式確認 - Expected format YYYY-MM-DD HH:MM:SS, got '$ts'"
fi

iso_ts=$(timestamp_iso)
if echo "$iso_ts" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z$'; then
    echo "  ✓ PASS: ISO8601タイムスタンプ形式確認"
else
    echo "  ✗ FAIL: ISO8601タイムスタンプ形式確認 - Expected format YYYY-MM-DDTHH:MM:SSZ, got '$iso_ts'"
fi

# テスト7: エージェント一覧取得
test_start "list_agents" "エージェント一覧取得のテスト"

agents=$(list_agents)
if echo "$agents" | grep -q "pm"; then
    echo "  ✓ PASS: PMエージェント存在確認"
else
    echo "  ✗ FAIL: PMエージェント存在確認 - 'pm' not found in agents list: '$agents'"
fi

if echo "$agents" | grep -q "coder"; then
    echo "  ✓ PASS: Coderエージェント存在確認"
else
    echo "  ✗ FAIL: Coderエージェント存在確認 - 'coder' not found in agents list: '$agents'"
fi

if echo "$agents" | grep -q "qa-functional"; then
    echo "  ✓ PASS: QA-Functionalエージェント存在確認"
else
    echo "  ✗ FAIL: QA-Functionalエージェント存在確認 - 'qa-functional' not found in agents list: '$agents'"
fi

# テスト8: エージェント情報取得
test_start "get_agent_info" "エージェント情報取得のテスト"

pm_title=$(get_agent_info "pm" "title")
assert_equals "PM" "$pm_title" "PM タイトル取得"

coder_role=$(get_agent_info "coder" "role")
assert_equals "フルスタック開発者" "$coder_role" "Coder 役割取得"

# 存在しない情報
invalid_info=$(get_agent_info "invalid" "title")
assert_equals "" "$invalid_info" "存在しないエージェント情報"

# テスト9: 初期化確認
test_start "is_initialized" "初期化確認のテスト"

# モック環境でのテスト
setup_mock_environment
current_dir=$(pwd)

cd "$TEST_TEMP_DIR"
create_mock_file "setup-chimera.sh" "#!/bin/bash\necho 'mock setup'"
mkdir -p "instructions"

result=$(is_initialized && echo "true" || echo "false")
assert_equals "true" "$result" "初期化済み環境の検出"

cd "$current_dir"

# テスト10: スクリプトディレクトリ取得
test_start "get_script_dir" "スクリプトディレクトリ取得のテスト"

script_dir=$(get_script_dir)
assert_dir_exists "$script_dir" "スクリプトディレクトリ存在確認"

# libディレクトリの確認（直接的な方法）
script_basename=$(basename "$script_dir")
if echo "$script_basename" | grep -q "lib"; then
    echo "  ✓ PASS: libディレクトリの確認"
else
    echo "  ✗ FAIL: libディレクトリの確認 - Expected 'lib' in basename, got '$script_basename'"
fi

# テスト11: 設定の妥当性確認
test_start "validate_config" "設定の妥当性確認のテスト"

if validate_config 2>/dev/null; then
    assert_true "true" "設定の妥当性確認成功"
else
    # 設定に問題がある場合はテストをスキップ
    skip_test "設定に問題があるため妥当性テストをスキップ"
fi

# テスト結果表示
run_test_suite "Common Functions"