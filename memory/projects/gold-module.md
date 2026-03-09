# Gold/Wealth Module

**Status**: Active development on both platforms
**Purpose**: Buy, sell, and manage gold investments within Vance app

## iOS (PR #1465 — `feature/wealth-module-gold-onboarding`)
- **Reviewer**: Paul
- **Branch**: `feature/wealth-module-gold-onboarding` → `dev`
- **Architecture**: Clean Architecture with UseCases, Actor-based repositories, SwiftUI views

### Completed
- Domain models: GoldPrice, GoldPortfolio, GoldTransaction, GoldChart, GoldKYCStatus, GoldPaymentMethod, GoldCertificate
- Use cases: FetchGoldPrice, FetchGoldPortfolio, FetchGoldTransactionHistory, FetchGoldChartData, BuyGold, SellGold
- Repository: Actor-based GoldRepository
- Network layer: Network+Gold models
- DI: Container+GoldUseCases, Container+GoldRepositories
- Views: Buy, Sell, Portfolio, PriceChart, Lander, Transactions, GoldHome, Placeholder
- Unit tests: 102 tests passing
- UI component standards: gold-ui-component-standards.md

### Pending
- ~66-81 additional tests (config, KYC, payment methods, mocked use cases, mocked repo, utilities)
- API timing tracking for Gold endpoints
- Remaining placeholder views (sell flow details, certificates)

## Gold Lander — Decided Answers

### Platform-Specific
| Question | Answer |
|----------|--------|
| iOS: Replace or new GoldLanderView? | Replace entirely with Figma |
| iOS: Gradient text style | Reusable `GoldColors.titleGradient` |
| Purple button color | Use theme token `primary500` (both platforms) |
| Android: separate Fragment or state? | State inside `GoldHomeFragment` |
| Android: chart bar style | Must match Figma exactly (rounded bars) |
| Android: Figma fidelity | Pixel-match Figma |
| Android: chart library | OPEN — product has no opinion yet, pending decision |

### Hero & CTA
| Question | Answer |
|----------|--------|
| Hero image | Use existing `hero_gold_coins.png` from repo |
| Trust badge icons | Figma's AI-generated images are final |
| "106% GAINS" text | Dynamic — compute daily + cache |
| Hero sticky/collapsible | NEEDS DISCUSSION with product |
| "Buy Digital Gold" button style | Match Figma purple |
| "Buy Digital Gold" tap action | KYC/onboarding flow first (not BuyGoldView directly) |

### Returns Calculator
| Question | Answer |
|----------|--------|
| Returns data source | Real API — compute daily + cache |
| Amount stepper step size | 500 |
| Amount min/max | Min 500, Max 1,000,000 |
| Amount field tappable? | Yes — manual text input supported |
| Bar chart animation | Animated on appear |

### Content Sections
| Question | Answer |
|----------|--------|
| Horizontal scroll cards | Just the 2 shown in Figma |
| "Asopra" typo | Fix to "Aspora" |
| Stats ("12,000 NRI" etc.) | Backend — card visibility should be configurable too |
| Comparison table data | Prefer Remote Config (unless tradeoff) — NEEDS DISCUSSION |
| Comparison table format | Flat table only (no expandable rows) |
| Comparison table component | NEEDS DISCUSSION (static grid vs reusable) |

### Help & Support
| Question | Answer |
|----------|--------|
| FAQs | Gold-specific FAQ — product working on content |
| "24x7 Aspora guide" | Existing Chat/Help flow |

### Partners & Trust
| Question | Answer |
|----------|--------|
| Partner logos | Export fresh from Figma (not in repo) |
| Gold checkmark badge | Use existing `trust_badge_*` images from repo |
| Disclaimer text | Pending legal review |
| Bottom tabs | Main app bottom nav (not Gold-specific) |

### Scope
| Question | Answer |
|----------|--------|
| Market | UAE first, then UK. No INR. Check roadmap sheet for timelines |

### Still Open / Needs Discussion
1. Hero section — sticky/collapsible on scroll? (product unclear, needs sync)
2. Comparison table — Remote Config vs hardcoded (tradeoffs to discuss)
3. Comparison table — static grid vs reusable component?
4. Android chart library — YCharts or Vico? (product deferring)
5. Disclaimer — legal copy pending review

### Key Patterns (iOS Gold)
- Protocol-based market config: `GoldMarketConfigurable` + UAEGoldMarketConfig / UKGoldMarketConfig
- Formatters separate from models: `GoldPriceFormatter`
- Actor-based repository for thread safety
- `ModelConversionError.failedToConvertFromNetworkModel` for domain conversion failures
- `Network+GoldPrice.swift` file naming convention
- No `.singleton` on use cases (stateless)
- Cache with TTL for polled data (price cache = 30 seconds)

## Android (early development)
- **Branch**: `feature/wealth-module-gold-onboarding`
- **Pattern**: MVI (GoldHomeFeature with State/Event/Command)

### Structure
- **App layer** (12 files): GoldColors, GoldHomeFragment, GoldHomeViewModel, GoldHomeFeature, GoldHomeScreen (Compose), 6 use cases, GoldAmountValidator
- **Data layer** (16 files): GoldService (Retrofit), GoldRemoteDataSource, GoldRepository, model files (GoldPrice, GoldPortfolio, etc.)
- **Tests**: 4 test files (~25% coverage)

### Test Gaps (Android)
- Most data layer, repository, and use case classes untested
- Service layer and remote data source untested
- Priority: Config → KYC/Payment → UseCases → Repository → Utilities
