#!/bin/bash

# 🧪 Chimera Engine - 統合テストランナー
# 全テストスイートを実行し、結果をまとめて報告

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 引数処理
VERBOSE=0
JSON_OUTPUT=0
OUTPUT_DIR="$SCRIPT_DIR/results"
PARALLEL=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -j|--json)
            JSON_OUTPUT=1
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -p|--parallel)
            PARALLEL=1
            shift
            ;;
        -h|--help)
            cat << EOF
Chimera Engine テストランナー

使用方法:
  ./run_all_tests.sh [オプション]

オプション:
  -v, --verbose     詳細出力モード
  -j, --json        JSON形式で結果出力
  -o, --output DIR  結果出力ディレクトリ
  -p, --parallel    並列実行（実験的）
  -h, --help        このヘルプを表示

例:
  ./run_all_tests.sh -v -j -o ./test_results
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# 結果ディレクトリ作成
mkdir -p "$OUTPUT_DIR"

# テストスイート一覧
declare -a TEST_SUITES=(
    "test_common_functions.sh"
    "test_messaging.sh"
)

# カラー設定
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# 統計
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

# ログファイル
LOG_FILE="$OUTPUT_DIR/test_run_$(date +%Y%m%d_%H%M%S).log"
JSON_FILE="$OUTPUT_DIR/test_results_$(date +%Y%m%d_%H%M%S).json"

echo -e "${BOLD}🧪 Chimera Engine テストスイート実行${NC}"
echo "======================================"
echo "実行時刻: $(date)"
echo "出力ディレクトリ: $OUTPUT_DIR"
echo "発見されたテストスイート: ${#TEST_SUITES[@]}"
echo ""

# JSON出力初期化
if [[ $JSON_OUTPUT -eq 1 ]]; then
    cat > "$JSON_FILE" << EOF
{
    "test_run": {
        "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
        "project_root": "$PROJECT_ROOT",
        "output_directory": "$OUTPUT_DIR",
        "verbose": $VERBOSE,
        "parallel": $PARALLEL
    },
    "test_suites": [
EOF
fi

# 単一テストスイート実行
run_test_suite() {
    local test_file="$1"
    local suite_name=$(basename "$test_file" .sh)
    
    echo -e "${BLUE}🔍 実行中:${NC} $suite_name"
    
    local start_time=$(date +%s)
    local temp_output="$OUTPUT_DIR/${suite_name}_output.tmp"
    local temp_log="$OUTPUT_DIR/${suite_name}.log"
    
    # テスト実行（macOS対応）
    if [[ $VERBOSE -eq 1 ]]; then
        if "$SCRIPT_DIR/$test_file" 2>&1 | tee "$temp_log"; then
            local exit_code=0
        else
            local exit_code=1
        fi
    else
        if "$SCRIPT_DIR/$test_file" > "$temp_log" 2>&1; then
            local exit_code=0
        else
            local exit_code=1
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # 結果解析
    local suite_passed=0
    local suite_failed=0
    local suite_skipped=0
    local suite_total=0
    
    if [[ -f "$temp_log" ]]; then
        suite_passed=$(grep -o "成功: [0-9]*" "$temp_log" | awk '{print $2}' | tail -1 || echo "0")
        suite_failed=$(grep -o "失敗: [0-9]*" "$temp_log" | awk '{print $2}' | tail -1 || echo "0")
        suite_skipped=$(grep -o "スキップ: [0-9]*" "$temp_log" | awk '{print $2}' | tail -1 || echo "0")
        suite_total=$(grep -o "実行: [0-9]*" "$temp_log" | awk '{print $2}' | tail -1 || echo "0")
    fi
    
    # デフォルト値設定
    suite_passed=${suite_passed:-0}
    suite_failed=${suite_failed:-0}
    suite_skipped=${suite_skipped:-0}
    suite_total=${suite_total:-0}
    
    # 統計更新
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + suite_total))
    TOTAL_PASSED=$((TOTAL_PASSED + suite_passed))
    TOTAL_FAILED=$((TOTAL_FAILED + suite_failed))
    TOTAL_SKIPPED=$((TOTAL_SKIPPED + suite_skipped))
    
    # 結果表示
    if [[ $exit_code -eq 0 && $suite_failed -eq 0 ]]; then
        echo -e "  ${GREEN}✅ PASS${NC} ($duration秒) - $suite_passed/$suite_total テスト成功"
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        echo -e "  ${RED}❌ FAIL${NC} ($duration秒) - $suite_failed/$suite_total テスト失敗"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        
        # エラーの要約表示
        if [[ $VERBOSE -eq 0 && -f "$temp_log" ]]; then
            echo "    最新のエラー:"
            grep -E "(FAIL|ERROR)" "$temp_log" | tail -3 | sed 's/^/      /'
        fi
    fi
    
    # JSON出力
    if [[ $JSON_OUTPUT -eq 1 ]]; then
        # カンマの追加判定
        if [[ $TOTAL_SUITES -gt 1 ]]; then
            echo "," >> "$JSON_FILE"
        fi
        
        cat >> "$JSON_FILE" << EOF
        {
            "name": "$suite_name",
            "file": "$test_file",
            "start_time": $start_time,
            "end_time": $end_time,
            "duration": $duration,
            "exit_code": $exit_code,
            "tests": {
                "total": $suite_total,
                "passed": $suite_passed,
                "failed": $suite_failed,
                "skipped": $suite_skipped
            },
            "log_file": "$temp_log"
        }
EOF
    fi
    
    # 一時ファイルクリーンアップ
    rm -f "$temp_output"
    
    return $exit_code
}

