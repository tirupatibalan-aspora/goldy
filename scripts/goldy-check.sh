#!/usr/bin/env bash
# Goldy — Session health check + daily briefing
# Usage: ./scripts/goldy-check.sh
#
# First run:  Shows welcome + what Goldy does + auto-setup
# Daily run:  Shows concise briefing — repos, branches, recent commits, blockers
# Repeat run: One-line OK (same day, already briefed)
#
# This script is idempotent — safe to run multiple times.

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
source "$WORKSPACE/scripts/detect-projects.sh"

# ── Colors ────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────
file_size() {
  if [ "$(uname)" = "Darwin" ]; then
    stat -f %z "$1" 2>/dev/null || echo 0
  else
    stat -c %s "$1" 2>/dev/null || echo 0
  fi
}

file_age_seconds() {
  if [ "$(uname)" = "Darwin" ]; then
    echo $(( $(date +%s) - $(stat -f %m "$1") ))
  else
    echo $(( $(date +%s) - $(stat -c %Y "$1") ))
  fi
}

# ── No repos? ─────────────────────────────────────────────────
if [ ${#GOLDY_PROJECTS[@]} -eq 0 ]; then
  echo ""
  echo -e "${BOLD}Goldy${NC} — AI Project Manager"
  echo ""
  echo "  No repos detected. To get started:"
  echo "    1. Clone your repo(s) inside this directory"
  echo "    2. Run: ./scripts/setup-memory-system.sh --backfill 30"
  echo ""
  exit 0
fi

# ── Detect first run vs returning ─────────────────────────────
MARKER="$WORKSPACE/.goldy-initialized"
TODAY=$(date '+%Y-%m-%d')
IS_FIRST_RUN=false
IS_NEW_DAY=false

if [ ! -f "$MARKER" ]; then
  IS_FIRST_RUN=true
elif [ "$(cat "$MARKER" 2>/dev/null)" != "$TODAY" ]; then
  IS_NEW_DAY=true
fi

# ── Auto-setup (silent for returning users) ───────────────────
ACTIONS=0

# 1. Auto-install hooks on new repos
for project in "${GOLDY_PROJECTS[@]}"; do
  hook_file="$WORKSPACE/$project/.git/hooks/post-commit"
  if [ ! -f "$hook_file" ] || ! grep -q "Goldy" "$hook_file" 2>/dev/null; then
    "$WORKSPACE/scripts/install-hooks.sh" >/dev/null 2>&1
    ACTIONS=$((ACTIONS + 1))
    break
  fi
done

# 2. Auto-backfill repos without changelogs
for project in "${GOLDY_PROJECTS[@]}"; do
  changelog_dir="$WORKSPACE/memory/changelogs/$project"
  mkdir -p "$changelog_dir"
  count=$(find "$changelog_dir" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -eq 0 ] && [ -d "$WORKSPACE/$project/.git" ]; then
    "$WORKSPACE/scripts/backfill.sh" "$project" 30 >/dev/null 2>&1
    ACTIONS=$((ACTIONS + 1))
  fi
done

# 3. Regenerate TRUTH.md if stale (>1 hour)
if [ -f "$WORKSPACE/TRUTH.md" ]; then
  if [ "$(file_age_seconds "$WORKSPACE/TRUTH.md")" -gt 3600 ]; then
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

# ── Collect stats ─────────────────────────────────────────────
total_changelogs=0
for project in "${GOLDY_PROJECTS[@]}"; do
  c=$(find "$WORKSPACE/memory/changelogs/$project" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  total_changelogs=$((total_changelogs + c))
done

learnings=0
learnings_dir="$WORKSPACE/claude-review-bot/.github/actions/claude-review/learnings"
if [ -d "$learnings_dir" ]; then
  learnings=$(find "$learnings_dir" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
fi

# Context memory estimation
ctx_bytes=0
for f in "$WORKSPACE/CLAUDE.md" "$WORKSPACE/TRUTH.md"; do
  [ -f "$f" ] && ctx_bytes=$((ctx_bytes + $(file_size "$f")))
done
_memory_dir="$HOME/.claude/projects/-Users-$(whoami)-Documents-Aspora/memory"
[ -f "$_memory_dir/MEMORY.md" ] && ctx_bytes=$((ctx_bytes + $(file_size "$_memory_dir/MEMORY.md")))
ctx_k=$(( ctx_bytes / 4 / 1000 ))

# ══════════════════════════════════════════════════════════════
# FIRST-TIME USER — Welcome + explain Goldy
# ══════════════════════════════════════════════════════════════
if [ "$IS_FIRST_RUN" = true ]; then
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  Goldy${NC} — AI Project Manager"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  ${CYAN}What is Goldy?${NC}"
  echo "  A shared knowledge base and automation toolkit that syncs"
  echo "  cross-platform, multi-project development — changelogs,"
  echo "  reviewer pattern enforcement, status reports, and health"
  echo "  checks — across iOS, Android, or any repos."
  echo ""
  echo -e "  ${CYAN}Two layers:${NC}"
  echo -e "  ${GREEN}Infrastructure${NC}  Git hooks + bash scripts (zero deps)"
  echo "                  Auto-logs commits, generates summaries, syncs state"
  echo -e "  ${GREEN}Intelligence${NC}    Claude Code + Review Bot + shared memory"
  echo "                  Reads TRUTH.md for instant context, audits PRs"
  echo ""
  echo -e "  ${CYAN}Push philosophy:${NC}"
  echo "  Review Bot audit (min 8/10) → local tests → push"
  echo ""
  echo -e "  ${CYAN}Auto-setup complete:${NC}"

  # Show what was set up
  for project in "${GOLDY_PROJECTS[@]}"; do
    branch=$(cd "$WORKSPACE/$project" && git branch --show-current 2>/dev/null || echo "detached")
    echo -e "    ${GREEN}+${NC} ${BOLD}$project${NC} — branch: $branch, hooks installed, changelogs backfilled"
  done

  echo ""
  echo -e "  ${DIM}Useful commands:${NC}"
  echo "    ./scripts/test-goldy.sh          Run full test suite"
  echo "    ./scripts/generate-report.sh     Status report"
  echo "    ./scripts/add-reviewer.sh        Onboard a reviewer"
  echo "    ./scripts/postreport.sh          Post report to Slack"
  echo ""
  echo -e "  ${DIM}${#GOLDY_PROJECTS[@]} repos | ${total_changelogs} changelogs | ${learnings} reviewers | ~${ctx_k}K/200K context${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  # Mark as initialized
  echo "$TODAY" > "$MARKER"
  exit 0
fi

# ══════════════════════════════════════════════════════════════
# NEW DAY — Daily briefing (concise)
# ══════════════════════════════════════════════════════════════
if [ "$IS_NEW_DAY" = true ]; then
  echo ""
  echo -e "${BOLD}Goldy${NC} — $(date '+%a %b %d')"
  echo -e "${DIM}────────────────────────────────────────${NC}"

  # Per-repo: branch + last commit
  for project in "${GOLDY_PROJECTS[@]}"; do
    branch=$(cd "$WORKSPACE/$project" && git branch --show-current 2>/dev/null || echo "detached")
    last=$(cd "$WORKSPACE/$project" && git log -1 --format='%h %s' 2>/dev/null || echo "no commits")
    last_date=$(cd "$WORKSPACE/$project" && git log -1 --date=short --format='%cd' 2>/dev/null || echo "")

    # Count today's commits
    today_count=$(cd "$WORKSPACE/$project" && git log --since="$TODAY" --oneline 2>/dev/null | wc -l | tr -d ' ')

    echo -e "  ${BOLD}$project${NC}  ${DIM}($branch)${NC}"
    echo -e "    Last: ${last}"
    if [ "$today_count" -gt 0 ]; then
      echo -e "    Today: ${GREEN}${today_count} commits${NC}"
    fi
  done

  echo ""

  # Blockers / alerts
  alerts=0

  # Check for uncommitted changes
  for project in "${GOLDY_PROJECTS[@]}"; do
    dirty=$(cd "$WORKSPACE/$project" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$dirty" -gt 0 ]; then
      echo -e "  ${YELLOW}!${NC} $project has $dirty uncommitted changes"
      alerts=$((alerts + 1))
    fi
  done

  # Check if TRUTH.md is stale (>2 hours)
  if [ -f "$WORKSPACE/TRUTH.md" ]; then
    age=$(file_age_seconds "$WORKSPACE/TRUTH.md")
    if [ "$age" -gt 7200 ]; then
      hours=$((age / 3600))
      echo -e "  ${YELLOW}!${NC} TRUTH.md is ${hours}h old (auto-refreshes at 1h)"
      alerts=$((alerts + 1))
    fi
  fi

  # Check for missing hooks
  for project in "${GOLDY_PROJECTS[@]}"; do
    hook_file="$WORKSPACE/$project/.git/hooks/post-commit"
    if [ ! -f "$hook_file" ] || ! grep -q "Goldy" "$hook_file" 2>/dev/null; then
      echo -e "  ${RED}!${NC} $project missing post-commit hook"
      alerts=$((alerts + 1))
    fi
  done

  if [ "$alerts" -eq 0 ]; then
    echo -e "  ${GREEN}No blockers${NC}"
  fi

  echo ""
  echo -e "  ${DIM}${#GOLDY_PROJECTS[@]} repos | ${total_changelogs} changelogs | ${learnings} reviewers | ~${ctx_k}K/200K context${NC}"

  if [ "$ACTIONS" -gt 0 ]; then
    echo -e "  ${DIM}Auto-fixed $ACTIONS issue(s) this session${NC}"
  fi

  echo -e "${DIM}────────────────────────────────────────${NC}"
  echo ""

  # Update marker
  echo "$TODAY" > "$MARKER"
  exit 0
fi

# ══════════════════════════════════════════════════════════════
# SAME DAY, ALREADY BRIEFED — One-line status
# ══════════════════════════════════════════════════════════════
status="${#GOLDY_PROJECTS[@]} repos, ${total_changelogs} changelogs, ${learnings} reviewers, ~${ctx_k}K/200K context"

if [ "$ACTIONS" -gt 0 ]; then
  echo -e "Goldy: Auto-fixed $ACTIONS issue(s). $status"
else
  echo -e "Goldy: OK. $status"
fi
