# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chimera Engine is a multi-agent development system that orchestrates PM (Product Manager), Developer, and QA team communication using tmux sessions and Claude Code. The system enables structured development workflows with role-based agent communication.

**Current Version**: 0.0.1 - **Legacy modes have been removed**, system now uses unified 5-agent architecture only.

## Core Architecture

### Agent Structure (Unified Workspace)
Single tmux session `chimera-workspace` with 5 specialized panes:
- **Pane 0 - PM**: Product management, planning, and requirements (top 1/3)
- **Pane 1 - Coder**: Full-stack development (middle 1/3)
- **Pane 2 - QA-Functional**: Feature testing specialist (bottom left)
- **Pane 3 - QA-Lead**: Quality management and release decisions (bottom center)
- **Pane 4 - Monitor**: Status monitoring and reporting (bottom right)

### Communication Flow
```
PM Planning → Development Instructions → Implementation → Testing → Quality Review → Release
    ↑                                                                                    ↓
    └─────────────────── Feedback Loop ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←┘
```

## Essential Commands

### Memory System (Dynamic Role Definition)
```bash
# Initialize memory system (auto-runs with chimera init)
chimera memory init

# Configure project context interactively
chimera memory configure

# Update agent roles dynamically
chimera memory update-role pm PROJECT_LANGUAGE=Japanese
chimera memory update-role coder PRIMARY_LANGUAGE=Python FRAMEWORKS="Django, FastAPI"
chimera memory update-role qa-lead RELEASE_STANDARDS="Zero Critical Bugs"

# View current configuration
chimera memory show

# Export/Import configurations
chimera memory export project-config.tar.gz
chimera memory import project-config.tar.gz
```

### Development and Testing
```bash
# Run all tests with comprehensive output
./tests/run_all_tests.sh -v

# Run tests with JSON output for CI/CD
./tests/run_all_tests.sh -j -o ./test_results

# Run specific test suite
./tests/test_common_functions.sh
./tests/test_messaging.sh

# Run tests in parallel (experimental)
./tests/run_all_tests.sh -p
```

### System Setup
```bash
# One-liner installation
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/scripts/install.sh | bash

# Initialize in existing project
chimera init

# Start multi-agent environment  
chimera start

# Alternative: Manual setup (for development)
./scripts/setup-chimera.sh

# Repair existing sessions
./scripts/setup-chimera.sh --repair

# Enable debug mode
./scripts/setup-chimera.sh --debug
```

### Plan Management and Structured Messaging
```bash
# Task Management
chimera send add-task <ID> <agent> <description> [priority] [dependencies]
chimera send update-task <ID> <status> [agent] [progress]
chimera send sync-plan

# Structured Messaging
chimera send task-assign <from> <to> <task_id> <description>
chimera send task-complete <from> <to> <task_id> <summary>
chimera send error-report <from> <to> <error_description> [task_id]
chimera send status-update <from> <to> <task_id> <progress%> <current_work>

# Plan Monitoring
./scripts/plan-watcher.sh start <agent>     # Start background monitoring
./scripts/plan-watcher.sh status           # Check monitoring status
./scripts/plan-watcher.sh stop-all         # Stop all monitoring

# Message Analytics
chimera send --msg-stats                    # Show messaging statistics
chimera send --msg-search <keyword>         # Search message history

# Parallel Task Optimization (NEW - 4x+ faster than reference article)
chimera send parallel-analyze               # Analyze parallel execution possibilities
chimera send parallel-execute               # Execute optimized parallel plan
chimera send parallel-report                # Generate optimization report

# Agent Health Monitoring (NEW - auto-fix "agents losing context")
chimera send health-check                   # Comprehensive health check
chimera send health-start                   # Start continuous monitoring daemon
chimera send health-stop                    # Stop monitoring daemon
chimera send health-report                  # Generate detailed health report

# Agent Identity & Role Recognition (NEW - auto-role assignment)
chimera send role-recognition <agent>       # Send role recognition to specific agent
chimera send role-recognition-all           # Send role recognition to all agents  
chimera send project-init <name> <desc>     # Initialize project with role assignments
chimera send identity-status                # Check agent identity confirmation status
chimera send emergency-resync               # Emergency agent re-identification
```

