# Goldy

**Your AI Hand in Product Development — One brain. Two codebases. Zero wasted tokens.**

Goldy maintains a shared knowledge base across iOS and Android development. Every decision made on one platform is automatically available to the other. Every commit is tracked. Every review pattern is learned.

---

## Installation

```bash
# 1. Clone Goldy as your workspace root
git clone https://github.com/tirupatibalan-aspora/goldy.git my-workspace
cd my-workspace

# 2. Clone your repos inside
git clone https://github.com/your-org/app-ios.git
git clone https://github.com/your-org/app-android.git

# 3. One-command setup (installs hooks + backfills history + generates TRUTH.md)
./scripts/setup-memory-system.sh --backfill 30
```

That's it. Every commit in your repos now auto-generates changelogs, summaries, and a unified `TRUTH.md`.

---

## Two Layers

Goldy has two layers that work together:

```
┌─────────────────────────────────────────────────────┐
│                 INTELLIGENCE LAYER                    │
│                                                       │
│  Architecture decisions, review patterns,             │
│  feature plans, Figma specs, QA status,               │
│  cross-platform decision sync, stakeholder reports    │
│                                                       │
│  Powered by: Claude Code sessions + shared memory     │
├───────────────────────────────────────────────────────┤
│                INFRASTRUCTURE LAYER                    │
│                                                       │
│  Auto-changelogs on every commit, per-project         │
│  summaries, TRUTH.md, cross-platform alerts,          │
│  frequently modified files, history backfill          │
│                                                       │
│  Powered by: git hooks + bash scripts (zero deps)     │
└───────────────────────────────────────────────────────┘
```

### Infrastructure Layer (always running, automatic)

Tracks every commit across all repos. No manual effort.

- **Post-commit hooks** → auto-create structured changelogs in `memory/changelogs/`
- **TRUTH.md** → auto-generated master state (branches, last commits, cross-platform alerts)
- **Project summaries** → rolling 14-day activity, feature areas, hot files
- **Cross-platform alerts** → detects commits touching shared contracts (API, schema, migration)
- **History backfill** → bootstrap from existing git history for instant onboarding

### Intelligence Layer (session-based, AI-powered)

Makes decisions and learns from humans. Persists across Claude Code sessions.

- **Review Bot** → learns from real PR reviewer feedback (Paul: 12 patterns, Sergei: 25 patterns)
- **Feature plans** → STRICT: plan before code, both platforms implement same spec
- **Architecture decisions** → made once, applied to both platforms (e.g., cart lifecycle, navigation)
- **Figma integration** → design specs, node IDs, exact values in shared memory
- **QA tracking** → master checklist, cross-platform status
- **Slack reports** → `/postreport` sends structured update to team channel
- **Token savings** → ~32% fewer tokens by sharing context across platforms

---

## How It Works

```
Developer commits in app-ios/
    │
    ▼ (post-commit hook — automatic)
Changelog created: memory/changelogs/vance-ios/2026-04-09_abc1234.md
TRUTH.md refreshed (background, non-blocking)
    │
    ▼ (Claude Code session)
Claude reads TRUTH.md + memory/ → full cross-project context
Makes architecture decisions → saves to shared memory
    │
    ▼ (developer switches to app-android)
Claude reads SAME memory → applies same decisions
No re-interpretation. No divergence. No wasted tokens.
    │
    ▼ (PR review)
Review Bot audits against reviewer patterns (min 8/10 score)
Reviewer feedback → extracted into learnings JSON → bot gets smarter
    │
    ▼ (status report)
/postreport → reads memory + git logs → posts to Slack
```

---

## Directory Structure

```
goldy/                                  (workspace root — this repo)
├── README.md                           # You are here
├── CLAUDE.md                           # Hot cache — loaded every AI session
├── TRUTH.md                            # Auto-generated cross-project state
│
├── scripts/                            # Infrastructure layer
│   ├── setup-memory-system.sh          # One-command setup
│   ├── log-commit.sh                   # Post-commit → structured changelog
│   ├── summarize.sh                    # Generate per-project summaries
│   ├── generate-truth.sh               # Generate TRUTH.md
│   ├── install-hooks.sh                # Install/reinstall git hooks
│   └── backfill.sh                     # Bootstrap from git history
│
├── memory/                             # Shared knowledge base
│   ├── changelogs/                     # Auto-generated (infrastructure layer)
│   │   ├── vance-ios/                  # Per-commit markdown files
│   │   └── vance-android/
│   ├── summaries/                      # Auto-generated project summaries
│   │   ├── vance-ios.md
│   │   └── vance-android.md
│   ├── projects/                       # Shared project state (intelligence)
│   │   └── gold-module.md              # Cross-platform Gold module status
│   ├── people/                         # Team members
│   ├── glossary.md                     # Terms dictionary
│   └── plan_*.md                       # Feature plans
│
├── claude-review-bot/                  # Review Bot (intelligence layer)
│   ├── scripts/
│   │   ├── goldy-sync.js              # Sync learnings → memory
│   │   ├── harvest-pr-comments.js     # Extract reviewer patterns
│   │   └── harvest-existing-prs.sh
│   └── .github/actions/claude-review/
│       └── learnings/
│           ├── ios-paul.json           # 12 patterns from Paul
│           └── android-sergei.json     # 25 patterns from Sergei
│
├── common_assets/                      # Shared Lottie, PNGs (both platforms)
│
├── vance-ios/                          # iOS repo (separate git repo)
│   ├── CLAUDE.md
│   └── GOLD_MODULE_HANDBOOK.md
│
└── vance-android/                      # Android repo (separate git repo)
    ├── CLAUDE.md
    └── GOLD_MODULE_HANDBOOK.md
```

