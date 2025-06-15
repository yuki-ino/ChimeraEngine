#!/bin/bash

# 🦁 Chimera Engine - ワンコマンドインストーラー
# Usage: curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/install.sh | bash

set -e

# 設定
INSTALL_DIR="${CHIMERA_DIR:-$HOME/.chimera}"
REPO_URL="https://github.com/yuki-ino/ChimeraEngine.git"
BRANCH="main"

# 共通ライブラリが利用可能か確認
if [[ -f "$INSTALL_DIR/scripts/lib/common.sh" ]]; then
    source "$INSTALL_DIR/scripts/lib/common.sh"
else
    # フォールバック: 独自ログ関数
    print_color() {
        local color=$1
        shift
        echo -e "\033[${color}m$@\033[0m"
    }
    
    info() { print_color "1;32" "[INFO] $@"; }
    warn() { print_color "1;33" "[WARN] $@"; }
    error() { print_color "1;31" "[ERROR] $@"; }
    success() { print_color "1;34" "[SUCCESS] $@"; }
fi

# ヘッダー
cat << "EOF"
╔═══════════════════════════════════════╗
║          Chimera Engine               ║
║       Quick Installer v0.0.1          ║
╚═══════════════════════════════════════╝
EOF

# 依存関係チェック
info "依存関係をチェック中..."

check_command() {
    if ! command -v $1 &> /dev/null; then
        error "$1 が見つかりません。インストールしてください。"
        return 1
    fi
    success "✓ $1"
}

# 必須コマンドの確認
REQUIRED_COMMANDS=("git" "tmux" "curl")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    check_command "$cmd" || exit 1
done

# wgetの代替確認
if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    error "curl または wget が必要です"
    exit 1
fi

# インストールディレクトリ作成
info "インストールディレクトリを作成: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# ファイルダウンロード（現在のディレクトリからコピー）
if [ -d "$(pwd)/scripts" ] && [ -d "$(pwd)/instructions" ]; then
    info "ローカルファイルからインストール..."
    
    # scriptsディレクトリ全体をコピー
    cp -r scripts "$INSTALL_DIR/"
    
    # instructionsディレクトリをコピー
    cp -r instructions "$INSTALL_DIR/"
    
    # 必要な個別ファイルもコピー
    for file in setup-chimera.sh chimera-send.sh pm-workflow-controller.sh project-analyzer.sh test-manual-generator.sh; do
        if [ -f "$(pwd)/$file" ]; then
            cp "$file" "$INSTALL_DIR/"
        elif [ -f "$(pwd)/scripts/$file" ]; then
            cp "scripts/$file" "$INSTALL_DIR/"
        fi
    done
    
else
    info "GitHubからダウンロード..."
    cd "$INSTALL_DIR"
    
    # 必要なファイルのみダウンロード
    files=(
        "scripts/setup-chimera.sh"
        "scripts/chimera-send.sh"
        "scripts/pm-workflow-controller.sh"
        "scripts/project-analyzer.sh"
        "scripts/test-manual-generator.sh"
        "instructions/pm-improved.md"
        "instructions/coder.md"
        "instructions/qa-functional.md"
        "instructions/qa-lead.md"
        "instructions/monitor.md"
    )
    
    for file in "${files[@]}"; do
        dir=$(dirname "$file")
        mkdir -p "$dir"
        curl -sSL "https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/$BRANCH/$file" -o "$file" || \
        wget -q "https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/$BRANCH/$file" -O "$file"
    done
fi

# 実行権限付与
info "実行権限を設定中..."
find "$INSTALL_DIR" -name "*.sh" -type f -exec chmod 755 {} \;
find "$INSTALL_DIR" -name "*.yaml" -o -name "*.yml" -type f -exec chmod 644 {} \;

# グローバルコマンド作成
info "グローバルコマンドを作成中..."

# chimeraコマンドの作成（リファクタリング版）
cat > "$INSTALL_DIR/chimera" << 'SCRIPT'
#!/bin/bash
# Chimera Engine System - メインコマンド（リファクタリング版）

CHIMERA_HOME="${CHIMERA_DIR:-$HOME/.chimera}"
COMMAND=$1
shift

# 共通ライブラリ読み込み（利用可能な場合）
if [[ -f "$CHIMERA_HOME/scripts/lib/common.sh" ]]; then
    source "$CHIMERA_HOME/scripts/lib/common.sh"
else
    # フォールバック関数
    log_info() { echo -e "\033[1;32m[INFO]\033[0m $*" >&2; }
    log_error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }
    log_success() { echo -e "\033[1;34m[SUCCESS]\033[0m $*" >&2; }
fi

