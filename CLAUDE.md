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
| **Gold Module (iOS)** | Wealth module — domain, use cases, repo, views, 102 tests. PR #1465 under review by Paul | Active — PR review |
| **Gold Module (Android)** | Gold home screen, MVI pattern, ~25% test coverage | Active — early dev |
| **UK SD Components (Android)** | UK-specific server-driven UI components (Address view, picker) | Active branch |
→ Details: memory/projects/

## Active Branches
| Repo | Branch |
|------|--------|
| vance-ios | `feature/wealth-module-gold-onboarding` |
| vance-android | `feature/wealth-module-gold-onboarding` |

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
