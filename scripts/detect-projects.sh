#!/usr/bin/env bash
# Goldy — Auto-detect git repos inside the workspace
# Usage: source scripts/detect-projects.sh
# Sets GOLDY_PROJECTS array with names of all git repos found

# Work in both bash and zsh
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  _DETECT_SCRIPT="${BASH_SOURCE[0]}"
elif [ -n "${(%):-%x}" 2>/dev/null ]; then
  _DETECT_SCRIPT="${(%):-%x}"
else
  _DETECT_SCRIPT="$0"
fi

# If WORKSPACE is already set (by caller), use it. Otherwise derive from script location.
if [ -z "${WORKSPACE:-}" ]; then
  WORKSPACE="$(cd "$(dirname "$_DETECT_SCRIPT")/.." && pwd)"
fi

GOLDY_PROJECTS=()

for dir in "$WORKSPACE"/*/; do
  [ -d "$dir" ] || continue
  dname=$(basename "$dir")
  # Skip non-repo dirs and goldy's own dirs
  if [ -d "$dir/.git" ] && [ "$dname" != "scripts" ] && [ "$dname" != "docs" ] && [ "$dname" != "goldy" ] && [ "$dname" != "common_assets" ] && [ "$dname" != "claude-review-bot" ] && [ "$dname" != "memory" ]; then
    GOLDY_PROJECTS+=("$dname")
  fi
done

if [ ${#GOLDY_PROJECTS[@]} -eq 0 ]; then
  echo "Goldy: No git repos found in $WORKSPACE"
  echo "  Clone your repos inside this directory first:"
  echo "  git clone https://github.com/your-org/app-ios.git"
  echo "  git clone https://github.com/your-org/app-android.git"
fi
