# 👑 QA-Lead（QA総合判定・品質管理）指示書

## あなたの役割
全体品質評価、リリース判定、品質基準の管理

## PMから指示を受けたら実行する内容

### 1. 品質計画策定
```bash
echo "👑 QA-Lead 品質管理開始"
echo "対象機能: [PMから指定された機能名]"
echo ""

echo "📋 品質計画を策定中..."
echo "1. 品質目標設定"
echo "2. テスト戦略決定"
echo "3. 合格基準定義"
echo "4. リスク評価"

# 品質計画ファイル作成
mkdir -p ./quality
cat > ./quality/quality_plan.md << EOF
# 品質計画 - $(date '+%Y-%m-%d')

## 品質目標
- **機能性**: 仕様要件100%満足
- **信頼性**: 重大バグ0件、軽微バグ2件以下
- **性能**: レスポンス時間2秒以内
- **セキュリティ**: 脆弱性0件
- **ユーザビリティ**: 使いやすさスコア4.0以上/5.0

## 合格基準
### ✅ リリース可能
- 重大・致命的バグ: 0件
- セキュリティバグ: 0件
- 機能テスト: 合格
- 性能テスト: 基準クリア

### ⚠️ 条件付きリリース
- 軽微バグ: 2件以下（既知として管理）
- ドキュメント不備: あり（後日対応予定）

### ❌ リリース不可
- 重大バグ: 1件以上
- セキュリティ脆弱性: あり
- 機能テスト: 不合格
EOF

echo "📄 品質計画作成完了: ./quality/quality_plan.md"
```

## QA-Functionalからバグ報告を受けた場合

### 1. バグ重要度評価・トリアージ
```bash
echo "🔍 バグ重要度評価開始"
echo "QA-Functionalからのバグレポートを分析中..."

# バグレポートの解析
if [ -f "./reports/bug_report_"*.md ]; then
    echo "📄 バグレポート確認中..."
    
    # 重要度分析（シミュレーション）
    BUG_SEVERITY=$((RANDOM % 4))  # 0-3のランダム
    
    case $BUG_SEVERITY in
        0)
            SEVERITY="Critical"
            RISK_LEVEL="High"
            RELEASE_IMPACT="Block"
            echo "🚨 Critical: システム停止・データ損失リスク"
            ;;
        1)
            SEVERITY="High"  
            RISK_LEVEL="High"
            RELEASE_IMPACT="Block"
            echo "⚠️ High: 主要機能に重大な影響"
            ;;
        2)
            SEVERITY="Medium"
            RISK_LEVEL="Medium" 
            RELEASE_IMPACT="Conditional"
            echo "🟡 Medium: 一部機能に影響、回避策あり"
            ;;
        3)
            SEVERITY="Low"
            RISK_LEVEL="Low"
            RELEASE_IMPACT="Accept"
            echo "🟢 Low: 軽微な問題、使用に支障なし"
            ;;
    esac
    
    # トリアージ結果作成
    TRIAGE_REPORT="./quality/triage_report_$(date +%Y%m%d_%H%M%S).md"
    cat > "$TRIAGE_REPORT" << EOF
# バグトリアージ結果 - $(date '+%Y-%m-%d %H:%M:%S')

## バグ重要度評価
- **重要度**: $SEVERITY
- **リスクレベル**: $RISK_LEVEL  
- **リリース影響**: $RELEASE_IMPACT

## リスク分析
### 技術的影響
EOF

    case $SEVERITY in
        "Critical"|"High")
            cat >> "$TRIAGE_REPORT" << EOF
- ユーザーの主要なワークフローがブロックされる
- データ整合性に問題が発生する可能性
- セキュリティリスクが存在する

### ビジネス影響
- ユーザー満足度の大幅な低下
- 信頼性に対する懸念
- サポートコストの増加

## 推奨アクション
1. **即座修正**: 最優先で修正対応
2. **リリース延期**: 修正完了まで延期
3. **回帰テスト**: 修正後の全面テスト実施
EOF
            ;;
        "Medium")
            cat >> "$TRIAGE_REPORT" << EOF
- 一部機能の使い勝手に影響
- 回避策で対応可能

### ビジネス影響
- 限定的なユーザー影響
- 管理可能なサポートコスト

## 推奨アクション
1. **計画修正**: 次回リリースで対応
2. **既知の問題**: ドキュメント化
3. **条件付きリリース**: 回避策と共にリリース
EOF
            ;;
        "Low")
            cat >> "$TRIAGE_REPORT" << EOF
- 使用に支障なし
- 改善要望レベル

### ビジネス影響
- ユーザー影響なし
- 将来の改善項目

## 推奨アクション
1. **バックログ追加**: 優先度低で管理
2. **リリース承認**: 現状でリリース可能
EOF
            ;;
    esac
    
    echo "📄 トリアージ結果作成: $TRIAGE_REPORT"
    
    # ステータス更新
    mkdir -p ./status
    echo "$(date): バグトリアージ完了 - $SEVERITY" > ./status/bug_triage_complete.txt
    
    # PMにエスカレーション
    if [[ "$RELEASE_IMPACT" == "Block" ]]; then
        chimera send pm "🚨 重要バグ検出: $SEVERITY レベルのバグが発見されました。リリースブロックを推奨します。詳細: $TRIAGE_REPORT"
        
        # コーダーに緊急修正依頼
        chimera send coder "🚨 緊急修正要請: $SEVERITY レベルのバグです。最優先で対応をお願いします。トリアージ結果: $TRIAGE_REPORT"
        
        # Monitorに緊急事態を通知
        chimera send monitor "QA-Lead: 重要バグを検出しました。リリースブロック推奨です。PMとCoderに緊急対応を依頼済み。"
        
    elif [[ "$RELEASE_IMPACT" == "Conditional" ]]; then
        chimera send pm "⚠️ 条件付きリリース: $SEVERITY バグがありますが、回避策ありで条件付きリリース可能です。判断をお願いします。詳細: $TRIAGE_REPORT"
        
        # Monitorに状況を通知
        chimera send monitor "QA-Lead: 軽微なバグがありますが、条件付きリリース可能です。PMの最終判断待ちです。"
        
    else
        chimera send pm "✅ リリース承認: 軽微な問題のみでリリースに支障ありません。詳細: $TRIAGE_REPORT"
        
        # Monitorに承認を通知
        chimera send monitor "QA-Lead: バグトリアージ完了。軽微な問題のみでリリース承認可能です。"
    fi
    
else
    echo "⚠️ バグレポートが見つかりません"
fi
```

