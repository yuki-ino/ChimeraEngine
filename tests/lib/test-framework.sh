#!/bin/bash

# 🧪 Chimera Engine - シェルスクリプトテストフレームワーク
# 軽量で使いやすいBashテストシステム

# テスト統計
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
ERROR_COUNT=0

# テスト設定
TEST_VERBOSE=0
TEST_STRICT=1
TEST_TIMEOUT=30
TEST_TEMP_DIR=""
TEST_OUTPUT_FORMAT="text"  # text, json, xml

# 色設定
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE='' BOLD='' NC=''
fi

# テストフレームワーク初期化
init_test_framework() {
    local verbose="${1:-0}"
    local strict="${2:-1}"
    local timeout="${3:-30}"
    
    TEST_VERBOSE="$verbose"
    TEST_STRICT="$strict"
    TEST_TIMEOUT="$timeout"
    
    # 一時ディレクトリ作成
    TEST_TEMP_DIR=$(mktemp -d -t "chimera_test_XXXXXX")
    
    # エラーハンドリング設定
    if [[ "$TEST_STRICT" == "1" ]]; then
        set -euo pipefail
    fi
    
    # テスト開始ログ
    if [[ "$TEST_VERBOSE" == "1" ]]; then
        echo -e "${BOLD}🧪 Chimera Test Framework 初期化${NC}"
        echo "Temp Dir: $TEST_TEMP_DIR"
        echo "Verbose: $TEST_VERBOSE, Strict: $TEST_STRICT, Timeout: $TEST_TIMEOUT"
        echo "----------------------------------------"
    fi
}

# テスト関数定義
test_start() {
    local test_name="$1"
    local description="${2:-}"
    
    if [[ "$TEST_VERBOSE" == "1" ]]; then
        echo -e "${BLUE}🔍 Testing:${NC} $test_name"
        if [[ -n "$description" ]]; then
            echo -e "${CYAN}   Description:${NC} $description"
        fi
    fi
}

# アサーション: 等価確認
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Equality assertion failed}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [[ "$expected" == "$actual" ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "$TEST_VERBOSE" == "1" ]]; then
            echo -e "  ${GREEN}✓ PASS${NC}: $message"
        else
            echo -n "."
        fi
        return 0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    Expected: ${CYAN}'$expected'${NC}"
        echo -e "    Actual:   ${YELLOW}'$actual'${NC}"
        
        if [[ "$TEST_STRICT" == "1" ]]; then
            echo -e "${RED}Strict mode: テスト中断${NC}"
            exit 1
        fi
        return 1
    fi
}

# アサーション: 非等価確認
assert_not_equals() {
    local not_expected="$1"
    local actual="$2"
    local message="${3:-Non-equality assertion failed}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [[ "$not_expected" != "$actual" ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "$TEST_VERBOSE" == "1" ]]; then
            echo -e "  ${GREEN}✓ PASS${NC}: $message"
        else
            echo -n "."
        fi
        return 0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    Should not equal: ${CYAN}'$not_expected'${NC}"
        echo -e "    But got:          ${YELLOW}'$actual'${NC}"
        return 1
    fi
}

# アサーション: 真偽値確認
assert_true() {
    local condition="$1"
    local message="${2:-Boolean assertion failed}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [[ "$condition" == "true" || "$condition" == "1" || "$condition" == "0" ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "$TEST_VERBOSE" == "1" ]]; then
            echo -e "  ${GREEN}✓ PASS${NC}: $message"
        else
            echo -n "."
        fi
        return 0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    Expected: ${CYAN}true${NC}"
        echo -e "    Actual:   ${YELLOW}'$condition'${NC}"
        return 1
    fi
}

# アサーション: ファイル存在確認
assert_file_exists() {
    local file_path="$1"
    local message="${2:-File existence assertion failed}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [[ -f "$file_path" ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "$TEST_VERBOSE" == "1" ]]; then
            echo -e "  ${GREEN}✓ PASS${NC}: $message"
        else
            echo -n "."
        fi
        return 0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    File not found: ${YELLOW}'$file_path'${NC}"
        return 1
    fi
}

