<p align="center">
  <img src="docs/assets/goldy-banner.svg" alt="Goldy" width="100%">
</p>

<h1 align="center">Goldy</h1>
<h3 align="center">AI Project Manager for Solo Developers</h3>

<p align="center">
  <strong>Track the speed of your vibe. Ship with confidence.</strong>
</p>

<p align="center">
  <a href="#what-is-goldy">What is Goldy</a> · <a href="#how-it-works">How It Works</a> · <a href="#live-dashboard">Live Dashboard</a> · <a href="#setup">Setup</a>
</p>

---

## What is Goldy?

Goldy is an AI-powered project manager built for **solo developers** and **small teams** who ship cross-platform apps but still need to give clear, professional status updates to their company.

You code. Goldy watches. Every day at 9 AM, your team gets a beautiful status report — pulled live from your GitHub commits, Figma designs, and Slack conversations. No standups. No Jira tickets. No context switching.

**The problem Goldy solves:**

You're a solo dev (or a tiny team) building iOS + Android simultaneously. Your manager asks "where are we on the Gold module?" Instead of stopping your flow to write a status update, Goldy already posted one this morning — with progress bars, risk callouts, and AI-generated sprint recommendations.

## How It Works

Goldy connects to your existing tools and synthesizes everything into one daily briefing:

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  GitHub   │     │  Figma   │     │  Slack   │
│  Commits  │     │  Designs │     │  Threads │
└─────┬─────┘     └─────┬────┘     └─────┬────┘
      │                 │                 │
      └────────┬────────┘────────┬────────┘
               │                 │
         ┌─────▼─────────────────▼─────┐
         │          Goldy AI           │
         │   Analyze · Plan · Report   │
         └─────────────┬───────────────┘
                       │
         ┌─────────────▼───────────────┐
         │     Daily Status Report     │
         │  HTML Dashboard + Slack     │
         └─────────────────────────────┘
```

### What Goldy Reads

| Source | What Goldy Extracts |
|--------|-------------------|
| **GitHub** | Commit history, branch activity, file counts, test counts, days since last push, PR status |
| **Figma** | Design specs, open questions, asset requirements, pixel-match targets |
| **Slack** | Product answers, team decisions, blockers, open threads |
| **Memory** | Project context, architecture decisions, team preferences, glossary |

### What Goldy Produces

| Output | Description |
|--------|-------------|
| **Visual Dashboard** | Dark-themed HTML report with progress bars, feature matrix, risk cards, timeline — hosted on GitHub Pages |
| **Slack Post** | Daily message to your status channel with the dashboard link |
| **AI Sprint Plan** | Day-by-day parallelization strategy based on remaining time to deadline |
| **Quick Wins** | 4 specific actionable items for the next 48 hours |
| **Risk Watch** | High/medium/low risk callouts with mitigation suggestions |
| **Goldy's Take** | Personalized message addressing you by name with honest assessment |

## Live Dashboard

Goldy generates a visual dashboard every day, hosted on GitHub Pages:

**[View Live Dashboard →](https://tirupatibalan-aspora.github.io/goldy/)**

The dashboard includes:

- **Navbar** — Live connection status to GitHub, Figma, Slack
- **Deadline Countdown** — Days remaining with target date
- **Goldy's Insight** — AI-generated personalized briefing
- **Key Metrics** — Commit gap, test counts, coverage, open questions
- **Platform Cards** — Side-by-side iOS vs Android with progress bars, file stats, task lists
- **Feature Matrix** — Cross-platform completion status (Done / WIP / Not Started / Blocked)
- **Open Questions** — Tracked by owner (Product / Engineering / Legal)
- **Sprint Plan** — Visual timeline with phased recommendations
- **Quick Wins** — Highest-impact low-effort tasks
- **Risk Watch** — Color-coded risk cards
- **Waiting On** — External dependency tracker

## Who is Goldy For?

Goldy is purpose-built for:

- **Solo developers** shipping to multiple platforms who need to report status to stakeholders
- **Small startup teams** (2-5 people) without a dedicated PM
- **Vibe coders** who want AI handling the boring parts of project management
- **Remote teams** where async status updates replace standups
- **Freelancers** who need to keep clients informed without writing reports

## The Goldy Philosophy

```
Less process. More shipping.
Less meetings. More building.
Less "where are we?" More "here's where we are."
```

Goldy believes:

1. **Status updates should be automatic** — not something you stop coding to write
2. **AI should read your code** — not ask you what you did
3. **Reports should be beautiful** — because stakeholders deserve clarity
4. **One solo dev with AI = a team** — Goldy is the PM you never hired
5. **Intelligence over process** — no tickets, no story points, no ceremonies

## Setup

### Prerequisites

- GitHub repository with your code
- Slack workspace with a status channel
- Figma file with your designs (optional)
- Claude Desktop with Cowork mode (for scheduled reports)

### Quick Start

1. **Clone this repo**
   ```bash
   git clone https://github.com/tirupatibalan-aspora/goldy.git
   ```

2. **Enable GitHub Pages**
   - Go to repo Settings → Pages
   - Source: Deploy from a branch
   - Branch: `main` → `/docs`
   - Save

3. **Your dashboard is live at:**
   ```
   https://tirupatibalan-aspora.github.io/goldy/
   ```

4. **Set up the scheduled task** in Claude Desktop / Cowork:
   - Goldy runs daily at 9 AM
   - Analyzes your Git repos
   - Generates the HTML dashboard
   - Posts the link to your Slack channel

### Project Structure

```
goldy/
├── README.md              # You are here
├── docs/
│   └── index.html         # Goldy dashboard (GitHub Pages)
└── memory/                # Goldy's brain
    ├── glossary.md        # Team terminology decoder
    ├── projects/
    │   ├── gold-module.md # Feature status + decisions
    │   ├── vance-ios.md   # iOS deep context
    │   └── vance-android.md # Android deep context
    └── context/
        └── company.md     # Company tools + integrations
