# Installation Verification Checklist

Use this checklist after deploying the Claude Code Review bot to verify everything is working correctly.

## Pre-Deployment Checklist

- [ ] Anthropic API key obtained from https://console.anthropic.com/keys
- [ ] Repository has `.github/` directory
- [ ] User has admin/maintainer access to repository settings
- [ ] Budget approved for API costs (~$2-5/month expected)

## File Structure Verification

Verify all files exist in your repository:

```
your-repo/
├── .github/
│   ├── workflows/
│   │   └── claude-review.yml                        ✓ Exists
│   └── actions/
│       └── claude-review/
│           ├── action.yml                           ✓ Exists
│           ├── index.js                             ✓ Exists
│           ├── package.json                         ✓ Exists
│           └── prompts/
│               ├── ios-review-prompt.md             ✓ Exists (if iOS repo)
│               └── android-review-prompt.md         ✓ Exists (if Android repo)
└── README.md (your repo's existing readme)
```

**Verification Command**:
```bash
ls -la .github/workflows/claude-review.yml
ls -la .github/actions/claude-review/
ls -la .github/actions/claude-review/prompts/
```

All should exist without errors.

## GitHub Secrets Configuration

- [ ] Go to **Settings** → **Secrets and variables** → **Actions**
- [ ] Verify secret named `ANTHROPIC_API_KEY` exists
- [ ] Secret value is non-empty (should be 20+ characters)
- [ ] No typos in secret name (case-sensitive: `ANTHROPIC_API_KEY`)

**Verification**:
Click the secret and confirm it shows `●●●●●●●●●●` (hidden value).

## Test PR Deployment

Create a test PR to verify the bot works:

### 1. Create Test Branch
```bash
git checkout -b test/claude-review-bot
```

### 2. Add Test Code

**For iOS repo** — Create file `test-code.swift`:
```swift
// ❌ INTENTIONAL BUG: Force unwrap
let dict = ["key": "value"]
let value = dict["missing"]!  // This will trigger review feedback
```

**For Android repo** — Create file `test-code.kt`:
```kotlin
// ❌ INTENTIONAL BUG: Double for money
val price: Double = 250.50  // This will trigger review feedback
```

### 3. Commit and Push
```bash
git add test-code.swift  # or test-code.kt
git commit -m "test: add code for Claude review verification"
git push origin test/claude-review-bot
```

### 4. Create PR
- Go to GitHub
- Create PR from `test/claude-review-bot` to `main`/`develop`
- Do NOT merge yet

### 5. Check Review
- [ ] Bot reviews PR within 2 minutes
- [ ] Review shows `CHANGES_REQUESTED` verdict
- [ ] Comments appear on the problematic line(s)
- [ ] Review text mentions the bug (force unwrap / Double for money)

**Expected Bot Comment**:
- iOS: "Remove force unwrap" or "Use optional binding"
- Android: "Use BigDecimal" or "never Double/Float"

### 6. Verify Verdict
- [ ] PR status shows "Some checks were not successful"
- [ ] Click **Details** next to Claude Code Review check
- [ ] Logs show `Verdict: CHANGES_REQUESTED`

### 7. Clean Up
```bash
# Close test PR without merging
# Delete test branch
git branch -D test/claude-review-bot
git push origin --delete test/claude-review-bot
```

## Workflow Status Check

### GitHub Actions Logs

1. Go to **Actions** tab in your repo
2. Find **Claude Code Review** workflow runs
3. Click latest run
4. Click **review** job
5. Expand **Claude Code Review** step
6. Verify output shows:
   - ✅ "Reviewing PR #X"
   - ✅ "Platform: ios" or "Platform: android"
   - ✅ "Claude Review: [response from Claude]"
   - ✅ "Verdict: [APPROVE/CHANGES_REQUESTED/COMMENT]"
   - ✅ "Review completed successfully"

### Common Workflow Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "API key is invalid" | Wrong API key in secrets | Verify API key in Anthropic console |
| "Diff file not found" | Missing `fetch-depth: 0` | Check workflow YAML has correct checkout |
| "Cannot post review" | GitHub token permissions | Ensure `pull-requests: write` in workflow |
| "Platform detection wrong" | Mixed file types | Add explicit `platform: ios` input |

## API Cost Verification

### Check Anthropic Console

1. Go to https://console.anthropic.com/
2. Navigate to **Billing** or **Usage**
3. Verify API key is active
4. Check recent API calls show requests from your IP/GitHub Actions
5. Verify monthly spend is <$10

### Expected Costs

- Per review: ~$0.01-0.03 (depends on diff size)
- 10 reviews/day: ~$0.20-0.60/day
- 100 reviews/month: ~$2-5/month

## Documentation Verification

Verify documentation is in place:

- [ ] README.md exists and is readable
- [ ] SETUP.md covers quick start
- [ ] EXAMPLES.md shows real review examples
- [ ] Review prompts are readable (ios-review-prompt.md, android-review-prompt.md)
- [ ] .gitignore includes sensitive files

## Team Onboarding

- [ ] Notify team that bot is deployed
- [ ] Share README.md and SETUP.md with team
- [ ] Point developers to EXAMPLES.md for understanding review patterns
- [ ] Share Reviewer A's/Reviewer B's review standards (reviewer-a-patterns.md, reviewer-b-patterns.md)
- [ ] Schedule review of example PRs as team training

## Optional: Configure as Required Check

To block merging without bot approval:

1. Go to **Settings** → **Branches** → **Add rule**
2. For branch pattern: `main` or `develop`
3. Check **Require status checks to pass before merging**
4. Add **Claude Code Review** to required checks
5. Save rule

**Verification**:
- [ ] Branch protection rule appears in settings
- [ ] "Claude Code Review" is listed as required
- [ ] Try creating test PR, verify you cannot merge without passing review

## Performance Monitoring (Week 1)

Track these metrics for the first week:

| Metric | Target | Actual |
|--------|--------|--------|
| Review time (seconds) | <30 | _____ |
| API cost per review | <$0.05 | _____ |
| False positive rate | <10% | _____ |
| Team satisfaction | >80% | _____ |
| Uptime (% successful reviews) | >99% | _____ |

## Sign-Off

Once you've verified everything above, sign off:

```
[ ] Technician Name: ________________
[ ] Date: __________
[ ] All checks passed ✓
```

### If Any Check Fails

1. Document the failure
2. Check the README.md troubleshooting section
3. Review GitHub Actions logs for errors
4. Contact support if issue persists

## Next Steps

1. **Customize** review standards if needed (edit prompt files)
2. **Train team** on review patterns
3. **Monitor** bot accuracy and costs weekly
4. **Iterate** on prompts based on feedback
5. **Extend** to other repositories once proven

## Common Questions

**Q: How long does review take?**
A: 5-15 seconds on average, sometimes up to 30 seconds for large diffs.

**Q: Can I disable the bot?**
A: Yes, delete the workflow file or disable in Actions settings.

**Q: Can I override the bot?**
A: Yes, humans can still approve/merge. Configure branch protection if you want bot approval to be required.

**Q: How do I customize review standards?**
A: Edit the prompt files in `.github/actions/claude-review/prompts/`. Changes take effect immediately on next PR.

**Q: What if the bot gets it wrong?**
A: Comment on the PR explaining disagreement. Over time, you can update prompts to match team preferences.

---

**Checklist Created**: March 10, 2026
**For Use With**: Claude Code Review Bot v1.0
**Estimated Time**: 15-30 minutes to complete
