#!/usr/bin/env bash
# Goldy — Interactive setup wizard
# Usage: ./setup.sh
#
# One-command onboarding for new developers:
#   1. Asks your name, email, GitHub username (or auto-detects)
#   2. Asks for repo URLs to clone
#   3. Clones repos, installs hooks, backfills changelogs
#   4. Generates TRUTH.md + summaries
#   5. Verifies everything works
#
# For non-interactive setup, use: ./scripts/setup-memory-system.sh --backfill 30

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")" && pwd)"

# ── Colors ────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────
prompt_with_default() {
  local prompt="$1"
  local default="$2"
  local result
  if [ -n "$default" ]; then
    printf "  %s [%s]: " "$prompt" "$default"
  else
    printf "  %s: " "$prompt"
  fi
  read -r result
  echo "${result:-$default}"
}

# ══════════════════════════════════════════════════════════════
# WELCOME
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Goldy Setup Wizard${NC}"
echo -e "${BOLD}  Cross-Project Memory for Claude Code${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  This wizard will set up your workspace in ~2 minutes."
echo ""

# ══════════════════════════════════════════════════════════════
# STEP 1: Developer identity
# ══════════════════════════════════════════════════════════════
echo -e "${CYAN}Step 1/4: Who are you?${NC}"
echo ""

# Auto-detect from gh CLI / git config
_auto_name=""
_auto_login=""
_auto_email=""

if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  _auto_login=$(gh api user --jq '.login // empty' 2>/dev/null || echo "")
  _auto_name=$(gh api user --jq '.name // empty' 2>/dev/null || echo "")
  _auto_email=$(gh api user --jq '.email // empty' 2>/dev/null || echo "")
fi

if [ -z "$_auto_name" ]; then
  _auto_name=$(git config --global user.name 2>/dev/null || echo "")
fi
if [ -z "$_auto_email" ]; then
  _auto_email=$(git config --global user.email 2>/dev/null || echo "")
fi

if [ -n "$_auto_login" ] || [ -n "$_auto_name" ]; then
  echo -e "  ${DIM}Auto-detected from $([ -n "$_auto_login" ] && echo "GitHub CLI" || echo "git config"):${NC}"
  [ -n "$_auto_name" ] && echo -e "    Name:   $_auto_name"
  [ -n "$_auto_login" ] && echo -e "    GitHub: @$_auto_login"
  [ -n "$_auto_email" ] && echo -e "    Email:  $_auto_email"
  echo ""
fi

USER_NAME=$(prompt_with_default "Your name" "$_auto_name")
USER_EMAIL=$(prompt_with_default "Your email" "$_auto_email")
USER_LOGIN=$(prompt_with_default "GitHub username" "$_auto_login")

# Derive git name for commit filtering
USER_GIT_NAME="$USER_NAME"

echo ""
echo -e "  ${GREEN}+${NC} Identity: ${USER_NAME} (@${USER_LOGIN})"
echo ""

# ══════════════════════════════════════════════════════════════
# STEP 2: Repos to clone
# ══════════════════════════════════════════════════════════════
echo -e "${CYAN}Step 2/4: Which repos do you work on?${NC}"
echo ""