### Agent Communication
```bash
# Send messages between agents
chimera send [agent] "[message]"

# List available agents
chimera send --list

# Available agents: pm, coder, qa-functional, qa-lead, monitor
# Examples:
chimera send coder "Implement user authentication"
chimera send qa-functional "Test the login functionality"
chimera send qa-lead "Review code quality and approve release"
```

### PM Workflow Management (Dev-QA Synchronization)
```bash
# PM-specific commands to manage dev-qa workflow
chimera send check-dev           # Check developer work status
chimera send status-all          # Check all agents status
chimera send wait-qa "Task Name" # Wait for dev completion before QA

# Manual workflow controller usage
./scripts/pm-workflow-controller.sh check-dev    # Analyze dev completion
./scripts/pm-workflow-controller.sh status-all   # Full system status
./scripts/pm-workflow-controller.sh wait-for-qa "Task Name" # Auto QA after dev
```

### Project Analysis (Auto-runs during init)
```bash
# Analyze project test frameworks and generate custom instructions
./scripts/project-analyzer.sh .
./scripts/test-manual-generator.sh .
```

### Session Management
```bash
# Attach to unified workspace
tmux attach-session -t chimera-workspace

# Access specific panes
# Mouse click     (Select pane - enabled by default)
# Ctrl+b, ↑↓←→  (Navigate between panes)
# Ctrl+b, z      (Maximize/restore pane)
# Ctrl+b, d      (Detach session)

# Manual Claude Code startup (auto-handled by setup)
for i in {0..4}; do 
  tmux send-keys -t "chimera-workspace:0.$i" "claude --dangerously-skip-permissions" C-m
done
```

## Key Components

### 1. Agent Instructions
**Static Instructions (`instructions/*.md`):**
- `pm-improved.md`: PM with planning mode support
- `coder.md`: Full-stack developer instructions  
- `qa-functional.md`: Feature testing specialist
- `qa-lead.md`: Quality management and release decisions

**Dynamic Role Definitions (`.chimera/memory/agent-roles/*-role.md`):**
- Automatically created from static instructions during `chimera init`
- Customizable per project with environment variables
- Loaded via Claude Code's `--memory-dir` feature
- Allows project-specific adaptations without modifying core instructions

### 2. Core Scripts (`scripts/`)
- `setup-chimera.sh`: Creates unified 5-pane tmux workspace with session management
- `chimera-send.sh`: Agent messaging system with broadcast and status features
- `pm-workflow-controller.sh`: PM workflow management and dev-qa synchronization
- `project-analyzer.sh`: Auto-detects test frameworks (Jest, Cypress, pytest, etc.)
- `test-manual-generator.sh`: Generates project-specific test instructions
- `pm-mode-controller.sh`: PM planning/development mode management
- `memory-manager.sh`: Dynamic role definition and project context management

### 3. Core Libraries (`scripts/lib/`)
**Modular architecture with shared components:**

- `common.sh`: Unified logging, utility functions, version comparison, session management
- `config.sh`: Centralized configuration with agent mappings and system settings  
- `messaging.sh`: Inter-agent communication, broadcast messaging, status analysis
- `session-manager.sh`: tmux session lifecycle, workspace creation, Claude Code integration
- `error-handler.sh`: Comprehensive error handling, recovery mechanisms, cleanup procedures
- `config-loader.sh`: YAML configuration loading and management

**Key Functions:**
```bash
# From common.sh
log_info "message"              # Colored logging
version_compare "1.0.0" "1.0.1" # Returns 0/1/2 for equal/newer/older
list_agents                     # Returns: pm, coder, qa-functional, qa-lead, monitor
safe_mkdir "path"              # Creates directories safely
escape_string "text[*]"        # Escapes shell special characters

# From messaging.sh  
send_agent_message "coder" "msg"    # Send message to specific agent
broadcast_message "msg" "exclude"   # Send to all agents except excluded
get_agent_output "pm" 20           # Get last 20 lines from agent
analyze_agent_status "coder"       # Returns: completed/error/waiting/working/unknown
```

