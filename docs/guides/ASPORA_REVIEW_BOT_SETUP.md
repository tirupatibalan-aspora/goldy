# Aspora Review Bot — Setup Guide

> A Claude-powered code review bot that learns from your team's PR reviewers and enforces their patterns automatically. Works with any platform, any reviewer, any team.

## What It Does

1. **Learns** from real PR review comments (auto-harvested when PRs merge)
2. **Audits** every PR diff against all learned patterns before review
3. **Scores** PRs out of 10 (Critical: -3, Major: -2, Minor: -0.5)
4. **Blocks** PRs below 8/10 from being created
5. **Self-improves** — every merged PR enriches the learnings database

## Quick Start (5 minutes)

### Step 1: Create Learnings File

Create `{platform}-{reviewer}.json` in your learnings directory:

```
claude-review-bot/
  .github/
    actions/
      claude-review/
        learnings/
          android-reviewer-b.json    # Example
          ios-reviewer-a.json          # Example
          web-alice.json         # YOUR NEW FILE
```

### Step 2: Define the JSON Schema

```json
{
  "reviewer": "Alice (alice-github)",
  "platform": "web",
  "last_updated": "2026-04-01",
  "source_prs": [],
  "stats": {
    "total_comments": 0,
    "critical": 0,
    "major": 0,
    "minor": 0
  },
  "patterns": []
}
```

### Step 3: Add Your First Patterns

Each pattern has this structure:

```json
{
  "id": "web-001",
  "severity": "critical",
  "category": "security",
  "rule": "Never use innerHTML — always use textContent or DOM APIs",
  "bad_example": "element.innerHTML = userInput",
  "good_example": "element.textContent = userInput",
  "source": "PR #42, Comment #3 — Alice: 'innerHTML opens XSS vulnerabilities'",
  "files_affected": ["src/components/UserProfile.tsx"],
  "frequency": 1
}
```

**Fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique: `{platform}-{number}` (e.g., `web-001`) |
| `severity` | Yes | `"critical"` / `"major"` / `"minor"` |
| `category` | Yes | Free-form: `architecture`, `security`, `performance`, `type-safety`, `constants`, `localization`, `code-quality`, `compose-pattern`, `ux`, `shared-code`, `assets` |
| `rule` | Yes | One-line description of what the reviewer enforces |
| `bad_example` | Yes | Code that violates the rule |
| `good_example` | Yes | Code that follows the rule |
| `source` | Yes | PR + comment reference + reviewer quote |
| `files_affected` | No | Files where this was flagged |
| `frequency` | No | How many times reviewer flagged it (higher = more important) |

### Step 4: Register in CLAUDE.md

Add your reviewer to the "Current reviewers" table in your project's `CLAUDE.md`:

```markdown
## Review Bot Learnings

### Current reviewers
| Platform | Reviewer | Learnings file | Patterns |
|----------|----------|---------------|----------|
| iOS | Reviewer A | `ios-reviewer-a.json` | 12 patterns |
| Android | Reviewer B | `android-reviewer-b.json` | 25 patterns |
| Web | Alice | `web-alice.json` | 5 patterns |   <!-- NEW -->
```

### Step 5: Add the Audit Rule to CLAUDE.md

If not already present, add this section to your `CLAUDE.md`:

```markdown
## STRICT: Aspora Review Bot Audit Before PR

**ALWAYS run the Aspora Review Bot audit before creating or updating a PR.**

### Audit process
1. Read ALL matching `{platform}-*.json` files from `claude-review-bot/.github/actions/claude-review/learnings/`
2. Diff the branch against base
3. Audit every changed file against ALL patterns
4. Score: Start at 10. Critical: -3, Major: -2, Minor: -0.5
5. Fix all critical/major issues BEFORE creating PR
6. Include score in PR description:

## Aspora Review Bot Score: X/10
| Severity | Count | Details |
|----------|-------|---------|
| Critical | N | (list or "None") |
| Major | N | (list or "None") |
| Minor | N | (list or "None") |

**Minimum score to create PR: 8/10.**
```

---

## Severity Guide

| Severity | Penalty | When to Use | Examples |
|----------|---------|-------------|---------|
| **Critical** | -3 | Would block merge, architectural violation, security issue | Wrong base class, hardcoded secrets, modifying shared files |
| **Major** | -2 | Must fix before merge, pattern violation | Missing preview, hardcoded strings, wrong patterns |
| **Minor** | -0.5 | Nice to have, style preference | Naming conventions, comment style |

---

## Auto-Harvesting (GitHub Actions)

The bot can automatically learn from merged PRs. Set up the harvest workflow:

### `workflows/harvest-learnings.yml`

```yaml
name: Harvest Review Learnings
on:
  pull_request:
    types: [closed]

jobs:
  harvest:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: main

      - name: Detect platform and reviewer
        id: detect
        run: |
          # Map repository to platform
          if [[ "${{ github.repository }}" == *"ios"* ]]; then
            echo "platform=ios" >> $GITHUB_OUTPUT
            echo "reviewer=your-ios-reviewer" >> $GITHUB_OUTPUT
          elif [[ "${{ github.repository }}" == *"android"* ]]; then
            echo "platform=android" >> $GITHUB_OUTPUT
            echo "reviewer=your-android-reviewer" >> $GITHUB_OUTPUT
          fi

      - name: Harvest PR comments
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          node scripts/harvest-pr-comments.js \
            --pr ${{ github.event.pull_request.number }} \
            --platform ${{ steps.detect.outputs.platform }} \
            --reviewer ${{ steps.detect.outputs.reviewer }}

      - name: Commit updated learnings
        run: |
          git config user.name "Review Bot"
          git config user.email "bot@your-org.com"
          git add .github/actions/claude-review/learnings/
          git diff --staged --quiet || git commit -m "chore: update review learnings from PR #${{ github.event.pull_request.number }}"
          git push
```

