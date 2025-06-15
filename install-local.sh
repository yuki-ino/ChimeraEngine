#!/bin/bash

# 🦁 Chimera Engine Local Installation Script
# Fixed version with macOS compatibility

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
CHIMERA_INSTALL_DIR="$HOME/.chimera"
CHIMERA_BIN_DIR="$HOME/.local/bin"
CHIMERA_CONFIG_DIR="$HOME/.config/chimera"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
    echo -e "${PURPLE}🦁 Chimera Engine Local Installation${NC}"
    echo "======================================================"
    echo ""
    
    log_info "Source directory: $SOURCE_DIR"
    log_info "Installation directory: $CHIMERA_INSTALL_DIR"
    log_info "Binary directory: $CHIMERA_BIN_DIR"
    log_info "Configuration directory: $CHIMERA_CONFIG_DIR"
    echo ""
    
    # Prerequisites check
    log_info "Checking prerequisites..."
    check_prerequisites
    
    # Clean installation
    log_info "Removing existing installation..."
    rm -rf "$CHIMERA_INSTALL_DIR"
    
    # Create directories
    log_info "Creating installation directories..."
    mkdir -p "$CHIMERA_INSTALL_DIR"
    mkdir -p "$CHIMERA_BIN_DIR"
    mkdir -p "$CHIMERA_CONFIG_DIR"
    log_success "Installation directories created"
    
    # Install files
    log_info "Installing Chimera Engine files..."
    
    # Copy all scripts
    cp -r "$SOURCE_DIR/scripts" "$CHIMERA_INSTALL_DIR/"
    
    # Copy instructions
    cp -r "$SOURCE_DIR/instructions" "$CHIMERA_INSTALL_DIR/"
    
    # Copy other necessary files
    if [[ -f "$SOURCE_DIR/CLAUDE.md" ]]; then
        cp "$SOURCE_DIR/CLAUDE.md" "$CHIMERA_INSTALL_DIR/"
    fi
    
    if [[ -f "$SOURCE_DIR/USER_GUIDE.md" ]]; then
        cp "$SOURCE_DIR/USER_GUIDE.md" "$CHIMERA_INSTALL_DIR/"
    fi
    
    # Make scripts executable
    find "$CHIMERA_INSTALL_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
    
    log_success "Chimera Engine files installed"
    
    # Create chimera binary
    log_info "Creating chimera command..."
    create_chimera_binary
    log_success "Chimera command created"
    
    # Setup PATH
    setup_path
    
    # Verification
    log_info "Verifying installation..."
    verify_installation
    
    # Installation complete
    installation_complete
}

check_prerequisites() {
    # Check for Claude Code CLI
    if command -v claude >/dev/null 2>&1; then
        log_success "Claude Code CLI found: $(which claude)"
    else
        log_error "Claude Code CLI not found. Please install it first."
        exit 1
    fi
    
    # Check for tmux
    if command -v tmux >/dev/null 2>&1; then
        log_success "tmux found: $(which tmux)"
    else
        log_error "tmux not found. Please install it first: brew install tmux"
        exit 1
    fi
    
    log_success "Prerequisites check completed"
    echo ""
}

create_chimera_binary() {
    cat > "$CHIMERA_BIN_DIR/chimera" << 'EOF'
#!/bin/bash

# Chimera Engine CLI wrapper
CHIMERA_HOME="${HOME}/.chimera"

if [[ ! -d "$CHIMERA_HOME" ]]; then
    echo "Error: Chimera Engine not installed. Run install script first."
    exit 1
fi

case "${1:-}" in
    "start"|"setup"|"")
        exec "$CHIMERA_HOME/scripts/setup-chimera.sh" "${@:2}"
        ;;
    "send")
        exec "$CHIMERA_HOME/scripts/chimera-send.sh" "${@:2}"
        ;;
    "init")
        # Initialize chimera in current directory
        if [[ ! -f "CHIMERA_PLAN.md" ]]; then
            "$CHIMERA_HOME/scripts/lib/plan-manager.sh" init
        fi
        exec "$CHIMERA_HOME/scripts/setup-chimera.sh"
        ;;
    "memory")
        exec "$CHIMERA_HOME/scripts/lib/memory-manager.sh" "${@:2}"
        ;;
    "health")
        exec "$CHIMERA_HOME/scripts/lib/agent-health-monitor.sh" "${@:2}"
        ;;
    "--version"|"version")
        echo "Chimera Engine v0.0.1"
        ;;
    "--help"|"help"|"h")
        cat << 'HELP'