### 4. Testing Framework (`tests/`)
**Custom bash testing framework with macOS compatibility:**

- `tests/lib/test-framework.sh`: Complete testing framework with assertions, mocking, benchmarking
- `tests/run_all_tests.sh`: Comprehensive test runner with parallel execution, JSON output
- Individual test suites: `test_common_functions.sh`, `test_messaging.sh`

**Test Framework Features:**
- Color-coded output with progress indicators
- Multiple assertion types (equals, file_exists, command_success, output_contains)
- Mock environment setup for isolated testing
- Automatic cleanup and error handling
- JSON output for CI/CD integration
- Parallel test execution support

### 5. Agent Communication System
Messages route through unified workspace panes:
- PM → `chimera-workspace:0.0`
- Coder → `chimera-workspace:0.1`  
- QA Functional → `chimera-workspace:0.2`
- QA Lead → `chimera-workspace:0.3`
- Monitor → `chimera-workspace:0.4`

## PM Planning Mode

The PM operates in two phases:
1. **Planning Mode**: Private planning without team notifications
2. **Development Mode**: Active team coordination

Trigger development start:
```bash
chimera send pm-self "START_DEVELOPMENT"
```

## Project Analysis Features

Automatically detects and configures:
- **JavaScript/TypeScript**: Jest, Vitest, Cypress, Playwright, Testing Library
- **Python**: pytest, unittest
- **Other**: Rust (cargo test), Go (go test), Java (Maven/Gradle)

Generated files:
- `.chimera/project-analysis.json`: Analysis results
- `instructions/tester-custom.md`: Project-specific test instructions

## Configuration and Error Handling

### Configuration Management
The system uses function-based configuration (macOS bash 3.x compatible):
```bash
# Agent configuration
get_agent_pane "pm"        # Returns: chimera-workspace:0.0
get_agent_info "pm" "role" # Returns: プロダクトマネージャー

# Environment settings
CHIMERA_VERSION="0.0.1"
CHIMERA_SESSION_NAME="chimera-workspace"
CHIMERA_WORKSPACE_DIR="${TMPDIR}/chimera-workspace-$$"
```

### Error Handling System
Comprehensive error handling with recovery mechanisms:
```bash
# Initialize error handling with strict mode
init_error_handling 1 0    # (strict=1, debug=0)

# Error recovery for common issues
# - tmux server connectivity problems
# - Missing directories and permissions  
# - Session management failures
```

**Features:**
- Automatic error ID generation with detailed logging
- Context-aware recovery attempts (tmux, directory, network)
- Cleanup procedures for graceful failure handling
- Error statistics and reporting

### Status and Logging

The system maintains isolated workspace (non-intrusive to project):
- `${TMPDIR}/chimera-workspace-$$/status/`: Status tracking files
- `${TMPDIR}/chimera-workspace-$$/logs/`: Communication and activity logs  
- `${TMPDIR}/chimera-workspace-$$/logs/errors/`: Detailed error logs with recovery info
- Real-time status monitoring through the monitor agent
- **Project folder remains clean** - no logs/status pollution

## 🚀 Advanced Features (Beyond Reference Article)

### Parallel Task Optimization System
The system automatically analyzes task dependencies and executes independent tasks in parallel:
- **Dependency Graph Analysis**: Automatically builds task dependency graphs from CHIMERA_PLAN.md
- **Resource Conflict Detection**: Prevents agents from working on conflicting resources
- **Dynamic Load Balancing**: Distributes tasks based on agent workload
- **4x+ Speed Improvement**: Exceeds the reference article's "4x faster progress" through advanced optimization

