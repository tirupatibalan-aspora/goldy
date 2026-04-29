# Claude Code Review Bot — Implementation Summary

## Overview

A production-ready GitHub Action that enforces Reviewer A's (iOS) and Reviewer B's (Android) code review standards automatically on every pull request using Claude AI.

## What Was Built

### 1. GitHub Action Workflow
**File**: `.github/workflows/claude-review.yml`

- Triggers on PR open/update/ready-for-review
- Extracts diff via `git diff origin/base...HEAD`
- Calls custom Claude Review action
- Auto-detects platform (iOS vs Android)
- Skips reviews for diffs >100KB
- Handles edge cases gracefully

### 2. Custom GitHub Action
**Directory**: `.github/actions/claude-review/`

**Files**:
- `action.yml` — Action metadata (Node 20 runtime)
- `index.js` — Main review engine (~350 lines)
- `package.json` — Dependencies (@anthropic-ai/sdk, @actions/core, @octokit/rest)

**Key Functions**:
- Platform detection (Swift → iOS, Kotlin → Android)
- Prompt loading (reviewer-specific standards)
- Claude API integration (Sonnet 4)
- Verdict parsing (APPROVE vs CHANGES_REQUESTED)
- Inline comment posting (file/line-specific feedback)
- PR review submission

### 3. Review Standards (System Prompts)

**iOS Prompt** (`prompts/ios-review-prompt.md`):
- Mined from Reviewer A's review patterns
- 5 critical blockers (force unwraps, race conditions, etc.)
- 7 major issues requiring changes
- 3 minor issues
- 16-item approval checklist
- Examples and patterns

**Android Prompt** (`prompts/android-review-prompt.md`):
- Mined from Reviewer B's review patterns
- 6 critical blockers (BigDecimal requirement, missing tests, etc.)
- 7 major issues requiring changes
- 4 minor issues
- 19-item approval checklist
- MVI pattern enforcement
- Market-specific considerations (UAE vs UK)

### 4. Documentation

**README.md**:
- 400+ lines comprehensive guide
- Setup instructions (4 steps)
- Customization options
- Troubleshooting
- Architecture overview
- Cost estimation (~$2/month for 100 reviews)
- Future improvements roadmap

**SETUP.md**:
- 5-minute quick start
- Step-by-step instructions
- Verification checklist
- Cost check
- Troubleshooting

**EXAMPLES.md**:
- 8 real-world example reviews
- iOS force unwrap (blocked)
- Android missing tests (blocked)
- iOS task cancellation (changes requested)
- Android design tokens (changes requested)
- Android exhaustive when (blocked)
- iOS caching (changes requested)
- 2 approved PRs (iOS and Android)
- Common approval/rejection patterns

**IMPLEMENTATION_SUMMARY.md** (this file):
- Overview of what was built
- File structure
- How to use
- Customization guide
- Integration strategy

## File Structure

```
.github/
├── workflows/
│   └── claude-review.yml                          # Main workflow
└── actions/
    └── claude-review/
        ├── action.yml                             # Action metadata
        ├── index.js                               # Core logic (350 lines)
        ├── package.json                           # Dependencies
        └── prompts/
            ├── ios-review-prompt.md              # Reviewer A's standards
            └── android-review-prompt.md          # Reviewer B's standards

README.md                                          # Main documentation
SETUP.md                                           # Quick start guide
EXAMPLES.md                                        # Example reviews
IMPLEMENTATION_SUMMARY.md                         # This file
.gitignore                                         # Git ignore rules
```

## How to Use

### For Repository Maintainers

1. **Copy files to your repo**:
   ```bash
   cp -r .github/workflows/claude-review.yml your-repo/.github/workflows/
   cp -r .github/actions/claude-review/ your-repo/.github/actions/
   ```

2. **Add Anthropic API key**:
   - Go to Settings → Secrets and variables → Actions
   - Add `ANTHROPIC_API_KEY` secret

3. **Test**: Create a PR with obvious issue (force unwrap, BigDecimal as Double)

4. **Customize** (optional):
   - Edit review standards in `prompts/*.md`
   - Change model in `index.js` (line ~110)
   - Adjust diff size limit in workflow YAML

### For Developers

1. **Understand review standards**: Read Reviewer A's and Reviewer B's patterns (or quick references)
2. **Self-review before pushing**: Check against the 16/19-item checklists
3. **Push PR**: Bot reviews automatically
4. **Fix issues**: Address feedback and push updates
5. **Get approved**: Bot approves when standards met

### For DevOps Teams

1. **Deploy to both repos**:
   - `app-ios`: Workflow auto-detects `platform: ios`
   - `app-android`: Workflow auto-detects `platform: android`

2. **Configure branch protection** (optional):
   - Settings → Branches → Add protection rule
   - Require "Claude Code Review" status check

3. **Monitor costs**:
   - Claude Sonnet 4: ~$0.02 per review
   - Expected: ~$2/month for typical activity

4. **Update standards**: Edit prompt files to evolve review criteria

## Key Features

### Platform Detection
- Automatic: Detects .swift → iOS, .kt → Android
- Manual override: Pass `platform: ios` or `platform: android` in workflow

### Large Diff Handling
- Skips reviews for diffs >100KB (configurable)
- Truncates large diffs with truncation notice
- Gracefully handles all sizes

