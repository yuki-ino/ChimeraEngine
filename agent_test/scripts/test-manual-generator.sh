#!/bin/bash

# 📖 テストマニュアル自動生成ツール
# プロジェクト解析結果を基に、テスター向けのカスタマイズされた指示書を生成

PROJECT_DIR="${1:-.}"
ANALYSIS_FILE="$PROJECT_DIR/.chimera/project-analysis.json"
OUTPUT_FILE="$PROJECT_DIR/instructions/tester.md"

# 解析結果が存在しない場合は解析を実行
if [ ! -f "$ANALYSIS_FILE" ]; then
    echo "📊 プロジェクト解析を実行中..."
    ./project-analyzer.sh "$PROJECT_DIR"
fi

# JSON解析のためのヘルパー関数
get_json_value() {
    jq -r ".$1" "$ANALYSIS_FILE" 2>/dev/null || echo ""
}

get_json_array() {
    jq -r ".$1[]" "$ANALYSIS_FILE" 2>/dev/null || echo ""
}

# プロジェクト情報取得
PROJECT_TYPE=$(get_json_value "project_type")
PACKAGE_MANAGER=$(get_json_value "package_manager")
TEST_FRAMEWORKS=($(get_json_array "test_frameworks"))
TEST_DIRECTORIES=($(get_json_array "test_directories"))
TEST_COMMANDS=($(get_json_array "test_commands"))
CONFIG_FILES=($(get_json_array "config_files"))
TECH_STACK=($(get_json_array "tech_stack"))

echo "📖 テストマニュアルを生成中..."
echo "プロジェクトタイプ: $PROJECT_TYPE"
echo "テストフレームワーク: ${TEST_FRAMEWORKS[*]}"

# テスター指示書生成
cat > "$OUTPUT_FILE" << EOF
# 🧪 Tester指示書 - $PROJECT_TYPE プロジェクト

## 🎯 プロジェクト概要
- **プロジェクトタイプ**: $PROJECT_TYPE
- **パッケージマネージャー**: $PACKAGE_MANAGER
- **技術スタック**: ${TECH_STACK[*]}
- **テストフレームワーク**: ${TEST_FRAMEWORKS[*]}

## 📁 テスト構成

### テストディレクトリ
EOF

