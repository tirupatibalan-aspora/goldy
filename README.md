# Goldy

**Cross-project memory for Claude Code. One brain. Multiple codebases. Zero wasted tokens.**

Goldy gives Claude Code persistent memory that survives across sessions and spans multiple repos. It syncs cross-platform development — changelogs, reviewer pattern enforcement (review bot), status reports, and health checks — across iOS, Android, or any repos. Clone it, drop your repos inside, run one command — done.

---

## Install

```bash
# 1. Clone Goldy
git clone https://github.com/tirupatibalan-aspora/goldy.git my-workspace
cd my-workspace

# 2. Run the setup wizard — it asks for your name, repos, and does the rest
./setup.sh
```

The wizard will:
1. Ask your name, email, and GitHub username (auto-detects from `gh` CLI if installed)
2. Ask for repo URLs to clone (paste one per line)
3. Clone repos, install git hooks, backfill changelogs
4. Generate TRUTH.md and summaries
5. Verify everything works

**For non-interactive / CI setup:**
```bash
# Manual alternative — clone repos yourself, then run:
git clone https://github.com/your-org/app-ios.git
./scripts/setup-memory-system.sh --backfill 30
./scripts/test-goldy.sh
```

Reports, PRs, commits, and changelogs are automatically filtered to your work.

---

## How It Works

```
You commit code
    |
    v (automatic — git hooks)
Changelog created + TRUTH.md refreshed
    |
    v (Claude Code session)
Claude reads TRUTH.md + memory/ = full context
    |
    v (before push)
Review Bot audit (min 8/10) -> local tests -> push
    |
    v (PR review)
Bot learns from reviewer feedback -> gets smarter
```

## Two Layers

| Layer | What | Powered By |
|-------|------|------------|
| **Infrastructure** | Auto-changelogs, TRUTH.md, summaries, cross-platform alerts, backfill | Git hooks + bash (zero deps) |
| **Intelligence** | Architecture decisions, review bot, feature plans, Figma specs, QA tracking | Claude Code + shared memory |

Infrastructure runs automatically on every commit. Intelligence persists across Claude Code sessions.

---

## Push Philosophy

**Every push follows this order — no exceptions:**

1. **Code** — write your changes
2. **Review Bot audit** — Claude audits diff against reviewer patterns (min 8/10 score)
3. **Run tests locally** — platform-specific test suite
4. **Push** — CI is for verification, not discovery

This is enforced in CLAUDE.md. The Review Bot learns from real reviewer feedback, so it catches issues before humans have to.

---

## Scripts

### Automated (you never run these — they just work)

| Script | Trigger | What |
|--------|---------|------|
| `log-commit.sh` | Every commit (git hook) | Creates structured changelog in `memory/changelogs/` |
| `summarize.sh` | Every commit (git hook) | Refreshes per-project summary (14-day window, hot files) |
| `generate-truth.sh` | Every commit (git hook) | Refreshes TRUTH.md (branches, alerts, activity) |
| `goldy-check.sh` | Every Claude Code session | Auto-detects new repos, installs hooks, backfills changelogs, refreshes stale TRUTH.md |
| `install-hooks.sh` | On setup + auto via `goldy-check` | Installs post-commit hooks in all detected repos |
| `backfill.sh` | On setup + auto via `goldy-check` | Bootstraps changelogs from existing git history |

### Manual (run when you need them)

| Script | What |
|--------|------|
| `setup-memory-system.sh` | One-command first-time setup |
| `test-goldy.sh` | Verify everything works (47 checks across both layers) |
| `generate-report.sh` | Status report from git + memory |
| `postreport.sh` | Post report to Slack (or terminal) |
| `add-reviewer.sh` | Onboard a new reviewer in one command |

## Status Reports

In any Claude Code session inside your Goldy workspace, just say:

```
"generate goldy report"
"give me a weekly goldy report"
"what happened this week"
"goldy status for last 3 days"
```

Claude knows about Goldy (via CLAUDE.md) — any natural phrasing works.

**Or run directly:**

```bash
./scripts/generate-report.sh                          # Your commits (last 24h) → terminal
./scripts/generate-report.sh --all                    # All team commits (unfiltered)
./scripts/generate-report.sh --hours 168              # Your last 7 days (weekly)
./scripts/generate-report.sh --hours 72 --output markdown  # Your last 3 days → saved to memory/reports/
./scripts/postreport.sh --channel C0XXXXX             # Post to Slack (needs SLACK_BOT_TOKEN)
```