### Error Recovery
- API failures: Gracefully exits without breaking workflow
- Review conflicts: Posts comment if review already exists
- Missing files: Skips comments for files not in PR

### Cost Optimization
- Claude Sonnet 4 (balanced cost/capability)
- ~$3/1M input tokens, $15/1M output tokens
- Average review: 5K input + 1K output = ~$0.02

### Security
- API key in GitHub Secrets (never logged)
- GitHub token scoped to `contents:read` + `pull-requests:write`
- Diff sent to Anthropic (not stored)
- Reviews visible only to collaborators

## Customization

### Change Review Standards

Edit the prompt files:

```markdown
# ios-review-prompt.md
- Add/remove criteria
- Change severity levels
- Add platform-specific examples
```

Changes take effect on next PR (no deployment needed).

### Change AI Model

In `index.js` (line ~110):

```javascript
const message = await client.messages.create({
  model: 'claude-opus-4-20250805', // Change model here
  max_tokens: 4000,
  // ...
});
```

Available models:
- `claude-opus-4-20250805` — Most capable ($0.03 input, $0.15 output per 1M tokens)
- `claude-sonnet-4-20250514` — Balanced (recommended, $0.003 input, $0.015 output)
- `claude-haiku-4-5-20251001` — Fastest ($0.0008 input, $0.004 output)

### Adjust Diff Limit

In `.github/workflows/claude-review.yml`:

```yaml
- name: Skip if diff too large
  if: steps.diff.outputs.diff_size > 100000  # ← Change this (in bytes)
```

### Platform-Specific Rules

Add market-specific logic to prompts:

```markdown
## Market-Specific Considerations

For UAE vs UK features:
- Validators must handle both markets
- Constants in separate objects
- Tests must cover both scenarios
```

## Integration Strategy

### Phase 1: Testing (Week 1)
- Deploy to single repo (recommend app-android first)
- Test with small features
- Collect feedback from Reviewer A/Reviewer B
- Refine prompts based on feedback

### Phase 2: Rollout (Week 2)
- Deploy to second repo (app-ios)
- Make reviews informational (not blocking)
- Team gets used to bot feedback

### Phase 3: Enforcement (Week 3+)
- Configure as required check (blocking merges)
- OR keep as informational + human review
- Adjust standards based on team feedback

### Phase 4: Refinement (Ongoing)
- Update prompts with new patterns
- Adjust Claude model as needed
- Track review accuracy and team satisfaction

## Metrics to Track

- **Review accuracy**: % of bot findings confirmed by humans
- **False positives**: % of bot suggestions humans disagree with
- **False negatives**: % of issues humans find that bot misses
- **Cost**: $ spent on reviews monthly
- **Time saved**: Estimated hours saved vs manual review
- **Developer satisfaction**: Team feedback on bot usefulness

## Known Limitations

1. **Large diffs**: >100KB diffs are truncated (may miss issues)
2. **Complexity**: Very complex files may confuse Claude
3. **Multi-language**: Mixed iOS+Android PRs use Android rules
4. **Latency**: ~5-10 seconds per review (async API calls)
5. **Context**: Bot can't see PR description/linked issues

## Future Improvements

- [ ] Per-feature customization (Gold vs Send module rules)
- [ ] Historical tracking (reviewer pattern dashboard)
- [ ] Batch review mode (review multiple PRs overnight)
- [ ] Linear/Jira integration (sync approval status)
- [ ] Custom review bypass (for hotfixes, infrastructure)
- [ ] Performance optimization (caching, batching)
- [ ] Custom metrics (auto-detect coding patterns)
- [ ] Reviewer feedback loop (learn from human corrections)

## Support & Troubleshooting

### Common Issues

**"API key is invalid"**:
- Check Anthropic console for key validity
- Verify secret is set correctly in GitHub

**"Diff file not found"**:
- Ensure workflow has `fetch-depth: 0`

**"Platform detection wrong"**:
- Manually set `platform: ios` in workflow

**"No reviews posted"**:
- Check GitHub Actions logs
- Verify GitHub token permissions

### Getting Help

1. Check README.md troubleshooting section
2. Review EXAMPLES.md for reference
3. Check GitHub Actions logs for error messages
4. Verify files exist: `.github/actions/claude-review/*`

## Maintenance

### Monthly
- Monitor costs (should be <$5)
- Review false positive rate
- Update prompts with new patterns

### Quarterly
- Check for new Claude models
- Assess team satisfaction
- Collect feedback for improvements

### Yearly
- Major prompt refactor based on learnings
- Consider alternative models
- Plan new features

## Success Criteria

The bot is successful when:

✅ Team finds bot feedback useful (>70% of findings confirmed)
✅ Monthly cost is <$5 for typical activity
✅ Reviews take <1 minute per PR
✅ False positive rate <10%
✅ Team velocity increases (less manual review overhead)
✅ Code quality improves (fewer issues slip through)

## Questions?

Refer to:
- **Setup**: SETUP.md
- **Detailed guide**: README.md
- **Examples**: EXAMPLES.md
- **Reviewer A's standards**: reviewer-a-patterns.md
- **Reviewer B's standards**: reviewer-b-patterns.md

---

**Built**: March 10, 2026
**Claude Model**: Sonnet 4 (claude-sonnet-4-20250514)
**Status**: Production Ready
**License**: MIT