# 並列実行関数
run_tests_parallel() {
    local pids=()
    local temp_results=()
    
    for test_file in "${TEST_SUITES[@]}"; do
        if [[ -f "$SCRIPT_DIR/$test_file" ]]; then
            temp_result="$OUTPUT_DIR/parallel_$(basename "$test_file" .sh).result"
            temp_results+=("$temp_result")
            
            (
                run_test_suite "$test_file"
                echo $? > "$temp_result"
            ) &
            
            pids+=($!)
        fi
    done
    
    # 全プロセス完了を待機
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # 結果収集
    local failed_suites=0
    for result_file in "${temp_results[@]}"; do
        if [[ -f "$result_file" ]]; then
            local exit_code=$(cat "$result_file")
            if [[ $exit_code -ne 0 ]]; then
                failed_suites=$((failed_suites + 1))
            fi
            rm -f "$result_file"
        fi
    done
    
    return $failed_suites
}

# メイン実行
main() {
    local start_time=$(date +%s)
    
    # テストスイート実行
    if [[ $PARALLEL -eq 1 ]]; then
        echo "🚀 並列実行モードでテストを実行中..."
        echo ""
        run_tests_parallel
        local overall_exit_code=$?
    else
        local overall_exit_code=0
        for test_file in "${TEST_SUITES[@]}"; do
            if [[ -f "$SCRIPT_DIR/$test_file" ]]; then
                if ! run_test_suite "$test_file"; then
                    overall_exit_code=1
                fi
            else
                echo -e "${YELLOW}⚠️  SKIP${NC}: $test_file (ファイルが見つかりません)"
            fi
        done
    fi
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    # JSON出力完了
    if [[ $JSON_OUTPUT -eq 1 ]]; then
        cat >> "$JSON_FILE" << EOF
    ],
    "summary": {
        "total_suites": $TOTAL_SUITES,
        "passed_suites": $PASSED_SUITES,
        "failed_suites": $FAILED_SUITES,
        "total_tests": $TOTAL_TESTS,
        "total_passed": $TOTAL_PASSED,
        "total_failed": $TOTAL_FAILED,
        "total_skipped": $TOTAL_SKIPPED,
        "success_rate": $(( TOTAL_TESTS > 0 ? TOTAL_PASSED * 100 / TOTAL_TESTS : 0 )),
        "duration": $total_duration
    }
}
EOF
        echo "JSON結果: $JSON_FILE"
    fi
    
    # 最終結果表示
    echo ""
    echo -e "${BOLD}📊 テスト実行結果サマリー${NC}"
    echo "==============================="
    echo -e "実行時間: ${BOLD}${total_duration}秒${NC}"
    echo -e "テストスイート: $PASSED_SUITES/$TOTAL_SUITES 成功"
    echo -e "個別テスト: $TOTAL_PASSED/$TOTAL_TESTS 成功"
    echo -e "スキップ: $TOTAL_SKIPPED"
    
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        local success_rate=$((TOTAL_PASSED * 100 / TOTAL_TESTS))
        echo -e "成功率: ${BOLD}$success_rate%${NC}"
    fi
    
    echo ""
    if [[ $FAILED_SUITES -eq 0 && $TOTAL_FAILED -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}🎉 全テスト合格！${NC}"
        echo "詳細ログ: $OUTPUT_DIR/"
        return 0
    else
        echo -e "${RED}${BOLD}💥 テスト失敗${NC}"
        echo -e "${RED}失敗したスイート: $FAILED_SUITES${NC}"
        echo -e "${RED}失敗した個別テスト: $TOTAL_FAILED${NC}"
        echo "詳細ログ: $OUTPUT_DIR/"
        
        # 主要なエラーファイル表示
        echo ""
        echo "主要なエラーログ:"
        find "$OUTPUT_DIR" -name "*.log" -exec grep -l "FAIL\|ERROR" {} \; | head -3 | while read -r log_file; do
            echo "  - $(basename "$log_file")"
        done
        
        return 1
    fi
}

# 実行
main "$@"