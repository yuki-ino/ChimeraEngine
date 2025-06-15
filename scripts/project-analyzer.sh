#!/bin/bash

# 🔍 プロジェクト解析ツール - テスト環境自動検出
# init時にプロジェクトのテスト構成を分析し、テスターに最適な情報を提供

PROJECT_DIR="${1:-.}"
OUTPUT_DIR="$PROJECT_DIR/instructions"
ANALYSIS_FILE="$PROJECT_DIR/.chimera/project-analysis.json"

# 色付きログ
log_info() { echo -e "\033[1;32m[INFO]\033[0m $1"; }
log_detect() { echo -e "\033[1;33m[DETECT]\033[0m $1"; }
log_success() { echo -e "\033[1;34m[SUCCESS]\033[0m $1"; }

echo "🔍 プロジェクト解析開始..."
echo "対象: $PROJECT_DIR"
echo ""

# ディレクトリ作成
mkdir -p "$PROJECT_DIR/.chimera"
mkdir -p "$OUTPUT_DIR"

# 解析結果を格納するJSON初期化
cat > "$ANALYSIS_FILE" << 'EOF'
{
  "project_type": "",
  "test_frameworks": [],
  "test_directories": [],
  "test_commands": [],
  "config_files": [],
  "package_manager": "",
  "tech_stack": [],
  "recommendations": []
}
EOF

# JSON更新関数
update_json() {
    local key="$1"
    local value="$2"
    local type="${3:-string}"
    
    if [ "$type" = "array" ]; then
        jq --arg key "$key" --arg value "$value" '.[$key] += [$value]' "$ANALYSIS_FILE" > tmp.$$ && mv tmp.$$ "$ANALYSIS_FILE"
    else
        jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$ANALYSIS_FILE" > tmp.$$ && mv tmp.$$ "$ANALYSIS_FILE"
    fi
}

