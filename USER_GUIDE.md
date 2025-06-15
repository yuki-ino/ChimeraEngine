# 🦁 Chimera Engine - User Guide

Multi-agent development system powered by Claude Code

## 🚀 Quick Start

### One-liner Installation
```bash
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/scripts/install.sh | bash
cd your-project
chimera init
chimera start
```

### Immediate Use
- 🎯 **PM**: Project planning to development instructions
- 👨‍💻 **Coder**: AI-era full-stack development  
- 🧪 **QA**: Feature testing + quality management specialization

## 📋 Essential Commands

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

## 🎯 PM Planning Mode

The PM operates in two phases:
1. **Planning Mode**: Private planning without team notifications
2. **Development Mode**: Active team coordination

Trigger development start:
```bash
chimera send pm-self "START_DEVELOPMENT"
```

## 🔧 Project Analysis Features

Automatically detects and configures:
- **JavaScript/TypeScript**: Jest, Vitest, Cypress, Playwright, Testing Library
- **Python**: pytest, unittest
- **Other**: Rust (cargo test), Go (go test), Java (Maven/Gradle)

Generated files:
- `.chimera/project-analysis.json`: Analysis results
- `instructions/tester-custom.md`: Project-specific test instructions

## 📚 Usage Examples

### React + TypeScript Project
```bash
cd my-react-app
chimera init

# Auto-detection results:
# ✅ React + TypeScript detected
# ✅ Jest + Testing Library detected
# ✅ package.json test scripts detected
# 📄 Custom test manual generated

chimera start

# In PM session for planning
"あなたはPMです。指示書に従って"
# → Planning mode starts, no team notifications

# After planning confirmation
./chimera send coder "Implement user authentication feature"
./chimera send qa-functional "Prepare testing for authentication feature"
```

### Python FastAPI Project
```bash
cd my-fastapi-project
chimera init

# Auto-detection results:
# ✅ Python project detected
# ✅ pytest framework detected
# ✅ requirements.txt detected
# 📄 Python test manual generated

# Actual development flow
./chimera send coder "Implement API endpoint /users"
# → Actual uvicorn startup, pytest execution commands auto-generated
```

## 🚀 Development Workflow

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

## 📄 License

MIT License - Free to use, modify, and distribute

## 🙏 Acknowledgments

- [Claude Code](https://claude.ai/code) - AI pair programming environment
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [Claude-Code-Communication](https://github.com/nishimoto265/Claude-Code-Communication) - Multi-agent communication system

---

**🚀 Experience PM/Dev/QA cycle in 1 minute!**

```bash
curl -sSL https://raw.githubusercontent.com/yuki-ino/ChimeraEngine/main/scripts/install.sh | bash && chimera init && chimera start
```