# Goldy

**One brain. Multiple codebases. Zero wasted tokens.**

Goldy is your AI-powered workspace that keeps every platform in sync. Clone it, drop your repos inside, run one command — done.

---

## Install

```bash
# 1. Clone Goldy
git clone https://github.com/tirupatibalan-aspora/goldy.git my-workspace
cd my-workspace

# 2. Drop your repos inside (one or many)
git clone https://github.com/your-org/app-android.git
git clone https://github.com/your-org/app-ios.git   # optional

# 3. Setup (auto-detects your repos)
./scripts/setup-memory-system.sh --backfill 30

# 4. Verify everything works
./scripts/test-goldy.sh
```

That's it. Goldy auto-detects every git repo you put inside it.

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
| `test-goldy.sh` | Verify everything works (46 checks across both layers) |
| `generate-report.sh` | Status report from git + memory |
| `postreport.sh` | Post report to Slack (or terminal) |
| `add-reviewer.sh` | Onboard a new reviewer in one command |

## Status Reports

```bash
# Generate report (terminal)
./scripts/generate-report.sh

# Save as markdown
./scripts/generate-report.sh --output markdown

# Post to Slack
export SLACK_BOT_TOKEN="xoxb-your-token"
./scripts/postreport.sh --channel C0XXXXX

# Or use Claude Code's /postreport command
# (uses Slack MCP to post directly)
```

Reports include: per-project commits, cross-platform alerts, infrastructure stats, and review bot status. All auto-generated from git history + Goldy memory.

---

## Add a New Repo

```bash
# Just clone inside the workspace and re-run setup
git clone https://github.com/your-org/app-web.git
./scripts/setup-memory-system.sh --backfill 30
```

Goldy auto-detects it. No config files to edit.

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
│  GOLDY — AI Project Manager              ● Live      │
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