# パッケージマネージャー検出
detect_package_manager() {
    log_info "パッケージマネージャーを検出中..."
    
    if [ -f "$PROJECT_DIR/package.json" ]; then
        log_detect "Node.js プロジェクト (npm/yarn/pnpm)"
        update_json "package_manager" "npm"
        
        if [ -f "$PROJECT_DIR/yarn.lock" ]; then
            update_json "package_manager" "yarn"
        elif [ -f "$PROJECT_DIR/pnpm-lock.yaml" ]; then
            update_json "package_manager" "pnpm"
        fi
        
        # package.jsonからテスト関連情報を抽出
        if command -v jq &> /dev/null; then
            # テストスクリプト検出
            test_scripts=$(jq -r '.scripts | to_entries[] | select(.key | test("test|spec|e2e|jest|vitest|cypress")) | "\(.key): \(.value)"' "$PROJECT_DIR/package.json" 2>/dev/null)
            while IFS= read -r script; do
                [ -n "$script" ] && update_json "test_commands" "$script" "array"
            done <<< "$test_scripts"
            
            # 依存関係からテストフレームワーク検出
            deps=$(jq -r '.dependencies + .devDependencies | keys[]' "$PROJECT_DIR/package.json" 2>/dev/null)
            while IFS= read -r dep; do
                case "$dep" in
                    "jest"|"@jest/*") update_json "test_frameworks" "Jest" "array" ;;
                    "vitest") update_json "test_frameworks" "Vitest" "array" ;;
                    "cypress") update_json "test_frameworks" "Cypress" "array" ;;
                    "playwright"|"@playwright/*") update_json "test_frameworks" "Playwright" "array" ;;
                    "mocha") update_json "test_frameworks" "Mocha" "array" ;;
                    "chai") update_json "test_frameworks" "Chai" "array" ;;
                    "@testing-library/*") update_json "test_frameworks" "Testing Library" "array" ;;
                    "supertest") update_json "test_frameworks" "Supertest" "array" ;;
                    "selenium-webdriver") update_json "test_frameworks" "Selenium" "array" ;;
                esac
            done <<< "$deps"
        fi
        
    elif [ -f "$PROJECT_DIR/requirements.txt" ] || [ -f "$PROJECT_DIR/pyproject.toml" ]; then
        log_detect "Python プロジェクト (pip/poetry/conda)"
        update_json "package_manager" "pip"
        update_json "project_type" "python"
        
        # Python テストフレームワーク検出
        if grep -q "pytest" "$PROJECT_DIR/requirements.txt" 2>/dev/null; then
            update_json "test_frameworks" "pytest" "array"
        fi
        if grep -q "unittest" "$PROJECT_DIR"/*.py 2>/dev/null; then
            update_json "test_frameworks" "unittest" "array"
        fi
        
    elif [ -f "$PROJECT_DIR/Cargo.toml" ]; then
        log_detect "Rust プロジェクト (cargo)"
        update_json "package_manager" "cargo"
        update_json "project_type" "rust"
        update_json "test_commands" "cargo test" "array"
        
    elif [ -f "$PROJECT_DIR/go.mod" ]; then
        log_detect "Go プロジェクト"
        update_json "package_manager" "go"
        update_json "project_type" "go"
        update_json "test_commands" "go test ./..." "array"
        
    elif [ -f "$PROJECT_DIR/pom.xml" ]; then
        log_detect "Java Maven プロジェクト"
        update_json "package_manager" "maven"
        update_json "project_type" "java"
        update_json "test_commands" "mvn test" "array"
        
    elif [ -f "$PROJECT_DIR/build.gradle" ] || [ -f "$PROJECT_DIR/build.gradle.kts" ]; then
        log_detect "Java/Kotlin Gradle プロジェクト"
        update_json "package_manager" "gradle"
        update_json "project_type" "java"
        update_json "test_commands" "./gradlew test" "array"
    fi
}

# テストディレクトリ検出
detect_test_directories() {
    log_info "テストディレクトリを検出中..."
    
    common_test_dirs=(
        "test" "tests" "__tests__" "spec" "specs"
        "e2e" "integration" "unit" "cypress"
        "src/test" "src/tests" "src/__tests__"
        "test/unit" "test/integration" "test/e2e"
        "tests/unit" "tests/integration" "tests/e2e"
    )
    
    for dir in "${common_test_dirs[@]}"; do
        if [ -d "$PROJECT_DIR/$dir" ]; then
            log_detect "テストディレクトリ: $dir"
            update_json "test_directories" "$dir" "array"
        fi
    done
}

# 設定ファイル検出
detect_config_files() {
    log_info "設定ファイルを検出中..."
    
    config_files=(
        "jest.config.js" "jest.config.ts" "jest.config.json"
        "vitest.config.js" "vitest.config.ts"
        "cypress.config.js" "cypress.config.ts" "cypress.json"
        "playwright.config.js" "playwright.config.ts"
        "mocha.opts" ".mocharc.json" ".mocharc.js"
        "karma.conf.js"
        "protractor.conf.js"
        "wdio.conf.js"
        "pytest.ini" "pyproject.toml" "tox.ini"
        "phpunit.xml" "phpunit.xml.dist"
    )
    
    for config in "${config_files[@]}"; do
        if [ -f "$PROJECT_DIR/$config" ]; then
            log_detect "設定ファイル: $config"
            update_json "config_files" "$config" "array"
        fi
    done
}

# プロジェクトタイプ推定
detect_project_type() {
    log_info "プロジェクトタイプを推定中..."
    
    if [ -f "$PROJECT_DIR/next.config.js" ] || [ -f "$PROJECT_DIR/next.config.ts" ]; then
        update_json "project_type" "Next.js"
        update_json "tech_stack" "Next.js" "array"
    elif [ -f "$PROJECT_DIR/nuxt.config.js" ] || [ -f "$PROJECT_DIR/nuxt.config.ts" ]; then
        update_json "project_type" "Nuxt.js"
        update_json "tech_stack" "Nuxt.js" "array"
    elif [ -f "$PROJECT_DIR/angular.json" ]; then
        update_json "project_type" "Angular"
        update_json "tech_stack" "Angular" "array"
    elif [ -f "$PROJECT_DIR/vue.config.js" ] || grep -q "vue" "$PROJECT_DIR/package.json" 2>/dev/null; then
        update_json "project_type" "Vue.js"
        update_json "tech_stack" "Vue.js" "array"
    elif grep -q "react" "$PROJECT_DIR/package.json" 2>/dev/null; then
        update_json "project_type" "React"
        update_json "tech_stack" "React" "array"
    elif [ -f "$PROJECT_DIR/svelte.config.js" ]; then
        update_json "project_type" "Svelte"
        update_json "tech_stack" "Svelte" "array"
    fi
    
    # TypeScript検出
    if [ -f "$PROJECT_DIR/tsconfig.json" ]; then
        update_json "tech_stack" "TypeScript" "array"
    fi
}

# 推奨事項生成
generate_recommendations() {
    log_info "推奨事項を生成中..."
    
    # テストフレームワークが未検出の場合
    frameworks=$(jq -r '.test_frameworks | length' "$ANALYSIS_FILE")
    if [ "$frameworks" -eq 0 ]; then
        project_type=$(jq -r '.project_type' "$ANALYSIS_FILE")
        case "$project_type" in
            *"React"*|*"Next.js"*)
                update_json "recommendations" "Jest + Testing Library の導入を推奨" "array"
                ;;
            *"Vue"*)
                update_json "recommendations" "Vue Test Utils + Jest の導入を推奨" "array"
                ;;
            *"python"*)
                update_json "recommendations" "pytest の導入を推奨" "array"
                ;;
            *)
                update_json "recommendations" "適切なテストフレームワークの導入を推奨" "array"
                ;;
        esac
    fi
    
    # E2Eテストの推奨
    has_e2e=$(jq -r '.test_directories[] | select(. | test("e2e|cypress|playwright"))' "$ANALYSIS_FILE" | wc -l)
    if [ "$has_e2e" -eq 0 ]; then
        update_json "recommendations" "E2Eテスト環境の構築を推奨 (Playwright/Cypress)" "array"
    fi
}

# メイン実行
detect_package_manager
detect_test_directories
detect_config_files
detect_project_type
generate_recommendations

log_success "✅ プロジェクト解析完了"
echo ""
echo "📊 解析結果:"
jq . "$ANALYSIS_FILE"

echo ""
echo "📄 解析結果ファイル: $ANALYSIS_FILE"