#!/usr/bin/env bash
# Goldy — Cross-project status report
# Usage: ./scripts/generate-report.sh [--hours 24] [--output slack|markdown|terminal]
#
# Generates a structured daily standup report:
#   - Yesterday: what was done
#   - Today: what was done so far
#   - Blockers
#   - Suggestions
#   - Review Bot status
#   - PR status
#   - Build info
#
# Template is reusable per project — auto-detects all repos.

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
HOURS=24
OUTPUT="terminal"
REPORT_DIR="$WORKSPACE/memory/reports"

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --hours) HOURS="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Auto-detect projects
source "$WORKSPACE/scripts/detect-projects.sh"

if [ ${#GOLDY_PROJECTS[@]} -eq 0 ]; then
  echo "No projects detected. Nothing to report."
  exit 1
fi

TODAY=$(date '+%Y-%m-%d')
YESTERDAY=$(date -v-1d '+%Y-%m-%d' 2>/dev/null || date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || echo "")
NOW=$(date '+%H:%M')
DAY_NAME=$(date '+%A')

mkdir -p "$REPORT_DIR"

# ── Helpers ───────────────────────────────────────────────────
SEP="------------------------------------------------------------"

# ──────────────────────────────────────────────────────────────
# Build report
# ──────────────────────────────────────────────────────────────

R=""

# ── Header ────────────────────────────────────────────────────
R+="**GOLDY STATUS REPORT**"$'\n'
R+="**${DAY_NAME}, ${TODAY} at ${NOW}**"$'\n'
R+="${SEP}"$'\n'
R+=""$'\n'

# ── Per Project ───────────────────────────────────────────────
for project in "${GOLDY_PROJECTS[@]}"; do
  repo_dir="$WORKSPACE/$project"
  [ -d "$repo_dir/.git" ] || continue

  branch=$(cd "$repo_dir" && git branch --show-current 2>/dev/null || echo "detached")
  platform="unknown"
  case "$project" in
    *ios*|*iOS*) platform="iOS" ;;
    *android*|*Android*) platform="Android" ;;
    *web*|*Web*) platform="Web" ;;
    *backend*|*api*) platform="Backend" ;;
  esac

  R+="**${project}** | ${platform} | \`${branch}\`"$'\n'
  R+="${SEP}"$'\n'
  R+=""$'\n'

  # ── Yesterday ─────────────────────────────────────────────
  R+="**YESTERDAY**"$'\n'
  R+=""$'\n'

  if [ -n "$YESTERDAY" ]; then
    yesterday_commits=$(cd "$repo_dir" && git log --oneline --after="${YESTERDAY} 00:00" --before="${TODAY} 00:00" 2>/dev/null || echo "")
  else
    yesterday_commits=""
  fi

  if [ -n "$yesterday_commits" ]; then
    while IFS= read -r line; do
      hash="${line%% *}"
      msg="${line#* }"
      R+="  - ${msg} (\`${hash}\`)"$'\n'
    done <<< "$yesterday_commits"
  else
    R+="  - No commits yesterday"$'\n'
  fi
  R+=""$'\n'

  # ── Today ─────────────────────────────────────────────────
  R+="**TODAY**"$'\n'
  R+=""$'\n'

  today_commits=$(cd "$repo_dir" && git log --oneline --since="${TODAY} 00:00" 2>/dev/null || echo "")

  if [ -n "$today_commits" ]; then
    today_count=$(echo "$today_commits" | wc -l | tr -d ' ')
    while IFS= read -r line; do
      hash="${line%% *}"
      msg="${line#* }"
      R+="  - ${msg} (\`${hash}\`)"$'\n'
    done <<< "$today_commits"

    # File stats for today
    if [ "$today_count" -gt 0 ]; then
      stats=$(cd "$repo_dir" && git diff --stat "HEAD~${today_count}" HEAD 2>/dev/null | tail -1 || echo "")
      if [ -n "$stats" ]; then
        R+="  - **Stats**: ${stats}"$'\n'
      fi
    fi
  else
    R+="  - No commits yet today"$'\n'
  fi
  R+=""$'\n'

  # ── Blockers ──────────────────────────────────────────────
  R+="**BLOCKERS**"$'\n'
  R+=""$'\n'

  blockers_found=0

  # Uncommitted changes
  dirty=$(cd "$repo_dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$dirty" -gt 0 ]; then
    R+="  - ${dirty} uncommitted file(s) in working tree"$'\n'
    blockers_found=1
  fi

  # Unpushed commits
  unpushed=$(cd "$repo_dir" && git log --oneline @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
  if [ "$unpushed" -gt 0 ]; then
    R+="  - ${unpushed} unpushed commit(s) — not yet on remote"$'\n'
    blockers_found=1
  fi

  # Merge conflicts
  conflicts=$(cd "$repo_dir" && git diff --name-only --diff-filter=U 2>/dev/null | wc -l | tr -d ' ')
  if [ "$conflicts" -gt 0 ]; then
    R+="  - **CONFLICT**: ${conflicts} file(s) with merge conflicts"$'\n'
    blockers_found=1
  fi

  if [ "$blockers_found" -eq 0 ]; then
    R+="  - None"$'\n'
  fi
  R+=""$'\n'

  # ── Build Info ────────────────────────────────────────────
  R+="**BUILD**"$'\n'
  R+=""$'\n'

  # Latest tag (version)
  latest_tag=$(cd "$repo_dir" && git tag --sort=-version:refname 2>/dev/null | head -1 || echo "")
  if [ -n "$latest_tag" ]; then
    R+="  - **Latest version**: ${latest_tag}"$'\n'
  fi

  # Total commits on current branch
  total_on_branch=$(cd "$repo_dir" && git rev-list --count HEAD 2>/dev/null || echo "?")
  R+="  - **Branch**: \`${branch}\` (${total_on_branch} commits)"$'\n'

  # Last commit timestamp
  last_date=$(cd "$repo_dir" && git log -1 --date=format:'%Y-%m-%d %H:%M' --format='%cd' 2>/dev/null || echo "N/A")
  R+="  - **Last activity**: ${last_date}"$'\n'

  R+=""$'\n'
  R+="${SEP}"$'\n'
  R+=""$'\n'
done

# ── Cross-Platform Alerts ─────────────────────────────────────
R+="**CROSS-PLATFORM ALERTS**"$'\n'
R+=""$'\n'

if [ -f "$WORKSPACE/TRUTH.md" ]; then
  alerts=$(grep -A 20 "Cross-Platform Alerts" "$WORKSPACE/TRUTH.md" 2>/dev/null | grep "^-" | head -5 || echo "")
  if [ -n "$alerts" ]; then
    while IFS= read -r line; do
      [ -n "$line" ] && R+="  ${line}"$'\n'
    done <<< "$alerts"
  else
    R+="  - None"$'\n'
  fi
else
  R+="  - TRUTH.md not found — run ./scripts/generate-truth.sh"$'\n'
fi
R+=""$'\n'

# ── Suggestions ───────────────────────────────────────────────
R+="**SUGGESTIONS**"$'\n'
R+=""$'\n'

# Auto-detect suggestions based on state
suggestions_found=0

for project in "${GOLDY_PROJECTS[@]}"; do
  repo_dir="$WORKSPACE/$project"
  [ -d "$repo_dir/.git" ] || continue

  # Stale branch (no commits in 3+ days)
  last_epoch=$(cd "$repo_dir" && git log -1 --format='%ct' 2>/dev/null || echo "0")
  now_epoch=$(date +%s)
  age_days=$(( (now_epoch - last_epoch) / 86400 ))
  if [ "$age_days" -ge 3 ]; then
    R+="  - ${project}: No commits in ${age_days} days — branch may be stale"$'\n'
    suggestions_found=1
  fi

  # Large uncommitted diff
  dirty=$(cd "$repo_dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$dirty" -gt 10 ]; then
    R+="  - ${project}: ${dirty} uncommitted files — consider committing or stashing"$'\n'
    suggestions_found=1
  fi
done

# TRUTH.md freshness
if [ -f "$WORKSPACE/TRUTH.md" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    truth_age=$(( $(date +%s) - $(stat -f %m "$WORKSPACE/TRUTH.md") ))
  else
    truth_age=$(( $(date +%s) - $(stat -c %Y "$WORKSPACE/TRUTH.md") ))
  fi
  truth_hours=$((truth_age / 3600))
  if [ "$truth_hours" -ge 4 ]; then
    R+="  - TRUTH.md is ${truth_hours}h old — consider running ./scripts/generate-truth.sh"$'\n'
    suggestions_found=1
  fi
fi

if [ "$suggestions_found" -eq 0 ]; then
  R+="  - All good — no action needed"$'\n'
fi
R+=""$'\n'

# ── Review Bot Status ─────────────────────────────────────────
R+="**REVIEW BOT**"$'\n'
R+=""$'\n'

learnings_dir="$WORKSPACE/claude-review-bot/.github/actions/claude-review/learnings"
if [ -d "$learnings_dir" ]; then
  for f in "$learnings_dir"/*.json; do
    [ -f "$f" ] || continue
    fname=$(basename "$f" .json)
    total_p=$(grep -c '"id"' "$f" 2>/dev/null || echo "0")
    critical=$(grep '"severity"' "$f" 2>/dev/null | grep -c '"critical"' || echo "0")
    major=$(grep '"severity"' "$f" 2>/dev/null | grep -c '"major"' || echo "0")
    minor=$(grep '"severity"' "$f" 2>/dev/null | grep -c '"minor"' || echo "0")
    R+="  - **${fname}**: ${total_p} patterns (${critical} critical, ${major} major, ${minor} minor)"$'\n'
  done
else
  R+="  - No review bot configured — run ./scripts/add-reviewer.sh"$'\n'
fi
R+=""$'\n'

# ── PR Status ─────────────────────────────────────────────────
R+="**OPEN PRs**"$'\n'
R+=""$'\n'

prs_found=0
for project in "${GOLDY_PROJECTS[@]}"; do
  repo_dir="$WORKSPACE/$project"
  [ -d "$repo_dir/.git" ] || continue

  # Check if gh CLI is available and repo has remote
  if command -v gh &>/dev/null; then
    pr_list=$(cd "$repo_dir" && gh pr list --state open --limit 5 --json number,title,author,reviewDecision 2>/dev/null || echo "")
    if [ -n "$pr_list" ] && [ "$pr_list" != "[]" ]; then
      while IFS= read -r pr_line; do
        [ -n "$pr_line" ] && R+="  - **${project}**: ${pr_line}"$'\n' && prs_found=1
      done < <(cd "$repo_dir" && gh pr list --state open --limit 5 2>/dev/null || echo "")
    fi
  fi
done

if [ "$prs_found" -eq 0 ]; then
  R+="  - No open PRs found (or gh CLI not available)"$'\n'
fi
R+=""$'\n'

# ── Infrastructure ────────────────────────────────────────────
R+="**INFRASTRUCTURE**"$'\n'
R+=""$'\n'

total_changelogs=0
for project in "${GOLDY_PROJECTS[@]}"; do
  changelog_dir="$WORKSPACE/memory/changelogs/$project"
  if [ -d "$changelog_dir" ]; then
    c=$(find "$changelog_dir" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    today_c=$(find "$changelog_dir" -name "${TODAY}*.md" 2>/dev/null | wc -l | tr -d ' ')
    R+="  - **${project}**: ${c} total changelogs (${today_c} today)"$'\n'
    total_changelogs=$((total_changelogs + c))
  fi
done

memory_files=$(find "$WORKSPACE/memory" -name '*.md' -not -path '*/changelogs/*' 2>/dev/null | wc -l | tr -d ' ')
R+="  - **Shared memory**: ${memory_files} files"$'\n'
R+="  - **TRUTH.md**: $([ -f "$WORKSPACE/TRUTH.md" ] && echo "active" || echo "missing")"$'\n'
R+=""$'\n'

# ── Footer ────────────────────────────────────────────────────
R+="${SEP}"$'\n'
R+="**Generated by Goldy** | ${TODAY} ${NOW}"$'\n'

# ──────────────────────────────────────────────────────────────
# Output
# ──────────────────────────────────────────────────────────────

case "$OUTPUT" in
  terminal)
    echo "$R"
    ;;
  markdown)
    outfile="$REPORT_DIR/report_${TODAY}.md"
    echo "$R" > "$outfile"
    echo "Goldy: report saved to $outfile"
    ;;
  slack)
    # Slack mrkdwn: **bold** → *bold*, keep bullets, keep separators
    slack_r=$(echo "$R" | sed 's/\*\*\([^*]*\)\*\*/\*\1\*/g')
    # Replace separator with Slack divider
    slack_r=$(echo "$slack_r" | sed "s/${SEP}/───────────────────────────────/g")
    echo "$slack_r"
    ;;
  *)
    echo "Unknown output format: $OUTPUT (use: terminal, markdown, slack)"
    exit 1
    ;;
esac
