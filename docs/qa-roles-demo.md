# 🧪 QA役割分化システム - 使用例

## 🎯 新しいチーム構成

### 従来（3人体制）
```
👨‍💼 PM + 👨‍💻 Coder + 🧪 Tester
```

### 改良版（5人体制）
```
👨‍💼 PM (企画・管理)
👨‍💻 Coder (フルスタック開発)
🧪 QA-Functional (機能テスト担当)
👑 QA-Lead (QA総合判定・品質管理)
📊 Monitor (ステータス監視)
```

## 🔄 実際のワークフロー例

### シナリオ: ログイン機能の開発・テスト

#### Phase 1: PM企画・指示
```bash
# PM起動
"あなたはPMです。指示書に従って"

# 企画検討後、開発指示
chimera send coder "ログイン機能を実装してください"
chimera send qa-functional "ログイン機能のテスト準備をお願いします"
chimera send qa-lead "品質計画を策定してください"
```

#### Phase 2: 開発実装
```bash
# Coder (フルスタック開発者)
echo "👨‍💻 フロントエンド実装中..."
echo "👨‍💻 バックエンドAPI実装中..."
echo "👨‍💻 モバイル対応実装中..."

# 実装完了通知
chimera send qa-functional "実装完了しました。テストをお願いします"
```

#### Phase 3: 機能テスト（詳細）
```bash
# QA-Functional (機能テスト担当)
echo "🧪 機能テスト開始"
echo "Phase 1: 基本機能テスト"
echo "Test 1.1: 正常ログイン ... ✓ PASS"
echo "Test 1.2: 無効パスワード ... ✗ FAIL - エラーメッセージ不適切"
echo "Test 1.3: SQLインジェクション ... ✗ FAIL - 脆弱性あり"

# バグレポート作成
📄 ./reports/bug_report_20240120_150000.md
### Bug #1: エラーメッセージが不適切
### Bug #2: SQLインジェクション脆弱性

# QA-Leadに報告
chimera send qa-lead "機能テストでバグを発見しました。セキュリティリスクあり"

# Coderに修正依頼
chimera send coder "❌ 重要バグ発見: SQLインジェクション脆弱性"
```

#### Phase 4: QA総合判定・トリアージ
```bash
# QA-Lead (品質管理・リリース判定)
echo "🔍 バグ重要度評価開始"
echo "🚨 Critical: SQLインジェクション脆弱性"
echo "⚠️ Medium: エラーメッセージ改善"

# トリアージ結果
📄 ./quality/triage_report_20240120_151000.md
## バグ重要度評価
- **重要度**: Critical
- **リスクレベル**: High  
- **リリース影響**: Block

# PMにエスカレーション
chimera send pm "🚨 重要バグ検出: リリースブロックを推奨"

# Coderに緊急修正依頼
chimera send coder "🚨 緊急修正要請: セキュリティ脆弱性です"
```

#### Phase 5: 修正・再テスト
```bash
# Coder修正
echo "👨‍💻 SQLインジェクション脆弱性修正中..."
echo "👨‍💻 エラーメッセージ改善中..."

# 修正完了通知
chimera send qa-functional "修正完了しました。再テストお願いします"

# QA-Functional再テスト
echo "🔄 修正版の再テスト開始"
echo "✅ SQLインジェクション: 修正確認"
echo "✅ エラーメッセージ: 改善確認"
echo "✅ 全機能テスト: 合格"

# QA-Leadに合格報告
chimera send qa-lead "✅ 機能テスト合格しました。最終判定お願いします"
```

#### Phase 6: 最終品質判定
```bash
# QA-Lead最終判定
echo "🏁 最終品質判定開始"
echo "📊 品質メトリクス確認"
echo "✅ 機能性: 合格"
echo "✅ 信頼性: 重大バグなし"
echo "✅ セキュリティ: 問題なし"
echo "✅ 性能: 基準クリア"

echo "📊 総合品質スコア: 85/100"
echo "🎉 リリース承認: 品質基準を満たしています"

# PM・全チームに承認通知
chimera send pm "🎉 最終品質判定: リリース承認"
chimera send coder "🎉 お疲れ様でした！リリース承認されました"
chimera send qa-functional "✅ 機能テストお疲れ様でした"
```

## 🆚 従来との比較

### 従来システムの問題
```bash
# 1人のテスターが全てを担当
🧪 Tester: "テスト実行 → バグ発見 → 重要度判定 → リリース判定"
→ 責任が重すぎる
→ 専門性が分散
→ 判定基準が曖昧
```

### 改良版の利点
```bash
# 役割分担で専門性向上
🧪 QA-Functional: 機能テストに集中
→ 詳細なテストケース実行
→ バグ検出能力向上
→ 再現手順の明確化

👑 QA-Lead: 品質管理に集中  
→ リスク評価・トリアージ
→ 品質基準の管理
→ ビジネス影響の判断
```

## 📊 実際の効果

### 1. **品質向上**
- **バグ検出率**: 詳細テストで見逃し減少
- **リスク管理**: 重要度に応じた適切な対応
- **品質基準**: 一貫した判定基準

### 2. **効率化**
- **専門分業**: 各自の得意分野に集中
- **並行作業**: QA-Leadが品質計画中にQA-Functionalがテスト準備
- **明確な責任**: 役割分担で責任の所在が明確

### 3. **コミュニケーション改善**
- **構造化された報告**: バグレポート→トリアージ→判定の流れ
- **エスカレーション**: 重要度に応じた適切な報告先
- **透明性**: 全プロセスが可視化

## 🚀 使用方法

### 1. 環境構築
```bash
# Chimera版セットアップ
chimera start

# Claude Code起動
for i in {0..4}; do tmux send-keys -t chimera-workspace:0.$i 'claude --dangerously-skip-permissions' C-m; done
```

### 2. エージェント起動
```bash
# 各ペインで適切な指示書を実行
PM: "あなたはPMです。指示書に従って"
Coder: "あなたはcoderです。指示書に従って" 
QA-Functional: "あなたはqa-functionalです。指示書に従って"
QA-Lead: "あなたはqa-leadです。指示書に従って"
```

### 3. メッセージ送信
```bash
# 新しいエージェント名で送信
chimera send qa-functional "テスト開始してください"
chimera send qa-lead "品質計画をお願いします"
```

## 💡 次の発展

この**QA役割分化**が成功したら、次は：

1. **DevOps役割**の追加
2. **Designer役割**の追加  
3. **複数Coder**への展開
4. **外部ツール連携**

段階的に現実的なチーム構成に近づけていけます！