**User-aware by default:**
Reports auto-detect your GitHub identity (via `gh api user` + `git config`) and filter to show only *your* commits, PRs, and changelogs. Use `--all` for team-wide view.

User config is cached in `.goldy-user.conf` (auto-generated on first run, editable).

**What's in a report:**
- Per-repo: your branch, your commits, file change stats
- Your open Gold PRs with review status
- Cross-platform alerts (from TRUTH.md)
- Infrastructure: your changelogs generated
- Review Bot: reviewers + patterns enforced

All auto-generated from git history + Goldy memory. No manual data entry.

---

## Add a New Repo

```bash
# Just clone inside the workspace and re-run setup
git clone https://github.com/your-org/app-web.git
./scripts/setup-memory-system.sh --backfill 30
```

Goldy auto-detects it. No config files to edit.

## Configure Install Links

Edit `.goldy-install.conf` to customize how installation links appear in reports:

```bash
# Android — point to your APK distribution channel
INSTALL_ANDROID_CHANNEL="#android-apk"
INSTALL_ANDROID_BRANCH_KEYWORD="gold"
INSTALL_ANDROID_STEPS="1. Join #android-apk channel..."

# iOS — TestFlight version + instructions
INSTALL_IOS_VERSION="11.0.0"
INSTALL_IOS_STEPS="1. Install TestFlight..."
```

If no config exists, Goldy auto-detects from GitHub artifacts (Android) or shows generic TestFlight (iOS).

## Add a New Reviewer

```bash
# One command — creates JSON, updates CLAUDE.md, ready to go
./scripts/add-reviewer.sh --name john --github john-dev --platform android

# With auto-harvest from existing PRs
./scripts/add-reviewer.sh --name sarah --github sarahk --platform ios --pr 1520 --pr 1600
```

The Review Bot will enforce their patterns on all future PRs.

---

## Context Strategy

| Level | File | When |
|-------|------|------|
| Hot cache | `CLAUDE.md` | Every AI session (auto) |
| Master state | `TRUTH.md` | Every AI session (auto) |
| Deep memory | `memory/*.md` | On-demand |

---

## Live Dashboard (GitHub Pages)

Goldy includes an HTML dashboard at `docs/index.html` — deploy via GitHub Pages for a visual overview.

**What it shows:**
- Platform status (iOS/Android branches, last commits, build health)
- Milestone progress bars (M1, M2, QA)
- Test counts and Review Bot scores per platform
- Cross-platform alerts and recent activity
- Architecture decisions and key links

**Setup:**
1. Go to your Goldy repo → Settings → Pages
2. Source: `Deploy from a branch` → Branch: `main` → Folder: `/docs`
3. Save → dashboard is live at `https://<org>.github.io/goldy/`

> Currently in draft — the dashboard is static HTML. A future `generate-dashboard.sh` will auto-refresh it from TRUTH.md + git data.

**Preview:**
```
┌──────────────────────────────────────────────────────┐
│  GOLDY — Cross-Project Memory            ● Live      │
├──────────┬───────────┬───────────────────────────────┤
│ iOS      │ Android   │  Cross-Platform Alerts        │
│ ━━━━━━━━ │ ━━━━━━━━  │  ⚠ API contract renamed       │
│ 226 tests│ 101+ tests│  ⚠ payment_instrument change  │
│ Bot: 9/10│ Bot: 10/10│                               │
├──────────┴───────────┴───────────────────────────────┤
│  M1 Landing    ████████████████████████████ 100%     │
│  M2 Buy/Sell   █████████████████████░░░░░░  85%     │
│  QA Fixes      ████████████░░░░░░░░░░░░░░░  55%     │
├──────────────────────────────────────────────────────┤
│  Review Bot: 2 reviewers, 37 patterns enforced       │
│  Memory: 12 shared files, 60 changelogs              │
│  Reports: ./scripts/generate-report.sh               │
└──────────────────────────────────────────────────────┘
```

---

*Imagined by [Tirupati Balan](https://github.com/tirupatibalan-aspora) · Built with [Claude Code](https://claude.com/claude-code)*
