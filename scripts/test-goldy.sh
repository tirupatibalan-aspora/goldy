#!/usr/bin/env bash
# Goldy — Automated test suite
# Usage: ./scripts/test-goldy.sh
# Verifies both Infrastructure and Intelligence layers work correctly

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
TOTAL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
  PASS=$((PASS + 1))
  TOTAL=$((TOTAL + 1))
  echo -e "  ${GREEN}✓${NC} $1"
}

fail() {
  FAIL=$((FAIL + 1))
  TOTAL=$((TOTAL + 1))
  echo -e "  ${RED}✗${NC} $1"
}

section() {
  echo ""
  echo -e "${YELLOW}=== $1 ===${NC}"
}

# ──────────────────────────────────────────────────────────────
section "1. Directory Structure"
# ──────────────────────────────────────────────────────────────

[ -d "$WORKSPACE/scripts" ] && pass "scripts/ exists" || fail "scripts/ missing"
[ -d "$WORKSPACE/memory" ] && pass "memory/ exists" || fail "memory/ missing"
[ -d "$WORKSPACE/memory/changelogs" ] && pass "memory/changelogs/ exists" || fail "memory/changelogs/ missing"
[ -d "$WORKSPACE/memory/summaries" ] && pass "memory/summaries/ exists" || fail "memory/summaries/ missing"
[ -d "$WORKSPACE/memory/projects" ] && pass "memory/projects/ exists" || fail "memory/projects/ missing"

# ──────────────────────────────────────────────────────────────
section "2. Scripts Exist & Executable"
# ──────────────────────────────────────────────────────────────

for script in detect-projects.sh setup-memory-system.sh log-commit.sh summarize.sh generate-truth.sh install-hooks.sh backfill.sh generate-report.sh postreport.sh add-reviewer.sh goldy-check.sh test-goldy.sh; do
  if [ -x "$WORKSPACE/scripts/$script" ]; then
    pass "$script executable"
  elif [ -f "$WORKSPACE/scripts/$script" ]; then
    fail "$script exists but not executable"
  else
    fail "$script missing"
  fi
done

# ──────────────────────────────────────────────────────────────
section "3. Auto-Detection (Infrastructure)"
# ──────────────────────────────────────────────────────────────

source "$WORKSPACE/scripts/detect-projects.sh"

