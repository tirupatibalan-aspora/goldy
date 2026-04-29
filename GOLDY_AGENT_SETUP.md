# Goldy — Cross-Platform AI Agent Setup Guide

> Build your own "Goldy" — an AI-powered project manager that shares knowledge across platforms (iOS, Android, Web, Backend), tracks progress, runs review audits, and posts status reports. Powered by Claude Code's memory system.

## What Goldy Does

1. **Shared knowledge base** — One memory system across iOS + Android (saves ~32% tokens on cross-platform dev)
2. **Feature planning** — Extracts Figma specs, creates implementation plans, tracks gaps
3. **Cross-platform parity** — Ensures iOS and Android implementations match
4. **Review bot integration** — Audits PRs against learned reviewer patterns before submission
5. **Status reports** — Auto-generates team updates from git history + memory
6. **Tribal knowledge** — Captures API quirks, design decisions, reviewer preferences, and edge cases

## Architecture

```
CLAUDE.md (project instructions)
    ↓ loaded every conversation
Memory System (persistent files)
    ├── MEMORY.md (index — max 200 lines)
    ├── user_*.md (who you are)
    ├── feedback_*.md (corrections/preferences)
    ├── project_*.md (ongoing work, milestones)
    ├── reference_*.md (external system pointers)
    └── plan_*.md (feature implementation plans)
    ↓ referenced by
Claude Code (the AI agent)
    ↓ operates on
Multiple Repos (iOS, Android, shared docs)
```

---

## Quick Start

### Step 1: Create the Memory Directory

Claude Code stores memory in `~/.claude/projects/{project-path}/memory/`.

For a multi-repo setup, use a **parent directory** as your project root so one memory system spans all repos:

```
~/Documents/MyProject/          ← Claude Code project root
  ├── my-ios-app/               ← iOS repo
  ├── my-android-app/           ← Android repo
  └── shared-docs/              ← Shared documentation
```

Memory lives at: `~/.claude/projects/-Users-you-Documents-MyProject/memory/`

### Step 2: Create MEMORY.md (Index)

```markdown
# Memory

## Module Progress
- [Module Status](project_module_status.md)
- [Active Branches](project_branches.md)

## People & Preferences
- [User Profile](user_profile.md)
- [Feedback: No Base Modifications](feedback_no_base_modifications.md)

## Architecture
- [API Contracts](project_api_contracts.md)
- [Key Patterns](project_patterns.md)

## References
- [Slack Channel](reference_slack.md)
- [Figma Nodes](figma-nodes.md)
```

**Rules:**
- Max 200 lines (truncated after that)
- Index only — no content, just links + brief descriptions
- Organized by topic, not chronologically

### Step 3: Create CLAUDE.md (Project Instructions)

This is the heart of Goldy. Place it in your project root:

```markdown
# CLAUDE.md

## Me
Your Name, your.email@company.com. Role, teams, responsibilities.

## People
| Who | Role |
|-----|------|
| **Alice** | iOS reviewer |
| **Bob** | Android reviewer |
| **Carol** | Backend engineer |

## Terms
| Term | Meaning |
|------|---------|
| **SDUI** | Server-Driven UI |
| **MVI** | Model-View-Intent |

## Projects
| Name | Status |
|------|--------|
| **Feature X** | Active — 70% complete |

## Active Branches
| Repo | Branch | Purpose |
|------|--------|---------|
| ios | `feature/x` | Feature X |
| android | `feature/x` | Feature X |

## Tech Stack
| | iOS | Android |
|---|-----|---------|
| **Language** | Swift | Kotlin |
| **UI** | SwiftUI | Compose |
| **Architecture** | MVVM | MVI |
| **DI** | Factory | Hilt |
| **Testing** | Swift Testing | JUnit + MockK |

## Preferences
- Act as a Senior Engineer — challenge ideas
- No over-engineering — simplest solution
- Quality > Speed
- Never build iOS project unless asked

## STRICT: Feature Plan Before Implementation
**ALWAYS create a plan file before starting any feature.**
1. Extract specs (Figma, API docs, requirements)
2. Analyze current codebase — what exists, what's missing
3. Create plan file: `memory/plan_{feature}.md`
4. Get user approval before writing code

## STRICT: No Shared File Modifications
**ALWAYS ASK before modifying files outside your module.**
- Navigation, base classes, DI, shared components
- Other teams depend on these

## PR Standards
- No hardcoded values in Views
- All strings localized
- Colors use centralized tokens
- Review bot audit required (min 8/10)
```

