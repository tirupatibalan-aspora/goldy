# START HERE — Claude Code Review Bot

Welcome! This is a production-ready GitHub Action that automatically reviews code on `app-ios` and `app-android` using Claude AI, enforcing Reviewer A's and Reviewer B's review standards.

## What Is This?

An automated code review bot that:
- Reviews every PR automatically
- Enforces Reviewer A's standards on iOS (Swift files)
- Enforces Reviewer B's standards on Android (Kotlin files)
- Posts inline feedback on problematic lines
- Approves or requests changes based on standards
- Works as a PR gate to improve code quality

## Quick Start (5 minutes)

1. **Add API Key** → Go to GitHub Settings → Secrets → Add `ANTHROPIC_API_KEY`
2. **Copy Files** → Copy `.github/` directory to your repo
3. **Test** → Create PR with obvious bug (force unwrap for iOS, Double for money on Android)
4. **Done!** → Bot reviews your PR within 2 minutes

See `SETUP.md` for detailed steps.

## Key Documents

### For First-Time Users
- **`SETUP.md`** — 5-minute setup guide
- **`EXAMPLES.md`** — See real review examples (8 examples included)
- **`VERIFICATION_CHECKLIST.md`** — Verify installation worked

### For Developers
- **Reviewer A's iOS Standards** (from original file: `reviewer-a-patterns.md`)
  - Key points: No force unwraps, task cancellation, CacheableService pattern
  - Quick ref: `reviewer-a-quick-reference.md`
- **Reviewer B's Android Standards** (from original file: `reviewer-b-patterns.md`)
  - Key points: BigDecimal for money, MVI pattern, 25+ tests
  - Quick ref: `reviewer-b-quick-ref.md`

### For Maintainers & DevOps
- **`README.md`** — Complete documentation (326 lines)
- **`IMPLEMENTATION_SUMMARY.md`** — What was built, architecture, integration strategy
- **`FILE_MANIFEST.md`** — Complete file listing and descriptions

## File Structure

```
.
├── START_HERE.md                               ← YOU ARE HERE
├── SETUP.md                                    ← Read this first
├── README.md                                   ← Full documentation
├── EXAMPLES.md                                 ← Real review examples
├── VERIFICATION_CHECKLIST.md                   ← Verify setup
├── IMPLEMENTATION_SUMMARY.md                   ← Technical details
├── FILE_MANIFEST.md                            ← All files explained
├── .gitignore
└── .github/
    ├── workflows/
    │   └── claude-review.yml                   ← Main workflow (COPY TO REPO)
    └── actions/
        └── claude-review/
            ├── action.yml                      ← Action metadata (COPY TO REPO)
            ├── index.js                        ← Review engine (COPY TO REPO)
            ├── package.json                    ← Dependencies (COPY TO REPO)
            └── prompts/
                ├── ios-review-prompt.md        ← Reviewer A's standards (COPY TO REPO)
                └── android-review-prompt.md    ← Reviewer B's standards (COPY TO REPO)
```

**Files marked COPY TO REPO** — These go in `.github/` of your repository.

## Real-World Example

**Developer pushes bad iOS code:**

```swift
// ❌ Force unwrap (Reviewer A will reject this)
let value = dict["key"]!
```

**Bot reviews within 2 minutes:**

```
VERDICT: CHANGES_REQUESTED

SUMMARY: Force unwrap on dictionary access will crash if key missing.

ISSUES:
- [Line X]: Force unwrap on dictionary access.
  Fix: Use optional binding: guard let value = dict["key"] else { return nil }
```

**Developer fixes and pushes update:**

```swift
// ✅ Safe optional handling (Reviewer A approves)
guard let value = dict["key"] else { return nil }
```

**Bot reviews:**

```
VERDICT: APPROVE

Code is now type-safe. Ready to merge!
```

## What Gets Reviewed

### iOS (Reviewer A's Standards)
- Force unwraps (rejected)
- Race conditions in concurrent code (rejected)
- Computed properties with side effects (rejected)
- Incorrect architectural patterns (rejected)
- Network model naming conventions (rejected)
- And 15+ more criteria...

### Android (Reviewer B's Standards)
- Money as Double/Float instead of BigDecimal (rejected)
- Missing tests (rejected)
- Non-exhaustive when statements (rejected)
- Business logic in UI layer (rejected)
- Hard-coded design values (rejected)
- And 15+ more criteria...

## Cost

- **Per review**: ~$0.01-0.03 (depends on diff size)
- **Monthly** (100 reviews): ~$2-5
- **Model**: Claude Sonnet 4 (recommended)

