#!/bin/bash

# 🦁 Chimera Engine - Local Installation Script
# Chimera Engineをローカル環境にインストール

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_DIR="$HOME/.chimera"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/chimera"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}${1}${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check tmux
    if ! command -v tmux >/dev/null 2>&1; then
        log_error "tmux is required but not installed."
        echo "Please install tmux:"
        echo "  macOS: brew install tmux"
        echo "  Linux: sudo apt-get install tmux"
        exit 1
    fi
    
    # Check Claude Code
    if ! command -v claude >/dev/null 2>&1; then
        log_warn "Claude Code CLI not found in PATH."
        log_warn "Please ensure Claude Code is installed and accessible."
        log_warn "Visit: https://claude.ai/code for installation instructions."
    else
        log_success "Claude Code CLI found: $(which claude)"
    fi
    
    # Check bash version
    if [[ ${BASH_VERSION%%.*} -lt 3 ]]; then
        log_error "Bash 3.0+ is required. Current version: $BASH_VERSION"
        exit 1
    fi
    
    log_success "Prerequisites check completed"
}

# Create installation directories
create_directories() {
    log_info "Creating installation directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$INSTALL_DIR/scripts"
    mkdir -p "$INSTALL_DIR/scripts/lib"
    mkdir -p "$INSTALL_DIR/instructions"
    mkdir -p "$INSTALL_DIR/templates"
    mkdir -p "$INSTALL_DIR/docs"
    mkdir -p "$INSTALL_DIR/tests"
    
    log_success "Installation directories created"
}

# Copy files
install_files() {
    log_info "Installing Chimera Engine files..."
    
    # Copy main scripts
    cp -r "$SOURCE_DIR/scripts/"* "$INSTALL_DIR/scripts/"
    
    # Copy instructions
    cp -r "$SOURCE_DIR/instructions/"* "$INSTALL_DIR/instructions/"
    
    # Copy templates
    cp -r "$SOURCE_DIR/templates/"* "$INSTALL_DIR/templates/"
    
    # Copy documentation
    cp -r "$SOURCE_DIR/docs/"* "$INSTALL_DIR/docs/"
    
    # Copy tests
    cp -r "$SOURCE_DIR/tests/"* "$INSTALL_DIR/tests/"
    
    # Copy configuration files
    cp "$SOURCE_DIR/CLAUDE.md" "$INSTALL_DIR/"
    cp "$SOURCE_DIR/VERSION" "$INSTALL_DIR/"
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR/scripts/"*.sh
    chmod +x "$INSTALL_DIR/scripts/lib/"*.sh
    
    log_success "Files installed to $INSTALL_DIR"
}

# Create chimera command
create_chimera_command() {
    log_info "Creating chimera command..."
    
    cat > "$BIN_DIR/chimera" << 'EOF'
#!/bin/bash

# Chimera Engine Command Line Interface
CHIMERA_INSTALL_DIR="$HOME/.chimera"
CHIMERA_SCRIPTS_DIR="$CHIMERA_INSTALL_DIR/scripts"

# Export for scripts
export CHIMERA_INSTALL_DIR
export CHIMERA_VERSION=$(cat "$CHIMERA_INSTALL_DIR/VERSION" 2>/dev/null || echo "unknown")

# Main command routing
case "${1:-}" in
    "start"|"setup")
        exec "$CHIMERA_SCRIPTS_DIR/setup-chimera.sh" "$@"
        ;;
    "send")
        shift
        exec "$CHIMERA_SCRIPTS_DIR/chimera-send.sh" "$@"
        ;;
    "init")
        # Initialize Chimera in current directory
        if [[ ! -f "CHIMERA_PLAN.md" ]]; then
            "$CHIMERA_SCRIPTS_DIR/lib/plan-manager.sh" init
        fi
        "$CHIMERA_SCRIPTS_DIR/lib/agent-identity.sh" init
        echo "🦁 Chimera Engine initialized in $(pwd)"
        ;;
    "memory")
        shift
        exec "$CHIMERA_SCRIPTS_DIR/memory-manager.sh" "$@"
        ;;
    "test")
        shift
        exec "$CHIMERA_INSTALL_DIR/tests/run_all_tests.sh" "$@"
        ;;
    "version"|"--version"|"-v")
        echo "Chimera Engine v${CHIMERA_VERSION}"
        echo "Installation: $CHIMERA_INSTALL_DIR"
        ;;
    "help"|"--help"|"-h"|"")
        cat << 'HELP'
🦁 Chimera Engine - Multi-Agent Development System

Usage:
  chimera <command> [options]

Commands:
  start                 Start multi-agent environment
  send <args>          Send messages between agents
  init                 Initialize Chimera in current directory
  memory <cmd>         Memory system management
  test [options]       Run test suite
  version              Show version information
  help                 Show this help

Examples:
  chimera start                                    # Start the system
  chimera init                                     # Initialize in project
  chimera send pm "Start development"              # Send message to PM
  chimera send role-recognition-all                # Send role recognition
  chimera send parallel-analyze                    # Analyze parallel tasks
  chimera send health-check                        # Check agent health

