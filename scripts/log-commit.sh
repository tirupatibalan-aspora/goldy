#!/usr/bin/env bash
# Goldy — Log a single commit as structured markdown
# Called by post-commit hook in each sub-project
# Usage: log-commit.sh <project-name> <workspace-root>

set -euo pipefail

PROJECT="$1"
WORKSPACE="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
CHANGELOG_DIR="$WORKSPACE/memory/changelogs/$PROJECT"

mkdir -p "$CHANGELOG_DIR"

# Extract commit metadata
HASH=$(git rev-parse --short HEAD)
FULL_HASH=$(git rev-parse HEAD)
DATE=$(git log -1 --date=short --format='%cd')
TIME=$(git log -1 --format='%ci' | cut -d' ' -f2 | cut -c1-8)
AUTHOR=$(git log -1 --format='%an')
BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
MESSAGE=$(git log -1 --format='%s')
BODY=$(git log -1 --format='%b')

# Files changed
FILES_CHANGED=$(git diff-tree --no-commit-id --name-status -r HEAD 2>/dev/null || echo "")
STAT=$(git diff-tree --no-commit-id --stat -r HEAD 2>/dev/null | tail -1 || echo "")

# Output file
OUTFILE="$CHANGELOG_DIR/${DATE}_${HASH}.md"

cat > "$OUTFILE" <<EOF
# $MESSAGE

| Field | Value |
|-------|-------|
| **Project** | $PROJECT |
| **Date** | $DATE $TIME |
| **Commit** | \`$HASH\` ($FULL_HASH) |
| **Author** | $AUTHOR |
| **Branch** | \`$BRANCH\` |

## Files Changed

\`\`\`
$FILES_CHANGED
\`\`\`

## Diff Summary

$STAT
EOF

# Append body if present
if [ -n "$BODY" ]; then
  cat >> "$OUTFILE" <<EOF

## Details

$BODY
EOF
fi

echo "Goldy: logged $PROJECT commit $HASH → $OUTFILE"
