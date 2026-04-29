# Claude Code Review Bot

Automated code review bot for `app-ios` and `app-android` repositories using Claude AI. The bot enforces Reviewer A's (iOS) and Reviewer B's (Android) code review standards automatically on every PR.

## Features

- **Platform Detection**: Automatically detects iOS (Swift files) or Android (Kotlin files)
- **Reviewer Standards**: Enforces Reviewer A's review patterns for iOS, Reviewer B's patterns for Android
- **Inline Comments**: Posts specific feedback on problematic code lines
- **PR Status Check**: Approves or requests changes based on review verdict
- **Large Diff Handling**: Gracefully handles diffs up to 100KB, truncates larger ones
- **Duplicate Review Prevention**: Handles edge cases where reviews already exist

## Setup Instructions

### 1. Add Anthropic API Key

**In both `app-ios` and `app-android` repositories:**

1. Go to **Settings → Secrets and Variables → Actions**
2. Click **New repository secret**
3. Name: `ANTHROPIC_API_KEY`
4. Value: Your Anthropic API key (get from https://console.anthropic.com/keys)
5. Click **Add secret**

### 2. Add Workflow File

Copy `.github/workflows/claude-review.yml` to your repository's `.github/workflows/` directory.

**Path**: `.github/workflows/claude-review.yml`

```yaml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize, ready_for_review]

permissions:
  contents: read
  pull-requests: write

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get PR diff
        id: diff
        run: |
          git diff origin/${{ github.base_ref }}...HEAD > pr_diff.txt
          echo "diff_size=$(wc -c < pr_diff.txt)" >> $GITHUB_OUTPUT

      - name: Skip if diff too large
        if: steps.diff.outputs.diff_size > 100000
        run: |
          echo "Diff size ($(steps.diff.outputs.diff_size) bytes) exceeds limit. Skipping review."
          exit 0

      - name: Claude Code Review
        uses: ./.github/actions/claude-review
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
          platform: ${{ contains(github.repository, 'ios') && 'ios' || 'android' }}
          pr_number: ${{ github.event.pull_request.number }}
```

### 3. Add Custom Action

Copy the entire `.github/actions/claude-review/` directory to your repository.

**Required files**:
- `.github/actions/claude-review/action.yml` — Action metadata
- `.github/actions/claude-review/index.js` — Main review logic
- `.github/actions/claude-review/package.json` — Node dependencies
- `.github/actions/claude-review/prompts/ios-review-prompt.md` — iOS standards
- `.github/actions/claude-review/prompts/android-review-prompt.md` — Android standards

### 4. Configure as Required Check (Optional)

To make reviews block merging:

1. Go to **Settings → Branches → Branch protection rules**
2. Add/edit a rule for your main/develop branch
3. Check **Require status checks to pass before merging**
4. Add **Claude Code Review** to the required checks
5. Click **Save**

## How It Works

### Workflow

1. **PR opened/updated** → Workflow triggers
2. **Diff extracted** → `git diff` saves changes to `pr_diff.txt`
3. **Platform detected** → By file extensions (.swift → iOS, .kt → Android)
4. **Claude review** → Calls Claude Sonnet 4 with reviewer standards
5. **Verdict extracted** → Parses APPROVE or CHANGES_REQUESTED
6. **Comments posted** → Inline feedback on problematic lines
7. **PR review submitted** → GitHub review with overall verdict

### Review Format

Claude returns reviews in this format:

```
VERDICT: APPROVE | CHANGES_REQUESTED

SUMMARY: [One sentence summary]

ISSUES:
- [File/Line X]: Issue description. Fix: Suggestion.
- [File/Line Y]: Another issue. Fix: Specific fix.

POSITIVES: [What code does well]

NEXT_STEPS: [If changes requested]
```

### Customization

#### Modify Review Standards

Edit the review prompts:

- **iOS**: `.github/actions/claude-review/prompts/ios-review-prompt.md`
- **Android**: `.github/actions/claude-review/prompts/android-review-prompt.md`

Add/remove criteria, change severity levels, or update examples.

#### Change Claude Model

In `.github/actions/claude-review/index.js`, line ~110:

```javascript
const message = await client.messages.create({
  model: 'claude-sonnet-4-20250514', // ← Change here
  max_tokens: 4000,
  // ...
});
```

Available models:
- `claude-opus-4-20250805` (most capable, slower, more expensive)
- `claude-sonnet-4-20250514` (balanced, recommended)
- `claude-haiku-4-5-20251001` (fastest, cheapest)

#### Adjust Diff Size Limit

In `.github/workflows/claude-review.yml`:

```yaml
- name: Skip if diff too large
  if: steps.diff.outputs.diff_size > 100000  # ← Change 100000 to your limit (bytes)
```

## Example PR Reviews

### iOS Review (Approved)

```
VERDICT: APPROVE

SUMMARY: Code follows project patterns with proper task cancellation and type safety.

POSITIVES:
- Correct use of CacheableService pattern
- Proper task cancellation on concurrent updates
- Excellent test coverage with MockRequestManager
- Localized strings correctly in Localizable.strings
- Guard let shorthand syntax used properly

NEXT_STEPS: Ready to merge!
```

### Android Review (Changes Requested)

```
VERDICT: CHANGES_REQUESTED

SUMMARY: BigDecimal requirement missed; missing tests for Feature logic.

ISSUES:
- [GoldBuyViewModel.kt:45]: Money value as Double instead of BigDecimal.
  Fix: Change `val price: Double` to `val price: BigDecimal = BigDecimal("0")`

- [GoldBuyFeature.kt:1]: Feature logic present but no test file found.
  Fix: Create GoldBuyFeatureTest.kt with 25+ test methods covering state transitions.

- [GoldBuyScreen.kt:23]: Hard-coded color value.
  Fix: Use `Theme.colors.primaryGreen` instead of `Color(0xFF6366F1)`

NEXT_STEPS: Address the 3 issues above, add test file, push updates.
```

## Integration with Reviewer A & Reviewer B's Reviews

This bot acts as a **gatekeeper** for obvious issues before human review:

1. **Bot catches common patterns** (force unwraps, BigDecimal misuse, missing tests)
2. **PR can still be approved/blocked by bot**
3. **Human reviewers focus on nuanced architectural decisions**
4. **Reduces back-and-forth on style/pattern violations**

The bot's verdicts don't override human judgment—configure branch protection to require both bot approval AND human review if desired.

## Troubleshooting

### "API rate limit exceeded"

Anthropic API has rate limits. If you exceed them:
1. Wait 30-60 seconds before retrying
2. Upgrade Anthropic plan for higher limits
3. Reduce review frequency (e.g., only on ready_for_review, not synchronize)

### "Diff file not found"

Check workflow YAML—git checkout must use `fetch-depth: 0`:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # ← Must be present
```

### "Review already exists"

The action handles this gracefully by posting a comment instead. No action needed.

### "Platform detection wrong"

Add explicit platform input in workflow:

```yaml
- name: Claude Code Review
  uses: ./.github/actions/claude-review
  with:
    # ... other inputs ...
    platform: ios  # Force platform detection
```

## Architecture

```
.github/
├── workflows/
│   └── claude-review.yml           # Main workflow trigger
└── actions/
    └── claude-review/
        ├── action.yml              # Action metadata
        ├── index.js                # Core review logic
        ├── package.json            # Node dependencies
        └── prompts/
            ├── ios-review-prompt.md    # Reviewer A's standards
            └── android-review-prompt.md # Reviewer B's standards
```

### Key Functions (index.js)

- `main()` — Entry point, orchestrates workflow
- `detectPlatform()` — Identifies iOS vs Android from file extensions
- `loadPrompt()` — Loads reviewer standards based on platform
- `reviewWithClaude()` — Calls Claude Sonnet API
- `parseVerdict()` — Extracts APPROVE/CHANGES_REQUESTED from response
- `extractComments()` — Parses inline feedback from review
- `postReviewComments()` — Posts comments on specific file lines
- `submitReview()` — Submits overall review verdict to GitHub

## Cost Estimation

Using Claude Sonnet 4 (recommended):

- **Input**: ~$3/million tokens
- **Output**: ~$15/million tokens

**Per review (typical):**
- Average diff: 5,000 tokens
- Average review: 1,000 tokens
- Cost: ~$0.02 per review

**Monthly (100 reviews):**
- Estimated: ~$2 cost

## Security

- **API Key**: Stored in GitHub Secrets, never logged
- **Diff content**: Sent to Anthropic API (not stored)
- **GitHub Token**: Scoped to `contents:read` and `pull-requests:write` only
- **Review text**: Posted as PR reviews (visible to collaborators)

## Known Limitations

1. **Large diffs** (>100KB) are truncated—may miss issues
2. **Very complex files** may confuse Claude—verify critical decisions
3. **Multi-language PRs** (mixing iOS + Android) use Android rules
4. **Async operations** in Claude API (~5-10 seconds per review)

## Future Improvements

- [ ] Per-feature customization (different rules for Gold vs Send module)
- [ ] Historical review tracking (dashboard of reviewer patterns)
- [ ] Batch review mode (review multiple PRs overnight)
- [ ] Integration with linear/Jira (sync approval status)
- [ ] Custom review bypass (for hotfixes, infrastructure changes)

## Support

For issues or suggestions:

1. Check logs: GitHub Actions → Workflow run → Claude Code Review step
2. Verify API key is set correctly in Secrets
3. Check Anthropic API status at https://status.anthropic.com
4. Review Reviewer A's/Reviewer B's standards in prompt files

## License

MIT License — Use freely within Aspora organization.

---

**Last Updated**: March 10, 2026
**Claude Model**: Sonnet 4 (claude-sonnet-4-20250514)
**Maintained By**: Aspora DevOps Team
