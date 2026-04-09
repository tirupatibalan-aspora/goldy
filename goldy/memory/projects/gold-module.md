# Gold/Wealth Module

**Status**: M2 merged on both platforms. QA fixes in progress.
**Purpose**: Buy, sell, and manage 24K gold investments within Vance app
**Markets**: UAE (AED), UK (GBP)
**Last Updated**: 2026-04-09

## Current State

| | iOS | Android |
|---|---|---|
| **M1 (Landing)** | PR #1484 — Merged ✅ | PR #1512 — Merged ✅ |
| **M2 (Buy/Sell)** | PR #1520 — In review (Paul) | PR #1548 — Merged ✅ |
| **QA Fixes** | On `feature/wealth-module-gold-buy-sell-flow` | PR #1637 — `feature/wealth-module-gold-qa-fixes` |
| **Source files** | 120+ Swift | 97 UI + 20 data layer Kotlin |
| **Tests** | 226 (all passing) | 101+ MVI feature tests |
| **Reviewer** | Paul | Sergei |
| **Review Bot Score** | 9/10 | 10/10 |

## Platform Handbooks

- **Android**: [`GOLD_MODULE_HANDBOOK.md`](https://github.com/Vance-Club/vance-android/blob/feature/wealth-module-gold-qa-fixes/GOLD_MODULE_HANDBOOK.md) — 16-section reference (architecture, APIs, components, testing, Goldy, Review Bot, push workflow)
- **iOS**: `GOLD_MODULE_HANDBOOK.md` — (pending creation, same structure)
- **Architecture Doc**: [GOLD_MODULE_ARCHITECTURE.md](https://github.com/tirupatibalan-aspora/goldy/blob/main/GOLD_MODULE_ARCHITECTURE.md)

## Milestones

### M1 — Gold Landing Page ✅ MERGED (Both Platforms)
- **iOS PR #1484**: Paul approved, merged
- **Android PR #1512**: Sergei approved, merged
- 7 lander sections, live price polling, vault tiers, returns calculator

### M2 — Buy & Sell Gold Flows ✅ BUILT (Both Platforms)
- **iOS PR #1520**: In review by Paul. 120+ files, 226 tests. Design system token migration done.
- **Android PR #1548**: Merged by Sergei. 170+ files, 85+ commits, 101 tests. Review Bot: 10/10.

### QA Fixes (Post-Merge)
- **Android PR #1637**: 10 commits — 7-part animation, backstack fix, vault tier image, API rename, test fixes
- **iOS**: Design system tokens (30 files), backstack navigation, vault tier image

## Screens (Both Platforms)

### Buy Flow
```
Gold Home → Buy Entry (amount/weight) → KYC Bottom Sheet → Order Review (price lock)
→ Payment WebView → Processing (7-part Lottie) → Buy Success (certificate)
```

### Sell Flow
```
Gold Home → Sell Entry (swipe confirm) → Why Selling Sheet → Retention Sheet
→ Order Review → Select Bank → Account Details (IBAN) → Processing
→ Sell Success (receipt)  OR  Sell Failed (retry)
```

### All Screens
| Screen | iOS | Android |
|--------|-----|---------|
| Gold Landing (fresh + existing user) | ✅ | ✅ |
| Buy Entry (numpad, presets, amount/weight) | ✅ | ✅ |
| KYC Bottom Sheet | ✅ | ✅ |
| Order Review (buy + sell unified) | ✅ | ✅ |
| Payment WebView | ✅ | ✅ |
| Processing (7-part Lottie animation) | ✅ | ✅ |
| Buy Success (certificate card) | ✅ | ✅ |
| Sell Entry (swipe-to-confirm) | ✅ | ✅ |
| Why Selling / Retention sheets | ✅ | ✅ |
| Select Bank | ✅ | ✅ |
| Account Details (IBAN entry) | ✅ | ✅ |
| Sell Success (receipt + timeline) | ✅ | ✅ |
| Sell Failed (retry) | ✅ | ✅ |
| Transaction List (paginated) | ✅ | ✅ |
| Transaction Detail (SDUI) | ✅ | ✅ |

## API Endpoints (15 — Both Platforms Use Same)

```
GET  wealth/v1/digital-metal/prices/live
GET  wealth/v1/digital-metal/chart
GET  wealth/v1/digital-metal/portfolio
GET  wealth/v1/digital-metal/transactions
GET  wealth/v1/digital-metal/transactions/{id}    (SDUI detail)
GET  wealth/v1/digital-metal/certificate/{id}
POST wealth/v1/digital-metal/cart
POST wealth/v1/digital-metal/cart/{id}/order-preview
POST wealth/v1/digital-metal/cart/{id}/refresh
POST wealth/v1/digital-metal/order
GET  wealth/v1/digital-metal/order/{id}/status
POST wealth/v1/digital-metal/onboarding/onboard
GET  wealth/v1/digital-metal/beneficiary-accounts
POST wealth/v1/digital-metal/beneficiary-accounts
GET  wealth/v1/digital-metal/payment-instruments
GET  wealth/v1/digital-metal/documents/invoices/{id}/download
```

**Headers**: `X-User-Id`, `X-Country` (NOT query params). All snake_case (v2 not deployed).

## Key Shared Components (Cross-Platform)

| Component | iOS | Android |
|-----------|-----|---------|
| Amount input (gradient) | `GoldAmountTextField` | `GoldAmountTextField` |
| Price lock pill | `GoldPriceLockPill` | `GoldPriceLockPill` |
| Lock timer | `GoldLockTimerPill` | `GoldLockTimerPill` |
| Live price banner | `GoldLivePriceBanner` | `GoldLivePriceBanner` |
| Color tokens | `GoldColors` | `GoldColors` |
| Swipe to sell | `SwipeToSellButton` | `SwipeToSellButton` |

## Key Decisions (Made Once, Applied Both)

| Decision | Applied |
|----------|---------|
| Cart becomes terminal after CREATE_FAILED — must create fresh | Both |
| Price lock: 300s, auto-refresh, green/orange/red | Both |
| Refresh button is SEPARATE circle (40×32, #F7F7FA) | Both |
| popUpTo(GOLD_HOME) for all terminal screens | Both |
| AML checkpoints wired but disabled (IS_AML_ENABLED=false) | Both |
| `paymentMode` → `paymentInstrument` API rename | Both |
| Vault tier images: 5 tiers by weight, not hardcoded locker | Both |
| 7-part segmented Lottie (buy: 7 phases, sell: 4 phases) | Both |

## What's Left

| Item | Priority | iOS | Android |
|------|----------|-----|---------|
| AML checkpoint enforcement | P1 | Wired, disabled | Wired, disabled |
| Negative gains badge | P1 | TODO | TODO |
| Gold certificate download | P2 | TODO | TODO |
| "Price updated" fade (3s) | P2 | Needs design spec | Needs design spec |
| SIP/Coins screens | P3 | Placeholder | Placeholder |
| UK market testing | P3 | Code ready | Code ready |

## Review Bot Integration
- **iOS (Paul)**: 12 patterns — 3 critical. Top: DateFormatter singletons, shared file protection.
- **Android (Sergei)**: 25 patterns — 6 critical. Top: BaseMviViewModel (7x), Screen(state,accept) (3x).
- **Cross-platform**: 1 shared pattern (constants/header keys).
- **Learnings DB**: `claude-review-bot/.github/actions/claude-review/learnings/`