### `workflows/claude-review.yml`

```yaml
name: Claude Code Review
on:
  pull_request:
    types: [opened, synchronize, ready_for_review]

jobs:
  review:
    if: "!github.event.pull_request.draft"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate diff
        id: diff
        run: |
          DIFF=$(git diff origin/${{ github.event.pull_request.base.ref }}...HEAD)
          echo "$DIFF" > /tmp/pr-diff.txt
          DIFF_SIZE=$(wc -c < /tmp/pr-diff.txt)
          if [ "$DIFF_SIZE" -gt 100000 ]; then
            echo "skip=true" >> $GITHUB_OUTPUT
          fi

      - name: Run review
        if: steps.diff.outputs.skip != 'true'
        uses: ./.github/actions/claude-review
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
          platform: ${{ contains(github.repository, 'ios') && 'ios' || 'android' }}
          pr_number: ${{ github.event.pull_request.number }}
```

---

## How Patterns Evolve

```
Reviewer leaves PR comment
        ↓
PR merges → harvest workflow runs
        ↓
Claude extracts pattern from comment
        ↓
Pattern added to {platform}-{reviewer}.json
        ↓
Next PR audit uses the new pattern
        ↓
Claude Code enforces it before PR creation
```

**The flywheel**: Every review comment makes future PRs better. Reviewers stop repeating themselves. New team members get instant access to all tribal knowledge.

---

## Best Practices

1. **Start small** — Add 3-5 critical patterns from your reviewer's most common complaints
2. **Use real quotes** — The `source` field should reference actual PR comments for credibility
3. **Bad + good examples** — Always provide both so Claude knows what to fix, not just what to flag
4. **Frequency matters** — Higher frequency patterns are more likely to be flagged
5. **Keep it updated** — Remove patterns that are no longer relevant, update ones that evolved
6. **Pre-existing vs new** — Only score issues introduced by the current diff, not pre-existing code
7. **One file per reviewer** — Don't mix reviewers in one file (different people have different standards)
8. **Cross-platform patterns** — If a rule applies to both iOS and Android, add it to both files

---

## Example: Bootstrapping from Existing PR Comments

To quickly populate patterns from an existing reviewer's history:

1. Pull up their last 5-10 PR reviews
2. Group comments by theme (architecture, naming, performance, etc.)
3. For each theme, create a pattern with the most representative comment
4. Set `frequency` to how many times they flagged that specific issue
5. Set `severity` based on whether they blocked the PR (critical), requested changes (major), or just commented (minor)

Example extraction from a real review:

> **Reviewer B on PR #XXXX (7 times)**: "ALL ViewModels MUST extend BaseMviViewModel"

```json
{
  "id": "android-001",
  "severity": "critical",
  "category": "architecture",
  "rule": "ALL ViewModels MUST extend BaseMviViewModel — never raw ViewModel()",
  "bad_example": "class GoldBuyViewModel : ViewModel() { ... }",
  "good_example": "class GoldBuyViewModel @Inject constructor(...) : BaseMviViewModel<State, Event, Command>(GoldBuyFeature) { ... }",
  "source": "PR #XXXX, Comments #5 #16 #23 — Reviewer B: 'ViewModels must extend BaseMviViewModel'",
  "files_affected": ["GoldBuyViewModel.kt"],
  "frequency": 7
}
```

---

## Directory Structure

```
your-repo/
  claude-review-bot/
    .github/
      actions/
        claude-review/
          action.yml           # Composite action definition
          index.js             # Review engine (Node.js)
          test.js              # Tests (76 passing)
          learnings/
            ios-reviewer-a.json      # iOS reviewer patterns
            android-reviewer-b.json # Android reviewer patterns
            web-alice.json     # Add your own!
      workflows/
        claude-review.yml      # PR review trigger
        harvest-learnings.yml  # Auto-learn from merged PRs
    scripts/
      harvest-pr-comments.js   # Extracts patterns from PR comments
```

---

## FAQ

**Q: Can I have multiple reviewers per platform?**
A: Yes. Create `android-reviewer-b.json` and `android-maria.json`. The audit loads ALL `{platform}-*.json` files.

**Q: What if a pattern is wrong or outdated?**
A: Delete it from the JSON and commit. The bot only enforces what's in the file.

**Q: Does it work without GitHub Actions?**
A: Yes. The CLAUDE.md rules make Claude Code run the audit locally before creating PRs. GitHub Actions is optional (adds automated PR review + auto-harvesting).

**Q: Can I use this for non-mobile platforms?**
A: Yes. The platform field is just a string. Use `"web"`, `"backend"`, `"infra"`, etc.

**Q: How do I test my patterns?**
A: Write a bad code snippet that violates your pattern. Ask Claude Code to review it. If it catches the violation, the pattern works.
