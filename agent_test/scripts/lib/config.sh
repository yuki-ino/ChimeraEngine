#!/bin/bash

# 🔧 Chimera Engine - 統一設定管理
# 全スクリプトで使用する設定値を一元管理

# 重複読み込み防止
[[ "${CHIMERA_CONFIG_LOADED:-}" == "1" ]] && return 0

# Chimera Engine 基本設定
readonly CHIMERA_VERSION="0.0.1"
readonly CHIMERA_SESSION_NAME="chimera-workspace"

# ワークスペース設定
readonly CHIMERA_WORKSPACE_DIR="${TMPDIR:-/tmp}/chimera-workspace-$$"
readonly STATUS_DIR="$CHIMERA_WORKSPACE_DIR/status"
readonly LOGS_DIR="$CHIMERA_WORKSPACE_DIR/logs"

# エージェント設定 - 関数ベース（macOS/古いBash互換）
get_agent_pane() {
    case "$1" in
        "pm"|"pm-self") echo "chimera-workspace:0.0" ;;
        "coder") echo "chimera-workspace:0.1" ;;
        "qa-functional") echo "chimera-workspace:0.2" ;;
        "qa-lead") echo "chimera-workspace:0.3" ;;
        "monitor") echo "chimera-workspace:0.4" ;;
        *) echo "" ;;
    esac
}


# エージェント情報 - 関数ベース（macOS/古いBash互換）
get_agent_info() {
    local agent="$1"
    local info_type="$2"
    
    case "${agent}:${info_type}" in
        "pm:title") echo "PM" ;;
        "pm:color") echo "1;31m" ;;
        "pm:role") echo "プロダクトマネージャー" ;;
        "coder:title") echo "Coder" ;;
        "coder:color") echo "1;36m" ;;
        "coder:role") echo "フルスタック開発者" ;;
        "qa-functional:title") echo "QA-Func" ;;
        "qa-functional:color") echo "1;33m" ;;
        "qa-functional:role") echo "機能テスト担当" ;;
        "qa-lead:title") echo "QA-Lead" ;;
        "qa-lead:color") echo "1;31m" ;;
        "qa-lead:role") echo "品質管理・リリース判定" ;;
        "monitor:title") echo "Monitor" ;;
        "monitor:color") echo "1;35m" ;;
        "monitor:role") echo "ステータス監視・レポート" ;;
        *) echo "" ;;
    esac
}

# タイムアウト設定
readonly DEFAULT_TIMEOUT=30
readonly MAX_CHECKS=10
readonly CHECK_INTERVAL=30
readonly CLAUDE_STARTUP_WAIT=5
readonly AUTH_RETRY_WAIT=3

# ファイルパス設定
readonly INSTALL_DIR="${CHIMERA_DIR:-$HOME/.chimera}"
readonly REPO_URL="https://github.com/yuki-ino/ChimeraEngine.git"
readonly BRANCH="main"

# 必須コマンド
readonly REQUIRED_COMMANDS=("tmux" "git" "curl")

# プロジェクト解析設定
readonly ANALYSIS_FILE=".chimera/project-analysis.json"
readonly TESTER_CUSTOM_FILE="instructions/tester-custom.md"

# ディレクトリ作成関数
ensure_directories() {
    mkdir -p "$CHIMERA_WORKSPACE_DIR" "$STATUS_DIR" "$LOGS_DIR"
}

# 設定値検証
validate_config() {
    local errors=0
    
    if [[ -z "$CHIMERA_VERSION" ]]; then
        echo "エラー: CHIMERA_VERSION が設定されていません" >&2
        ((errors++))
    fi
    
    if [[ -z "$CHIMERA_SESSION_NAME" ]]; then
        echo "エラー: CHIMERA_SESSION_NAME が設定されていません" >&2
        ((errors++))
    fi
    
    return $errors
}

# 設定情報表示
show_config() {
    cat << EOF
🔧 Chimera Engine Configuration
================================
Version: $CHIMERA_VERSION
Session: $CHIMERA_SESSION_NAME
Workspace: $CHIMERA_WORKSPACE_DIR
Required Commands: ${REQUIRED_COMMANDS[*]}
Agent Count: 5
EOF
}

# 重複読み込み防止フラグ設定
readonly CHIMERA_CONFIG_LOADED=1