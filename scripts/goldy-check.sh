#!/usr/bin/env bash
# Goldy — Lightweight health check (runs on every Claude Code session start)
# Usage: ./scripts/goldy-check.sh
#
# What it does (fast — under 5 seconds):
#   1. Auto-detects new repos without hooks → installs them
#   2. Auto-detects repos without changelogs → backfills last 30
#   3. Regenerates TRUTH.md if stale (older than 1 hour)
#   4. Prints a one-line health summary
#
# This script is idempotent — safe to run multiple times.

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
source "$WORKSPACE/scripts/detect-projects.sh"

if [ ${#GOLDY_PROJECTS[@]} -eq 0 ]; then
  echo "Goldy: No repos detected. Clone a repo inside this workspace first."
  exit 0
fi

ACTIONS=0

# ── 1. Auto-install hooks on new repos ──────────────────────
for project in "${GOLDY_PROJECTS[@]}"; do
  hook_file="$WORKSPACE/$project/.git/hooks/post-commit"
  if [ ! -f "$hook_file" ] || ! grep -q "Goldy" "$hook_file" 2>/dev/null; then
    echo "Goldy: Installing hooks for $project..."
    "$WORKSPACE/scripts/install-hooks.sh" >/dev/null 2>&1
    ACTIONS=$((ACTIONS + 1))
    break  # install-hooks.sh handles all projects at once
  fi
done

# ── 2. Auto-backfill repos without changelogs ───────────────
for project in "${GOLDY_PROJECTS[@]}"; do
  changelog_dir="$WORKSPACE/memory/changelogs/$project"
  mkdir -p "$changelog_dir"
  count=$(find "$changelog_dir" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -eq 0 ] && [ -d "$WORKSPACE/$project/.git" ]; then
    echo "Goldy: Backfilling $project (first time detected)..."
    "$WORKSPACE/scripts/backfill.sh" "$project" 30 >/dev/null 2>&1
    ACTIONS=$((ACTIONS + 1))
  fi
done

# ── 3. Regenerate TRUTH.md if stale (>1 hour) ──────────────
if [ -f "$WORKSPACE/TRUTH.md" ]; then
  # Check age in seconds
  if [ "$(uname)" = "Darwin" ]; then
    file_age=$(( $(date +%s) - $(stat -f %m "$WORKSPACE/TRUTH.md") ))
  else
    file_age=$(( $(date +%s) - $(stat -c %Y "$WORKSPACE/TRUTH.md") ))
  fi
  if [ "$file_age" -gt 3600 ]; then
    "$WORKSPACE/scripts/summarize.sh" >/dev/null 2>&1
    "$WORKSPACE/scripts/generate-truth.sh" >/dev/null 2>&1
    ACTIONS=$((ACTIONS + 1))
  fi
else
  mkdir -p "$WORKSPACE/memory/summaries"
  "$WORKSPACE/scripts/summarize.sh" >/dev/null 2>&1
  "$WORKSPACE/scripts/generate-truth.sh" >/dev/null 2>&1
  ACTIONS=$((ACTIONS + 1))
fi

# ── 4. Health summary ───────────────────────────────────────
total_changelogs=0
for project in "${GOLDY_PROJECTS[@]}"; do
  c=$(find "$WORKSPACE/memory/changelogs/$project" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  total_changelogs=$((total_changelogs + c))
done

learnings=0
if [ -d "$WORKSPACE/claude-review-bot/.github/actions/claude-review/learnings" ]; then
  learnings=$(find "$WORKSPACE/claude-review-bot/.github/actions/claude-review/learnings" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
fi

if [ "$ACTIONS" -gt 0 ]; then
  echo "Goldy: Auto-setup complete ($ACTIONS actions). ${#GOLDY_PROJECTS[@]} repos, ${total_changelogs} changelogs, ${learnings} reviewers."
else
  echo "Goldy: OK. ${#GOLDY_PROJECTS[@]} repos, ${total_changelogs} changelogs, ${learnings} reviewers."
fi
