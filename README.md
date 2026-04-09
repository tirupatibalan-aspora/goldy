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

| Script | What |
|--------|------|
| `setup-memory-system.sh` | One-command setup (auto-detects repos) |
| `test-goldy.sh` | Verify everything works (36 checks) |
| `log-commit.sh` | Auto-changelog per commit |
| `summarize.sh` | Per-project summaries |
| `generate-truth.sh` | TRUTH.md (master state) |
| `install-hooks.sh` | Install git hooks |
| `backfill.sh` | Bootstrap from git history |

## Add a New Repo

```bash
# Just clone inside the workspace and re-run setup
git clone https://github.com/your-org/app-web.git
./scripts/setup-memory-system.sh --backfill 30
```

Goldy auto-detects it. No config files to edit.

## Add a New Reviewer

```bash
# Create learnings JSON (see existing files for schema)
claude-review-bot/.github/actions/claude-review/learnings/{platform}-{name}.json
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

*Imagined by [Tirupati Balan](https://github.com/tirupatibalan-aspora) · Built with [Claude Code](https://claude.com/claude-code)*
