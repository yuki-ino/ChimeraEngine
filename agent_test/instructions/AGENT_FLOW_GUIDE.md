# 🔄 エージェント間自律連携フローガイド

## 📋 完全自律フロー概要

```
🎯 PM企画確定 → 👨‍💻 Coder実装 → 🧪 QA-Functional → 👑 QA-Lead → 🎉 完了報告
     ↑              ↓             ↓              ↓
     └──── 📊 Monitor による全工程監視・仲介 ────────────────┘
```

## 🚀 フェーズ1: プロジェクト開始

### PM による開始指示
```bash
# PM企画確定後の一斉指示
chimera send coder "あなたはcoderです。企画が確定しました。実装を開始してください。要件：[具体的な機能要件]"
chimera send qa-functional "あなたはqa-functionalです。開発が開始されました。テスト準備をお願いします。"
chimera send qa-lead "あなたはqa-leadです。プロジェクトが開始されました。品質計画を策定してください。"
chimera send monitor "あなたはmonitorです。プロジェクト監視を開始してください。"
```

**📊 Monitor の対応:**
- プロジェクト開始を検知
- 全エージェントの初期状態を確認
- 進捗追跡を開始

## 🔄 フェーズ2: 開発→テスト自律連携

### Coder 完了時の自動連携
```bash
# Coder実装完了後の自動通知
chimera send qa-functional "実装完了しました。ログイン機能のテストをお願いします。実装内容：[詳細]"
chimera send monitor "Coder: 実装作業が完了しました。QA-Functionalにテスト指示を送信済みです。"
```

**📊 Monitor の対応:**
```bash
echo "✅ Coder実装完了通知受信"
echo "QA-Functional テスト開始を確認中..."
# QA-Functionalの状態を監視
```

### QA-Functional の自動判定連携

#### パターンA: テスト合格時
```bash
# QA-Functional → QA-Lead 自動連携
chimera send qa-lead "✅ 機能テスト合格しました。詳細レポート: $TEST_REPORT 最終品質判定をお願いします。"
chimera send monitor "QA-Functional: 機能テストが全て合格しました。QA-Leadに最終判定を依頼済みです。"
```

#### パターンB: バグ発見時
```bash
# QA-Functional → Coder & QA-Lead 自動連携
chimera send coder "❌ 機能テスト失敗: 重要なバグを発見しました。詳細レポート: $BUG_REPORT をご確認ください。"
chimera send qa-lead "機能テストでバグを発見しました。詳細レポート: $BUG_REPORT セキュリティリスクが含まれるため、リリースブロックを推奨します。"
chimera send monitor "QA-Functional: 機能テストでバグを発見しました。Coderに修正依頼、QA-Leadに報告済みです。"
```

**📊 Monitor の対応:**
```bash
# テスト結果に応じた監視継続
if [合格]; then
    echo "🧪 QA-Functional テスト合格"
    echo "QA-Lead 最終判定を確認中..."
else
    echo "⚠️ QA-Functional バグ発見"
    echo "Coder修正とQA-Lead判定を確認中..."
fi
```

## 🎯 フェーズ3: 最終判定と完了報告

### QA-Lead の最終判定と全体通知

#### パターンA: リリース承認時
```bash
# QA-Lead → 全体への完了通知
chimera send pm "🎉 最終品質判定: リリース承認 品質スコア $QUALITY_SCORE/100 で全基準をクリアしました。詳細: $FINAL_REPORT"
chimera send coder "🎉 お疲れ様でした！品質判定でリリース承認されました。"
chimera send qa-functional "✅ 機能テストお疲れ様でした。最終判定でリリース承認です。"
chimera send monitor "QA-Lead: 🎉 最終品質判定完了！リリース承認されました。プロジェクト成功です。"
```

#### パターンB: 条件付き承認時
```bash
# QA-Lead → 条件付き承認通知
chimera send pm "⚠️ 最終品質判定: 条件付き承認 軽微な問題はありますが、条件付きでリリース可能です。詳細: $FINAL_REPORT"
chimera send monitor "QA-Lead: ⚠️ 条件付き承認です。軽微な問題あり、PMの最終判断待ちです。"
```

