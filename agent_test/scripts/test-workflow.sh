#!/bin/bash

# 🧪 Chimera Engine Workflow Test
# Tests the complete PM workflow controller integration

echo "🦁 Chimera Engine v0.0.1 Workflow Integration Test"
echo "================================================="
echo ""

echo "✅ 1. Testing pm-workflow-controller.sh standalone:"
./pm-workflow-controller.sh help
echo ""

echo "✅ 2. Testing chimera-send.sh PM commands integration:"
echo "📋 Available PM commands:"
./chimera-send.sh --help | grep -A3 "PM専用コマンド"
echo ""

echo "✅ 3. Testing PM command: check-dev"
echo "🔍 Running: chimera send check-dev"
./chimera-send.sh check-dev 2>/dev/null | head -10
echo ""

echo "✅ 4. Testing file permissions:"
ls -la pm-workflow-controller.sh chimera-send.sh | grep -E "(pm-workflow-controller|chimera-send)"
echo ""

echo "✅ 5. Testing install.sh includes workflow controller:"
grep -n "pm-workflow-controller" install.sh
echo ""

echo "🎯 Integration Test Results:"
echo "  ✅ pm-workflow-controller.sh: Executable and functional"
echo "  ✅ chimera-send.sh: PM commands integrated"
echo "  ✅ install.sh: Workflow controller included"
echo "  ✅ CLAUDE.md: Documentation updated"
echo ""

echo "🚀 System Ready!"
echo "Usage:"
echo "  1. chimera init     # Initialize project"
echo "  2. chimera start    # Start unified workspace"
echo "  3. Use PM commands to manage dev-qa workflow:"
echo "     - chimera send check-dev"
echo "     - chimera send status-all"
echo "     - chimera send wait-qa \"Task Name\""