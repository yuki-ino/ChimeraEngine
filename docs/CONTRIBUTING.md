# 🤝 Contributing to Chimera Engine

Chimera Engineへの貢献をありがとうございます！

## 🚀 クイック貢献

### バグ報告
```bash
# システム使用後のフィードバック収集
./feedback-collector.sh

# GitHub Issueで報告
https://github.com/yuki-ino/ChimeraEngine/issues/new
```

### 機能要望
- 新しいテストフレームワーク対応
- 新しいプログラミング言語対応
- ワークフロー改善提案

## 🛠️ 開発に参加

### 開発環境セットアップ
```bash
# リポジトリクローン
git clone https://github.com/yuki-ino/ChimeraEngine.git
cd ChimeraEngine

# 開発環境構築
./setup-chimera.sh

# テスト実行
./chimera send --list
```

### 開発フロー
```bash
# 1. ブランチ作成
git checkout -b feature/new-test-framework

# 2. 開発・テスト
vim project-analyzer.sh  # 新機能追加
./test-manual-generator.sh  # テスト

# 3. コミット
git add .
git commit -m "feat: Add support for Mocha test framework"

# 4. プッシュ・PR作成
git push origin feature/new-test-framework
gh pr create
```

## 📋 貢献エリア

### 🔧 テストフレームワーク対応
新しいフレームワークの追加:
- `project-analyzer.sh` に検出ロジック追加
- `test-manual-generator.sh` にテンプレート追加
- `test-framework-examples.md` にドキュメント追加

### 🎯 新しい役割の追加
例：DevOps役割
- `setup-chimera.sh` にセッション追加
- `instructions/devops.md` 作成
- `chimera-send.sh` にエージェント追加

### 📚 ドキュメント改善
- README.md の使用例追加
- 実プロジェクト事例の追加
- 多言語対応

### 🐛 バグ修正
- tmuxセッション管理の改善
- メッセージ送信の安定性向上
- エラーハンドリング強化

## 📝 コーディング規約

### Shell Script
```bash
# 関数名: snake_case
generate_test_commands() {
    local framework="$1"
    # 処理
}

# 変数名: UPPER_CASE (定数), lower_case (変数)
FRAMEWORK_LIST=("jest" "vitest" "cypress")
project_type="react"

# エラーハンドリング必須
if [ ! -f "$config_file" ]; then
    echo "❌ 設定ファイルが見つかりません: $config_file"
    return 1
fi
```

### Markdown
```markdown
# セクション構造
## 大見出し
### 中見出し
#### 小見出し

# コードブロック
```bash
# コメント付きのサンプルコード
./command --option
```

# 絵文字の使用
✅ 成功・完了
❌ エラー・失敗
⚠️ 警告・注意
💡 ヒント・アイデア
🚀 新機能・改善
```

## 🧪 テスト

### 手動テスト
```bash
# 基本機能テスト
./setup-chimera.sh
tmux list-sessions

# メッセージ送信テスト
./chimera send --list
./chimera send coder "テストメッセージ"

# プロジェクト解析テスト
mkdir test-project && cd test-project
echo '{"scripts":{"test":"jest"}}' > package.json
../project-analyzer.sh .
```

### 各種プロジェクトでのテスト
```bash
# React プロジェクトでテスト
npx create-react-app test-react
cd test-react
chimera init

# Python プロジェクトでテスト
mkdir test-python && cd test-python
echo "pytest" > requirements.txt
chimera init
```

## 📊 PR要件

### 必須チェック項目
- [ ] 既存機能を破壊していない
- [ ] 新機能にドキュメントを追加
- [ ] 手動テストで動作確認済み
- [ ] README.md に必要な更新

### PR説明テンプレート
```markdown
## 変更内容
- 新機能: XXXテストフレームワーク対応
- 改善: YYYの安定性向上

## テスト方法
```bash
# テスト手順
chimera init
# 期待結果: XXXが検出される
```

## 影響範囲
- project-analyzer.sh
- test-manual-generator.sh
- README.md

## チェックリスト
- [x] 手動テスト完了
- [x] ドキュメント更新
- [x] 既存機能確認
```

## 🌟 貢献者特典

### 認定
- README.md の貢献者リストに追加
- GitHub Contributorバッジ

### フィードバック
- 新機能の早期アクセス
- 開発方針の相談・意見交換

## 📞 コミュニケーション

### GitHub Issues
- バグ報告
- 機能要望
- 質問・相談

### 実装相談
- 大きな変更前の相談歓迎
- 設計方針の議論

---

**すべての貢献に感謝します！** 🙏

小さな改善から大きな新機能まで、どんな貢献も歓迎です。