#### パターンC: リリース不可時
```bash
# QA-Lead → 追加修正依頼
chimera send pm "❌ 最終品質判定: リリース不可 重大な品質問題のため、追加修正が必要です。詳細: $FINAL_REPORT"
chimera send coder "❌ 品質基準未達のため、追加修正をお願いします。詳細な改善点は $FINAL_REPORT をご確認ください。"
chimera send qa-functional "❌ 追加修正後、再テストをお願いします。"
chimera send monitor "QA-Lead: ❌ 品質基準未達。追加修正が必要です。開発サイクルを継続します。"
```

**📊 Monitor の最終レポート:**
```bash
echo "🎉 プロジェクト完了レポート"
echo "==============================="
echo "プロジェクト名: [プロジェクト名]"
echo "開始時刻: [開始時刻]"
echo "完了時刻: $(date '+%Y-%m-%d %H:%M:%S')"
echo "総実行時間: [計算値]"
echo "最終判定: [承認/条件付き/不可]"
echo "🏆 プロジェクト成功"
```

## 🔄 修正フィードバックループ

### バグ発見時の自動修正サイクル
```
🧪 QA-Functional (バグ発見)
    ↓ 自動通知
👨‍💻 Coder (修正実装)
    ↓ 完了通知  
🧪 QA-Functional (再テスト)
    ↓ 結果通知
👑 QA-Lead (再判定)
    ↓ 最終通知
🎯 PM (完了確認)
```

**各段階での Monitor の監視:**
```bash
echo "🔄 修正サイクル監視中"
echo "現在のフェーズ: 修正実装中"
echo "サイクル回数: [カウント]"
echo "推定完了時刻: [計算値]"
```

## 📊 Monitor の統合監視機能

### リアルタイム状態表示
```bash
echo "📊 Monitor エージェント - リアルタイム監視"
echo "============================================="
echo "🤖 エージェント状態:"
echo "- PM: ✅ 企画確定済み"
echo "- Coder: 🔄 実装中"
echo "- QA-Functional: ⏳ 待機中"
echo "- QA-Lead: ⏳ 待機中"
echo ""
echo "📋 プロジェクト進捗:"
echo "- 現在のフェーズ: 開発"
echo "- 完了したタスク: 1/4"
echo "- 推定残り時間: 15分"
```

### エラー・遅延検出
```bash
if [30秒以上応答なし]; then
    echo "⚠️ エージェント応答遅延を検出"
    echo "対象: [エージェント名]"
    echo "最終活動: [時刻]"
    # 必要に応じて仲介
fi
```

## 🎯 成功パターンの典型例

### 理想的な自律フロー実行例
```
🎯 PM: START_DEVELOPMENT → 全エージェントに指示
👨‍💻 Coder: 15分で実装完了 → QA-Functional & Monitor に自動通知
🧪 QA-Functional: 10分でテスト完了 → QA-Lead & Monitor に自動通知
👑 QA-Lead: 5分で品質判定 → 全体に承認通知
📊 Monitor: 30分で完了レポート作成
```

**総所要時間**: 約30分で完全自律実行

## ⚠️ エラーハンドリングパターン

### 通信エラー時の回復
```bash
# Monitor による仲介
if [エージェント応答なし]; then
    chimera send monitor "⚠️ 通信エラーを検出しました。セッション状態を確認中..."
    ./scripts/setup-chimera.sh --repair
fi
```

### 品質基準未達時の継続
```bash
# 自動的な修正サイクル継続
while [品質基準未達]; do
    echo "🔄 修正サイクル継続中..."
    # Coder修正 → QA再テスト → QA-Lead再判定
done
```

## 📝 各エージェントの責任範囲

| エージェント | 主責任 | 自動通知先 | 完了条件 |
|-------------|--------|-----------|----------|
| PM | 企画・意思決定 | 全体指示 | 企画確定 |
| Coder | 実装・修正 | QA-Functional, Monitor | 実装完了 |
| QA-Functional | 機能テスト | QA-Lead, Monitor | テスト完了 |
| QA-Lead | 品質判定 | 全体通知 | 最終判定 |
| Monitor | 監視・仲介 | 状況レポート | プロジェクト完了 |

## 🚀 このフローの利点

1. **完全自律**: PMの初期指示後、エージェントが自動連携
2. **透明性**: Monitorによる全工程の可視化
3. **迅速性**: 手動介入なしで高速実行
4. **品質保証**: 多段階チェックと自動フィードバック
5. **拡張性**: 新しいエージェントの追加が容易