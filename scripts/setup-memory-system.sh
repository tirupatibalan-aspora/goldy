#!/usr/bin/env bash
# Goldy — One-command setup for Cross-Project Memory
# Usage: ./scripts/setup-memory-system.sh [--backfill N]
#
# What it does:
#   1. Creates memory/changelogs/ and memory/summaries/ directories
#   2. Installs post-commit hooks in vance-ios and vance-android
#   3. Optionally backfills N commits from each repo
#   4. Generates initial summaries and TRUTH.md

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
BACKFILL_COUNT=0

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --backfill) BACKFILL_COUNT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

echo "=== Goldy Setup ==="
echo "Workspace: $WORKSPACE"
echo ""

# Step 1: Create directories
echo "Step 1: Creating directory structure..."
mkdir -p "$WORKSPACE/memory/changelogs/vance-ios"
mkdir -p "$WORKSPACE/memory/changelogs/vance-android"
mkdir -p "$WORKSPACE/memory/summaries"
echo "  ✓ memory/changelogs/vance-ios/"
echo "  ✓ memory/changelogs/vance-android/"
echo "  ✓ memory/summaries/"
echo ""

# Step 2: Make scripts executable
echo "Step 2: Making scripts executable..."
chmod +x "$WORKSPACE/scripts/"*.sh
echo "  ✓ All scripts in scripts/ are executable"
echo ""

# Step 3: Install hooks
echo "Step 3: Installing post-commit hooks..."
"$WORKSPACE/scripts/install-hooks.sh"
echo ""

# Step 4: Backfill (optional)
if [ "$BACKFILL_COUNT" -gt 0 ]; then
  echo "Step 4: Backfilling last $BACKFILL_COUNT commits..."
  "$WORKSPACE/scripts/backfill.sh" vance-ios "$BACKFILL_COUNT"
  "$WORKSPACE/scripts/backfill.sh" vance-android "$BACKFILL_COUNT"
  echo ""
fi

# Step 5: Generate summaries + TRUTH.md
echo "Step 5: Generating summaries and TRUTH.md..."
"$WORKSPACE/scripts/summarize.sh"
"$WORKSPACE/scripts/generate-truth.sh"
echo ""

echo "=== Goldy Setup Complete ==="
echo ""
echo "What happens now:"
echo "  • Every commit in vance-ios/ or vance-android/ auto-creates a changelog"
echo "  • Summaries and TRUTH.md refresh automatically (background, non-blocking)"
echo "  • Claude Code reads TRUTH.md for instant cross-project state"
echo ""
echo "Manual commands:"
echo "  ./scripts/backfill.sh <project> <count>   — Backfill from git history"
echo "  ./scripts/summarize.sh [project]           — Regenerate summaries"
echo "  ./scripts/generate-truth.sh                — Regenerate TRUTH.md"
echo "  ./scripts/install-hooks.sh                 — Reinstall hooks"
