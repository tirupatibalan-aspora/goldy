#!/usr/bin/env bash
# Goldy — Detect current user via GitHub CLI + git config
# Usage: source scripts/detect-user.sh
#
# Sets these variables:
#   GOLDY_USER_NAME     — display name (e.g., "Tirupati Balan")
#   GOLDY_USER_LOGIN    — GitHub username (e.g., "tirupatibalan-aspora")
#   GOLDY_USER_EMAIL    — email (e.g., "tirupati.balan@aspora.com")
#   GOLDY_USER_GIT_NAME — git author name for commit filtering
#
# Reads from .goldy-user.conf if it exists (cached).
# Otherwise auto-detects from gh CLI / git config and writes .goldy-user.conf.

if [ -z "${WORKSPACE:-}" ]; then
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  else
    WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
  fi
fi

GOLDY_USER_CONF="$WORKSPACE/.goldy-user.conf"

# ── Load from cache ──────────────────────────────────────────
if [ -f "$GOLDY_USER_CONF" ]; then
  source "$GOLDY_USER_CONF"
fi

# ── Auto-detect if not cached ────────────────────────────────
if [ -z "${GOLDY_USER_LOGIN:-}" ] || [ -z "${GOLDY_USER_NAME:-}" ] || [ "${GOLDY_USER_NAME:-}" = "None" ]; then

  GOLDY_USER_LOGIN=""
  GOLDY_USER_NAME=""
  GOLDY_USER_EMAIL=""
  GOLDY_USER_GIT_NAME=""

  # Try GitHub CLI for login
  if command -v gh &>/dev/null; then
    GOLDY_USER_LOGIN=$(gh api user --jq '.login // empty' 2>/dev/null || echo "")
    _gh_name=$(gh api user --jq '.name // empty' 2>/dev/null || echo "")
    _gh_email=$(gh api user --jq '.email // empty' 2>/dev/null || echo "")
    [ -n "$_gh_name" ] && GOLDY_USER_NAME="$_gh_name"
    [ -n "$_gh_email" ] && GOLDY_USER_EMAIL="$_gh_email"
  fi

  # Fallback: git config (check repo-level first via any detected project, then global)
  _first_repo=""
  for dir in "$WORKSPACE"/*/; do
    if [ -d "$dir/.git" ]; then
      _first_repo="$dir"
      break
    fi
  done

  if [ -z "${GOLDY_USER_NAME:-}" ] && [ -n "$_first_repo" ]; then
    GOLDY_USER_NAME=$(cd "$_first_repo" && git config user.name 2>/dev/null || echo "")
  fi
  if [ -z "${GOLDY_USER_NAME:-}" ]; then
    GOLDY_USER_NAME=$(git config --global user.name 2>/dev/null || echo "")
  fi

  if [ -z "${GOLDY_USER_EMAIL:-}" ] && [ -n "$_first_repo" ]; then
    GOLDY_USER_EMAIL=$(cd "$_first_repo" && git config user.email 2>/dev/null || echo "")
  fi
  if [ -z "${GOLDY_USER_EMAIL:-}" ]; then
    GOLDY_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
  fi

  if [ -z "${GOLDY_USER_LOGIN:-}" ] && [ -n "${GOLDY_USER_EMAIL:-}" ]; then
    # Derive login from email (before @) as last resort
    GOLDY_USER_LOGIN=$(echo "${GOLDY_USER_EMAIL}" | cut -d'@' -f1 | tr '.' '-')
  fi

  # Git author name (used for filtering commits)
  if [ -n "$_first_repo" ]; then
    GOLDY_USER_GIT_NAME=$(cd "$_first_repo" && git config user.name 2>/dev/null || echo "")
  fi
  if [ -z "${GOLDY_USER_GIT_NAME:-}" ]; then
    GOLDY_USER_GIT_NAME="${GOLDY_USER_NAME:-}"
  fi

  # ── Cache to file ────────────────────────────────────────────
  if [ -n "${GOLDY_USER_LOGIN:-}" ] && [ -n "${GOLDY_USER_NAME:-}" ]; then
    cat > "$GOLDY_USER_CONF" <<EOF
# Goldy user config — auto-generated, edit if needed
GOLDY_USER_NAME="${GOLDY_USER_NAME}"
GOLDY_USER_LOGIN="${GOLDY_USER_LOGIN}"
GOLDY_USER_EMAIL="${GOLDY_USER_EMAIL:-}"
GOLDY_USER_GIT_NAME="${GOLDY_USER_GIT_NAME:-${GOLDY_USER_NAME}}"
EOF
    echo "Goldy: detected user → ${GOLDY_USER_NAME} (@${GOLDY_USER_LOGIN})" >&2
  fi
fi

# Ensure git name is set for commit filtering
if [ -z "${GOLDY_USER_GIT_NAME:-}" ]; then
  GOLDY_USER_GIT_NAME="${GOLDY_USER_NAME:-}"
fi