# Check for repos already present
EXISTING_REPOS=()
for dir in "$WORKSPACE"/*/; do
  [ -d "$dir/.git" ] || continue
  dname=$(basename "$dir")
  [ "$dname" = "goldy" ] || [ "$dname" = "scripts" ] || [ "$dname" = "docs" ] || \
  [ "$dname" = "common_assets" ] || [ "$dname" = "claude-review-bot" ] || [ "$dname" = "memory" ] && continue
  EXISTING_REPOS+=("$dname")
done

if [ ${#EXISTING_REPOS[@]} -gt 0 ]; then
  echo -e "  ${DIM}Already in workspace:${NC}"
  for repo in "${EXISTING_REPOS[@]}"; do
    branch=$(cd "$WORKSPACE/$repo" && git branch --show-current 2>/dev/null || echo "detached")
    echo -e "    ${GREEN}+${NC} $repo ($branch)"
  done
  echo ""
fi

echo "  Paste repo URLs to clone (one per line)."
echo "  Press Enter on an empty line when done."
echo -e "  ${DIM}Example: git@github.com:your-org/app-ios.git${NC}"
echo ""

CLONE_URLS=()
while true; do
  printf "  Repo URL: "
  read -r url
  [ -z "$url" ] && break
  CLONE_URLS+=("$url")
done

# Clone repos
CLONED=()
if [ ${#CLONE_URLS[@]} -gt 0 ]; then
  echo ""
  for url in "${CLONE_URLS[@]}"; do
    # Extract repo name from URL (strip .git suffix, take last path component)
    repo_name=$(basename "$url" .git)

    if [ -d "$WORKSPACE/$repo_name" ]; then
      echo -e "  ${YELLOW}!${NC} $repo_name already exists, skipping clone"
      CLONED+=("$repo_name")
      continue
    fi

    echo -e "  Cloning ${BOLD}$repo_name${NC}..."
    if git clone "$url" "$WORKSPACE/$repo_name" 2>&1 | tail -1; then
      CLONED+=("$repo_name")
      echo -e "  ${GREEN}+${NC} $repo_name cloned"
    else
      echo -e "  ${RED}x${NC} Failed to clone $url"
    fi
  done
fi

echo ""

# Check we have at least one repo
ALL_REPOS=("${EXISTING_REPOS[@]}" "${CLONED[@]}")
# Deduplicate
REPOS=()
declare -A _seen 2>/dev/null || true
for r in "${ALL_REPOS[@]}"; do
  if [ -z "${_seen[$r]:-}" ]; then
    REPOS+=("$r")
    _seen[$r]=1
  fi
done

if [ ${#REPOS[@]} -eq 0 ]; then
  echo -e "  ${RED}No repos found.${NC} Clone at least one repo and re-run ./setup.sh"
  exit 1
fi

echo -e "  ${GREEN}+${NC} Workspace repos: ${REPOS[*]}"
echo ""

# ══════════════════════════════════════════════════════════════
# STEP 3: Optional config
# ══════════════════════════════════════════════════════════════
echo -e "${CYAN}Step 3/4: Optional config${NC}"
echo ""

SLACK_CHANNEL=$(prompt_with_default "Slack channel ID for reports (press Enter to skip)" "")
echo ""

# ══════════════════════════════════════════════════════════════
# STEP 4: Run setup
# ══════════════════════════════════════════════════════════════
echo -e "${CYAN}Step 4/4: Setting up Goldy...${NC}"
echo ""

# 4a. Write .goldy-user.conf (gitignored, local only)
cat > "$WORKSPACE/.goldy-user.conf" <<EOF
# Goldy user config — auto-generated by setup.sh, edit if needed
GOLDY_USER_NAME="${USER_NAME}"
GOLDY_USER_LOGIN="${USER_LOGIN}"
GOLDY_USER_EMAIL="${USER_EMAIL}"
GOLDY_USER_GIT_NAME="${USER_GIT_NAME}"
EOF
echo -e "  ${GREEN}+${NC} .goldy-user.conf created (local only, gitignored)"

# 4b. Write Slack config if provided
if [ -n "$SLACK_CHANNEL" ]; then
  mkdir -p "$WORKSPACE/memory"
  cat > "$WORKSPACE/memory/reference_slack_channel.md" <<EOF
---
name: Slack channel for reports
type: reference
---
Channel ID: ${SLACK_CHANNEL}
EOF
  echo -e "  ${GREEN}+${NC} Slack channel saved"
fi

# 4c. Run the existing setup pipeline
echo -e "  ${DIM}Installing hooks + backfilling changelogs...${NC}"
"$WORKSPACE/scripts/setup-memory-system.sh" --backfill 30 2>&1 | while IFS= read -r line; do
  # Show progress but not verbose output
  case "$line" in
    *"✓"*|*"Step"*|*"Detected"*|*"=== Goldy"*|*"Complete"*)
      echo "    $line" ;;
  esac
done

# 4d. Verify
echo ""
echo -e "  ${DIM}Running verification...${NC}"
VERIFY_PASS=true

# Check hooks installed
for repo in "${REPOS[@]}"; do
  hook="$WORKSPACE/$repo/.git/hooks/post-commit"
  if [ -f "$hook" ] && grep -q "Goldy" "$hook" 2>/dev/null; then
    echo -e "    ${GREEN}+${NC} $repo: hooks installed"
  else
    echo -e "    ${RED}x${NC} $repo: hooks missing"
    VERIFY_PASS=false
  fi
done

# Check TRUTH.md exists
if [ -f "$WORKSPACE/TRUTH.md" ]; then
  echo -e "    ${GREEN}+${NC} TRUTH.md generated"
else
  echo -e "    ${RED}x${NC} TRUTH.md missing"
  VERIFY_PASS=false
fi

# Check changelogs
for repo in "${REPOS[@]}"; do
  count=$(find "$WORKSPACE/memory/changelogs/$repo" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    echo -e "    ${GREEN}+${NC} $repo: $count changelogs"
  else
    echo -e "    ${YELLOW}!${NC} $repo: no changelogs yet (will populate on first commit)"
  fi
done

# ══════════════════════════════════════════════════════════════
# DONE
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Setup complete!${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  What happens now:"
echo ""
echo "  1. Open this directory in Claude Code:"
echo -e "     ${DIM}cd $WORKSPACE && claude${NC}"
echo ""
echo "  2. Claude auto-reads TRUTH.md + CLAUDE.md = full project context"
echo ""
echo "  3. Every commit auto-logs to memory/changelogs/"
echo ""
echo "  Useful commands:"
echo -e "    ${DIM}goldycheck${NC}       — Health check (run every session)"
echo -e "    ${DIM}goldyreport${NC}      — Status report"
echo -e "    ${DIM}goldytest${NC}        — Run diagnostic checks"
echo -e "    ${DIM}goldyreviewer${NC}    — Onboard a code reviewer"
echo ""
if [ "$VERIFY_PASS" = false ]; then
  echo -e "  ${YELLOW}Some checks failed. Run ./scripts/test-goldy.sh for details.${NC}"
  echo ""
fi
echo -e "  ${DIM}Docs: https://github.com/tirupatibalan-aspora/goldy${NC}"
echo ""
