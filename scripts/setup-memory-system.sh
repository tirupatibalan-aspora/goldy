#!/usr/bin/env bash
# Goldy — One-command setup for Cross-Project Memory
# Usage: ./scripts/setup-memory-system.sh [--backfill N]
#
# What it does:
#   1. Auto-detects git repos inside this workspace
#   2. Creates memory/changelogs/ and memory/summaries/ directories
#   3. Installs post-commit hooks in all detected repos
#   4. Optionally backfills N commits from each repo
#   5. Generates initial summaries and TRUTH.md

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

# Step 0: Detect user via GitHub CLI / git config
echo "Step 0: Detecting user..."
source "$WORKSPACE/scripts/detect-user.sh"
if [ -n "${GOLDY_USER_LOGIN:-}" ]; then
  echo "  ✓ User: ${GOLDY_USER_NAME} (@${GOLDY_USER_LOGIN})"
  echo "  ✓ Email: ${GOLDY_USER_EMAIL:-n/a}"
  echo "  ✓ Git author: ${GOLDY_USER_GIT_NAME}"
  echo "  ✓ Config saved to .goldy-user.conf"
else
  echo "  ⚠ Could not detect user. Install gh CLI or set git config user.name/email."
  echo "  Reports will show all commits (unfiltered)."
fi
echo ""

# Auto-detect repos
source "$WORKSPACE/scripts/detect-projects.sh"

if [ ${#GOLDY_PROJECTS[@]} -eq 0 ]; then
  echo "ERROR: No git repos found in $WORKSPACE"
  echo "  Clone your repos inside this directory first:"
  echo "  git clone https://github.com/your-org/app-ios.git"
  exit 1
fi

echo "Detected projects: ${GOLDY_PROJECTS[*]}"
echo ""

# Step 1: Create directories
echo "Step 1: Creating directory structure..."
mkdir -p "$WORKSPACE/memory/summaries"
mkdir -p "$WORKSPACE/memory/projects"
mkdir -p "$WORKSPACE/memory/people"
for project in "${GOLDY_PROJECTS[@]}"; do
  mkdir -p "$WORKSPACE/memory/changelogs/$project"
  echo "  ✓ memory/changelogs/$project/"
done
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
  for project in "${GOLDY_PROJECTS[@]}"; do
    "$WORKSPACE/scripts/backfill.sh" "$project" "$BACKFILL_COUNT"
  done
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
echo "  • Every commit in your repos auto-creates a changelog"
echo "  • Summaries and TRUTH.md refresh automatically (background, non-blocking)"
echo "  • Claude Code reads TRUTH.md for instant cross-project state"
echo ""
echo "Manual commands:"
echo "  ./scripts/backfill.sh <project> <count>   — Backfill from git history"
echo "  ./scripts/summarize.sh [project]           — Regenerate summaries"
echo "  ./scripts/generate-truth.sh                — Regenerate TRUTH.md"
echo "  ./scripts/install-hooks.sh                 — Reinstall hooks"
