#!/bin/bash

# 🚀 実プロジェクト用設定スクリプト
# このスクリプトで実際のプロジェクトに合わせた設定を生成

# プロジェクト名を引数から取得
PROJECT_NAME="${1:-myproject}"
PROJECT_DIR="${2:-.}"

echo "🔧 プロジェクト設定生成: $PROJECT_NAME"
echo "================================"

# プロジェクト用ディレクトリ作成
mkdir -p "$PROJECT_DIR/.chimera"
mkdir -p "$PROJECT_DIR/.chimera/instructions"
mkdir -p "$PROJECT_DIR/.chimera/templates"

# プロジェクト設定ファイル作成
cat > "$PROJECT_DIR/.chimera/config.yaml" << EOF
# PM/Dev/QA Configuration for $PROJECT_NAME
project:
  name: $PROJECT_NAME
  type: web_application  # web_application, cli_tool, library, etc.

# エージェント設定
agents:
  pm:
    session: pmproject
    role: "プロダクトマネージャー"
    tasks:
      - "要件定義"
      - "進捗管理"
      - "リリース判定"
  
  coder:
    session: devqa:0.0
    role: "開発者"
    tasks:
      - "機能実装"
      - "バグ修正"
      - "コードレビュー対応"
  
  tester:
    session: devqa:0.1
    role: "QAエンジニア"
    tasks:
      - "テスト設計"
      - "テスト実行"
      - "バグ報告"

# ワークフロー設定
workflow:
  phases:
    - name: "要件定義"
      owner: pm
      outputs: ["requirements.md"]
    
    - name: "実装"
      owner: coder
      inputs: ["requirements.md"]
      outputs: ["implementation_done.txt"]
    
    - name: "テスト"
      owner: tester
      inputs: ["implementation_done.txt"]
      outputs: ["test_report.md"]

# プロジェクト固有の設定
project_specific:
  # ここに実際のプロジェクトの詳細を追加
  tech_stack: []
  test_framework: ""
  coding_standards: ""
EOF

echo "✅ 設定ファイル作成: .chimera/config.yaml"

# カスタマイズ可能な指示書テンプレート作成
cat > "$PROJECT_DIR/.chimera/templates/pm_template.md" << 'EOF'
# 🎯 PM指示書テンプレート - {{PROJECT_NAME}}

## プロジェクト概要
{{PROJECT_DESCRIPTION}}

## あなたの役割
{{PM_ROLE_DESCRIPTION}}

## 実行タスク
1. **要件定義フェーズ**
   ```bash
   # 開発者への指示
   chimera send coder "{{IMPLEMENTATION_TASK}}"
   
   # テスターへの指示
   chimera send qa-functional "{{TEST_PREPARATION_TASK}}"
   ```

2. **進捗管理**
   - {{PROGRESS_TRACKING_METHOD}}

3. **完了確認**
   - {{COMPLETION_CRITERIA}}

## カスタムコマンド
{{CUSTOM_COMMANDS}}
EOF

cat > "$PROJECT_DIR/.chimera/templates/coder_template.md" << 'EOF'
# 👨‍💻 Coder指示書テンプレート - {{PROJECT_NAME}}

## 実装タスク
{{IMPLEMENTATION_DETAILS}}

## 技術スタック
{{TECH_STACK}}

## コーディング規約
{{CODING_STANDARDS}}

## 実装フロー
1. **実装開始**
   ```bash
   echo "🚀 実装開始: {{FEATURE_NAME}}"
   # 実際のコーディング作業
   {{ACTUAL_CODING_COMMANDS}}
   ```

2. **実装完了通知**
   ```bash
   chimera send qa-functional "実装完了: {{COMPLETION_MESSAGE}}"
   ```

3. **修正対応**
   {{BUG_FIX_PROCESS}}
EOF

cat > "$PROJECT_DIR/.chimera/templates/tester_template.md" << 'EOF'
# 🧪 Tester指示書テンプレート - {{PROJECT_NAME}}

## テスト戦略
{{TEST_STRATEGY}}

## テストケース
{{TEST_CASES}}

## テスト実行
1. **テスト準備**
   ```bash
   {{TEST_SETUP_COMMANDS}}
   ```

2. **テスト実行**
   ```bash
   {{TEST_EXECUTION_COMMANDS}}
   ```

3. **結果報告**
   - 合格時: `chimera send pm "{{PASS_MESSAGE}}"`
   - 失敗時: `chimera send coder "{{FAIL_MESSAGE}}"`

## 品質基準
{{QUALITY_CRITERIA}}
EOF

echo "✅ テンプレート作成完了"

# 実プロジェクト用のセットアップスクリプト生成
cat > "$PROJECT_DIR/.chimera/setup-project.sh" << 'EOF'
#!/bin/bash

# プロジェクト固有のセットアップ
echo "🚀 プロジェクト環境構築"

# 既存のChimera環境を利用
../setup-chimera.sh

# プロジェクト固有の初期化
mkdir -p ./docs
mkdir -p ./tests
mkdir -p ./src

echo "✅ プロジェクト環境準備完了"
EOF

chmod +x "$PROJECT_DIR/.chimera/setup-project.sh"

echo ""
echo "📋 次のステップ:"
echo "1. 設定をカスタマイズ: vim .chimera/config.yaml"
echo "2. テンプレートを編集: vim .chimera/templates/*.md"
echo "3. 実際の指示書を生成: ./generate-instructions.sh"
echo "4. プロジェクト開始: ./.chimera/setup-project.sh"