### Step 4: Seed Your Memory

Create initial memory files for things Claude can't derive from code:

**`memory/user_profile.md`**
```markdown
---
name: User Profile
description: Developer role, expertise, preferences
type: user
---

Senior iOS/Android developer. Deep SwiftUI expertise, learning Compose.
Prefers concise responses, no trailing summaries.
Works on Feature X module — both platforms simultaneously.
```

**`memory/project_module_status.md`**
```markdown
---
name: Module Status
description: Current state of Feature X across iOS and Android
type: project
---

### iOS
- PR #100 OPEN (reviewer: Alice)
- Buy flow complete, Sell flow in progress
- 150 tests passing

### Android
- PR #200 OPEN (reviewer: Bob)
- Buy flow complete, Sell flow blocked on API
- 93 tests passing

### API
- Cart endpoint returns 500 intermittently
- Backend team (Carol) fixing — ETA April 3
```

**`memory/feedback_no_base_modifications.md`**
```markdown
---
name: No Base File Modifications
description: NEVER modify shared/base files without asking — other teams depend on them
type: feedback
---

Files that require explicit approval before modification:
- Route.kt / Route.swift — navigation
- Base ViewModels, Fragments, Views
- DI modules / Containers
- Shared components, utilities
- Build scripts

Reason: Other teams depend on these. Changes can break their work.
Module should be self-contained during development.
```

### Step 5: Add the Review Bot (Optional)

See [ASPORA_REVIEW_BOT_SETUP.md](./ASPORA_REVIEW_BOT_SETUP.md) for full setup.

Add this to your `CLAUDE.md`:

```markdown
## STRICT: Review Bot Audit Before PR
1. Read `{platform}-{reviewer}.json` from learnings directory
2. Diff branch against base
3. Audit all changed files against all patterns
4. Score out of 10 (Critical: -3, Major: -2, Minor: -0.5)
5. Fix critical/major issues before creating PR
6. Include score in PR description
7. Minimum: 8/10
```

---

## Memory Types & When to Use Them

| Type | What | When to Save | Example |
|------|------|-------------|---------|
| **user** | Developer profile, skills, preferences | Learn about the developer | "Deep Go expertise, new to React" |
| **feedback** | Corrections to Claude's behavior | User says "don't do X" or "always do Y" | "No trailing summaries after edits" |
| **project** | Ongoing work, milestones, blockers | Status changes, deadlines, team decisions | "Merge freeze starts April 5" |
| **reference** | Pointers to external systems | Learn about tools, channels, dashboards | "Bugs tracked in Linear project INGEST" |

**What NOT to save:**
- Code patterns derivable from reading the codebase
- Git history (`git log` is authoritative)
- Fix details (the commit message has context)
- Anything in CLAUDE.md already
- Temporary/ephemeral task details

---

## Cross-Platform Parity Workflow

The key advantage of Goldy is maintaining parity across platforms. Here's the workflow:

```
1. Plan feature in memory/plan_{feature}.md
   ↓
2. Implement on Platform A (e.g., iOS)
   ↓
3. Memory captures patterns, API quirks, edge cases
   ↓
4. Switch to Platform B (e.g., Android)
   ↓
5. Claude reads memory → knows exactly what to build
   ↓
6. Implementation matches Platform A automatically
```

**What memory captures during Platform A work:**
- API response format quirks (snake_case fields, null handling)
- Design decisions (why this approach over that)
- Edge cases discovered during implementation
- Figma node IDs and exact spec values
- Reviewer feedback patterns

**How Platform B benefits:**
- No re-discovery of API quirks
- Same edge cases handled from the start
- Matching UI specs without re-extracting from Figma
- Pre-compliance with the other platform's reviewer patterns

---

## Status Reports

Set up automated status reports to your team channel:

**`memory/reference_slack.md`**
```markdown
---
name: Slack Status Channel
description: Team channel for automated status updates
type: reference
---

Channel: #your-team-channel (ID: C0XXXXX)
Trigger: /postreport command
```

**Report template (add to CLAUDE.md):**

```markdown
## Status Report Format

When `/postreport` is triggered:
1. Read MEMORY.md for current state
2. Check git logs (last 24h) on all repos
3. Update memory with any new findings
4. Compose status using this template:

**{Module} Status — {Date}**

**Completed (last 24h)**
- {bullet points}

**In Progress**
- {bullet points with % estimates}

**Blocked**
- {bullet points with who/what}

**Next Steps**
- {bullet points}

Rules: No emojis, under 40 lines, backticks for technical terms.
```

