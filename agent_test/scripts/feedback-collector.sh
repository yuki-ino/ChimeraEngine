#!/bin/bash

# 📊 PM/Dev/QAシステム フィードバック収集ツール
# 実プロジェクトでの使用経験を記録し、システム改善に活用

FEEDBACK_DIR="./feedback"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
FEEDBACK_FILE="$FEEDBACK_DIR/feedback_$TIMESTAMP.md"

# ディレクトリ作成
mkdir -p "$FEEDBACK_DIR"

# 色付き出力
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_question() {
    echo -e "\033[1;33m[Q]\033[0m $1"
}

# ヘッダー
echo "📊 PM/Dev/QAシステム フィードバック収集"
echo "====================================="
echo ""

# フィードバックファイル初期化
cat > "$FEEDBACK_FILE" << EOF
# PM/Dev/QA System Feedback Report
Date: $(date '+%Y-%m-%d %H:%M:%S')

## Project Information
EOF

# プロジェクト情報収集
log_question "プロジェクト名を入力してください:"
read -r project_name
echo "Project Name: $project_name" >> "$FEEDBACK_FILE"

log_question "プロジェクトの種類 (web/cli/library/other):"
read -r project_type
echo "Project Type: $project_type" >> "$FEEDBACK_FILE"

# 使用状況
cat >> "$FEEDBACK_FILE" << EOF

## Usage Statistics
EOF

log_question "使用期間 (例: 3 days, 1 week):"
read -r usage_duration
echo "Usage Duration: $usage_duration" >> "$FEEDBACK_FILE"

log_question "チームメンバー数:"
read -r team_size
echo "Team Size: $team_size" >> "$FEEDBACK_FILE"

# 効果測定
cat >> "$FEEDBACK_FILE" << EOF

## Effectiveness
EOF

echo "以下の項目を5段階で評価してください (1:最低 - 5:最高)"

log_question "コミュニケーションの改善度 (1-5):"
read -r comm_score
echo "Communication Improvement: $comm_score/5" >> "$FEEDBACK_FILE"

log_question "開発効率の向上度 (1-5):"
read -r efficiency_score
echo "Development Efficiency: $efficiency_score/5" >> "$FEEDBACK_FILE"

log_question "品質管理の改善度 (1-5):"
read -r quality_score
echo "Quality Management: $quality_score/5" >> "$FEEDBACK_FILE"

# 詳細フィードバック
cat >> "$FEEDBACK_FILE" << EOF

## Detailed Feedback
EOF

log_question "最も役立った機能は何ですか？"
read -r best_feature
echo "### Best Feature" >> "$FEEDBACK_FILE"
echo "$best_feature" >> "$FEEDBACK_FILE"

log_question "改善が必要な点は何ですか？"
read -r improvement_needed
echo -e "\n### Needs Improvement" >> "$FEEDBACK_FILE"
echo "$improvement_needed" >> "$FEEDBACK_FILE"

log_question "追加してほしい機能はありますか？"
read -r feature_request
echo -e "\n### Feature Request" >> "$FEEDBACK_FILE"
echo "$feature_request" >> "$FEEDBACK_FILE"

# カスタマイズ情報
cat >> "$FEEDBACK_FILE" << EOF

## Customizations Made
EOF

log_question "指示書をカスタマイズしましたか？ (y/n):"
read -r customized
if [[ "$customized" == "y" ]]; then
    log_question "どのような変更を加えましたか？"
    read -r customization_details
    echo "Customized: Yes" >> "$FEEDBACK_FILE"
    echo "Details: $customization_details" >> "$FEEDBACK_FILE"
else
    echo "Customized: No" >> "$FEEDBACK_FILE"
fi

# システムログの収集（オプション）
log_question "システムログを含めますか？ (y/n):"
read -r include_logs
if [[ "$include_logs" == "y" ]]; then
    cat >> "$FEEDBACK_FILE" << EOF

## System Logs
EOF
    
    if [ -d "./logs" ]; then
        echo "### Recent Communication Log (last 20 lines)" >> "$FEEDBACK_FILE"
        tail -n 20 ./logs/communication_log.txt 2>/dev/null >> "$FEEDBACK_FILE" || echo "No communication log found" >> "$FEEDBACK_FILE"
        
        echo -e "\n### Status Files" >> "$FEEDBACK_FILE"
        ls -la ./status/*.txt 2>/dev/null >> "$FEEDBACK_FILE" || echo "No status files found" >> "$FEEDBACK_FILE"
    fi
fi

# 改善提案の生成
cat >> "$FEEDBACK_FILE" << EOF

## Improvement Suggestions for System
EOF

# スコアに基づく提案
avg_score=$(( (comm_score + efficiency_score + quality_score) / 3 ))

if [ $avg_score -lt 3 ]; then
    cat >> "$FEEDBACK_FILE" << EOF
- Consider simplifying the workflow
- Add more automation features
- Improve error handling and recovery
EOF
elif [ $avg_score -lt 4 ]; then
    cat >> "$FEEDBACK_FILE" << EOF
- Fine-tune the current workflow
- Add customization options
- Enhance status monitoring
EOF
else
    cat >> "$FEEDBACK_FILE" << EOF
- System is working well
- Consider adding advanced features
- Document best practices
EOF
fi

# 完了メッセージ
echo ""
log_info "✅ フィードバック収集完了！"
echo ""
echo "📄 フィードバックファイル: $FEEDBACK_FILE"
echo ""

# 集計レポート生成（複数のフィードバックがある場合）
if [ $(ls -1 "$FEEDBACK_DIR"/feedback_*.md 2>/dev/null | wc -l) -gt 1 ]; then
    log_info "📊 集計レポートを生成しますか？ (y/n):"
    read -r generate_report
    
    if [[ "$generate_report" == "y" ]]; then
        ./generate-feedback-report.sh
    fi
fi

# GitHub Issue作成の提案
echo ""
echo "💡 このフィードバックを元に改善を提案するには:"
echo "1. GitHub Issueを作成: https://github.com/yourusername/Claude-Code-Communication/issues/new"
echo "2. フィードバックファイルの内容をコピー"
echo "3. 具体的な改善提案を記載"