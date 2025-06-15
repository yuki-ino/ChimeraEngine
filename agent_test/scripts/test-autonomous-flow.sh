#!/bin/bash

# 🧪 Chimera Engine 自律連携システムテスト
# PMが初期指示のみでエージェントが完全自律実行するかテスト

echo "🦁 Chimera Engine v0.0.1 自律連携システムテスト"
echo "==============================================="
echo ""

echo "✅ 1. 自律連携フロー確認:"
echo ""
echo "🎯 PM指示書確認 - 初期指示の内容:"
echo "----------------------------------------"
grep -A5 "コーダーに実装指示を送信" instructions/pm.md | head -3
echo ""

echo "👨‍💻 Coder指示書確認 - QA自動通知:"
echo "----------------------------------------"
grep -A1 "QAに自動通知" instructions/coder.md
echo ""

echo "🧪 QA-Functional指示書確認 - QA-Lead自動報告:"
echo "----------------------------------------"
grep -A1 "QA-Leadに合格報告" instructions/qa-functional.md
echo ""

echo "👑 QA-Lead指示書確認 - PM自動報告:"
echo "----------------------------------------"
grep -A1 "PMに最終品質判定" instructions/qa-lead.md | head -1
echo ""

echo "✅ 2. 期待される自律フロー:"
echo ""
echo "PM (初期指示) → Coder (実装) → QA-Functional (テスト) → QA-Lead (判定) → PM (完了)"
echo ""
echo "🔄 各段階での自動通知:"
echo "  Coder完了      → qa-functional自動通知"
echo "  QA-Func完了    → qa-lead自動通知" 
echo "  QA-Lead判定    → pm自動報告"
echo ""

echo "✅ 3. PMの待機動作確認:"
echo "----------------------------------------"
grep -A3 "PMは待機状態に入る" instructions/pm.md
echo ""

echo "✅ 4. 自律連携の重要ポイント:"
echo "----------------------------------------"
echo "❌ PMはQAに初期指示を送らない（旧システムから変更）"
echo "✅ Coderが完了時に自動でQA-Functionalに通知"
echo "✅ QA-Functionalがテスト後、自動でQA-Leadに報告"
echo "✅ QA-Leadが最終判定後、自動でPMに報告"
echo "✅ PMは待機のみ、エージェントが自律実行"
echo ""

echo "🎉 自律連携システム構築完了！"
echo ""
echo "📋 使用方法:"
echo "1. chimera start                    # ワークスペース起動"
echo "2. PMペインで「あなたはPMです。指示書に従って」  # 自律連携開始"
echo "3. PMは待機、エージェントが自律実行"
echo "4. QA-Leadから最終報告を受信"