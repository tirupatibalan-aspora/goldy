#!/usr/bin/env bash
# Goldy — Install post-commit hooks in all sub-project repos
# Usage: install-hooks.sh

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"

# Auto-detect projects
source "$WORKSPACE/scripts/detect-projects.sh"
PROJECTS=("${GOLDY_PROJECTS[@]}")

for project in "${PROJECTS[@]}"; do
  repo_dir="$WORKSPACE/$project"
  hook_file="$repo_dir/.git/hooks/post-commit"

  if [ ! -d "$repo_dir/.git" ]; then
    echo "SKIP: $project — not a git repo"
    continue
  fi

  # Create hooks directory if needed
  mkdir -p "$repo_dir/.git/hooks"

  # Check if hook already exists
  if [ -f "$hook_file" ]; then
    if grep -q "Goldy" "$hook_file" 2>/dev/null; then
      echo "OK: $project — Goldy hook already installed"
      continue
    fi
    # Append to existing hook
    cat >> "$hook_file" <<HOOK

# --- Goldy: Cross-Project Memory (auto-tracking) ---
"$WORKSPACE/scripts/log-commit.sh" "$project" "$WORKSPACE" &
(sleep 2 && "$WORKSPACE/scripts/summarize.sh" "$project" && "$WORKSPACE/scripts/generate-truth.sh") &>/dev/null &
# --- End Goldy ---
HOOK
    echo "UPDATED: $project — appended Goldy to existing post-commit hook"
  else
    # Create new hook
    cat > "$hook_file" <<HOOK
#!/usr/bin/env bash
# Post-commit hook — auto-installed by Goldy

# --- Goldy: Cross-Project Memory (auto-tracking) ---
"$WORKSPACE/scripts/log-commit.sh" "$project" "$WORKSPACE" &
(sleep 2 && "$WORKSPACE/scripts/summarize.sh" "$project" && "$WORKSPACE/scripts/generate-truth.sh") &>/dev/null &
# --- End Goldy ---
HOOK
    echo "INSTALLED: $project — new post-commit hook created"
  fi

  chmod +x "$hook_file"
done

echo ""
echo "Goldy hooks installed. Every commit in sub-projects will auto-generate changelogs."
