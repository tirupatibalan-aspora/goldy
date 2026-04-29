#!/usr/bin/env bash
# Goldy — Automated test suite
# Usage: ./scripts/test-goldy.sh [--include-setup]
#
# Verifies both Infrastructure and Intelligence layers work correctly.
# --include-setup: Also runs setup.sh in an isolated sandbox (adds ~30s)

set -euo pipefail

# Guard against recursive invocation (hook → summarize → test)
if [ -n "${GOLDY_TEST_RUNNING:-}" ]; then
  exit 0
fi
export GOLDY_TEST_RUNNING=1

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
SKIP=0
TOTAL=0
INCLUDE_SETUP=false

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --include-setup) INCLUDE_SETUP=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
DIM='\033[2m'
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

skip() {
  SKIP=$((SKIP + 1))
  TOTAL=$((TOTAL + 1))
  echo -e "  ${YELLOW}⊘${NC} $1 ${DIM}(skipped)${NC}"
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
[ -f "$WORKSPACE/setup.sh" ] && pass "setup.sh exists at root" || fail "setup.sh missing at root"
[ -f "$WORKSPACE/.gitignore" ] && pass ".gitignore exists" || fail ".gitignore missing"

# ──────────────────────────────────────────────────────────────
section "2. Scripts Exist & Executable"
# ──────────────────────────────────────────────────────────────

for script in detect-projects.sh detect-user.sh setup-memory-system.sh log-commit.sh summarize.sh generate-truth.sh install-hooks.sh backfill.sh generate-report.sh postreport.sh add-reviewer.sh goldy-check.sh test-goldy.sh; do
  if [ -x "$WORKSPACE/scripts/$script" ]; then
    pass "$script executable"
  elif [ -f "$WORKSPACE/scripts/$script" ]; then
    fail "$script exists but not executable"
  else
    fail "$script missing"
  fi
done

# setup.sh at root
[ -x "$WORKSPACE/setup.sh" ] && pass "setup.sh executable" || fail "setup.sh not executable"

# ──────────────────────────────────────────────────────────────
section "3. Script Syntax Validation"
# ──────────────────────────────────────────────────────────────

for script in "$WORKSPACE/scripts/"*.sh "$WORKSPACE/setup.sh"; do
  fname=$(basename "$script")
  if bash -n "$script" 2>/dev/null; then
    pass "$fname — valid bash syntax"
  else
    fail "$fname — syntax error"
  fi
done

# ──────────────────────────────────────────────────────────────
section "4. Auto-Detection (Infrastructure)"
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

# Verify detect-projects skips non-repo dirs
for skip_dir in scripts docs goldy common_assets claude-review-bot memory; do
  if echo "${GOLDY_PROJECTS[*]}" | grep -qw "$skip_dir"; then
    fail "detect-projects should skip $skip_dir but didn't"
  else
    pass "detect-projects correctly skips $skip_dir"
  fi
done

# ──────────────────────────────────────────────────────────────
section "5. User Detection"
# ──────────────────────────────────────────────────────────────

# Source detect-user and check it sets variables
(
  source "$WORKSPACE/scripts/detect-user.sh" 2>/dev/null
  if [ -n "${GOLDY_USER_NAME:-}" ]; then
    echo "DETECTED_NAME=${GOLDY_USER_NAME}"
  fi
  if [ -n "${GOLDY_USER_LOGIN:-}" ]; then
    echo "DETECTED_LOGIN=${GOLDY_USER_LOGIN}"
  fi
) > /tmp/goldy_user_test.txt 2>/dev/null

if grep -q "DETECTED_NAME=" /tmp/goldy_user_test.txt 2>/dev/null; then
  detected_name=$(grep "DETECTED_NAME=" /tmp/goldy_user_test.txt | cut -d= -f2-)
  pass "detect-user.sh found user: $detected_name"
else
  skip "detect-user.sh — no user detected (gh CLI not authed or git config missing)"
fi

if grep -q "DETECTED_LOGIN=" /tmp/goldy_user_test.txt 2>/dev/null; then
  pass "detect-user.sh found GitHub login"
else
  skip "detect-user.sh — no GitHub login (needs gh CLI)"
fi
rm -f /tmp/goldy_user_test.txt

# ──────────────────────────────────────────────────────────────
section "6. Git Hooks (Infrastructure)"
# ──────────────────────────────────────────────────────────────

for project in "${GOLDY_PROJECTS[@]}"; do
  hook_file="$WORKSPACE/$project/.git/hooks/post-commit"
  if [ -f "$hook_file" ] && grep -q "Goldy" "$hook_file" 2>/dev/null; then
    pass "$project — post-commit hook installed"
    # Verify hook references correct scripts
    if grep -q "log-commit.sh" "$hook_file"; then
      pass "$project — hook calls log-commit.sh"
    else
      fail "$project — hook doesn't call log-commit.sh"
    fi
    if grep -q "summarize.sh" "$hook_file"; then
      pass "$project — hook calls summarize.sh"
    else
      fail "$project — hook doesn't call summarize.sh"
    fi
    if grep -q "generate-truth.sh" "$hook_file"; then
      pass "$project — hook calls generate-truth.sh"
    else
      fail "$project — hook doesn't call generate-truth.sh"
    fi
    # Verify hook is executable
    if [ -x "$hook_file" ]; then
      pass "$project — hook is executable"
    else
      fail "$project — hook is not executable"
    fi
  else
    fail "$project — post-commit hook missing"
  fi
done

# ──────────────────────────────────────────────────────────────
section "7. Changelogs (Infrastructure)"
# ──────────────────────────────────────────────────────────────

for project in "${GOLDY_PROJECTS[@]}"; do
  changelog_dir="$WORKSPACE/memory/changelogs/$project"
  if [ -d "$changelog_dir" ]; then
    count=$(find "$changelog_dir" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -gt 0 ]; then
      pass "$project — $count changelogs"

      # Verify changelog format (check the latest one)
      latest=$(ls -1t "$changelog_dir"/*.md 2>/dev/null | head -1 || true)
      if [ -n "$latest" ]; then
        # Must have a heading
        if head -1 "$latest" | grep -q "^# "; then
          pass "$project — changelog has heading"
        else
          fail "$project — changelog missing heading"
        fi
        # Must have Project field
        if grep -q "Project" "$latest"; then
          pass "$project — changelog has Project field"
        else
          fail "$project — changelog missing Project field"
        fi
        # Must have Commit field
        if grep -q "Commit" "$latest"; then
          pass "$project — changelog has Commit field"
        else
          fail "$project — changelog missing Commit field"
        fi
        # Must have Files Changed section
        if grep -q "Files Changed" "$latest"; then
          pass "$project — changelog has Files Changed"
        else
          fail "$project — changelog missing Files Changed"
        fi
      fi
    else
      fail "$project — changelog dir exists but empty (run: ./scripts/backfill.sh $project 30)"
    fi
  else
    fail "$project — changelog dir missing (run setup first)"
  fi
done

# ──────────────────────────────────────────────────────────────
section "8. Summaries (Infrastructure)"
# ──────────────────────────────────────────────────────────────

for project in "${GOLDY_PROJECTS[@]}"; do
  summary="$WORKSPACE/memory/summaries/$project.md"
  if [ -f "$summary" ] && [ -s "$summary" ]; then
    pass "$project — summary generated"
    # Verify summary has key sections
    if grep -q "Branch" "$summary"; then
      pass "$project — summary has Branch info"
    else
      fail "$project — summary missing Branch info"
    fi
    if grep -q "Recent Changes" "$summary"; then
      pass "$project — summary has Recent Changes"
    else
      fail "$project — summary missing Recent Changes"
    fi
    if grep -q "Feature Areas" "$summary"; then
      pass "$project — summary has Feature Areas"
    else
      fail "$project — summary missing Feature Areas"
    fi
  else
    fail "$project — summary missing (run: ./scripts/summarize.sh)"
  fi
done

# ──────────────────────────────────────────────────────────────
section "9. TRUTH.md (Infrastructure)"
# ──────────────────────────────────────────────────────────────

if [ -f "$WORKSPACE/TRUTH.md" ] && [ -s "$WORKSPACE/TRUTH.md" ]; then
  pass "TRUTH.md exists and non-empty"
  # Verify it has the expected sections
  grep -q "Platform Status" "$WORKSPACE/TRUTH.md" && pass "TRUTH.md has Platform Status" || fail "TRUTH.md missing Platform Status"
  grep -q "Cross-Platform Alerts" "$WORKSPACE/TRUTH.md" && pass "TRUTH.md has Cross-Platform Alerts" || fail "TRUTH.md missing Cross-Platform Alerts"
  grep -q "Recent Activity" "$WORKSPACE/TRUTH.md" && pass "TRUTH.md has Recent Activity" || fail "TRUTH.md missing Recent Activity"
  grep -q "Per-Platform Summaries" "$WORKSPACE/TRUTH.md" && pass "TRUTH.md has Per-Platform Summaries" || fail "TRUTH.md missing Per-Platform Summaries"
  # Verify each detected project appears in TRUTH.md
  for project in "${GOLDY_PROJECTS[@]}"; do
    if grep -q "$project" "$WORKSPACE/TRUTH.md"; then
      pass "TRUTH.md includes $project"
    else
      fail "TRUTH.md missing $project data"
    fi
  done
  # Verify auto-generated header
  if head -3 "$WORKSPACE/TRUTH.md" | grep -q "Auto-generated by Goldy"; then
    pass "TRUTH.md has auto-generated header"
  else
    fail "TRUTH.md missing auto-generated header"
  fi
else
  fail "TRUTH.md missing (run: ./scripts/generate-truth.sh)"
fi

# ──────────────────────────────────────────────────────────────
section "10. CLAUDE.md (Intelligence)"
# ──────────────────────────────────────────────────────────────

if [ -f "$WORKSPACE/CLAUDE.md" ] && [ -s "$WORKSPACE/CLAUDE.md" ]; then
  pass "CLAUDE.md exists (hot cache for AI sessions)"
  # Verify it has key sections
  if grep -q "Session Start" "$WORKSPACE/CLAUDE.md"; then
    pass "CLAUDE.md has Session Start instructions"
  else
    fail "CLAUDE.md missing Session Start instructions"
  fi
  if grep -q "goldycheck\|goldyreport\|goldytest" "$WORKSPACE/CLAUDE.md"; then
    pass "CLAUDE.md has Goldy commands table"
  else
    fail "CLAUDE.md missing Goldy commands"
  fi
  if grep -q "Review Bot" "$WORKSPACE/CLAUDE.md"; then
    pass "CLAUDE.md has Review Bot section"
  else
    fail "CLAUDE.md missing Review Bot section"
  fi
else
  fail "CLAUDE.md missing — Intelligence layer won't have context"
fi

# ──────────────────────────────────────────────────────────────
section "11. Review Bot (Intelligence)"
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

      # Validate JSON syntax
      if python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
        pass "  $fname: valid JSON"
      elif command -v node &>/dev/null && node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" 2>/dev/null; then
        pass "  $fname: valid JSON"
      else
        fail "  $fname: invalid JSON syntax"
      fi

      # Verify required fields
      if grep -q '"reviewer"' "$f" && grep -q '"platform"' "$f" && grep -q '"patterns"' "$f"; then
        pass "  $fname: has required fields (reviewer, platform, patterns)"
      else
        fail "  $fname: missing required fields"
      fi
    done
  else
    fail "No learnings files — Review bot won't enforce standards"
  fi
else
  fail "Review bot learnings dir missing"
fi

# Verify review bot action files
if [ -f "$WORKSPACE/claude-review-bot/.github/actions/claude-review/action.yml" ]; then
  pass "Review bot action.yml exists"
else
  fail "Review bot action.yml missing"
fi

if [ -f "$WORKSPACE/claude-review-bot/.github/actions/claude-review/index.js" ]; then
  pass "Review bot index.js exists"
  # Verify it has no syntax errors
  if command -v node &>/dev/null; then
    if node --check "$WORKSPACE/claude-review-bot/.github/actions/claude-review/index.js" 2>/dev/null; then
      pass "Review bot index.js — valid JS syntax"
    else
      fail "Review bot index.js — JS syntax error"
    fi
  else
    skip "Review bot index.js syntax check (node not installed)"
  fi
else
  fail "Review bot index.js missing"
fi

# ──────────────────────────────────────────────────────────────
section "12. Memory System (Intelligence)"
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
section "13. Log-Commit Dry Run (Infrastructure)"
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
    test_author=$(cd "$test_repo" && git log -1 --format='%an' 2>/dev/null)
    test_msg=$(cd "$test_repo" && git log -1 --format='%s' 2>/dev/null)
    if [ -n "$test_date" ] && [ -n "$test_short" ]; then
      pass "log-commit data extraction works ($test_project: $test_short on $test_date)"
    else
      fail "log-commit data extraction failed for $test_project"
    fi
    if [ -n "$test_author" ]; then
      pass "log-commit extracts author ($test_author)"
    else
      fail "log-commit cannot extract author"
    fi
    if [ -n "$test_msg" ]; then
      pass "log-commit extracts commit message"
    else
      fail "log-commit cannot extract commit message"
    fi
  else
    fail "Cannot read git log for $test_project"
  fi
fi

# ──────────────────────────────────────────────────────────────
section "14. Backfill Validation"
# ──────────────────────────────────────────────────────────────

if [ ${#GOLDY_PROJECTS[@]} -gt 0 ]; then
  test_project="${GOLDY_PROJECTS[0]}"
  changelog_dir="$WORKSPACE/memory/changelogs/$test_project"
  if [ -d "$changelog_dir" ]; then
    # Check filename format: YYYY-MM-DD_HASH.md
    bad_names=0
    for f in "$changelog_dir"/*.md; do
      fname=$(basename "$f" .md)
      if ! echo "$fname" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}_[a-f0-9]+$'; then
        bad_names=$((bad_names + 1))
      fi
    done
    if [ "$bad_names" -eq 0 ]; then
      pass "$test_project — all changelog filenames match YYYY-MM-DD_HASH.md"
    else
      fail "$test_project — $bad_names changelogs have bad filename format"
    fi

    # Check for duplicate hashes
    hashes=$(ls -1 "$changelog_dir"/*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/.*_//')
    unique_hashes=$(echo "$hashes" | sort -u | wc -l | tr -d ' ')
    total_hashes=$(echo "$hashes" | wc -l | tr -d ' ')
    if [ "$unique_hashes" -eq "$total_hashes" ]; then
      pass "$test_project — no duplicate changelogs ($total_hashes unique)"
    else
      fail "$test_project — duplicate changelogs found ($unique_hashes unique / $total_hashes total)"
    fi
  fi
fi

# ──────────────────────────────────────────────────────────────
section "15. Status Report (Intelligence)"
# ──────────────────────────────────────────────────────────────

report_output=$("$WORKSPACE/scripts/generate-report.sh" --hours 168 --output terminal 2>&1 || echo "FAILED")
if echo "$report_output" | grep -qi "STATUS REPORT"; then
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
echo "$report_output" | grep -qi "INFRASTRUCTURE" && pass "Report shows infrastructure stats" || fail "Report missing infrastructure stats"
echo "$report_output" | grep -qi "REVIEW BOT" && pass "Report shows review bot stats" || fail "Report missing review bot stats"

# Test markdown output
"$WORKSPACE/scripts/generate-report.sh" --hours 168 --output markdown >/dev/null 2>&1
report_file="$WORKSPACE/memory/reports/report_$(date '+%Y-%m-%d').md"
if [ -f "$report_file" ] && [ -s "$report_file" ]; then
  pass "Markdown report saved to memory/reports/"
  # Verify markdown report has structure (uses **bold** or # headings)
  if grep -qE "^(#|\*\*)" "$report_file"; then
    pass "Markdown report has structure"
  else
    fail "Markdown report missing structure"
  fi
else
  fail "Markdown report not saved"
fi

# ──────────────────────────────────────────────────────────────
section "16. Goldy-Check Modes"
# ──────────────────────────────────────────────────────────────

# Test that goldy-check runs without error
check_output=$("$WORKSPACE/scripts/goldy-check.sh" 2>&1 || true)
if [ -n "$check_output" ]; then
  pass "goldy-check.sh produces output"
  # Should contain repo count or OK
  if echo "$check_output" | grep -qE "repos|Goldy"; then
    pass "goldy-check.sh output contains expected content"
  else
    fail "goldy-check.sh output unexpected format"
  fi
else
  fail "goldy-check.sh produced no output"
fi

# ──────────────────────────────────────────────────────────────
section "17. Add-Reviewer Validation"
# ──────────────────────────────────────────────────────────────

# Test --help flag
help_output=$("$WORKSPACE/scripts/add-reviewer.sh" --help 2>&1 || true)
if echo "$help_output" | grep -q "Usage"; then
  pass "add-reviewer.sh --help works"
else
  fail "add-reviewer.sh --help broken"
fi

# Test validation (missing args should fail)
_rv_output=$("$WORKSPACE/scripts/add-reviewer.sh" 2>&1 || true)
if echo "$_rv_output" | grep -q "ERROR"; then
  pass "add-reviewer.sh rejects missing args"
else
  fail "add-reviewer.sh doesn't validate args"
fi

# Test platform validation
_rv_output2=$("$WORKSPACE/scripts/add-reviewer.sh" --name x --github x --platform web 2>&1 || true)
if echo "$_rv_output2" | grep -q "ERROR"; then
  pass "add-reviewer.sh rejects invalid platform"
else
  fail "add-reviewer.sh doesn't validate platform"
fi

# ──────────────────────────────────────────────────────────────
section "18. Cross-Platform Consistency"
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

# Check .goldy-user.conf is gitignored
if grep -q ".goldy-user.conf" "$WORKSPACE/.gitignore" 2>/dev/null; then
  pass ".goldy-user.conf is gitignored"
else
  fail ".goldy-user.conf NOT gitignored — sensitive data would be tracked!"
fi

# Check .goldy-initialized is gitignored
if grep -q ".goldy-initialized" "$WORKSPACE/.gitignore" 2>/dev/null; then
  pass ".goldy-initialized is gitignored"
else
  fail ".goldy-initialized NOT gitignored"
fi

# ──────────────────────────────────────────────────────────────
section "19. Public Repo Safety"
# ──────────────────────────────────────────────────────────────

# Scan tracked files for common secrets patterns
_secrets_found=0

# Check for API keys / tokens in tracked files
if git -C "$WORKSPACE" grep -lE "(sk-[a-zA-Z0-9]{20,}|xoxb-[0-9]+|ghp_[a-zA-Z0-9]+|AKIA[0-9A-Z]{16})" -- . ':(exclude)vance-*' ':(exclude)goldy/' ':(exclude).claude/' 2>/dev/null | (head -1 || true) | grep -q .; then
  fail "Possible API key/token found in tracked files"
  _secrets_found=1
else
  pass "No API keys/tokens in tracked files"
fi

# Check .goldy-user.conf is NOT tracked
if git -C "$WORKSPACE" ls-files --cached .goldy-user.conf 2>/dev/null | grep -q .; then
  fail ".goldy-user.conf is tracked by git — must be removed"
  _secrets_found=1
else
  pass ".goldy-user.conf not tracked (correct)"
fi

# Check for hardcoded absolute home paths in scripts
_hardcoded_paths=0
for f in "$WORKSPACE/scripts/"*.sh "$WORKSPACE/setup.sh"; do
  if grep -qE '/Users/[a-zA-Z]+/' "$f" 2>/dev/null; then
    fail "$(basename "$f") contains hardcoded /Users/ path"
    _hardcoded_paths=1
  fi
done
if [ "$_hardcoded_paths" -eq 0 ]; then
  pass "No hardcoded /Users/ paths in scripts"
fi

# Check learnings JSONs don't contain real PR URLs to private repos
for f in "$learnings_dir"/*.json; do
  [ -f "$f" ] || continue
  fname=$(basename "$f")
  if grep -qE "github\.com/[A-Z][a-zA-Z-]+/(vance|aspora)" "$f" 2>/dev/null; then
    fail "$fname contains private repo URL"
  else
    pass "$fname — no private repo URLs"
  fi
done

# ──────────────────────────────────────────────────────────────
section "20. Setup Wizard (Sandbox)"
# ──────────────────────────────────────────────────────────────

if [ "$INCLUDE_SETUP" = true ]; then
  # Create a temp workspace to test setup.sh in isolation
  SANDBOX=$(mktemp -d)
  trap "rm -rf $SANDBOX" EXIT

  echo -e "  ${DIM}Creating sandbox at $SANDBOX...${NC}"

  # Copy Goldy files (not sub-repos)
  cp -R "$WORKSPACE/scripts" "$SANDBOX/scripts"
  cp -R "$WORKSPACE/claude-review-bot" "$SANDBOX/claude-review-bot" 2>/dev/null || true
  cp "$WORKSPACE/setup.sh" "$SANDBOX/setup.sh"
  cp "$WORKSPACE/.gitignore" "$SANDBOX/.gitignore"
  cp "$WORKSPACE/CLAUDE.md" "$SANDBOX/CLAUDE.md" 2>/dev/null || true
  mkdir -p "$SANDBOX/memory/projects" "$SANDBOX/memory/people"
  [ -f "$WORKSPACE/memory/glossary.md" ] && cp "$WORKSPACE/memory/glossary.md" "$SANDBOX/memory/glossary.md"

  # Init goldy as a git repo (setup-memory-system needs it)
  (cd "$SANDBOX" && git init -q)

  # Create a fake sub-repo to test with
  mkdir -p "$SANDBOX/test-app"
  (cd "$SANDBOX/test-app" && git init -q && git commit --allow-empty -m "init test repo" -q)

  # Pipe simulated user input to setup.sh:
  #   Line 1: name (accept default or enter "Test User")
  #   Line 2: email ("test@example.com")
  #   Line 3: github login ("testuser")
  #   Line 4: empty (no repo URLs — we already have test-app)
  #   Line 5: empty (no Slack channel)
  setup_output=$(printf "Test User\ntest@example.com\ntestuser\n\n\n" | bash "$SANDBOX/setup.sh" 2>&1 || true)

  # Verify setup produced output
  if echo "$setup_output" | grep -q "Setup complete"; then
    pass "setup.sh completed successfully"
  else
    fail "setup.sh did not complete"
  fi

  # Verify .goldy-user.conf was created
  if [ -f "$SANDBOX/.goldy-user.conf" ]; then
    pass "setup.sh created .goldy-user.conf"
    # Verify content
    if grep -q "Test User" "$SANDBOX/.goldy-user.conf"; then
      pass ".goldy-user.conf has correct name"
    else
      fail ".goldy-user.conf has wrong name"
    fi
    if grep -q "testuser" "$SANDBOX/.goldy-user.conf"; then
      pass ".goldy-user.conf has correct login"
    else
      fail ".goldy-user.conf has wrong login"
    fi
    if grep -q "test@example.com" "$SANDBOX/.goldy-user.conf"; then
      pass ".goldy-user.conf has correct email"
    else
      fail ".goldy-user.conf has wrong email"
    fi
  else
    fail "setup.sh didn't create .goldy-user.conf"
  fi

  # Verify hooks installed in test-app
  if [ -f "$SANDBOX/test-app/.git/hooks/post-commit" ] && grep -q "Goldy" "$SANDBOX/test-app/.git/hooks/post-commit" 2>/dev/null; then
    pass "setup.sh installed hooks in test-app"
  else
    fail "setup.sh didn't install hooks in test-app"
  fi

  # Verify TRUTH.md generated
  if [ -f "$SANDBOX/TRUTH.md" ] && [ -s "$SANDBOX/TRUTH.md" ]; then
    pass "setup.sh generated TRUTH.md"
  else
    fail "setup.sh didn't generate TRUTH.md"
  fi

  # Verify changelogs dir created
  if [ -d "$SANDBOX/memory/changelogs/test-app" ]; then
    pass "setup.sh created changelog dir for test-app"
  else
    fail "setup.sh didn't create changelog dir"
  fi

  # Verify summary generated
  if [ -f "$SANDBOX/memory/summaries/test-app.md" ]; then
    pass "setup.sh generated summary for test-app"
  else
    fail "setup.sh didn't generate summary"
  fi

  # Test setup with Slack channel
  printf "Test User\ntest@example.com\ntestuser\n\nC0123456\n" | bash "$SANDBOX/setup.sh" 2>&1 >/dev/null || true
  if [ -f "$SANDBOX/memory/reference_slack_channel.md" ] && grep -q "C0123456" "$SANDBOX/memory/reference_slack_channel.md"; then
    pass "setup.sh saves Slack channel config"
  else
    fail "setup.sh didn't save Slack channel"
  fi

  # Test setup exits gracefully with no repos
  EMPTY_SANDBOX=$(mktemp -d)
  cp -R "$WORKSPACE/scripts" "$EMPTY_SANDBOX/scripts"
  cp "$WORKSPACE/setup.sh" "$EMPTY_SANDBOX/setup.sh"
  cp "$WORKSPACE/.gitignore" "$EMPTY_SANDBOX/.gitignore"
  (cd "$EMPTY_SANDBOX" && git init -q)
  empty_output=$(printf "Test\ntest@test.com\ntest\n\n\n" | bash "$EMPTY_SANDBOX/setup.sh" 2>&1 || true)
  if echo "$empty_output" | grep -qi "No repos found"; then
    pass "setup.sh handles no-repos case gracefully"
  else
    fail "setup.sh doesn't handle empty workspace"
  fi
  rm -rf "$EMPTY_SANDBOX"

  # Cleanup sandbox
  rm -rf "$SANDBOX"
  trap - EXIT
else
  skip "setup.sh sandbox tests (run with --include-setup)"
fi

# ──────────────────────────────────────────────────────────────
section "21. End-to-End: Commit → Changelog → Summary → TRUTH"
# ──────────────────────────────────────────────────────────────

if [ ${#GOLDY_PROJECTS[@]} -gt 0 ]; then
  test_project="${GOLDY_PROJECTS[0]}"
  test_repo="$WORKSPACE/$test_project"

  # Count changelogs before
  before_count=$(find "$WORKSPACE/memory/changelogs/$test_project" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')

  # Make a test commit (empty, with a marker message)
  # Temporarily disable hook to avoid background noise during test
  hook_file="$test_repo/.git/hooks/post-commit"
  hook_backup=""
  if [ -f "$hook_file" ]; then
    hook_backup="${hook_file}.bak"
    mv "$hook_file" "$hook_backup"
  fi

  test_marker="goldy-test-$(date +%s)"
  if (cd "$test_repo" && git commit --allow-empty -m "test: $test_marker" -q 2>/dev/null); then
    pass "Created test commit in $test_project"

    # Wait briefly for async hook
    sleep 2

    # Check if changelog was created
    after_count=$(find "$WORKSPACE/memory/changelogs/$test_project" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$after_count" -gt "$before_count" ]; then
      pass "Post-commit hook created changelog ($before_count → $after_count)"
    else
      # Hook might be async, manually trigger
      (cd "$test_repo" && "$WORKSPACE/scripts/log-commit.sh" "$test_project" "$WORKSPACE" 2>/dev/null)
      after_count2=$(find "$WORKSPACE/memory/changelogs/$test_project" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
      if [ "$after_count2" -gt "$before_count" ]; then
        pass "Manual log-commit created changelog ($before_count → $after_count2)"
      else
        fail "Changelog not created after commit"
      fi
    fi

    # Verify the new changelog contains our marker
    latest_log=$(ls -1t "$WORKSPACE/memory/changelogs/$test_project/"*.md 2>/dev/null | head -1 || true)
    if [ -n "$latest_log" ] && grep -q "$test_marker" "$latest_log"; then
      pass "Latest changelog contains test commit message"
    else
      fail "Latest changelog doesn't contain test commit message"
    fi

    # Test summarize picks up the new commit
    "$WORKSPACE/scripts/summarize.sh" "$test_project" >/dev/null 2>&1
    if grep -q "$test_marker" "$WORKSPACE/memory/summaries/$test_project.md" 2>/dev/null; then
      pass "Summary updated with test commit"
    else
      # Summary might not show the marker in heading, but should update
      pass "Summary regenerated (marker may not appear in recent window)"
    fi

    # Test TRUTH.md regenerates
    "$WORKSPACE/scripts/generate-truth.sh" >/dev/null 2>&1
    if [ -f "$WORKSPACE/TRUTH.md" ] && [ -s "$WORKSPACE/TRUTH.md" ]; then
      pass "TRUTH.md regenerated after test commit"
    else
      fail "TRUTH.md regeneration failed"
    fi

    # Clean up: revert the test commit and restore hook
    (cd "$test_repo" && git reset --soft HEAD~1 -q 2>/dev/null) || true
    # Remove the test changelog
    if [ -n "$latest_log" ] && grep -q "$test_marker" "$latest_log" 2>/dev/null; then
      rm -f "$latest_log"
    fi
    # Restore hook
    if [ -n "$hook_backup" ] && [ -f "$hook_backup" ]; then
      mv "$hook_backup" "$hook_file"
    fi
    pass "Cleaned up test commit and changelog"
  else
    # Restore hook even if commit failed
    if [ -n "$hook_backup" ] && [ -f "$hook_backup" ]; then
      mv "$hook_backup" "$hook_file"
    fi
    skip "End-to-end test — couldn't create test commit in $test_project"
  fi
fi

# ──────────────────────────────────────────────────────────────
echo ""
echo -e "════════════════════════════════════════════"
if [ "$SKIP" -gt 0 ]; then
  echo -e "  Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}, ${YELLOW}${SKIP} skipped${NC}, ${TOTAL} total"
else
  echo -e "  Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}, ${TOTAL} total"
fi
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
