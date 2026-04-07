# Memory

## Me
Tirupati Balan, tirupati.balan@aspora.com. Works on Vance (Aspora) — a cross-border money transfer fintech app (iOS + Android).

## People
| Who | Role |
|-----|------|
| **Paul** | iOS code reviewer (reviews Gold module PRs) |
→ Full list: memory/glossary.md, profiles: memory/people/

## Terms
| Term | Meaning |
|------|---------|
| **Vance** | Consumer-facing brand name for Aspora app |
| **Aspora** | Company / codebase name |
| **SDUI** | Server-Driven UI — backend defines UI components via JSON |
| **Canvas** | Home V3 — new server-driven home screen (iOS) |
| **Gold module** | Wealth/Gold investment feature (buy/sell gold) — active development |
| **BBPS** | Bharat Bill Payment System — Indian bill payments feature |
| **NRE/NRO** | Non-Resident External/Ordinary bank accounts (India-specific) |
| **KYC** | Know Your Customer — identity verification |
| **P0/P1/P2/P3** | Priority levels (P0 = drop everything) |
| **MVI** | Model-View-Intent pattern (Android Gold module) |
| **Plus\*** | Custom Android view prefix (PlusButton, PlusEditText) |
→ Full glossary: memory/glossary.md

## Projects
| Name | What | Status |
|------|------|--------|
| **vance-ios** | iOS app — SwiftUI, Clean Architecture + MVVM, Swift 6, iOS 16.4+ | Active |
| **vance-android** | Android app — Kotlin, Clean Architecture + MVVM, Dagger Hilt, Compose + XML | Active |
| **Gold Module (iOS)** | Wealth module — 100+ files, 453 tests. M1 merged ✅. M2 all screens built, live price polling, ORDER_COMPLETED fix. Pending PR. | Active — 70% complete |
| **Gold Module (Android)** | Gold module — 76 Kotlin files, 306 tests. M1 merged ✅. M2 all screens built, live price polling + toolbar pill, ORDER_COMPLETED fix. Cart API 500 blocking buy flow. Pending PR. | Active — 60% complete |
| **Goldy** | AI project manager — shared knowledge base across iOS & Android, saves ~32% tokens on cross-platform dev | Active |
| **UK SD Components (Android)** | UK-specific server-driven UI components (Address view, picker) | Active branch |
→ Details: memory/projects/

## Active Branches
| Repo | Branch | Milestone |
|------|--------|-----------|
| vance-ios | `feature/wealth-module-gold-buy-sell-flow` | M2 — Buy/Sell flows |
| vance-android | `feature/wealth-module-gold-buy-sell-flow` | M2 — Buy/Sell flows |