Chimera Engine - Multi-Agent Development Environment

Usage:
  chimera [command] [options]

Commands:
  start                 Start/setup Chimera workspace
  init                  Initialize Chimera in current project
  send <agent> <msg>    Send message to agent
  memory <cmd>          Memory management
  health <cmd>          Health monitoring
  version               Show version
  help                  Show this help

Examples:
  chimera start         # Start Chimera workspace
  chimera init          # Initialize in current project
  chimera send pm "プロジェクトを開始してください"
  chimera send coder "ログイン機能を実装してください"

For more details, see USER_GUIDE.md
HELP
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'chimera help' for available commands."
        exit 1
        ;;
esac
EOF

    chmod +x "$CHIMERA_BIN_DIR/chimera"
}

setup_path() {
    log_info "Setting up PATH..."
    
    # Detect shell
    SHELL_RC=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        SHELL_RC="$HOME/.bashrc"
        [[ -f "$HOME/.bash_profile" ]] && SHELL_RC="$HOME/.bash_profile"
    fi
    
    if [[ -n "$SHELL_RC" ]]; then
        # Add PATH export if not already present
        if ! grep -q "$CHIMERA_BIN_DIR" "$SHELL_RC" 2>/dev/null; then
            echo "" >> "$SHELL_RC"
            echo "# Chimera Engine" >> "$SHELL_RC"
            echo "export PATH=\"\$PATH:$CHIMERA_BIN_DIR\"" >> "$SHELL_RC"
            log_success "Added $CHIMERA_BIN_DIR to PATH in $SHELL_RC"
        else
            log_info "PATH already configured in $SHELL_RC"
        fi
    fi
    
    # Add to current session PATH
    export PATH="$PATH:$CHIMERA_BIN_DIR"
}

verify_installation() {
    # Verify key files exist
    local key_files=(
        "$CHIMERA_INSTALL_DIR/scripts/setup-chimera.sh"
        "$CHIMERA_INSTALL_DIR/scripts/chimera-send.sh"
        "$CHIMERA_INSTALL_DIR/scripts/lib/common.sh"
        "$CHIMERA_INSTALL_DIR/scripts/lib/agent-health-monitor.sh"
        "$CHIMERA_BIN_DIR/chimera"
    )
    
    for file in "${key_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "✓ $(basename "$file")"
        else
            log_error "✗ $(basename "$file") - missing"
            return 1
        fi
    done
    
    # Verify chimera command
    if "$CHIMERA_BIN_DIR/chimera" --version >/dev/null 2>&1; then
        log_success "✓ chimera command working"
    else
        log_error "✗ chimera command not working"
        return 1
    fi
    
    log_success "Installation verification completed"
}

installation_complete() {
    echo ""
    log_success "🎉 Chimera Engine installation completed!"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc (or ~/.bashrc)"
    echo "  2. Navigate to your project directory"
    echo "  3. Run: chimera init"
    echo "  4. Run: chimera start"
    echo ""
    echo "📖 Documentation:"
    echo "  • User Guide: $CHIMERA_INSTALL_DIR/USER_GUIDE.md"
    echo "  • Developer Guide: $CHIMERA_INSTALL_DIR/CLAUDE.md"
    echo ""
    echo "🔧 Commands:"
    echo "  • chimera help     - Show help"
    echo "  • chimera start    - Start workspace"
    echo "  • chimera send <agent> <message>"
    echo ""
    echo "Current PATH: $PATH"
    echo "Chimera binary: $CHIMERA_BIN_DIR/chimera"
}

# Run main function
main "$@"