```

### How the Memory System Works

Goldy uses a two-tier memory system to stay context-aware across sessions:

**Tier 1 — Hot Cache (`CLAUDE.md`)**
~80 lines of essential context loaded every session. Contains: who you are, your team, active projects, tech stack, current branches, and preferences.

**Tier 2 — Deep Memory (`memory/`)**
Full knowledge base loaded on-demand. Architecture details, decided answers, test gap analysis, company integrations. Only pulled when needed to save tokens.

This means Goldy remembers your project across sessions — your architecture decisions, your team's preferences, your product answers, your open questions — without burning tokens re-reading everything.

## Currently Tracking

Goldy is currently the AI Project Manager for the **Gold/Wealth Module** at **Vance (Aspora)** — a cross-border money transfer fintech app shipping on iOS and Android simultaneously.

| | iOS | Android |
|---|---|---|
| Language | Swift 6 | Kotlin |
| UI | SwiftUI | Jetpack Compose + XML |
| Architecture | Clean Arch + MVVM | Clean Arch + MVVM (MVI for Gold) |
| DI | Factory (@Injected) | Dagger Hilt |
| Testing | Swift Testing | JUnit + MockK + Turbine |

## Roadmap

- [x] Daily HTML dashboard generation
- [x] Slack integration (post + thread)
- [x] GitHub commit analysis
- [x] Figma design question tracking
- [x] AI sprint recommendations
- [x] Memory system (two-tier)
- [x] Scheduled daily reports (9 AM)
- [ ] GitHub Pages auto-deploy on report generation
- [ ] PR review status tracking
- [ ] Test coverage trend charts
- [ ] Burndown visualization
- [ ] Multi-project support
- [ ] Team velocity tracking
- [ ] Jira / Linear integration
- [ ] Auto-generated release notes

---

<p align="center">
  <strong>Goldy</strong> — AI Project Manager<br>
  <em>Track the speed of your vibe.</em><br><br>
  Built by <a href="https://github.com/tirupatibalan-aspora">Tirupati Balan</a> at <a href="https://aspora.com">Aspora</a>
</p>