# テストディレクトリの詳細を追加
if [ ${#TEST_DIRECTORIES[@]} -gt 0 ]; then
    for dir in "${TEST_DIRECTORIES[@]}"; do
        echo "- \`$dir/\` - $(describe_test_directory "$dir")" >> "$OUTPUT_FILE"
    done
else
    echo "- テストディレクトリが検出されませんでした" >> "$OUTPUT_FILE"
    echo "- 推奨: \`tests/\` または \`__tests__/\` ディレクトリの作成" >> "$OUTPUT_FILE"
fi

# 設定ファイルセクション
cat >> "$OUTPUT_FILE" << EOF

### 設定ファイル
EOF

if [ ${#CONFIG_FILES[@]} -gt 0 ]; then
    for config in "${CONFIG_FILES[@]}"; do
        echo "- \`$config\` - $(describe_config_file "$config")" >> "$OUTPUT_FILE"
    done
else
    echo "- 設定ファイルが検出されませんでした" >> "$OUTPUT_FILE"
fi

# テストコマンドセクション生成
generate_test_commands_section() {
    cat >> "$OUTPUT_FILE" << EOF

## 🚀 テスト実行コマンド

### 基本テストコマンド
EOF

    if [ ${#TEST_COMMANDS[@]} -gt 0 ]; then
        for cmd in "${TEST_COMMANDS[@]}"; do
            echo "\`\`\`bash" >> "$OUTPUT_FILE"
            echo "$cmd" >> "$OUTPUT_FILE"
            echo "\`\`\`" >> "$OUTPUT_FILE"
        done
    else
        # フレームワーク別のデフォルトコマンドを生成
        generate_default_commands
    fi
}

# フレームワーク別デフォルトコマンド生成
generate_default_commands() {
    for framework in "${TEST_FRAMEWORKS[@]}"; do
        case "$framework" in
            *"Jest"*)
                cat >> "$OUTPUT_FILE" << 'EOF'
```bash
# Jest テスト実行
npm test                    # 全テスト実行
npm test -- --watch         # ウォッチモード
npm test -- --coverage     # カバレッジ付き
npm test -- --verbose      # 詳細出力
npm test -- pattern        # パターンマッチング
```
EOF
                ;;
            *"Vitest"*)
                cat >> "$OUTPUT_FILE" << 'EOF'
```bash
# Vitest テスト実行
npm run test               # 全テスト実行
npm run test:ui           # UI付きテスト
npm run test:coverage     # カバレッジ付き
npx vitest run            # ウォッチなしで実行
npx vitest --reporter=verbose  # 詳細出力
```
EOF
                ;;
            *"Cypress"*)
                cat >> "$OUTPUT_FILE" << 'EOF'
```bash
# Cypress E2Eテスト
npx cypress open          # GUI起動
npx cypress run           # ヘッドレス実行
npx cypress run --spec "cypress/e2e/**/*.cy.js"  # 特定ファイル
npx cypress run --browser chrome  # ブラウザ指定
```
EOF
                ;;
            *"Playwright"*)
                cat >> "$OUTPUT_FILE" << 'EOF'
```bash
# Playwright テスト
npx playwright test                    # 全テスト実行
npx playwright test --ui              # UI付きテスト
npx playwright test --debug          # デバッグモード
npx playwright test --headed         # ブラウザ表示
npx playwright show-report           # レポート表示
```
EOF
                ;;
            *"pytest"*)
                cat >> "$OUTPUT_FILE" << 'EOF'
```bash
# pytest テスト実行
pytest                     # 全テスト実行
pytest -v                  # 詳細出力
pytest --cov              # カバレッジ付き
pytest -k "pattern"       # パターンマッチング
pytest --html=report.html # HTMLレポート
```
EOF
                ;;
        esac
    done
    
    # パッケージマネージャー別コマンド
    case "$PACKAGE_MANAGER" in
        "yarn")
            sed -i.bak 's/npm run/yarn/g; s/npm test/yarn test/g' "$OUTPUT_FILE"
            ;;
        "pnpm")
            sed -i.bak 's/npm run/pnpm/g; s/npm test/pnpm test/g' "$OUTPUT_FILE"
            ;;
    esac
}

# テストタイプ別のセクション生成
generate_test_types_section() {
    cat >> "$OUTPUT_FILE" << EOF

## 🎭 テストタイプ別実行

### Unit Tests (単体テスト)
EOF

    case "$PROJECT_TYPE" in
        *"React"*|*"Next.js"*)
            cat >> "$OUTPUT_FILE" << 'EOF'
```bash
# React コンポーネントテスト
npm test -- --testPathPattern="components"
npm test -- --testNamePattern="Component"

# フック単体テスト
npm test -- --testPathPattern="hooks"
```
EOF
            ;;
        *"Vue"*)
            cat >> "$OUTPUT_FILE" << 'EOF'
```bash
# Vue コンポーネントテスト
npm test -- --testPathPattern="components"
npm test -- unit

# Composition API テスト
npm test -- --testPathPattern="composables"
```
EOF
            ;;
    esac

    cat >> "$OUTPUT_FILE" << EOF

### Integration Tests (統合テスト)
\`\`\`bash
# API統合テスト
EOF

    for framework in "${TEST_FRAMEWORKS[@]}"; do
        if [[ "$framework" == *"Supertest"* ]]; then
            echo "npm test -- --testPathPattern=\"integration\"" >> "$OUTPUT_FILE"
            break
        fi
    done

    cat >> "$OUTPUT_FILE" << 'EOF'
```

### E2E Tests (エンドツーエンドテスト)
EOF

    # E2Eテスト用のコマンドを追加
    has_cypress=false
    has_playwright=false
    
    for framework in "${TEST_FRAMEWORKS[@]}"; do
        case "$framework" in
            *"Cypress"*) has_cypress=true ;;
            *"Playwright"*) has_playwright=true ;;
        esac
    done
    
    if [ "$has_cypress" = true ]; then
        cat >> "$OUTPUT_FILE" << 'EOF'
