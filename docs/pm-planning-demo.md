# 🎯 PM企画検討モード - 使用例

## 📋 現在の問題点
従来のシステム：
```bash
# PMが起動すると即座にチームに指示
./chimera-send.sh coder "実装してください"  # 企画未確定なのに指示
./chimera-send.sh tester "テストしてください"  # 要件が曖昧
```

## ✅ 改良版の動作

### 1. 初期状態 - 企画検討モード
```bash
# PM起動時
chimera init
chimera start

# PMウィンドウで
"あなたはPMです。指示書に従って"

# 出力例:
🎯 PM企画検討モードを開始します
================================
現在のステータス: 企画検討中

📋 検討項目:
- 機能要件の詳細化
- 技術方針の決定
- 優先順位の確定
- リスクの洗い出し

💡 企画が固まったら以下のコマンドで開発開始:
   chimera send pm-self 'START_DEVELOPMENT'
```

### 2. 企画検討中の行動
```bash
# PMは自由に検討・会話
🤔 "ログイン機能の仕様について検討中..."
🤔 "OAuth対応が必要か？パスワードリセット機能は？"
🤔 "セキュリティ要件を整理しよう"

# この間、コーダー・テスターには何も送信されない
```

### 3. PMモードコントローラーの活用
```bash
# PMダッシュボード確認
./pm-mode-controller.sh dashboard

# 出力例:
🎯 PM ダッシュボード
====================
現在のモード: PLANNING
日時: 2024-01-20 15:30:00

🤔 ステータス: 企画検討中
説明: コーダー・テスターには指示を送信していません
検討時間: 2時間30分

📝 企画検討チェックリスト:
□ ビジネス価値の明確化
□ ユーザーストーリーの定義
□ 技術要件の整理
...

💡 コマンド:
  ./pm-mode-controller.sh add-note "検討内容"
  ./pm-mode-controller.sh finalize-planning
```

### 4. 検討メモの追加
```bash
# 企画検討中の思考を記録
./pm-mode-controller.sh add-note "OAuth 2.0の導入を検討。Google/GitHub認証を優先"
./pm-mode-controller.sh add-note "パスワードリセット機能は Phase 2 で実装"
./pm-mode-controller.sh add-note "セキュリティ監査は外部委託予定"
```

### 5. 企画確定・開発開始
```bash
# 十分な検討後、企画を確定
./pm-mode-controller.sh finalize-planning

# 確認画面:
🔍 企画確定前の最終チェック
以下の項目を確認してください:
□ ビジネス価値の明確化
□ ユーザーストーリーの定義
□ 技術要件の整理
...

すべて完了していますか? (y/N): y

# 確定後の自動処理:
🚀 企画が確定し、開発モードを開始しました
チームに開発指示を送信します...

✅ 開発指示を送信しました
```

### 6. 開発モード中のPM
```bash
# 進捗確認
./pm-mode-controller.sh check-progress

# 出力例:
📊 プロジェクト進捗確認
======================
✅ コーディング: 完了
⏳ テスト: 進行中

💬 最新のチーム連絡:
[2024-01-20 16:45] coder → tester: 実装完了しました
[2024-01-20 16:50] tester → coder: テスト中、1件不具合発見
[2024-01-20 17:00] coder → tester: 修正完了、再テストお願いします
```

## 🔄 実際の使用フロー

### シナリオ: ECサイトの商品検索機能開発

#### Phase 1: 企画検討（2時間）
```bash
# 15:00 PM起動
"あなたはPMです。指示書に従って"

# 15:00-17:00 企画検討
🤔 "商品検索機能の要件を整理しよう"
🤔 "全文検索？カテゴリ検索？フィルタリング？"
🤔 "検索速度の要件は？1秒以内？"
🤔 "Elasticsearch導入するか？"

./pm-mode-controller.sh add-note "全文検索＋カテゴリフィルタで開始"
./pm-mode-controller.sh add-note "検索速度目標: 500ms以内"
./pm-mode-controller.sh add-note "Elasticsearch Phase 2で検討"

# コーダー・テスターは待機中（指示なし）
```

#### Phase 2: 企画確定・開発開始（17:00）
```bash
# 17:00 企画確定
./pm-mode-controller.sh finalize-planning

# チームに指示送信
chimera send coder "商品検索機能を実装してください。要件：..."
chimera send qa-functional "商品検索機能のテスト準備をお願いします。..."
```

#### Phase 3: 開発進行中（17:00-19:00）
```bash
# PMは進捗監視と意思決定に集中
./pm-mode-controller.sh check-progress

# 必要に応じて要件変更
chimera send coder "要件変更: ソート機能も追加してください"
```

## 💡 効果とメリット

### 1. **情報漏洩防止**
- 企画検討中はチームに情報が流れない
- 機密性の高い企画を安全に検討可能

### 2. **無駄な作業の防止**
- 企画が固まってから開発指示
- 手戻り・やり直しを最小化

### 3. **PM思考の可視化**
- 検討プロセスの記録
- 意思決定根拠の保存

### 4. **段階的な情報開示**
- 適切なタイミングでの情報共有
- チームの混乱を防止

## 🚀 次のステップ

1. **PM指示書の切り替え**
   ```bash
   cp instructions/pm.md instructions/pm-original.md
   cp instructions/pm-improved.md instructions/pm.md
   ```

2. **PMモードコントローラーの統合**
   ```bash
   # 自動起動設定
   echo "./pm-mode-controller.sh start-planning" >> setup-chimera.sh
   ```

3. **チーム用待機メッセージの追加**
   ```bash
   # coder/tester 用の待機指示書
   echo "PM企画検討中です。指示をお待ちください" > instructions/standby-message.md
   ```

これで**PMが安心して企画を練れる**環境が完成しました！