### Agent Health Monitoring & Recovery
Fully automated solution to the reference article's "agents losing context" problem:
- **24/7 Continuous Monitoring**: Real-time agent health tracking
- **Automatic Context Resync**: Auto-detects and fixes context loss without manual intervention
- **Predictive Maintenance**: Identifies performance degradation before it becomes critical
- **Emergency Recovery**: Automatic agent restart and team resynchronization
- **Performance Optimization**: AI-driven suggestions for improving agent efficiency

### Structured Messaging System
Advanced inter-agent communication with message history and analytics:
- **8 Message Types**: TASK_ASSIGN, TASK_COMPLETE, ERROR_REPORT, STATUS_UPDATE, etc.
- **Message History Tracking**: Full audit trail with JSON storage
- **Search & Analytics**: Query message history for debugging and optimization
- **Auto-logging to CHIMERA_PLAN.md**: Seamless integration with unified planning

## Development Workflow

### 🤖 Autonomous Agent Collaboration
**PM sends initial instruction only, agents work autonomously:**
1. **PM**: Initial requirements to coder → enters waiting mode
2. **Coder**: Implementation → auto-notifies QA-Functional upon completion
3. **QA-Functional**: Testing → auto-reports to QA-Lead (pass/fail)
4. **QA-Lead**: Final quality judgment → auto-reports to PM
5. **PM**: Receives final report → project completion/retry cycle

**Key Feature**: PM waits passively while agents collaborate autonomously

### 🚀 Autonomous Workflow Example
```bash
# PM sends ONLY initial instruction
chimera send coder "Implement login feature"

# PM enters waiting mode - no further action needed
echo "🎯 PM: Agent autonomous collaboration started"
echo "⏳ PM: Waiting for final report from QA-Lead..."

# Agents work autonomously:
# 1. Coder completes → auto-notifies QA-Functional
# 2. QA-Functional tests → auto-reports to QA-Lead
# 3. QA-Lead judges → auto-reports to PM
```

### Optional Monitoring Commands
```bash
# Check overall system status (optional)
chimera send status-all

# Check specific agent status (optional) 
chimera send check-dev

# Manual intervention only for emergencies
chimera send coder "Emergency instruction..."
```

## Development Best Practices

### macOS Compatibility
The system is designed for cross-platform compatibility with special attention to macOS limitations:

**Bash Compatibility:**
- Uses function-based configuration instead of associative arrays (bash 3.x compatibility)
- Avoids `timeout` command (not available on macOS by default)
- Uses `declare` without `-g` flag for broader bash version support

**Error Handling:**
- Graceful degradation when advanced bash features are unavailable
- Alternative implementations for macOS-specific limitations
- Comprehensive testing on both Linux and macOS environments

## Quick Start Demo

```bash
# Complete setup and demo in 3 commands
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/scripts/install.sh | bash
chimera init && chimera start

# In PM session, trigger the demo:
# Type: "あなたはPMです。指示書に従って"
```

## Development Guidelines

### Code Architecture Principles
1. **Modular Design**: All functionality is split into focused libraries in `scripts/lib/`
2. **Error Resilience**: Comprehensive error handling with recovery mechanisms  
3. **Cross-Platform**: Designed for macOS/Linux compatibility with bash 3.x+ support
4. **Testing**: Custom test framework with full coverage of core functionality
5. **Configuration-Driven**: Function-based configuration system for maximum compatibility

### When Modifying the System
- **Always run tests**: `./tests/run_all_tests.sh -v` before committing changes
- **Update agent mappings**: Modify `get_agent_pane()` in `config.sh` for new agents
- **Add error handling**: Use `init_error_handling()` for new critical scripts
- **Maintain compatibility**: Test on both macOS and Linux environments
- **Follow patterns**: Use existing logging functions (`log_info`, `log_error`, etc.)

### File Dependencies
```
setup-chimera.sh → session-manager.sh → common.sh → config.sh
chimera-send.sh → messaging.sh → common.sh → config.sh  
All scripts → error-handler.sh (optional)
```

## Repository Information

- **GitHub**: https://github.com/yuki-ino/ChimeraEngine
- **License**: MIT
- **Version**: 0.0.1

When working with this system, always follow the established agent communication patterns and respect the role boundaries defined in the instruction files.