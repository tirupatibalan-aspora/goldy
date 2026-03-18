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

## PR Standards (Strict)
- **No hardcoded values in Views**: All strings, colors, presets, config values, formatting, and business logic MUST live in the ViewModel (or Model/Constants layer). Views should only bind to ViewModel properties — never contain inline strings, NumberFormatters, conditional logic for data, or raw color values. The View layer is strictly for layout and rendering.
- **All user-visible strings must be localized**: Use `R.string.localizable.*` (iOS) or `R.string.*` (Android). No inline string literals in Views or ViewModels for user-facing text.
- **Colors must use centralized tokens**: Use `GoldColors.*`, `Theme.colors.*`, or `theme.p91Colors.*`. Never use raw `Color(hex:)` / `Color(0x...)` in View or ViewModel files — add new constants to `GoldColors` (or equivalent) instead.
- **Figma specs must use exact values**: Gradient stops, icon sizes, spacing, and font weights must match Figma exactly — no approximations. Reference the Figma node ID in a comment when implementing non-obvious design specs.
