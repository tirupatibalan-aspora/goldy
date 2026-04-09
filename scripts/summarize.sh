#!/usr/bin/env bash
# Goldy — Generate per-project summary from changelogs
# Usage: summarize.sh [project]  (no arg = all projects)

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
CHANGELOG_BASE="$WORKSPACE/memory/changelogs"
SUMMARY_DIR="$WORKSPACE/memory/summaries"

# Auto-detect projects (or use provided arg)
source "$WORKSPACE/scripts/detect-projects.sh"
PROJECTS=("${GOLDY_PROJECTS[@]}")

mkdir -p "$SUMMARY_DIR"

summarize_project() {
  local project="$1"
  local changelog_dir="$CHANGELOG_BASE/$project"
  local outfile="$SUMMARY_DIR/$project.md"
  local repo_dir="$WORKSPACE/$project"

  if [ ! -d "$changelog_dir" ]; then
    echo "No changelogs for $project, skipping."
    return
  fi

  # Count changelogs
  local total=$(find "$changelog_dir" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')

  # Current branch and last commit
  local branch="N/A"
  local last_commit="N/A"
  local last_date="N/A"
  if [ -d "$repo_dir/.git" ]; then
    branch=$(cd "$repo_dir" && git branch --show-current 2>/dev/null || echo "detached")
    last_commit=$(cd "$repo_dir" && git log -1 --format='%h %s' 2>/dev/null || echo "N/A")
    last_date=$(cd "$repo_dir" && git log -1 --date=short --format='%cd' 2>/dev/null || echo "N/A")
  fi

  # Recent changes (14-day window)
  local cutoff=$(date -v-14d '+%Y-%m-%d' 2>/dev/null || date -d '14 days ago' '+%Y-%m-%d' 2>/dev/null || echo "2026-01-01")

  cat > "$outfile" <<EOF
# $project — Summary

| Field | Value |
|-------|-------|
| **Branch** | \`$branch\` |
| **Last Commit** | $last_commit |
| **Last Activity** | $last_date |
| **Total Changelogs** | $total |

## Recent Changes (14 days)

EOF

  # List recent changelogs (sorted newest first)
  local found_recent=0
  for f in $(find "$changelog_dir" -name '*.md' -newer "$changelog_dir" 2>/dev/null | sort -r | head -20); do
    local fname=$(basename "$f" .md)
    local fdate=${fname%%_*}
    if [[ "$fdate" > "$cutoff" ]] || [[ "$fdate" == "$cutoff" ]]; then
      local title=$(head -1 "$f" | sed 's/^# //')
      echo "- **$fdate** — $title" >> "$outfile"
      found_recent=1
    fi
  done

  # Fallback: just list the 20 most recent files by name
  if [ "$found_recent" -eq 0 ]; then
    for f in $(ls -1 "$changelog_dir"/*.md 2>/dev/null | sort -r | head -20); do
      local fname=$(basename "$f" .md)
      local fdate=${fname%%_*}
      local title=$(head -1 "$f" | sed 's/^# //')
      echo "- **$fdate** — $title" >> "$outfile"
    done
  fi

  # Feature areas (from conventional commits)
  cat >> "$outfile" <<EOF

## Feature Areas

EOF

  # Group by commit type prefix
  for prefix in "feat" "fix" "refactor" "docs" "test" "style" "chore"; do
    local count=$(grep -rl "^# ${prefix}" "$changelog_dir" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -gt 0 ]; then
      echo "- **$prefix**: $count commits" >> "$outfile"
    fi
  done

  # Frequently modified files (from git log)
  if [ -d "$repo_dir/.git" ]; then
    cat >> "$outfile" <<EOF

## Frequently Modified Files (last 50 commits)

\`\`\`
$(cd "$repo_dir" && git log --pretty=format: --name-only -50 2>/dev/null | sort | uniq -c | sort -rn | head -15 | sed 's/^  *//')
\`\`\`
EOF
  fi

  echo "Goldy: summarized $project → $outfile ($total changelogs)"
}

# Run for specified project or all
if [ -n "${1:-}" ]; then
  summarize_project "$1"
else
  for p in "${PROJECTS[@]}"; do
    summarize_project "$p"
  done
fi