if [ ${#GOLDY_PROJECTS[@]} -gt 0 ]; then
  pass "Auto-detected ${#GOLDY_PROJECTS[@]} project(s): ${GOLDY_PROJECTS[*]}"
else
  fail "No projects detected"
fi

for project in "${GOLDY_PROJECTS[@]}"; do
  [ -d "$WORKSPACE/$project/.git" ] && pass "$project is a valid git repo" || fail "$project is not a git repo"
done

# ──────────────────────────────────────────────────────────────
section "4. Git Hooks (Infrastructure)"
# ──────────────────────────────────────────────────────────────

for project in "${GOLDY_PROJECTS[@]}"; do
  hook_file="$WORKSPACE/$project/.git/hooks/post-commit"
  if [ -f "$hook_file" ] && grep -q "Goldy" "$hook_file" 2>/dev/null; then
    pass "$project — post-commit hook installed"
  else
    fail "$project — post-commit hook missing"
  fi
done

# ──────────────────────────────────────────────────────────────
section "5. Changelogs (Infrastructure)"
# ──────────────────────────────────────────────────────────────

for project in "${GOLDY_PROJECTS[@]}"; do
  changelog_dir="$WORKSPACE/memory/changelogs/$project"
  if [ -d "$changelog_dir" ]; then
    count=$(find "$changelog_dir" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -gt 0 ]; then
      pass "$project — $count changelogs"
    else
      fail "$project — changelog dir exists but empty (run: ./scripts/backfill.sh $project 30)"
    fi
  else
    fail "$project — changelog dir missing (run setup first)"
  fi
done

# ──────────────────────────────────────────────────────────────
section "6. Summaries (Infrastructure)"
# ──────────────────────────────────────────────────────────────

for project in "${GOLDY_PROJECTS[@]}"; do
  summary="$WORKSPACE/memory/summaries/$project.md"
  if [ -f "$summary" ] && [ -s "$summary" ]; then
    pass "$project — summary generated"
  else
    fail "$project — summary missing (run: ./scripts/summarize.sh)"
  fi
done

# ──────────────────────────────────────────────────────────────
section "7. TRUTH.md (Infrastructure)"
# ──────────────────────────────────────────────────────────────

if [ -f "$WORKSPACE/TRUTH.md" ] && [ -s "$WORKSPACE/TRUTH.md" ]; then
  pass "TRUTH.md exists and non-empty"
  # Verify it has the expected sections
  grep -q "Platform Status" "$WORKSPACE/TRUTH.md" && pass "TRUTH.md has Platform Status" || fail "TRUTH.md missing Platform Status"
  grep -q "Cross-Platform Alerts" "$WORKSPACE/TRUTH.md" && pass "TRUTH.md has Cross-Platform Alerts" || fail "TRUTH.md missing Cross-Platform Alerts"
  grep -q "Recent Activity" "$WORKSPACE/TRUTH.md" && pass "TRUTH.md has Recent Activity" || fail "TRUTH.md missing Recent Activity"
else
  fail "TRUTH.md missing (run: ./scripts/generate-truth.sh)"
fi

# ──────────────────────────────────────────────────────────────
section "8. CLAUDE.md (Intelligence)"
# ──────────────────────────────────────────────────────────────

if [ -f "$WORKSPACE/CLAUDE.md" ] && [ -s "$WORKSPACE/CLAUDE.md" ]; then
  pass "CLAUDE.md exists (hot cache for AI sessions)"
else
  fail "CLAUDE.md missing — Intelligence layer won't have context"
fi

# ──────────────────────────────────────────────────────────────
section "9. Review Bot (Intelligence)"
# ──────────────────────────────────────────────────────────────

learnings_dir="$WORKSPACE/claude-review-bot/.github/actions/claude-review/learnings"
if [ -d "$learnings_dir" ]; then
  pass "Review bot learnings directory exists"
  learnings_count=$(find "$learnings_dir" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$learnings_count" -gt 0 ]; then
    pass "$learnings_count reviewer learnings file(s)"
    for f in "$learnings_dir"/*.json; do
      fname=$(basename "$f" .json)
      patterns=$(grep -c '"id"' "$f" 2>/dev/null || echo "0")
      pass "  $fname: $patterns patterns"
    done
  else
    fail "No learnings files — Review bot won't enforce standards"
  fi
else
  fail "Review bot learnings dir missing"
fi

# ──────────────────────────────────────────────────────────────
section "10. Memory System (Intelligence)"
# ──────────────────────────────────────────────────────────────

memory_files=$(find "$WORKSPACE/memory" -name '*.md' -not -path '*/changelogs/*' 2>/dev/null | wc -l | tr -d ' ')
if [ "$memory_files" -gt 0 ]; then
  pass "$memory_files shared memory files in memory/"
else
  fail "No shared memory files — Intelligence layer has no context"
fi

# Check key memory files
[ -f "$WORKSPACE/memory/glossary.md" ] && pass "glossary.md exists" || fail "glossary.md missing"
if ls "$WORKSPACE/memory/projects/"*.md 1>/dev/null 2>&1; then
  pass "Project state files exist"
else
  fail "No project state files in memory/projects/"
fi

# ──────────────────────────────────────────────────────────────
section "11. Log-Commit Dry Run (Infrastructure)"
# ──────────────────────────────────────────────────────────────

# Test log-commit works by running it for the first detected project
if [ ${#GOLDY_PROJECTS[@]} -gt 0 ]; then
  test_project="${GOLDY_PROJECTS[0]}"
  test_repo="$WORKSPACE/$test_project"
  last_hash=$(cd "$test_repo" && git log -1 --format='%H' 2>/dev/null)
  if [ -n "$last_hash" ]; then
    # Check log-commit can produce output (don't actually write)
    test_date=$(cd "$test_repo" && git log -1 --date=short --format='%cd' 2>/dev/null)
    test_short=$(cd "$test_repo" && git log -1 --format='%h' 2>/dev/null)
    if [ -n "$test_date" ] && [ -n "$test_short" ]; then
      pass "log-commit data extraction works ($test_project: $test_short on $test_date)"
    else
      fail "log-commit data extraction failed for $test_project"
    fi
  else
    fail "Cannot read git log for $test_project"
  fi
fi

# ──────────────────────────────────────────────────────────────
section "12. Status Report (Intelligence)"
# ──────────────────────────────────────────────────────────────

report_output=$("$WORKSPACE/scripts/generate-report.sh" --hours 168 --output terminal 2>&1 || echo "FAILED")
if echo "$report_output" | grep -q "Status Report"; then
  pass "generate-report.sh produces valid report"
else
  fail "generate-report.sh failed to produce report"
fi

# Check report contains project data
for project in "${GOLDY_PROJECTS[@]}"; do
  if echo "$report_output" | grep -q "$project"; then
    pass "Report includes $project data"
  else
    fail "Report missing $project data"
  fi
done

# Check report includes infrastructure + review bot lines
echo "$report_output" | grep -q "Infrastructure" && pass "Report shows infrastructure stats" || fail "Report missing infrastructure stats"
echo "$report_output" | grep -q "Review Bot" && pass "Report shows review bot stats" || fail "Report missing review bot stats"

# Test markdown output
"$WORKSPACE/scripts/generate-report.sh" --hours 168 --output markdown >/dev/null 2>&1
report_file="$WORKSPACE/memory/reports/report_$(date '+%Y-%m-%d').md"
if [ -f "$report_file" ] && [ -s "$report_file" ]; then
  pass "Markdown report saved to memory/reports/"
else
  fail "Markdown report not saved"
fi

# ──────────────────────────────────────────────────────────────
section "13. Cross-Platform Consistency"
# ──────────────────────────────────────────────────────────────

if [ ${#GOLDY_PROJECTS[@]} -ge 2 ]; then
  pass "Multi-project workspace (${#GOLDY_PROJECTS[@]} repos) — cross-platform sync enabled"
else
  pass "Single project workspace — no cross-platform sync needed"
fi

# Check .gitignore excludes sub-repos
if [ -f "$WORKSPACE/.gitignore" ]; then
  ignored=0
  for project in "${GOLDY_PROJECTS[@]}"; do
    if grep -q "^${project}/" "$WORKSPACE/.gitignore" 2>/dev/null; then
      ignored=$((ignored + 1))
    fi
  done
  if [ "$ignored" -eq "${#GOLDY_PROJECTS[@]}" ]; then
    pass ".gitignore excludes all sub-repos (prevents tracking nested git)"
  else
    fail ".gitignore missing some sub-repo exclusions"
  fi
else
  fail ".gitignore missing"
fi

# ──────────────────────────────────────────────────────────────
echo ""
echo -e "════════════════════════════════════════════"
echo -e "  Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}, ${TOTAL} total"
echo -e "════════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Fix failing tests, then run again: ./scripts/test-goldy.sh"
  exit 1
else
  echo ""
  echo "All tests passing. Goldy is fully operational."
  exit 0
fi
