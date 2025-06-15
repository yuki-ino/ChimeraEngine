# 🧪 テストフレームワーク対応例

テストマニュアル自動生成で対応しているフレームワークとプロジェクト例

## ✅ 対応済みフレームワーク

### JavaScript/TypeScript

#### 1. **Jest** - Reactプロジェクト
```json
// package.json の例
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "@testing-library/react": "^13.0.0"
  }
}
```

**生成されるテストマニュアル例:**
- Reactコンポーネントテストの方法
- モック作成手順  
- カバレッジ測定コマンド

#### 2. **Vitest** - Vue/Vitプロジェクト
```json
// package.json の例
{
  "scripts": {
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage"
  },
  "devDependencies": {
    "vitest": "^0.34.0",
    "@vue/test-utils": "^2.4.0"
  }
}
```

#### 3. **Cypress** - E2Eテスト
```json
// package.json の例
{
  "scripts": {
    "cypress:open": "cypress open",
    "cypress:run": "cypress run"
  },
  "devDependencies": {
    "cypress": "^13.0.0"
  }
}
```

**生成されるマニュアル:**
- E2Eテストシナリオの実行方法
- 画面録画・スクリーンショット取得
- ブラウザ別テスト実行

#### 4. **Playwright** - モダンE2E
```json
// package.json の例
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui"
  },
  "devDependencies": {
    "@playwright/test": "^1.40.0"
  }
}
```

### Python

#### 5. **pytest** - Pythonプロジェクト
```ini
# pytest.ini の例
[tool:pytest]
testpaths = tests
python_files = test_*.py *_test.py
python_classes = Test*
python_functions = test_*
addopts = --verbose --cov=src
```

**生成されるマニュアル:**
- pytest実行オプション
- フィクスチャ活用方法
- カバレッジレポート生成

### その他言語

#### 6. **Cargo Test** - Rustプロジェクト
```toml
# Cargo.toml の例
[package]
name = "my-rust-app"

[dev-dependencies]
tokio-test = "0.4"
```

#### 7. **Go Test** - Goプロジェクト
```bash
# 検出されるテストコマンド
go test ./...
go test -v ./...
go test -cover ./...
```

## 🎯 プロジェクトタイプ別の最適化

### React + TypeScript プロジェクト
**検出内容:**
- テストフレームワーク: Jest, Testing Library
- 設定ファイル: jest.config.ts, tsconfig.json
- テストディレクトリ: src/__tests__, src/components/__tests__

**生成されるマニュアル:**
- コンポーネントのprops/stateテスト
- カスタムフックのテスト
- MSWを使ったAPIモック

### Next.js プロジェクト
**検出内容:**
- フレームワーク: Jest + Cypress/Playwright
- 設定: next.config.js, jest.config.js
- E2Eテスト: Cypress統合

**生成されるマニュアル:**
- SSR/SSGページのテスト
- API Routesのテスト
- E2Eシナリオテスト

### Vue 3 + Composition API
**検出内容:**
- テストフレームワーク: Vitest, Vue Test Utils
- 設定: vitest.config.ts, vite.config.ts

**生成されるマニュアル:**
- Composition APIのテスト
- Piniaストアテスト
- コンポーネント間連携テスト

## 📊 自動検出の仕組み

### 1. **ファイル検出**
```bash
# 検出対象ファイル
package.json          → npm/yarn/pnpm + フレームワーク
requirements.txt      → Python + pytest
Cargo.toml           → Rust + cargo test
go.mod               → Go + go test
pom.xml              → Java + Maven
build.gradle         → Java/Kotlin + Gradle
```

### 2. **ディレクトリ構造解析**
```bash
# 検出対象ディレクトリ
tests/               → 汎用テストディレクトリ
__tests__/           → Jest形式
cypress/             → Cypress E2E
e2e/                 → E2Eテスト
spec/                → 仕様テスト
src/test/            → Java形式
```

### 3. **設定ファイル識別**
```bash
# テストフレームワーク設定
jest.config.*        → Jest設定
vitest.config.*      → Vitest設定
cypress.config.*     → Cypress設定
playwright.config.*  → Playwright設定
pytest.ini           → pytest設定
```

## 🚀 使用例

### Reactプロジェクトでの初期化
```bash
# 1. プロジェクトに移動
cd my-react-app

# 2. PM/Dev/QA初期化（自動解析実行）
chimera init

# 検出結果例:
# ✅ React + TypeScript プロジェクトを検出
# ✅ Jest + Testing Library を検出
# ✅ カスタムテストマニュアルを生成
# ✅ src/__tests__ ディレクトリを検出
```

### 生成されるテスター指示書（抜粋）
```markdown
# 🧪 Tester指示書 - React プロジェクト

## 🚀 テスト実行コマンド
```bash
# Jest テスト実行
npm test                    # 全テスト実行
npm test -- --watch         # ウォッチモード
npm test -- --coverage     # カバレッジ付き
```

## 🎭 テストタイプ別実行
### Unit Tests (単体テスト)
```bash
# React コンポーネントテスト
npm test -- --testPathPattern="components"
npm test -- --testNamePattern="Component"
```

## 📥 PMから指示を受けた時の実行内容
```bash
# 実際のプロジェクトに合わせたコマンドが自動生成
npm install
npm test
# [結果に基づく条件分岐...]
```

これにより、**init一発で**そのプロジェクトに最適化されたテスト環境がセットアップされます！