#!/usr/bin/env bash
# Goldy — Backfill changelogs from existing git history
# Usage: backfill.sh <project> [count]  (default: 30 commits)

set -euo pipefail

PROJECT="${1:?Usage: backfill.sh <project> [count]}"
COUNT="${2:-30}"
WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
REPO_DIR="$WORKSPACE/$PROJECT"
CHANGELOG_DIR="$WORKSPACE/memory/changelogs/$PROJECT"

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "ERROR: $REPO_DIR is not a git repo"
  exit 1
fi

mkdir -p "$CHANGELOG_DIR"

cd "$REPO_DIR"

echo "Goldy: backfilling last $COUNT commits from $PROJECT..."

# Get commit hashes (oldest first)
HASHES=$(git log --format='%H' -"$COUNT" | tail -r)

backfilled=0
skipped=0

for full_hash in $HASHES; do
  hash=$(git rev-parse --short "$full_hash")
  commit_date=$(git log -1 --date=short --format='%cd' "$full_hash")
  commit_time=$(git log -1 --format='%ci' "$full_hash" | cut -d' ' -f2 | cut -c1-8)
  outfile="$CHANGELOG_DIR/${commit_date}_${hash}.md"

  # Skip if already exists
  if [ -f "$outfile" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  author=$(git log -1 --format='%an' "$full_hash")
  branch_name=$(git branch --show-current 2>/dev/null || echo "unknown")
  message=$(git log -1 --format='%s' "$full_hash")
  body=$(git log -1 --format='%b' "$full_hash")
  files_changed=$(git diff-tree --no-commit-id --name-status -r "$full_hash" 2>/dev/null || echo "")
  stat_line=$(git diff-tree --no-commit-id --stat -r "$full_hash" 2>/dev/null | tail -1 || echo "")

  cat > "$outfile" <<ENDOFFILE
# $message

| Field | Value |
|-------|-------|
| **Project** | $PROJECT |
| **Date** | $commit_date |
| **Commit** | \`$hash\` |
| **Author** | $author |
| **Branch** | \`$branch_name\` |

## Files Changed

\`\`\`
$files_changed
\`\`\`

## Diff Summary

$stat_line
ENDOFFILE

  if [ -n "$body" ]; then
    cat >> "$outfile" <<ENDOFBODY

## Details

$body
ENDOFBODY
  fi

  backfilled=$((backfilled + 1))
done

echo "Goldy: backfilled $backfilled commits, skipped $skipped (already exist)"
echo "Goldy: changelogs at $CHANGELOG_DIR/"
