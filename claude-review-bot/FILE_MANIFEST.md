# File Manifest — Complete File Listing

Complete listing of all files in the Claude Code Review Bot with descriptions.

## Directory Structure

```
claude-review-bot/
├── .github/
│   ├── workflows/
│   │   └── claude-review.yml                    [Workflow trigger & orchestration]
│   └── actions/
│       └── claude-review/
│           ├── action.yml                       [Action metadata & inputs]
│           ├── index.js                         [Main review engine]
│           ├── package.json                     [Node dependencies]
│           └── prompts/
│               ├── ios-review-prompt.md         [Reviewer A's iOS standards]
│               └── android-review-prompt.md     [Reviewer B's Android standards]
├── .gitignore                                   [Git ignore rules]
├── README.md                                    [Main documentation]
├── SETUP.md                                     [Quick start guide]
├── EXAMPLES.md                                  [Real review examples]
├── IMPLEMENTATION_SUMMARY.md                    [What was built]
├── VERIFICATION_CHECKLIST.md                    [Installation verification]
└── FILE_MANIFEST.md                            [This file]
```

## File Details

### Workflow Files

#### `.github/workflows/claude-review.yml` (41 lines)
**Purpose**: Main GitHub Actions workflow that triggers on PR events

**Key Features**:
- Triggers on PR open/update/ready_for_review
- Extracts PR diff via git
- Skips reviews for diffs >100KB
- Calls custom Claude Review action
- Auto-detects platform (ios/android)

**Inputs**:
- `anthropic_api_key`: Anthropic API secret
- `github_token`: GitHub token for PR operations
- `platform`: Target platform (auto-detected if not specified)
- `pr_number`: PR number (optional)

### Action Files

#### `.github/actions/claude-review/action.yml` (18 lines)
**Purpose**: GitHub Action metadata and input definitions

**Defines**:
- Action name and description
- Input parameters (3 required, 1 optional)
- Runtime: Node 20
- Main entry point: index.js

#### `.github/actions/claude-review/index.js` (301 lines)
**Purpose**: Core review engine—orchestrates the review process

**Key Functions**:
- `main()` — Entry point, orchestrates workflow
- `detectPlatform()` — Detects iOS (.swift) vs Android (.kt)
- `loadPrompt()` — Loads platform-specific review standards
- `reviewWithClaude()` — Calls Claude Sonnet 4 API
- `parseVerdict()` — Extracts APPROVE/CHANGES_REQUESTED verdict
- `extractComments()` — Parses file/line feedback from review
- `postReviewComments()` — Posts inline comments on PR
- `submitReview()` — Submits overall PR review verdict

**Dependencies**:
- @actions/core — GitHub Actions toolkit
- @actions/github — GitHub API client
- @anthropic-ai/sdk — Claude API client
- fs, path — Node.js built-ins

#### `.github/actions/claude-review/package.json` (25 lines)
**Purpose**: Node.js dependencies for the action

**Dependencies**:
- @actions/core@^1.10.1 — GitHub Actions toolkit
- @actions/github@^6.0.0 — GitHub API operations
- @anthropic-ai/sdk@^0.24.3 — Claude API integration

**Node Version**: >=18.0.0

### Prompt Files

#### `.github/actions/claude-review/prompts/ios-review-prompt.md` (124 lines)
**Purpose**: Reviewer A's iOS code review standards system prompt

**Sections**:
1. Critical Blockers (5) — Force unwraps, race conditions, side effects, patterns, naming
2. Major Issues (6) — Optionality, model conversion, task cancellation, caching, formatting, architecture
3. Minor Issues (3) — Strings, theme tokens, enums
4. Approval Checklist (16 items)
5. Response Format (VERDICT, SUMMARY, ISSUES, POSITIVES, NEXT_STEPS)

**Standards Enforced**:
- Zero force unwraps
- Proper task cancellation with checks
- CacheableService pattern
- Actor repositories
- @MainActor ViewModels
- Network+ file naming
- Formatters in Core/Utils/
- Localization
- Type safety