# アサーション: ディレクトリ存在確認
assert_dir_exists() {
    local dir_path="$1"
    local message="${2:-Directory existence assertion failed}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if [[ -d "$dir_path" ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "$TEST_VERBOSE" == "1" ]]; then
            echo -e "  ${GREEN}✓ PASS${NC}: $message"
        else
            echo -n "."
        fi
        return 0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    Directory not found: ${YELLOW}'$dir_path'${NC}"
        return 1
    fi
}

# アサーション: コマンド成功確認
assert_command_success() {
    local command="$1"
    local message="${2:-Command success assertion failed}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if bash -c "$command" &>/dev/null; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "$TEST_VERBOSE" == "1" ]]; then
            echo -e "  ${GREEN}✓ PASS${NC}: $message"
        else
            echo -n "."
        fi
        return 0
    else
        local exit_code=$?
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    Command failed: ${YELLOW}'$command'${NC}"
        echo -e "    Exit code: ${YELLOW}$exit_code${NC}"
        return 1
    fi
}

# アサーション: コマンド失敗確認
assert_command_failure() {
    local command="$1"
    local message="${2:-Command failure assertion failed}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    if ! bash -c "$command" &>/dev/null; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "$TEST_VERBOSE" == "1" ]]; then
            echo -e "  ${GREEN}✓ PASS${NC}: $message"
        else
            echo -n "."
        fi
        return 0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    Command unexpectedly succeeded: ${YELLOW}'$command'${NC}"
        return 1
    fi
}

# アサーション: 出力確認
assert_output_contains() {
    local command="$1"
    local expected_output="$2"
    local message="${3:-Output contains assertion failed}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    local actual_output
    actual_output=$(bash -c "$command" 2>&1)
    local command_exit_code=$?
    
    if [[ $command_exit_code -eq 0 ]] && echo "$actual_output" | grep -q "$expected_output"; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "$TEST_VERBOSE" == "1" ]]; then
            echo -e "  ${GREEN}✓ PASS${NC}: $message"
        else
            echo -n "."
        fi
        return 0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    Command: ${CYAN}'$command'${NC}"
        echo -e "    Expected to contain: ${CYAN}'$expected_output'${NC}"
        echo -e "    Actual output: ${YELLOW}'$actual_output'${NC}"
        echo -e "    Command exit code: ${YELLOW}$command_exit_code${NC}"
        return 1
    fi
}

# テストスキップ
skip_test() {
    local reason="${1:-No reason provided}"
    
    SKIP_COUNT=$((SKIP_COUNT + 1))
    echo -e "  ${YELLOW}⚠ SKIP${NC}: $reason"
}

# モックファイル作成
create_mock_file() {
    local file_path="$1"
    local content="${2:-}"
    
    local dir_path=$(dirname "$file_path")
    mkdir -p "$dir_path"
    echo "$content" > "$file_path"
}

# モック環境設定
setup_mock_environment() {
    # 一時的な環境変数設定
    export CHIMERA_TEST_MODE=1
    export CHIMERA_WORKSPACE_DIR="$TEST_TEMP_DIR/workspace"
    export TMPDIR="$TEST_TEMP_DIR"
    
    # モックディレクトリ作成
    mkdir -p "$CHIMERA_WORKSPACE_DIR/status"
    mkdir -p "$CHIMERA_WORKSPACE_DIR/logs"
    
    if [[ "$TEST_VERBOSE" == "1" ]]; then
        echo -e "${PURPLE}🔧 モック環境設定完了${NC}"
    fi
}