```bash
# Cypress E2Eテスト
npx cypress run --spec "cypress/e2e/**/*.cy.js"
```
EOF
    elif [ "$has_playwright" = true ]; then
        cat >> "$OUTPUT_FILE" << 'EOF'
```bash
# Playwright E2Eテスト
npx playwright test tests/e2e/
```
EOF
    else
        cat >> "$OUTPUT_FILE" << 'EOF'
```bash
# E2Eテストフレームワークが検出されませんでした
# Cypress または Playwright の導入を推奨
```
EOF
    fi
}

# PMから指示を受けた時の行動パターン生成
generate_pm_instruction_section() {
    cat >> "$OUTPUT_FILE" << 'EOF'

## 📥 PMから指示を受けた時の実行内容

### 1. テスト準備
```bash
echo "🧪 テスト準備開始"
echo "対象機能: [PMから指定された機能名]"
echo ""

# 依存関係の確認
EOF

    case "$PACKAGE_MANAGER" in
        "npm") echo "npm install  # 依存関係インストール" >> "$OUTPUT_FILE" ;;
        "yarn") echo "yarn install  # 依存関係インストール" >> "$OUTPUT_FILE" ;;
        "pnpm") echo "pnpm install  # 依存関係インストール" >> "$OUTPUT_FILE" ;;
        "pip") echo "pip install -r requirements.txt  # 依存関係インストール" >> "$OUTPUT_FILE" ;;
    esac

    cat >> "$OUTPUT_FILE" << 'EOF'

# テスト環境確認
echo "テスト環境を確認中..."
```

### 2. コーダーから実装完了通知を受けた時
```bash
echo "🧪 テスト実行開始"
echo "========================"

# 1. Unit Tests
echo "Step 1: Unit Tests"
EOF

    # 検出されたテストコマンドを使用
    if [ ${#TEST_COMMANDS[@]} -gt 0 ]; then
        echo "${TEST_COMMANDS[0]}" >> "$OUTPUT_FILE"
    else
        case "$PACKAGE_MANAGER" in
            "npm"|"yarn"|"pnpm") echo "npm test" >> "$OUTPUT_FILE" ;;
            "pip") echo "pytest" >> "$OUTPUT_FILE" ;;
            "cargo") echo "cargo test" >> "$OUTPUT_FILE" ;;
            "go") echo "go test ./..." >> "$OUTPUT_FILE" ;;
        esac
    fi

    cat >> "$OUTPUT_FILE" << 'EOF'

# 2. Integration Tests
echo "Step 2: Integration Tests"
# [プロジェクト固有の統合テストコマンド]

# 3. E2E Tests
echo "Step 3: E2E Tests"
EOF

    # E2Eテストコマンドを追加
    for framework in "${TEST_FRAMEWORKS[@]}"; do
        case "$framework" in
            *"Cypress"*)
                echo "npx cypress run" >> "$OUTPUT_FILE"
                break
                ;;
            *"Playwright"*)
                echo "npx playwright test" >> "$OUTPUT_FILE"
                break
                ;;
        esac
    done

    cat >> "$OUTPUT_FILE" << 'EOF'

# テスト結果判定
if [ $? -eq 0 ]; then
    echo "✅ 全テスト合格"
    TEST_RESULT="PASS"
else
    echo "❌ テスト失敗"
    TEST_RESULT="FAIL"
fi
```

### 3. テスト結果の処理
```bash
# ステータス更新
mkdir -p ./status

if [ "$TEST_RESULT" = "PASS" ]; then
    touch ./status/test_passed.txt
    rm -f ./status/test_failed.txt
    echo "$(date): テスト合格" > ./status/test_passed.txt
    
    # PMに合格報告
    chimera send pm "✅ テスト合格！要件を満たしています。全てのテストが正常に完了しました。"
    
else
    touch ./status/test_failed.txt
    rm -f ./status/test_passed.txt
    echo "$(date): テスト失敗" > ./status/test_failed.txt
    
    # 失敗詳細の取得（フレームワーク別）
EOF

    for framework in "${TEST_FRAMEWORKS[@]}"; do
        case "$framework" in
            *"Jest"*|*"Vitest"*)
                cat >> "$OUTPUT_FILE" << 'EOF'    
    # Jest/Vitest エラー詳細
    FAILURE_DETAILS="単体テストで失敗が検出されました。テスト結果を確認してください。"
EOF
                ;;
            *"Cypress"*)
                cat >> "$OUTPUT_FILE" << 'EOF'
    # Cypress エラー詳細
    FAILURE_DETAILS="E2Eテストで失敗が検出されました。Cypress Dashboardを確認してください。"
EOF
                ;;
        esac
        break
    done

    cat >> "$OUTPUT_FILE" << 'EOF'
    
    # コーダーに修正依頼
    chimera send coder "❌ テスト失敗: $FAILURE_DETAILS 修正をお願いします。"
fi
```
EOF
}