---

## Feature Plan Template

Every feature starts with a plan file:

**`memory/plan_{feature_name}.md`**

```markdown
---
name: Feature X Plan
description: Implementation plan for Feature X — both platforms
type: project
---

## Specs
- Figma: {node IDs, screenshots}
- API: {endpoints, request/response shapes}
- Requirements: {business rules}

## Current State
- iOS: {what exists}
- Android: {what exists}

## Gap Analysis
| Spec | iOS | Android | Notes |
|------|-----|---------|-------|
| Buy screen | Done | Missing | Need PlusButtonLarge for CTA |
| Cart API | Wired | Wired | API returns snake_case |

## Implementation Tasks

### iOS
1. [ ] Create BuyViewModel
2. [ ] Wire cart API
3. [ ] Add unit tests

### Android
1. [ ] Create BuyFeature (MVI)
2. [ ] Wire cart API
3. [ ] Add MVI tests

## Edge Cases
- Cart expires after 5 minutes
- API returns 409 if cart already finalized
- Null weight on amount-based purchases

## Testing
- iOS: 20 tests (ViewModel + UseCase)
- Android: 15 MVI feature tests
```

---

## Token Savings

The shared memory system provides significant token savings:

| Without Goldy | With Goldy | Savings |
|---------------|------------|---------|
| Re-discover API quirks on each platform | Memory has API format, edge cases | ~15% |
| Re-extract Figma specs | Memory has node IDs, exact values | ~10% |
| Re-learn reviewer preferences | Memory has patterns, past feedback | ~5% |
| Re-investigate blockers | Memory has status, workarounds | ~2% |
| **Total** | | **~32%** |

---

## Directory Structure

```
~/.claude/projects/{project-path}/memory/
  ├── MEMORY.md                          # Index (max 200 lines)
  ├── user_profile.md                    # Developer profile
  ├── feedback_no_base_modifications.md  # "Don't touch shared files"
  ├── feedback_response_style.md         # "No trailing summaries"
  ├── project_module_status.md           # Current progress
  ├── project_branches.md                # Active branches + PRs
  ├── project_api_contracts.md           # API quirks, formats
  ├── project_review_bot.md              # Review bot setup
  ├── project_pr_review_responses.md     # PR review reply tracking
  ├── reference_slack.md                 # Slack channel pointer
  ├── reference_figma.md                 # Figma file pointers
  ├── plan_feature_x.md                  # Feature X plan
  ├── plan_feature_y.md                  # Feature Y plan
  └── figma-nodes.md                     # Figma node ID reference

your-project-root/
  ├── CLAUDE.md                          # Project instructions
  ├── repo-ios/
  ├── repo-android/
  └── claude-review-bot/                 # Optional: review bot
        .github/
          actions/claude-review/
            learnings/
              ios-reviewer.json
              android-reviewer.json
```

---

## FAQ

**Q: Can I use this for a single-platform project?**
A: Yes. Goldy works for any project — the cross-platform aspect is just a bonus. The memory system, planning workflow, and review bot work for any repo.

**Q: How do I share Goldy across team members?**
A: CLAUDE.md is committed to the repo (shared). Memory files are per-developer (in `~/.claude/`). Each developer builds their own memory, but CLAUDE.md ensures consistent behavior.

**Q: What if memory gets too large?**
A: Keep MEMORY.md under 200 lines (it's an index). Move detailed content into separate topic files. Delete outdated memories. Claude only loads what's relevant.

**Q: Can Goldy work with other AI tools?**
A: The CLAUDE.md format is specific to Claude Code, but the concepts (project instructions, memory files, review patterns) can be adapted. The review bot JSON schema works with any LLM that can read JSON.

**Q: How do I migrate an existing project?**
A: Start with CLAUDE.md (project instructions), then add memory files as you work. Don't try to document everything upfront — let memory build organically through conversations.

**Q: What's the ROI?**
A: Based on the Gold module (100+ files, 500+ tests, 2 platforms):
- Feature implementation: ~40% faster (no re-discovery between platforms)
- PR quality: Review bot catches 80%+ of reviewer complaints before submission
- Status reports: 5 min instead of 30 min (auto-generated from git + memory)
- Onboarding: New developers get instant access to all tribal knowledge via CLAUDE.md