# テスト結果サマリー表示
run_test_suite() {
    local suite_name="${1:-Test Suite}"
    
    echo ""
    if [[ "$TEST_VERBOSE" == "0" ]]; then
        echo ""  # 改行（ドット表示の後）
    fi
    
    echo -e "${BOLD}📊 $suite_name 結果${NC}"
    echo "=================================="
    echo -e "実行: ${BOLD}$TEST_COUNT${NC} テスト"
    echo -e "成功: ${GREEN}$PASS_COUNT${NC}"
    echo -e "失敗: ${RED}$FAIL_COUNT${NC}"
    echo -e "スキップ: ${YELLOW}$SKIP_COUNT${NC}"
    echo -e "エラー: ${PURPLE}$ERROR_COUNT${NC}"
    
    local success_rate=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        success_rate=$((PASS_COUNT * 100 / TEST_COUNT))
    fi
    
    echo -e "成功率: ${BOLD}$success_rate%${NC}"
    
    # 結果判定
    if [[ $FAIL_COUNT -eq 0 && $ERROR_COUNT -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✅ 全テスト合格！${NC}"
        cleanup_test_environment
        return 0
    else
        echo -e "${RED}${BOLD}❌ テスト失敗${NC}"
        if [[ $FAIL_COUNT -gt 0 ]]; then
            echo -e "  ${RED}$FAIL_COUNT 件のテストが失敗${NC}"
        fi
        if [[ $ERROR_COUNT -gt 0 ]]; then
            echo -e "  ${PURPLE}$ERROR_COUNT 件のエラーが発生${NC}"
        fi
        cleanup_test_environment
        return 1
    fi
}

# JSON形式でテスト結果出力
output_test_results_json() {
    local output_file="${1:-test_results.json}"
    
    cat > "$output_file" << EOF
{
    "summary": {
        "total": $TEST_COUNT,
        "passed": $PASS_COUNT,
        "failed": $FAIL_COUNT,
        "skipped": $SKIP_COUNT,
        "errors": $ERROR_COUNT,
        "success_rate": $(( TEST_COUNT > 0 ? PASS_COUNT * 100 / TEST_COUNT : 0 ))
    },
    "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
    "environment": {
        "chimera_test_mode": true,
        "temp_dir": "$TEST_TEMP_DIR",
        "shell": "$SHELL",
        "user": "$(whoami)"
    }
}
EOF
    
    echo "JSON結果出力: $output_file"
}

# テスト環境クリーンアップ
cleanup_test_environment() {
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        if [[ "$TEST_VERBOSE" == "1" ]]; then
            echo -e "${PURPLE}🧹 テスト環境クリーンアップ完了${NC}"
        fi
    fi
    
    # テスト用環境変数リセット
    unset CHIMERA_TEST_MODE
}

# ベンチマーク実行
benchmark() {
    local name="$1"
    local command="$2"
    local iterations="${3:-10}"
    
    echo -e "${BLUE}⏱️  ベンチマーク:${NC} $name"
    
    local total_time=0
    local min_time=999999
    local max_time=0
    
    for ((i=1; i<=iterations; i++)); do
        local start_time=$(date +%s%N)
        
        if bash -c "$command" &>/dev/null; then
            local end_time=$(date +%s%N)
            local execution_time=$(( (end_time - start_time) / 1000000 ))  # ミリ秒
            
            total_time=$((total_time + execution_time))
            
            if [[ $execution_time -lt $min_time ]]; then
                min_time=$execution_time
            fi
            
            if [[ $execution_time -gt $max_time ]]; then
                max_time=$execution_time
            fi
            
            if [[ "$TEST_VERBOSE" == "1" ]]; then
                echo "  Iteration $i: ${execution_time}ms"
            fi
        else
            echo -e "  ${RED}✗ Iteration $i failed${NC}"
        fi
    done
    
    local avg_time=$((total_time / iterations))
    
    echo -e "  平均時間: ${BOLD}${avg_time}ms${NC}"
    echo -e "  最小時間: ${min_time}ms"
    echo -e "  最大時間: ${max_time}ms"
}

# テストヘルパー関数
is_testing() {
    [[ "${CHIMERA_TEST_MODE:-0}" == "1" ]]
}

# テスト専用ログ
test_log() {
    if [[ "$TEST_VERBOSE" == "1" ]]; then
        echo -e "${CYAN}[TEST LOG]${NC} $*"
    fi
}

# テストデータ生成
generate_test_data() {
    local type="$1"
    local size="${2:-10}"
    
    case "$type" in
        "string")
            head -c "$size" /dev/urandom | base64 | tr -d '\n' | head -c "$size"
            ;;
        "number")
            echo $((RANDOM % size + 1))
            ;;
        "email")
            echo "test_$(date +%s)_$RANDOM@example.com"
            ;;
        *)
            echo "test_data_$RANDOM"
            ;;
    esac
}