case "$COMMAND" in
    init)
        # プロジェクトにChimera Engineを初期化
        log_info "Chimera Engineを現在のディレクトリに初期化中..."
        
        # 必要なファイルをコピー
        if [[ -d "$CHIMERA_HOME/scripts" ]]; then
            cp -r "$CHIMERA_HOME/scripts" . || {
                log_error "スクリプトディレクトリのコピーに失敗しました"
                exit 1
            }
        else
            log_error "スクリプトディレクトリが見つかりません: $CHIMERA_HOME/scripts"
            exit 1
        fi
        
        # 設定ファイルもコピー
        if [[ -d "$CHIMERA_HOME/config" ]]; then
            cp -r "$CHIMERA_HOME/config" . 2>/dev/null || log_info "設定ファイルは任意です"
        fi
        
        # インストラクションファイルをコピー
        if [[ -d "$CHIMERA_HOME/instructions" ]]; then
            cp -r "$CHIMERA_HOME/instructions" . || {
                log_error "インストラクションファイルのコピーに失敗しました"
                exit 1
            }
        else
            log_error "インストラクションディレクトリが見つかりません: $CHIMERA_HOME/instructions"
            exit 1
        fi
        
        # 実行権限設定
        find . -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null
        
        # 自動プロジェクト解析とテストマニュアル生成
        if command -v jq &> /dev/null && [[ -f "./scripts/project-analyzer.sh" ]]; then
            log_info "🔍 プロジェクトを解析中..."
            ./scripts/project-analyzer.sh .
            if [[ -f "./scripts/test-manual-generator.sh" ]]; then
                log_info "📖 カスタムテストマニュアルを生成中..."
                ./scripts/test-manual-generator.sh .
            fi
            log_success "✅ プロジェクト固有のテスト環境を設定しました"
        else
            log_info "⚠️  jqが見つからないか、解析スクリプトがありません"
            log_info "   詳細解析には 'brew install jq' または 'apt install jq' でjqをインストールしてください"
        fi
        
        log_success "✅ Chimera Engineシステムを現在のディレクトリに初期化しました"
        echo "次のステップ:"
        echo "  1. chimera start     # 環境起動"
        echo "  2. 設定カスタマイズ    # config/chimera.yaml (オプション)"
        echo "  3. テスト実行        # ./tests/run_all_tests.sh (オプション)"
        ;;
    
    start)
        # セットアップと起動
        if [[ ! -f "./scripts/setup-chimera.sh" ]]; then
            log_info "セットアップスクリプトが見つかりません。初期化を実行します..."
            "$0" init
        fi
        
        # 環境チェックと実行
        if [[ -f "./scripts/setup-chimera.sh" ]]; then
            log_info "リファクタリング版セットアップを使用"
            ./scripts/setup-chimera.sh "$@"
        else
            log_error "setup-chimera.sh が見つかりません"
            log_info "初期化が完了していない可能性があります。'chimera init' を先に実行してください。"
            exit 1
        fi
        ;;
    
    send)
        # メッセージ送信
        if [[ -f "./scripts/chimera-send.sh" ]]; then
            ./scripts/chimera-send.sh "$@"
        elif [[ -f "./chimera-send.sh" ]]; then
            ./chimera-send.sh "$@"
        else
            log_error "chimera-send.sh が見つかりません。'chimera init' を実行してください。"
            exit 1
        fi
        ;;
    
    update)
        # システムアップデート
        log_info "Chimera Engineシステムをアップデート中..."
        
        # バックアップ作成
        if [[ -d "$CHIMERA_HOME" ]]; then
            local backup_dir="${CHIMERA_HOME}.backup.$(date +%Y%m%d_%H%M%S)"
            cp -r "$CHIMERA_HOME" "$backup_dir"
            log_info "バックアップ作成: $backup_dir"
        fi
        
        # アップデート実行
        cd "$CHIMERA_HOME"
        if curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/scripts/install.sh | bash; then
            log_success "アップデート完了"
        else
            log_error "アップデートに失敗しました"
            exit 1
        fi
        ;;
    
    help|--help|-h|"")
        cat << EOF
Chimera Engine - Multi-Agent Development System

使用方法:
  chimera <command> [options]

コマンド:
  init      現在のプロジェクトにChimera Engineを初期化
  start     マルチエージェント環境を起動
  send      エージェントにメッセージを送信
  update    システムをアップデート
  help      このヘルプを表示

例:
  chimera init                    # プロジェクトに初期化
  chimera start                   # 環境起動
  chimera send coder "実装開始"   # メッセージ送信

詳細:
  https://github.com/yuki-ino/ChimeraEngine
EOF
        ;;
    
    *)
        echo "不明なコマンド: $COMMAND"
        echo "使用方法: chimera help"
        exit 1
        ;;
esac
SCRIPT

chmod +x "$INSTALL_DIR/chimera"

# PATH設定の提案
info "PATH設定を確認中..."

add_to_path() {
    local shell_rc=""
    
    if [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    fi
    
    if [ -n "$shell_rc" ] && [ -f "$shell_rc" ]; then
        if ! grep -q "CHIMERA_DIR" "$shell_rc"; then
            cat >> "$shell_rc" << EOF

# Chimera Engine System
export CHIMERA_DIR="$INSTALL_DIR"
export PATH="\$CHIMERA_DIR:\$PATH"
EOF
            success "PATH設定を $shell_rc に追加しました"
            warn "新しいターミナルを開くか、以下を実行してください:"
            echo "  source $shell_rc"
        fi
    fi
}

add_to_path

# インストール完了
echo ""
success "🎉 Chimera Engineシステムのインストールが完了しました！"
echo ""
echo "📋 クイックスタート:"
echo "  1. プロジェクトディレクトリに移動"
echo "  2. chimera init    # 初期化"
echo "  3. chimera start   # 起動"
echo ""
echo "💡 今すぐ使うには:"
echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
echo "  chimera help"
echo ""

# 一時的にPATHに追加（現在のシェルセッション用）
export PATH="$INSTALL_DIR:$PATH"