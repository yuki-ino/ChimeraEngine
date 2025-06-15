# CLAUDE.md

This file provides technical guidance to Claude Code when working with the Chimera Engine codebase.

## Project Context

### Purpose
Chimera Engine is a **multi-agent development orchestration system** that enables autonomous collaboration between PM, Developer, and QA roles using tmux sessions and Claude Code. This is NOT a user application - it's a development workflow automation tool.

### Core Problem Being Solved
Traditional development workflows suffer from:
- PM role confusion (doing implementation vs. management)
- Manual QA handoffs and context loss
- Agent communication fragmentation
- Cross-platform compatibility issues (especially macOS bash limitations)

### Technical Philosophy
- **Role-based autonomy**: Each agent operates independently within defined constraints
- **Fail-safe design**: Comprehensive error handling with graceful degradation
- **Cross-platform compatibility**: Designed for macOS bash 3.x+ and Linux environments

## Architecture Decisions

### 1. Unified 5-Pane tmux Workspace
**Decision**: Single session `chimera-workspace` with specialized panes
**Rationale**: 
- Reduces session management complexity (vs. 3-session legacy design)
- Enables real-time monitoring across all agents
- Simplifies inter-agent communication routing

```
Pane Layout:
├── 0: PM (Product Management)      [1/3 top]
├── 1: Coder (Implementation)       [1/3 middle] 
├── 2: QA-Functional (Testing)      [1/3 bottom-left]
├── 3: QA-Lead (Quality Mgmt)       [1/3 bottom-center]
└── 4: Monitor (Status/Reports)     [1/3 bottom-right]
```

### 2. Function-Based Configuration System
**Decision**: Use bash functions instead of associative arrays
**Rationale**: macOS ships with bash 3.x which lacks associative array support
**Implementation**: `scripts/lib/config.sh` - `get_agent_pane()`, `get_agent_info()`

### 3. Modular Library Architecture
**Decision**: Split functionality into focused libraries under `scripts/lib/`
**Rationale**: 
- Enables isolated testing of individual components
- Reduces code duplication across scripts
- Facilitates maintenance and debugging

## Critical Implementation Constraints

### 1. PM Role Enforcement
**CRITICAL**: PM must NEVER perform implementation tasks
- **Forbidden tools**: Write, Edit, MultiEdit, Task, Grep, Glob, List
- **Allowed tools**: Bash (tmux send-keys only), Read (CHIMERA_PLAN.md only)
- **Enforcement location**: `instructions/pm-improved.md`

### 2. Agent Auto-Communication Flow
**CRITICAL**: Agents must automatically notify downstream roles
```
Coder completes → auto-notify QA-Functional → auto-notify QA-Lead → auto-notify PM
```
**Implementation**: `chimera send` commands in completion handlers

### 3. macOS Compatibility Requirements (CRITICAL)
**ABSOLUTE REQUIREMENT**: All scripts MUST work with bash 3.x (macOS default)

#### ❌ FORBIDDEN - Never Use These Features:
```bash
# NEVER use associative arrays (bash 4.x+ only)
declare -A ARRAY_NAME           # ❌ FORBIDDEN
ARRAY_NAME["key"]="value"       # ❌ FORBIDDEN

# NEVER use declare -g (bash 4.x+ only)  
declare -g GLOBAL_VAR           # ❌ FORBIDDEN

# NEVER use timeout command (not available on macOS)
timeout 30 command              # ❌ FORBIDDEN
```

#### ✅ REQUIRED - Use These Alternatives:
```bash
# Use functions instead of associative arrays
get_value() {
    case "$1" in
        "key1") echo "value1" ;;
        "key2") echo "value2" ;;
        *) echo "" ;;
    esac
}

# Use regular declare without -g
declare VARIABLE_NAME="value"

# Use alternative timeout implementations
# (See common.sh for portable implementations)
```

#### 🚨 MANDATORY Compatibility Checks:
Every new script MUST include this check:
```bash
# MANDATORY: Check bash version compatibility
if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
    log_warn "Feature requires bash 4.x+ (current: bash ${BASH_VERSION})"
    log_warn "macOS bash 3.x: Feature disabled for compatibility"
    return 0  # Graceful degradation, do not fail
fi
```

#### 📋 macOS Compatibility Checklist:
Before committing ANY script, verify:
- [ ] No `declare -A` anywhere in the file
- [ ] No `["key"]="value"` associative array syntax
- [ ] No `declare -g` global declarations
- [ ] No `timeout` command usage
- [ ] Bash version check for advanced features
- [ ] Test on bash 3.x (or add compatibility check)

## Development Guidelines

### 1. Error Handling Strategy
```bash
# Initialize error handling in all scripts
source "$SCRIPT_DIR/lib/error-handler.sh"
init_error_handling 0 0  # (strict=0 for tmux compatibility, debug=0)
```