---

## Scripts Reference

| Script | What It Does | When It Runs |
|--------|-------------|--------------|
| `setup-memory-system.sh` | Creates dirs, installs hooks, backfills, generates TRUTH.md | Once (setup) |
| `log-commit.sh` | Creates structured changelog from a single commit | Every commit (auto) |
| `summarize.sh` | Generates per-project summary (14-day window, feature areas, hot files) | Every commit (auto) |
| `generate-truth.sh` | Generates TRUTH.md (platform status, cross-platform alerts, activity) | Every commit (auto) |
| `install-hooks.sh` | Installs post-commit hooks in all sub-repos | On setup or after fresh clone |
| `backfill.sh` | Bootstraps changelogs from existing git history | On setup or onboarding |

### Manual Commands

```bash
# Backfill last 50 commits from a specific repo
./scripts/backfill.sh vance-ios 50

# Regenerate all summaries
./scripts/summarize.sh

# Regenerate TRUTH.md
./scripts/generate-truth.sh

# Reinstall hooks (e.g., after fresh clone)
./scripts/install-hooks.sh

# Full setup with backfill
./scripts/setup-memory-system.sh --backfill 30
```

### Review Bot Scripts

```bash
# Sync commit learnings into memory + CLAUDE.md
node claude-review-bot/scripts/goldy-sync.js --full-sync

# Extract reviewer patterns from a merged PR
node claude-review-bot/scripts/harvest-pr-comments.js --pr 1548 --repo vance-android

# Bulk harvest from multiple PRs
bash claude-review-bot/scripts/harvest-existing-prs.sh
```

---

## Adding a New Repo

```bash
# 1. Clone the repo inside the workspace
git clone https://github.com/your-org/app-web.git

# 2. Create changelog directory
mkdir -p memory/changelogs/app-web

# 3. Add "app-web" to PROJECTS array in: summarize.sh, generate-truth.sh, install-hooks.sh

# 4. Install hooks + backfill
./scripts/install-hooks.sh
./scripts/backfill.sh app-web 30
./scripts/summarize.sh && ./scripts/generate-truth.sh
```

## Adding a New Reviewer

```bash
# Create learnings JSON (use existing files as schema reference)
claude-review-bot/.github/actions/claude-review/learnings/{platform}-{reviewer}.json

# Add reviewer row to CLAUDE.md "Current reviewers" table
# Bot will auto-enforce on all future PRs
```

---

## Three-Level Context Strategy

| Level | File | Loaded | Purpose |
|-------|------|--------|---------|
| 1. Hot cache | `CLAUDE.md` | Every session (auto) | Team, stack, branches, preferences |
| 2. Master state | `TRUTH.md` | Every session (auto) | Cross-project branches, alerts, activity |
| 3. Deep memory | `memory/*.md` | On-demand | Architecture decisions, plans, QA, patterns |

Claude Code reads Level 1 + 2 automatically. Level 3 is pulled when deeper context is needed.

---

## Current Status (2026-04-09)

| | iOS | Android |
|---|---|---|
| **M1 (Landing)** | Merged | Merged |
| **M2 (Buy/Sell)** | PR #1520 (Paul reviewing) | PR #1548 Merged |
| **QA Fixes** | On branch | PR #1637 |
| **Tests** | 226 | 101+ |
| **Bot Score** | 9/10 | 10/10 |
| **Handbook** | Pending | [GOLD_MODULE_HANDBOOK.md](https://github.com/Vance-Club/vance-android/blob/feature/wealth-module-gold-qa-fixes/GOLD_MODULE_HANDBOOK.md) |

---

## Links

| Resource | URL |
|----------|-----|
| Live Dashboard | https://tirupatibalan-aspora.github.io/goldy/ |
| Architecture Doc | [GOLD_MODULE_ARCHITECTURE.md](GOLD_MODULE_ARCHITECTURE.md) |
| Android Handbook | [GOLD_MODULE_HANDBOOK.md](https://github.com/Vance-Club/vance-android/blob/feature/wealth-module-gold-qa-fixes/GOLD_MODULE_HANDBOOK.md) |
| iOS PR #1520 | https://github.com/Vance-Club/vance-ios/pull/1520 |
| Android PR #1637 | https://github.com/Vance-Club/vance-android/pull/1637 |

---

*Imagined by [Tirupati Balan](https://github.com/tirupatibalan-aspora) · Built with [Claude Code](https://claude.com/claude-code)*