#### `.github/actions/claude-review/prompts/android-review-prompt.md` (144 lines)
**Purpose**: Reviewer B's Android code review standards system prompt

**Sections**:
1. Critical Blockers (6) — BigDecimal requirement, missing tests, exhaustive when, business logic in UI, wrong patterns, hard-coded design
2. Major Issues (7) — BigDecimal formatting, type safety, MVI, Compose patterns, DI, lifecycle, test quality
3. Minor Issues (4) — Imports, whitespace, naming, mocking
4. Approval Checklist (19 items)
5. Response Format (same as iOS)
6. Market-Specific Considerations (UAE vs UK)

**Standards Enforced**:
- BigDecimal for all money
- MVI pattern (State/Event/Command)
- 25+ feature tests, 8+ validator tests
- Sealed interfaces (exhaustive when)
- Theme tokens (no hard-coded colors/fonts)
- AppScreen wrapper
- Dagger Hilt DI
- Tests organized by region

### Documentation Files

#### `README.md` (326 lines)
**Purpose**: Comprehensive documentation and user guide

**Sections**:
1. Overview — What it does
2. Features — Key capabilities
3. Setup Instructions — 4-step deployment
4. How It Works — Workflow, verdict format, customization
5. Integration Examples — iOS/Android examples
6. Customization — Edit prompts, change model, adjust limits
7. Architecture — File structure, key functions
8. Troubleshooting — Common issues and fixes
9. Cost Estimation — Monthly costs
10. Security — Key handling, permissions
11. Known Limitations — Size, complexity, latency
12. Future Improvements — Planned enhancements

**Audience**: Developers, DevOps, maintainers

#### `SETUP.md` (101 lines)
**Purpose**: Quick 5-minute setup guide

**Sections**:
1. Prerequisites — What you need
2. Step 1: Add API Key — GitHub Secrets setup
3. Step 2: Copy Files — File copying instructions
4. Step 3: Test — Quick verification
5. Step 4: Make Required (Optional) — Branch protection
6. Step 5: Customize (Optional) — Edit standards
7. Verification Checklist — What to check
8. Troubleshooting — Common issues

**Audience**: First-time users, quick-start seekers

#### `EXAMPLES.md` (527 lines)
**Purpose**: Real-world review examples showing bot behavior

**Examples Included**:
1. iOS Force Unwrap — Blocked
2. Android Missing Tests — Blocked
3. iOS Task Cancellation — Changes Requested
4. Android Design Tokens — Changes Requested
5. Android Exhaustive When — Blocked
6. iOS Caching — Changes Requested
7. iOS Approved PR — Approved
8. Android Approved PR — Approved

**Each Example Shows**:
- Bad/good code snippet
- Bot review response
- Expected feedback
- How to fix

**Audience**: Developers learning review patterns, understanding bot behavior

#### `IMPLEMENTATION_SUMMARY.md` (372 lines)
**Purpose**: Technical summary of what was built

**Sections**:
1. Overview — High-level summary
2. What Was Built — Components created
3. File Structure — Directory layout
4. How to Use — For maintainers, developers, DevOps
5. Key Features — Platform detection, error handling, etc.
6. Customization — Options for changing behavior
7. Integration Strategy — 4-phase rollout plan
8. Metrics to Track — Success measurements
9. Known Limitations — What it can't do
10. Future Improvements — Roadmap
11. Support & Troubleshooting — Getting help
12. Success Criteria — When it's working

**Audience**: Technical leads, architects, DevOps

#### `VERIFICATION_CHECKLIST.md` (281 lines)
**Purpose**: Step-by-step verification after deployment

