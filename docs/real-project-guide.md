# 🚀 実プロジェクトでPM/Dev/QAシステムを使う方法

## 📋 クイックスタート

### 1. システムを実プロジェクトにコピー

```bash
# 実プロジェクトのルートディレクトリで実行
cd /path/to/your/actual/project

# 必要なファイルをコピー
cp /path/to/Claude-Code-Communication/setup-chimera.sh .
cp /path/to/Claude-Code-Communication/chimera-send.sh .
cp -r /path/to/Claude-Code-Communication/instructions .

# 実行権限付与
chmod +x setup-chimera.sh
```

### 2. プロジェクトに合わせてカスタマイズ

#### A. 指示書の編集

```bash
# PM指示書をプロジェクトに合わせて編集
vim instructions/pm.md
```

例：Webアプリケーション開発の場合
```markdown
# 🎯 PM指示書 - ECサイト構築プロジェクト

## 初期指示
```bash
# フロントエンド開発者への指示
chimera send coder "商品一覧ページのUIを実装してください。React + TypeScriptで、APIエンドポイント /api/products を使用"

# バックエンド開発者への指示（coderを複数起動する場合）
chimera send coder "商品一覧APIを実装してください。GET /api/products, ページネーション対応"

# テスターへの指示
chimera send qa-functional "商品一覧機能のE2Eテストを準備してください。Cypress使用"
```

#### B. 実際のコマンドを組み込む

```bash
# instructions/coder.md の編集
vim instructions/coder.md
```

```markdown
## 実装作業
```bash
# 実際の開発コマンド
npm run dev
git checkout -b feature/product-list

# 実装...
npm test
npm run build

# 完了通知
chimera send qa-functional "実装完了。ブランチ: feature/product-list"
```

### 3. ワークフローの拡張

#### 複数コーダー対応版のセットアップ

```bash
# setup-chimera-multi.sh を作成
#!/bin/bash

# フロントエンド、バックエンド、インフラの3人体制
tmux new-session -d -s chimera-workspace
tmux split-window -h
tmux split-window -v
tmux select-pane -t 0
tmux split-window -v

# ペイン割り当て
# 0: frontend-dev
# 1: backend-dev  
# 2: infra-dev
# 3: tester
```

## 🔄 フィードバックループの実装

### 1. 使用経験の記録

```bash
# プロジェクト終了後または定期的に実行
./feedback-collector.sh
```

### 2. 改善案の実装

フィードバックを基に:
- 新しい指示書テンプレートを作成
- ワークフローの最適化
- 自動化の追加

### 3. システムへの反映

```bash
# 改善した設定を本体にフィードバック
cp instructions/pm.md /path/to/Claude-Code-Communication/instructions/pm-improved.md
```

## 📊 実践例

### 例1: Reactアプリ開発

```bash
# プロジェクト固有の設定
cat > .chimera-config << EOF
PROJECT_NAME="MyReactApp"
TECH_STACK="React, TypeScript, Vite"
TEST_FRAMEWORK="Vitest, Playwright"
EOF

# 指示書に反映
source .chimera-config
envsubst < instructions/coder.md > instructions/coder-react.md
```

### 例2: API開発プロジェクト

```bash
# API専用のワークフロー
chimera send coder "POST /users エンドポイントを実装"
chimera send qa-functional "Postmanでテストスイート作成"
```

## 🛠️ トラブルシューティング

### よくある課題と解決策

1. **tmuxセッションの競合**
   ```bash
   # プロジェクトごとに異なるセッション名を使用
   sed -i 's/chimera-workspace/myapp-workspace/g' setup-chimera.sh
   ```

2. **複数プロジェクトの並行実行**
   ```bash
   # プロジェクトごとにポート番号を変える
   export CHIMERA_PROJECT_ID="project1"
   ```

3. **実コマンドとの統合**
   ```bash
   # CI/CDパイプラインとの連携
   chimera send monitor "CI/CDパイプライン起動: $(git rev-parse HEAD)"
   ```

## 📈 効果測定

### メトリクスの収集

```bash
# 開発効率の測定
- タスク完了時間
- 修正サイクル数
- コミュニケーション頻度

# 品質指標
- バグ発見率
- テストカバレッジ
- リリース頻度
```

## 🔮 発展的な使い方

1. **GitHubとの統合**
   ```bash
   # PR作成時に自動でテスターに通知
   gh pr create --title "Feature X" --body "実装完了"
   chimera send qa-functional "PR #123 のレビューとテストをお願いします"
   ```

2. **Slackへの通知**
   ```bash
   # 重要なイベントをSlackに通知
   curl -X POST $SLACK_WEBHOOK -d '{"text":"テスト完了: 全項目合格"}'
   ```

3. **自動化の追加**
   ```bash
   # ファイル監視で自動テスト
   fswatch -o src/ | xargs -n1 -I{} chimera send qa-functional "ファイル変更検知、自動テスト開始"
   ```

## 💡 ベストプラクティス

1. **小さく始める**: まず1つの機能開発で試す
2. **段階的に拡張**: 成功体験を積んでから複雑化
3. **チームで改善**: 全員でフィードバックを共有
4. **ドキュメント化**: 成功パターンを記録

---

このガイドを参考に、実プロジェクトでPM/Dev/QAシステムを活用してください！
フィードバックは `./feedback-collector.sh` で収集し、継続的な改善につなげましょう。