# プロジェクト固有のベストプラクティス生成
generate_best_practices_section() {
    cat >> "$OUTPUT_FILE" << 'EOF'

## 💡 プロジェクト固有のベストプラクティス

### テスト作成のガイドライン
EOF

    case "$PROJECT_TYPE" in
        *"React"*|*"Next.js"*)
            cat >> "$OUTPUT_FILE" << 'EOF'
- コンポーネントのpropsとstateをテスト
- ユーザーインタラクションのテスト
- API呼び出しのモック化
- アクセシビリティテストの実装
EOF
            ;;
        *"Vue"*)
            cat >> "$OUTPUT_FILE" << 'EOF'
- コンポーネントのpropsとemitsをテスト
- Composition APIのテスト
- ルーティングのテスト
- Vuexストアのテスト
EOF
            ;;
        *"python"*)
            cat >> "$OUTPUT_FILE" << 'EOF'
- 関数の入出力テスト
- 例外処理のテスト
- モック・パッチの活用
- データベースのテスト
EOF
            ;;
    esac

    cat >> "$OUTPUT_FILE" << EOF

### カバレッジ目標
- **Unit Tests**: 80%以上
- **Integration Tests**: 60%以上  
- **E2E Tests**: 主要フローをカバー

### テスト命名規則
EOF

    for framework in "${TEST_FRAMEWORKS[@]}"; do
        case "$framework" in
            *"Jest"*|*"Vitest"*)
                cat >> "$OUTPUT_FILE" << 'EOF'
- `*.test.js` または `*.spec.js`
- `__tests__/` ディレクトリ内
EOF
                ;;
            *"pytest"*)
                cat >> "$OUTPUT_FILE" << 'EOF'
- `test_*.py` または `*_test.py`
- `tests/` ディレクトリ内
EOF
                ;;
        esac
        break
    done
}

# ディレクトリ説明関数
describe_test_directory() {
    case "$1" in
        *"unit"*) echo "単体テスト用ディレクトリ" ;;
        *"integration"*) echo "統合テスト用ディレクトリ" ;;
        *"e2e"*) echo "E2Eテスト用ディレクトリ" ;;
        *"cypress"*) echo "Cypress E2Eテスト用ディレクトリ" ;;
        *"__tests__"*) echo "Jest/Vitest テスト用ディレクトリ" ;;
        *"spec"*) echo "仕様テスト用ディレクトリ" ;;
        *) echo "テストファイル用ディレクトリ" ;;
    esac
}

# 設定ファイル説明関数
describe_config_file() {
    case "$1" in
        jest.*) echo "Jest テストランナー設定" ;;
        vitest.*) echo "Vitest テストランナー設定" ;;
        cypress.*) echo "Cypress E2Eテスト設定" ;;
        playwright.*) echo "Playwright テスト設定" ;;
        pytest.*) echo "pytest 設定ファイル" ;;
        *) echo "テスト関連設定ファイル" ;;
    esac
}

# 各セクションを生成
generate_test_commands_section
generate_test_types_section
generate_pm_instruction_section  
generate_best_practices_section

echo "✅ テストマニュアル生成完了: $OUTPUT_FILE"
echo ""
echo "📋 生成された内容:"
echo "- プロジェクト固有のテストコマンド"
echo "- フレームワーク別実行方法"
echo "- PMとのコミュニケーションフロー"
echo "- ベストプラクティス"