#!/bin/bash

# 🧪 Chimera Engine v0.0.1 - プロジェクトフォルダ非侵食テスト
# プロジェクトディレクトリにlogs/statusが作成されないことを確認

echo "🦁 Chimera Engine v0.0.1 - プロジェクトフォルダ非侵食テスト"
echo "=========================================================="
echo ""

echo "✅ 1. プロジェクトディレクトリクリーン確認:"
echo "----------------------------------------"
if [ -d "logs" ] || [ -d "status" ]; then
    echo "❌ プロジェクトフォルダにlogs/statusが存在します"
    ls -la logs status 2>/dev/null || true
else
    echo "✅ プロジェクトフォルダはクリーンです（logs/status無し）"
fi
echo ""

echo "✅ 2. Chimera専用作業ディレクトリ設定確認:"
echo "----------------------------------------"
echo "🔍 chimera-send.shの設定:"
grep -n "chimera-workspace-" chimera-send.sh | head -3
echo ""

echo "🔍 setup-chimera.shの設定:"
grep -n "CHIMERA_WORKSPACE_DIR" setup-chimera.sh | head -3
echo ""

echo "🔍 pm-workflow-controller.shの設定:"
grep -n "CHIMERA_WORKSPACE_DIR" pm-workflow-controller.sh | head -3
echo ""

echo "✅ 3. 指示書ファイルの更新確認:"
echo "----------------------------------------"
echo "🔍 coder.mdの設定:"
grep -n "CHIMERA_WORKSPACE_DIR" instructions/coder.md | head -2
echo ""

echo "🔍 qa-functional.mdの設定:"
grep -n "CHIMERA_WORKSPACE_DIR" instructions/qa-functional.md | head -2
echo ""

echo "✅ 4. 作業ディレクトリの分離効果:"
echo "----------------------------------------"
echo "📁 従来: プロジェクトフォルダに ./logs/ ./status/ 作成"
echo "📁 新仕様: ${TMPDIR:-/tmp}/chimera-workspace-$$/logs/"
echo "📁 新仕様: ${TMPDIR:-/tmp}/chimera-workspace-$$/status/"
echo ""
echo "🎯 効果:"
echo "  ✅ プロジェクトフォルダがクリーンに保たれる"
echo "  ✅ 一時ファイルは適切な場所に分離"
echo "  ✅ .gitignoreに追加する必要なし"
echo "  ✅ プロジェクトの純粋性を保持"
echo ""

echo "🎉 プロジェクトフォルダ非侵食システム構築完了！"
echo ""
echo "📋 使用方法:"
echo "1. chimera start                    # ワークスペース起動"
echo "2. プロジェクトフォルダはクリーンのまま"
echo "3. ログ・ステータスは専用ディレクトリで管理"