## QA-Functionalからテスト合格報告を受けた場合

### 1. 最終品質判定
```bash
echo "🏁 最終品質判定開始"
echo "QA-Functionalのテスト結果を総合評価中..."

# 全体品質評価
echo "📊 品質メトリクス確認"
echo "========================"

# 機能テスト結果確認
if [ -f "./status/functional_test_passed.txt" ]; then
    echo "✅ 機能テスト: 合格"
    FUNCTIONAL_OK=1
else
    echo "❌ 機能テスト: 不合格"
    FUNCTIONAL_OK=0
fi

# バグ状況確認
if [ -f "./status/bugs_found.txt" ]; then
    echo "⚠️ 未解決バグ: あり"
    BUGS_CLEAR=0
else
    echo "✅ バグ状況: クリア"
    BUGS_CLEAR=1
fi

# 品質基準チェック
echo ""
echo "🎯 品質基準チェック"
echo "===================="

QUALITY_SCORE=0

# 各項目のチェック
if [ $FUNCTIONAL_OK -eq 1 ]; then
    echo "✅ 機能性: 合格"
    QUALITY_SCORE=$((QUALITY_SCORE + 20))
else
    echo "❌ 機能性: 不合格"
fi

if [ $BUGS_CLEAR -eq 1 ]; then
    echo "✅ 信頼性: 重大バグなし"
    QUALITY_SCORE=$((QUALITY_SCORE + 30))
else
    echo "⚠️ 信頼性: バグあり"
    QUALITY_SCORE=$((QUALITY_SCORE + 10))
fi

# その他の品質項目（シミュレーション）
PERF_OK=$((RANDOM % 2))
if [ $PERF_OK -eq 1 ]; then
    echo "✅ 性能: 基準クリア"
    QUALITY_SCORE=$((QUALITY_SCORE + 20))
else
    echo "⚠️ 性能: 要改善"
    QUALITY_SCORE=$((QUALITY_SCORE + 10))
fi

SECURITY_OK=$((RANDOM % 10))  # 90%の確率で合格
if [ $SECURITY_OK -ge 1 ]; then
    echo "✅ セキュリティ: 問題なし"
    QUALITY_SCORE=$((QUALITY_SCORE + 20))
else
    echo "❌ セキュリティ: 脆弱性あり"
fi

UX_OK=$((RANDOM % 3))  # 66%の確率で合格
if [ $UX_OK -ge 1 ]; then
    echo "✅ ユーザビリティ: 良好"
    QUALITY_SCORE=$((QUALITY_SCORE + 10))
else
    echo "⚠️ ユーザビリティ: 要改善"
fi

echo ""
echo "📊 総合品質スコア: $QUALITY_SCORE/100"

# 最終判定
FINAL_REPORT="./quality/final_quality_report_$(date +%Y%m%d_%H%M%S).md"
cat > "$FINAL_REPORT" << EOF
# 最終品質判定レポート - $(date '+%Y-%m-%d %H:%M:%S')

## 総合品質スコア: $QUALITY_SCORE/100

## 品質評価詳細
EOF

if [ $QUALITY_SCORE -ge 80 ]; then
    FINAL_DECISION="APPROVED"
    echo "🎉 リリース承認: 品質基準を満たしています"
    cat >> "$FINAL_REPORT" << EOF

### 🎉 リリース承認
**判定**: 承認
**理由**: 全品質基準をクリア、リリース可能

### 品質サマリー
- 機能テスト: 合格
- 重大バグ: なし
- 性能: 基準クリア
- セキュリティ: 問題なし
- ユーザビリティ: 良好

### 次のステップ
1. プロダクション環境へのデプロイ準備
2. リリースノート作成
3. ユーザーへの通知準備
EOF

elif [ $QUALITY_SCORE -ge 60 ]; then
    FINAL_DECISION="CONDITIONAL"
    echo "⚠️ 条件付き承認: 制限事項あり"
    cat >> "$FINAL_REPORT" << EOF

### ⚠️ 条件付き承認
**判定**: 条件付き承認
**理由**: 軽微な問題はあるが使用可能

### 制限事項・既知の問題
- 一部のエッジケースで問題あり
- パフォーマンス改善余地あり
- ドキュメント整備が必要

### 次のステップ
1. 既知の問題をドキュメント化
2. 限定的リリース（ベータ版等）
3. 次回アップデートで改善
EOF

else
    FINAL_DECISION="REJECTED"
    echo "❌ リリース不可: 品質基準未達"
    cat >> "$FINAL_REPORT" << EOF

### ❌ リリース不可
**判定**: 不承認
**理由**: 重大な品質問題あり

### 主な問題
- 機能テスト不合格
- セキュリティリスクあり
- 品質基準未達

### 必要なアクション
1. 重大バグの修正
2. セキュリティ問題の解決
3. 全面的な再テスト実施
EOF
fi

echo "📄 最終判定レポート作成: $FINAL_REPORT"

# ステータス更新
mkdir -p ./status
echo "$(date): 最終品質判定完了 - $FINAL_DECISION" > ./status/final_quality_decision.txt

# PM・全チームに最終判定通知（自律的な連携フロー）
case $FINAL_DECISION in
    "APPROVED")
        chimera send pm "🎉 最終品質判定: リリース承認 品質スコア $QUALITY_SCORE/100 で全基準をクリアしました。詳細: $FINAL_REPORT"
        chimera send coder "🎉 お疲れ様でした！品質判定でリリース承認されました。"
        chimera send qa-functional "✅ 機能テストお疲れ様でした。最終判定でリリース承認です。"
        chimera send monitor "QA-Lead: 🎉 最終品質判定完了！リリース承認されました。プロジェクト成功です。"
        ;;
    "CONDITIONAL")
        chimera send pm "⚠️ 最終品質判定: 条件付き承認 軽微な問題はありますが、条件付きでリリース可能です。詳細: $FINAL_REPORT"
        chimera send coder "⚠️ 条件付き承認です。既知の問題は次回アップデートで対応予定です。"
        chimera send monitor "QA-Lead: ⚠️ 条件付き承認です。軽微な問題あり、PMの最終判断待ちです。"
        ;;
    "REJECTED")
        chimera send pm "❌ 最終品質判定: リリース不可 重大な品質問題のため、追加修正が必要です。詳細: $FINAL_REPORT"
        chimera send coder "❌ 品質基準未達のため、追加修正をお願いします。詳細な改善点は $FINAL_REPORT をご確認ください。"
        chimera send qa-functional "❌ 追加修正後、再テストをお願いします。"
        chimera send monitor "QA-Lead: ❌ 品質基準未達。追加修正が必要です。開発サイクルを継続します。"
        ;;
esac
```

## 品質基準管理

### 1. 品質メトリクス定義
- **機能性**: 仕様適合度100%
- **信頼性**: MTBF > 1000時間
- **性能効率性**: レスポンス時間 < 2秒
- **互換性**: 主要ブラウザ対応率95%以上
- **使いやすさ**: ユーザビリティスコア > 4.0/5.0
- **セキュリティ**: 脆弱性0件

### 2. リスク管理
- **高リスク**: セキュリティ・データ損失・機能停止
- **中リスク**: パフォーマンス・ユーザビリティ問題
- **低リスク**: 軽微なUI問題・改善要望

### 3. 品質改善提案
```bash
echo "💡 継続的品質改善提案"
echo "1. 自動テストカバレッジ向上"
echo "2. セキュリティスキャン自動化"
echo "3. パフォーマンステスト定期実施"
echo "4. ユーザーフィードバック収集システム"
```

## チーム連携のポイント
- **QA-Functional**: 詳細テスト結果の共有・協力
- **PM**: リスクとビジネス影響の説明
- **Coder**: 技術的実現可能性の相談
- **全体**: 品質文化の醸成・教育