## Milestones
| # | Name | Status | Branch |
|---|------|--------|--------|
| M1 | Gold Landing Page | ✅ Merged on both platforms (iOS PR #1484, Android PR #1512) | `feature/wealth-module-gold-onboarding` |
| M2 | Buy & Sell Gold Flows | All screens built, pushed. Pending PRs. | `feature/wealth-module-gold-buy-sell-flow` |

## Tech Stack Summary
| | iOS | Android |
|---|-----|---------|
| **Language** | Swift 6 | Kotlin |
| **UI** | SwiftUI | Jetpack Compose + XML Views |
| **Architecture** | Clean Arch + MVVM | Clean Arch + MVVM (Gold: MVI) |
| **DI** | Factory (@Injected) | Dagger Hilt |
| **Networking** | Custom Network layer | Retrofit |
| **DB** | — | Room |
| **Navigation** | Router + Coordinator + NavigationStack | Jetpack Navigation (Fragments) |
| **Testing** | Swift Testing (@Suite, @Test, #expect) | JUnit, MockK, Turbine |
| **Analytics** | Mixpanel, Firebase, MoEngage, AppsFlyer, Smartlook | Mixpanel, GA, AppsFlyer, Crashlytics, Smartlook, Moengage |
| **Image Loading** | Kingfisher | Glide & Coil |

## Key Integrations (Both Platforms)
- **Plaid** — Bank account linking
- **TrueLayer** — Open banking payments (UK)
- **Checkout.com** — Card payments / 3DS
- **Persona** — KYC verification
- **SumSub** — KYC verification
- **Sardine** — Fraud detection
- **Firebase** — Analytics, Crashlytics, Remote Config, Auth

## Preferences
- Act as a Senior Engineer — challenge ideas, be brutally honest
- No over-engineering — simplest solution that works
- Quality > Speed
- Never build iOS project (xcodebuild) unless explicitly asked
- **Figma**: ALWAYS use `figma-console` MCP plugin (southleft/figma-console-mcp) for ALL Figma operations — design extraction, variables, components, screenshots, design system kit. NEVER use the built-in claude.ai Figma MCP. If figma-console is not running, show a message asking to start it — do NOT fall back to claude.ai Figma MCP.
- **Buttons**: NEVER create custom buttons. Always use the platform's Aspora button as the base:
  - **Android (Compose)**: `PlusButtonLarge` / `PlusButtonMedium` / `PlusButtonSmall` from `tech.vance.app.base.compose.components`. Use `ButtonState.ENABLED` / `ButtonState.DISABLED` / `ButtonState.LOADING` for state management.
  - **Android (XML)**: `PlusButton` custom view from `tech.vance.app.base.views`
  - **iOS**: `AsporaButton` with variants `.primary` / `.secondary` / `.tertiary`. Supports async actions.
- **Buttons**: ALWAYS use the platform's Aspora button as the base component — never create custom Button composables/views. iOS: `AsporaButton` (.primary, .secondary, .tertiary). Android: `PlusButtonLarge`/`PlusButtonMedium`/`PlusButtonSmall` from `tech.vance.app.base.compose.components`. Only use raw `Button` if the Aspora button variants don't support the required styling (e.g. secondary gray).

## STRICT: Feature Plan Before Implementation

**ALWAYS create a markdown plan file before starting any feature implementation.**

For every new feature, screen, or module:
1. Extract Figma specs (via figma-console MCP) — node IDs, exact values, all states/variants
2. Analyze current codebase — what exists, what's missing, what needs changing
3. Create a plan markdown file in Goldy memory (`memory/plan_<feature_name>.md`)
4. Get user approval on the plan before writing any code
5. Reference the plan file in MEMORY.md

Plan file must include:
- Figma node IDs and screenshot analysis
- Current state (what's built)
- Gap analysis (Figma vs current)
- Implementation tasks (numbered, per-platform)
- Files to create/modify
- Validation rules, error messages, edge cases
- Colors, typography, spacing (exact Figma values)
- Testing requirements

**NEVER start implementation without an approved plan file.**

## STRICT: No Modifications Outside Gold Module

**ALWAYS ASK before modifying any file outside the Gold module on either platform.**

This applies to ALL files that are shared, base-level, or used by other modules — even if the change seems small or Gold-specific.

### Android — files that require explicit approval:
- `navigation/Route.kt` — navigation route enum
- `navigation/nav_graph_common.xml` — navigation graph
- `navigation/AppNavigation.kt` — navigation controller
- `base/` — any base classes, components, views, extensions, themes
- `di/` — Dagger Hilt modules
- `data-layer/` — shared data layer (network, models, repositories)
- `utils/` — shared utilities
- Any file outside `ui/gold/`

### iOS — files that require explicit approval:
- `Coordinator/` — route enums (except `Gold/GoldRoute.swift`)
- `Router/` — router classes (except `Gold/GoldRouter.swift`)
- `Core/` — DI containers, network, services, stores
- `Components/` — shared UI components (except `Gold/`)
- `Domain/` — shared use cases, models
- `Repository/` — shared repositories
- `Resources/` — Localizable.strings (adding strings is OK, never modify existing)
- Any file outside `UserInterface/Views/Gold/`, `UserInterface/Components/Gold/`, `UserInterface/Styles/Gold/`

### Why:
- Other teams depend on shared files — changes can break their work
- Gold module should be self-contained during M2 development
- Route/navigation changes affect the entire app
- Paul (iOS) and Sergei (Android) review Gold PRs — minimize non-Gold diff

## Review Bot Learnings (auto-synced 2026-03-25)

Bot test score: 10/10 (76/76 tests passing)

### Top Cross-Platform Patterns (both reviewers flag these)
| # | Category | Rule | Frequency |
|---|----------|------|-----------|
| 1 | constants | Use Constants for repeated header keys and magic strings | 3x |

### iOS — Paul's Top Blockers
- **Never create DateFormatter or ISO8601DateFormatter per call — use static let singleton** (2x)
- **Static/singleton formatters — DateFormatter is one of the most expensive Foundation objects to instantiate** (2x)
- **NEVER modify shared/base files used by other modules — revert any changes to CurrencyFormatter, shared models, etc.** (1x)

### Android — Sergei's Top Blockers
- **ALL ViewModels MUST extend BaseMviViewModel — never raw ViewModel()** (7x)
- **All screens must have @Preview composable and use AppScreen as root wrapper** (4x)
- **Use enums for order statuses — never hardcoded strings like 'COMPLETED', 'ORDER_COMPLETED', 'FAILED'** (3x)
- **Dangerous defaults — never hardcode currency 'AED' or country 'AE'. Use required fields or market-aware constants** (3x)
- **Screen composables must accept State + accept: (Event) -> Unit — never pass ViewModel directly** (3x)
- **NEVER modify base components (PlusButton, MainFragment) or build scripts (app.gradle.kts) — keep wealth module isolated** (3x)

→ Full learnings: `claude-review-bot/.github/actions/claude-review/learnings/`

## PR Standards (Strict)
- **No hardcoded values in Views**: All strings, colors, presets, config values, formatting, and business logic MUST live in the ViewModel (or Model/Constants layer). Views should only bind to ViewModel properties — never contain inline strings, NumberFormatters, conditional logic for data, or raw color values. The View layer is strictly for layout and rendering.
- **All user-visible strings must be localized**: Use `R.string.localizable.*` (iOS) or `R.string.*` (Android). No inline string literals in Views or ViewModels for user-facing text.
- **Colors must use centralized tokens**: Use `GoldColors.*`, `Theme.colors.*`, or `theme.p91Colors.*`. Never use raw `Color(hex:)` / `Color(0x...)` in View or ViewModel files — add new constants to `GoldColors` (or equivalent) instead.
- **Figma specs must use exact values**: Gradient stops, icon sizes, spacing, and font weights must match Figma exactly — no approximations. Reference the Figma node ID in a comment when implementing non-obvious design specs.

## STRICT: Run Tests Locally Before Pushing to CI

**ALWAYS run tests locally before pushing code and triggering CI builds.**

This avoids wasting CI runner time and gives faster feedback. Run the relevant test suite — not the full project — to keep the feedback loop tight.

### Commands

**iOS** (run from `vance-ios/`):
```bash
xcodebuild test \
  -workspace Vance.xcworkspace \
  -scheme Vance_Stage \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug \
  -only-testing:VanceTests/<TestSuiteName> \
  -skipPackagePluginValidation
```
- Replace `<TestSuiteName>` with the specific test class (e.g., `GoldOrderUseCaseTests`, `FileSessionLoggerTests`)
- For multiple suites: repeat `-only-testing:VanceTests/<Suite>` for each
- To run ALL Gold tests: `-only-testing:VanceTests` and grep for Gold (or list each Gold suite)

**Android** (run from `vance-android/`):
```bash
# Single test class
./gradlew :app:testDebugUnitTest --tests "tech.vance.app.ui.gold.<package>.<TestClass>"

# All Gold tests
./gradlew :app:testDebugUnitTest --tests "tech.vance.app.ui.gold.*"
```

### Rules
1. **Before every `git push`**: run at minimum the test suites for files you changed
2. **After merge conflicts**: run ALL tests for the affected module (not just changed files)
3. **If local tests fail**: fix before pushing — never push broken code hoping CI will catch it
4. **Run Aspora Review Bot audit**: before every push, audit changed files against reviewer learnings (see below). Min score 8/10. Fix critical/major issues before pushing.
4. **CI is for verification, not discovery** — local tests should catch issues first

## STRICT: Aspora Review Bot Audit Before Every Push

**ALWAYS run the Aspora Review Bot audit before every `git push` — not just PR creation.**

This applies to ALL modules and teams, not just Gold. The review bot learns from each reviewer's PR comments and enforces their patterns automatically.

### How it works
1. **Reviewer learnings** are stored in `claude-review-bot/.github/actions/claude-review/learnings/` as JSON files named `{platform}-{reviewer}.json` (e.g., `ios-paul.json`, `android-sergei.json`)
2. Each file contains categorized patterns (critical/major/minor) with bad/good examples, extracted from real PR review comments
3. Before any PR, Claude audits the diff against ALL patterns for the target reviewer

### Adding a new reviewer / module
Any team can onboard their reviewer by creating a learnings file:
```
claude-review-bot/.github/actions/claude-review/learnings/{platform}-{reviewer}.json
```
Format: see existing files for schema (`patterns[]` with `id`, `severity`, `category`, `rule`, `bad_example`, `good_example`, `source`, `frequency`). Once added, the review bot will enforce that reviewer's patterns on all future PRs targeting their platform.

### Audit process (before every push)
1. **Find the reviewer**: Check the PR reviewer (from `gh pr view` or user context), then read **ALL** matching learnings JSONs from `claude-review-bot/.github/actions/claude-review/learnings/`. Load every `{platform}-*.json` file for the target platform (e.g., all `ios-*.json` for an iOS PR). If a specific reviewer is assigned, prioritize their file but still check platform-wide patterns.
2. Diff the branch changes against the base branch
3. Audit every changed file against ALL reviewer patterns (critical, major, minor)
4. Score the PR out of 10:
   - Critical issues: -3 each (would block merge)
   - Major issues: -2 each (must fix before merge)
   - Minor issues: -0.5 each (nice to have)
5. Fix all critical and major issues BEFORE creating/updating the PR
6. Include the **Aspora Review Bot Score** section in the PR description:

```markdown
## Aspora Review Bot Score: X/10
| Severity | Count | Details |
|----------|-------|---------|
| Critical | N | (list or "None") |
| Major | N | (list or "None") |
| Minor | N | (list or "None") |
```

**Minimum score to create PR: 8/10.** If below 8, fix issues first. Never create a PR with critical issues.

### Current reviewers
| Platform | Reviewer | Learnings file | Patterns |
|----------|----------|---------------|----------|
| iOS | Paul | `ios-paul.json` | 12 patterns (3 critical, 7 major, 2 minor) |
| Android | Sergei | `android-sergei.json` | 25 patterns (6 critical, 14 major, 5 minor) |

To add your module's reviewer: create the JSON, add a row here, and the bot will enforce their standards automatically.