For detailed documentation:
  cat ~/.chimera/CLAUDE.md
  cat ~/.chimera/docs/agent-role-recognition-guide.md

Installation: $CHIMERA_INSTALL_DIR
Version: ${CHIMERA_VERSION}
HELP
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run 'chimera help' for usage information."
        exit 1
        ;;
esac
EOF

    chmod +x "$BIN_DIR/chimera"
    log_success "chimera command created at $BIN_DIR/chimera"
}

# Update PATH
update_path() {
    log_info "Updating PATH configuration..."
    
    # Detect shell
    local shell_rc=""
    if [[ "$SHELL" == */zsh ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ "$SHELL" == */bash ]]; then
        shell_rc="$HOME/.bashrc"
    else
        shell_rc="$HOME/.profile"
    fi
    
    # Check if PATH already contains our bin directory
    if ! grep -q "$BIN_DIR" "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# Chimera Engine PATH" >> "$shell_rc"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$shell_rc"
        log_success "Added $BIN_DIR to PATH in $shell_rc"
    else
        log_info "PATH already configured in $shell_rc"
    fi
    
    # Also add to current session
    export PATH="$BIN_DIR:$PATH"
}

# Create configuration
create_configuration() {
    log_info "Creating configuration files..."
    
    # Main configuration
    cat > "$CONFIG_DIR/config.yaml" << EOF
# Chimera Engine Configuration
version: $(cat "$SOURCE_DIR/VERSION" 2>/dev/null || echo "0.0.1")
install_dir: $INSTALL_DIR
install_date: $(date -Iseconds)

# System settings
session_name: chimera-workspace
claude_startup_wait: 3
auth_retry_wait: 2

# Agent configuration
agents:
  pm:
    name: "Product Manager"
    pane: 0
    color: "1;34m"  # Blue
  coder:
    name: "Full-Stack Developer"
    pane: 1
    color: "1;32m"  # Green
  qa-functional:
    name: "Functional QA"
    pane: 2
    color: "1;33m"  # Yellow
  qa-lead:
    name: "QA Lead"
    pane: 3
    color: "1;31m"  # Red
  monitor:
    name: "System Monitor"
    pane: 4
    color: "1;35m"  # Purple

# Feature flags
features:
  parallel_optimization: true
  health_monitoring: true
  structured_messaging: true
  agent_identity: true
  auto_recovery: true
EOF

    log_success "Configuration created at $CONFIG_DIR/config.yaml"
}

# Run tests
run_verification() {
    log_info "Running installation verification..."
    
    # Test chimera command
    if command -v chimera >/dev/null 2>&1; then
        log_success "chimera command is accessible"
        chimera version
    else
        log_warn "chimera command not found in PATH. You may need to restart your shell."
    fi
    
    # Test basic functionality
    cd /tmp
    if chimera init >/dev/null 2>&1; then
        log_success "Basic initialization test passed"
        rm -f CHIMERA_PLAN.md 2>/dev/null || true
    else
        log_warn "Basic initialization test failed"
    fi
}

# Main installation
main() {
    log_header "🦁 Chimera Engine Local Installation"
    echo "======================================================"
    echo
    
    log_info "Source directory: $SOURCE_DIR"
    log_info "Installation directory: $INSTALL_DIR"
    log_info "Binary directory: $BIN_DIR"
    log_info "Configuration directory: $CONFIG_DIR"
    echo
    
    # Installation steps
    check_prerequisites
    echo
    
    create_directories
    echo
    
    install_files
    echo
    
    create_chimera_command
    echo
    
    update_path
    echo
    
    create_configuration
    echo
    
    run_verification
    echo
    
    log_header "🎉 Installation Complete!"
    echo "======================================================"
    echo
    log_success "Chimera Engine has been successfully installed!"
    echo
    echo "📁 Installation location: $INSTALL_DIR"
    echo "🔧 Command location: $BIN_DIR/chimera"
    echo "⚙️  Configuration: $CONFIG_DIR/config.yaml"
    echo
    echo "🚀 Quick Start:"
    echo "  1. Restart your shell or run: source ~/.$(basename $SHELL)rc"
    echo "  2. Navigate to your project directory"
    echo "  3. Run: chimera init"
    echo "  4. Run: chimera start"
    echo
    echo "📚 Documentation:"
    echo "  • chimera help"
    echo "  • cat ~/.chimera/CLAUDE.md"
    echo "  • cat ~/.chimera/docs/agent-role-recognition-guide.md"
    echo
    echo "🔧 Advanced Features:"
    echo "  • Parallel Task Optimization: chimera send parallel-analyze"
    echo "  • Agent Health Monitoring: chimera send health-check"
    echo "  • Role Recognition: chimera send role-recognition-all"
    echo
    log_success "Happy multi-agent development! 🦁"
}

# Handle interruption
trap 'log_error "Installation interrupted"; exit 1' INT TERM

# Run installation
main "$@"