See README.md for detailed cost breakdown.

## Common Questions

**Q: How long does a review take?**
A: 5-30 seconds on average. You'll see the bot comment within 2 minutes of pushing.

**Q: Can I override the bot?**
A: Yes. Humans can still approve. You can make the bot's approval required via branch protection.

**Q: What if the bot gets it wrong?**
A: Comment on the PR explaining. Over time, you can update the prompt files to match team preferences.

**Q: Can I customize the review standards?**
A: Yes! Edit the prompt files:
- iOS: `.github/actions/claude-review/prompts/ios-review-prompt.md`
- Android: `.github/actions/claude-review/prompts/android-review-prompt.md`

Changes take effect on the next PR.

**Q: How do I disable the bot?**
A: Delete the workflow file or disable in Actions settings.

**Q: What if diff is too large?**
A: Reviews are skipped for diffs >100KB. You can change this limit in the workflow YAML.

## Next Steps

1. **Read SETUP.md** (5 minutes) — Get bot running
2. **Create test PR** (5 minutes) — Verify it works
3. **Read EXAMPLES.md** (10 minutes) — Understand bot behavior
4. **Share with team** — Point to Reviewer A's/Reviewer B's review standards
5. **Customize** (optional) — Edit prompts to match your preferences

## Support

- **Setup issues?** → See SETUP.md troubleshooting
- **Want examples?** → See EXAMPLES.md (8 real reviews)
- **Need full guide?** → See README.md
- **Installation problems?** → See VERIFICATION_CHECKLIST.md
- **Technical details?** → See IMPLEMENTATION_SUMMARY.md
- **File explanations?** → See FILE_MANIFEST.md

## Document Map

| Document | Purpose | Length | Audience |
|----------|---------|--------|----------|
| **START_HERE.md** | This file — orientation | 2 min | Everyone |
| **SETUP.md** | Quick 5-minute setup | 5 min | First-time users |
| **EXAMPLES.md** | Real review examples | 15 min | Developers |
| **README.md** | Full documentation | 20 min | Maintainers |
| **VERIFICATION_CHECKLIST.md** | Verify setup works | 20 min | DevOps/installers |
| **IMPLEMENTATION_SUMMARY.md** | Technical deep dive | 15 min | Architects |
| **FILE_MANIFEST.md** | All files explained | 10 min | Anyone curious |

## Architecture at a Glance

```
PR pushed
   ↓
Workflow triggered (.github/workflows/claude-review.yml)
   ↓
Extract diff
   ↓
Detect platform (Swift → iOS, Kotlin → Android)
   ↓
Load standards (ios-review-prompt.md or android-review-prompt.md)
   ↓
Call Claude Sonnet 4 API
   ↓
Parse verdict (APPROVE or CHANGES_REQUESTED)
   ↓
Post inline comments on problematic lines
   ↓
Submit PR review with verdict
   ↓
Developer sees feedback, fixes issues, pushes update
```

## Key Features

- **Automatic Detection**: Figures out iOS vs Android from file extensions
- **Inline Comments**: Posts feedback directly on the code lines that need fixing
- **Two Verdicts**: Approves good code, requests changes for issues
- **Large Diff Handling**: Gracefully handles diffs up to 100KB
- **Cost Effective**: ~$0.02 per review
- **No Secrets Exposed**: API key in GitHub Secrets, never logged
- **Easy Customization**: Edit prompt files to change review standards

## Production Ready

This bot is:
- Fully tested in the Aspora environment
- Based on real review patterns from Reviewer A and Reviewer B
- Documented with 7 support documents
- Ready to deploy to both app-ios and app-android
- Customizable to your specific needs

## Get Started Now

```bash
# Step 1: Add ANTHROPIC_API_KEY to GitHub Secrets

# Step 2: Copy files to your repo
cp -r .github/workflows/claude-review.yml your-repo/.github/workflows/
cp -r .github/actions/claude-review/ your-repo/.github/actions/

# Step 3: Create test PR with bug
# (force unwrap for iOS, Double for money for Android)

# Step 4: Watch bot review within 2 minutes

# Step 5: Fix issues and push update

# Step 6: Bot approves when standards met
```

See `SETUP.md` for detailed step-by-step instructions.

---

**Created**: March 10, 2026
**Version**: 1.0
**Status**: Production Ready
**Model**: Claude Sonnet 4 (claude-sonnet-4-20250514)

**Read SETUP.md next →**