**Sections**:
1. Pre-Deployment Checklist — Before you start
2. File Structure Verification — Verify all files exist
3. GitHub Secrets Configuration — API key setup
4. Test PR Deployment — Create test PR with intentional bugs
5. Workflow Status Check — Verify bot reviews
6. API Cost Verification — Check Anthropic console
7. Documentation Verification — Docs are in place
8. Team Onboarding — Notify team
9. Optional: Configure as Required Check — Make it blocking
10. Performance Monitoring — Track metrics
11. Sign-Off — Verification complete
12. Common Questions — FAQ

**Audience**: Deployment engineers, verification teams

#### `FILE_MANIFEST.md` (This file)
**Purpose**: Complete listing of all files with descriptions

**Sections**:
1. Directory Structure — File tree
2. File Details — Each file with purpose and contents
3. Total Statistics — Line counts, file sizes

**Audience**: Anyone wanting to understand project structure

#### `.gitignore` (13 lines)
**Purpose**: Ignore files from Git tracking

**Ignored Items**:
- node_modules/ — npm packages
- .env/.env.local — Environment files
- *.log — Log files
- .DS_Store — macOS files
- dist/, build/ — Build artifacts
- pr_diff.txt — Generated diff file
- coverage/ — Test coverage reports

## File Statistics

| Category | Count | Lines |
|----------|-------|-------|
| Workflow files | 1 | 41 |
| Action files | 3 | 344 |
| Prompt files | 2 | 268 |
| Documentation | 7 | 1,907 |
| **Total** | **13** | **2,560** |

## Key Statistics

- **Total Files**: 13
- **Total Lines**: ~2,560
- **Core Logic**: 301 lines (index.js)
- **Documentation**: ~1,900 lines (75% of total)
- **Review Standards**: 268 lines of prompts

## Dependencies

**Runtime**:
- Node.js >= 18.0.0

**NPM Packages**:
- @actions/core@^1.10.1
- @actions/github@^6.0.0
- @anthropic-ai/sdk@^0.24.3

**External Services**:
- Anthropic API (Claude Sonnet 4)
- GitHub API

## Usage Flow

```
1. PR created/updated
   ↓
2. Workflow triggers (claude-review.yml)
   ↓
3. Extracts diff (git diff)
   ↓
4. Calls action (claude-review/index.js)
   ↓
5. Detects platform (Swift/Kotlin)
   ↓
6. Loads prompt (ios/android-review-prompt.md)
   ↓
7. Calls Claude API
   ↓
8. Parses verdict
   ↓
9. Posts comments
   ↓
10. Submits review
    ↓
11. PR shows review status
```

## Important Files to Customize

1. **iOS Standards**: `.github/actions/claude-review/prompts/ios-review-prompt.md`
   - Edit to change Reviewer A's enforcement rules
   - Add/remove criteria as needed

2. **Android Standards**: `.github/actions/claude-review/prompts/android-review-prompt.md`
   - Edit to change Reviewer B's enforcement rules
   - Add market-specific rules here

3. **Workflow**: `.github/workflows/claude-review.yml`
   - Edit to change trigger events
   - Adjust diff size limit
   - Change platform detection logic

4. **Main Logic**: `.github/actions/claude-review/index.js`
   - Change Claude model (line ~110)
   - Modify comment posting logic
   - Adjust verdict parsing

## Deployment Checklist

- [ ] All files copied to repository
- [ ] Anthropic API key added as GitHub secret
- [ ] Workflow file in `.github/workflows/`
- [ ] Action directory in `.github/actions/claude-review/`
- [ ] All prompt files present
- [ ] package.json has correct dependencies
- [ ] README.md readable in repo
- [ ] Test PR created and reviewed successfully

## Support Resources

- **README.md** — Full documentation
- **SETUP.md** — Quick start
- **EXAMPLES.md** — Review examples
- **VERIFICATION_CHECKLIST.md** — Deployment verification
- **IMPLEMENTATION_SUMMARY.md** — Technical details

---

**Last Updated**: March 10, 2026
**Version**: 1.0
**Status**: Production Ready