### 2. Logging Standards
Use standardized logging functions from `common.sh`:
```bash
log_info "Informational message"
log_warn "Warning message"  
log_error "Error message"
log_success "Success message"
log_debug "Debug message" # Only shown when DEBUG=1
```

### 3. Session Management
**Never assume sessions exist** - always validate:
```bash
if ! session_exists "$session_name"; then
    log_error "Session '$session_name' not found"
    return 1
fi
```

### 4. File Operations
**Use safe operations** from `common.sh`:
```bash
safe_mkdir "$directory"           # Creates with error handling
escape_string "$user_input"       # Escapes shell special characters
```

## Testing Strategy

### 1. Custom Test Framework
**Location**: `tests/lib/test-framework.sh`
**Features**: macOS-compatible bash testing with color output, progress indicators
**Execution**: `./tests/run_all_tests.sh -v` (verbose mode)

### 2. Test Coverage Requirements
- **Unit tests**: All library functions in `scripts/lib/`
- **Integration tests**: End-to-end workflow scenarios
- **Compatibility tests**: macOS and Linux validation

### 3. Test Data Management
**Principle**: Use isolated test environments
**Implementation**: Temporary directories with automatic cleanup
```bash
TEST_WORKSPACE_DIR="${TMPDIR:-/tmp}/chimera-test-$$"
# Auto-cleanup in test teardown
```

## Code Quality Standards

### 1. Shell Scripting Standards
- **Strict mode**: `set -euo pipefail` (disabled in tmux integration scripts)
- **Quoting**: Always quote variables: `"$variable"`
- **Error checking**: Check return codes for all critical operations

### 2. Documentation Requirements
- **Function documentation**: Purpose, parameters, return values
- **Complex logic**: Inline comments explaining rationale
- **Architecture decisions**: Document in this CLAUDE.md file

### 3. Naming Conventions
- **Functions**: `snake_case` (e.g., `create_chimera_session`)
- **Variables**: `UPPER_CASE` for constants, `snake_case` for locals
- **Files**: `kebab-case.sh` for scripts

## Troubleshooting Guide

### 1. tmux Session Issues
**Symptom**: "Session not found" errors
**Cause**: tmux server disconnected or session killed
**Solution**: Run `./scripts/setup-chimera.sh --repair`

### 2. Agent Communication Failures
**Symptom**: Messages not reaching target agents
**Cause**: Pane indices changed or session corrupted
**Debug**: Check with `tmux list-sessions` and `tmux list-panes`

### 3. macOS Compatibility Issues
**Symptom**: "command not found" for GNU tools
**Cause**: macOS uses BSD variants of common tools
**Solution**: Use portable implementations in `common.sh`

## Development Workflow

### 1. Adding New Features
1. **Update this CLAUDE.md** with architectural decisions
2. **Write tests first** (TDD approach)
3. **🚨 CRITICAL: Verify macOS bash 3.x compatibility** (see checklist above)
4. **Implement in modular fashion** (use existing libraries)
5. **Test on both macOS and Linux**
6. **Update agent instructions** if behavior changes

**MANDATORY**: Every new script/function MUST pass macOS compatibility checklist

### 2. Modifying Agent Behavior
1. **Update instruction files** in `instructions/`
2. **Test role compliance** (especially PM constraints)
3. **Verify auto-communication flows**
4. **Update CHIMERA_PLAN.md integration**

### 3. Debugging Agent Issues
1. **Check agent instruction files** for role violations
2. **Verify tmux session structure** with debug commands
3. **Review CHIMERA_PLAN.md** for task state consistency
4. **Use health monitoring** commands for diagnosis

## Version History

- **v0.0.1**: Initial unified 5-agent architecture
- **Legacy**: 3-session system (removed for complexity)

## Repository Structure
```
├── instructions/           # Agent role definitions
├── scripts/               # Core implementation
│   ├── lib/              # Modular libraries
│   ├── setup-chimera.sh  # Main setup script
│   └── chimera-send.sh   # Communication system
├── tests/                # Test framework and suites
├── USER_GUIDE.md         # User documentation (separate from dev guide)
└── CLAUDE.md            # This developer guide
```

## Important Notes for Claude Code

1. **Always read agent instructions** before modifying behavior
2. **Respect role boundaries** especially PM implementation restrictions
3. **🚨 CRITICAL: Ensure macOS bash 3.x compatibility** (see requirements above)
4. **Test thoroughly on macOS** due to bash compatibility issues
5. **Update documentation** when making architectural changes
6. **Use existing library functions** rather than reimplementing

## ⚠️ CRITICAL COMPATIBILITY WARNING

**NEVER IGNORE macOS COMPATIBILITY**: 
- macOS ships with bash 3.x by default
- Using bash 4.x+ features will cause system failure
- Always use the compatibility checklist before implementing
- When in doubt, add bash version checks and graceful degradation

**Failure to follow macOS compatibility will break the entire system for macOS users**

When in doubt, prioritize **macOS compatibility** and **system stability** over feature complexity.