# Gold/Wealth Module

**Status**: Active development on both platforms
**Purpose**: Buy, sell, and manage gold investments within Vance app
**Completion**: iOS 70% | Android 60% (of full Gold module scope)

## Milestones

### M1 — Gold Landing Page ✅ MERGED
- **Branch**: `feature/wealth-module-gold-onboarding` → merged
- **Status**: QA in progress (build comparison running parallel)
- **iOS**: PR #1465 approved by Reviewer A, merged. 64 files, 117 tests, 7 lander sections.
- **Android**: PR #1512 approved by Reviewer B, merged. `feature/wealth-module-gold-onboarding` → `feature/wealth-module`. 40 files changed (+4,703 −244). Wired live gold price API, updated domain models with change/changePercent fields, 3 test files updated.

### M2 — Buy & Sell Gold Flows 🚧 ALL SCREENS BUILT — PENDING PR
- **Branch**: `feature/wealth-module-gold-buy-sell-flow` (pushed to origin)
- **Status**: All 10 screens built on iOS. 453 tests. Ready for PR creation → Reviewer A review.
- **Scope**: 10 unique screens (3 buy + 1 success + 7 sell). All Figma-matched.
- **Figma**: Buy section `28949:69838` | Sell section `28950:1317`
- **Commits**: `a5e077bc6` (sell friction flow) → `efa2c41dc` (ViewModel tests) → `2a1de8474` (buy flow + assets)

#### Buy Flow Screens (3 to build) — ALL BUILT ✅ (Both Platforms)
1. **Buy Gold Entry** ✅ — Amount in grams, price lock timer, presets (2/5/10/50gm), numpad, amount/weight toggle, social proof
2. **KYC Bottom Sheet** ✅ — First-time only gate, 3 benefit rows, "Proceed to Digital KYC" CTA
3. **Buy Review** ✅ — Order summary, rate pill, 3% processing fee, bank selector, countdown timer, Pay CTA
4. **Success Screen** ✅ — GoldAddedView (post-purchase confirmation)

#### Sell Flow Screens (7 to build) — ALL BUILT ✅ (Both Platforms)
1. **Sell Gold Entry** ✅ — Amount in gms, % presets (25/50/75/MAX), numpad, holdings badge
2. **"Why?" Friction Sheet** ✅ — Reason chips (Wedding/Emergency/Goals Met/Testing App/Expenses/Other), animated bottom sheet overlay
3. **Retention Friction Sheet** ✅ — Long-term user only, profit stats + compounding streak warning, animated overlay
4. **Select Bank** ✅ — Search, frequently used, A-Z grouping, availability badges
5. **Account Details** ✅ — Bank account number input (8-18 digits), test deposit note, auto-fetch banner
6. **Review Sell Order** ✅ — Rate pill, lock timer, AED 2 flat fee, payout time card, bank selector via navigation
7. **Retention Nudge** ✅ — Value today vs 6m projection, growth chart placeholder, "Keep Gold" / "Sell Gold" CTAs

#### Sell Friction Flow (wired — both platforms)
Entry → (ContinueClick) → Why? sheet → (if long-term user) → Retention sheet → Review → Success
Review → (bank selector tap) → SelectBank → AccountDetails → Review with bank set
Review → (if long-term) → RetentionNudge → "Keep Gold" (back) / "Sell Gold" (execute)

**Android**: Fragment Result API for bank selector callback
**iOS**: Closure-based callbacks via GoldRoute (.selectBank(onBankSelected:))

#### M2 Tests (Android)
- **GoldSellFeatureTest** — 42 tests (numpad, presets, validation, friction flow, timer, computed properties)
- **GoldSellReviewFeatureTest** — 16 tests (bank selection, confirm sell, sell result, computed properties)
- **SelectBankFeatureTest** — 10 tests (search, bank selection, availability, data loading)
- **AccountDetailsFeatureTest** — 12 tests (input validation, verification flow, navigation)

#### M2 Tests (iOS) — 453 total Gold module tests
- **BuyGoldViewModelTests** — 37 tests (numpad input, presets, mode toggle, validation, KYC flow, countdown)
- **BuyReviewViewModelTests** — 17 tests (order summary, fees, countdown, pay gating)
- **SellGoldViewModelTests** — 33 tests (numpad input, percent presets, friction flow, validation, display)
- **SellReviewViewModelTests** — 26 tests (flat fee, retention nudge, execute sell gating)
- **SelectBankViewModelTests** — 15 tests (search filtering, availability, bank info)
- **AccountDetailsViewModelTests** — 16 tests (validation, numpad, verification)
- **SellFrictionFlowTests** — 23 tests across 4 suites (SellReason enum, BankInfo model, SelectBankVM, AccountDetailsVM, GoldRoute)
- **GoldLanderViewTests** — 66 tests (lander section logic)

#### External/Placeholder Flows (not building)
- KYC Flow (Persona/SumSub integration)
- Payment Flow (Checkout.com/TrueLayer integration)
- Account Verification Flow

## iOS
### M1 Branch (`feature/wealth-module-gold-onboarding`)
- **PR #1465**: Approved by Reviewer A ✅, merged → `dev`
- **PR URL**: https://github.com/your-org/app-ios/pull/1465

### M2 Branch (`feature/wealth-module-gold-buy-sell-flow`) — PUSHED
- **Status**: All screens built, pushed to origin. Next: create PR for Reviewer A.
- **Architecture**: Clean Architecture with UseCases, Actor-based repositories, SwiftUI views
- **Stats**: ~100+ Swift files, 453 tests across 10+ test files

### Completed (iOS)
- Domain models: GoldPrice, GoldPortfolio, GoldTransaction, GoldChart, GoldKYCStatus, GoldPaymentMethod, GoldCertificate
- Use cases: FetchGoldPrice, FetchGoldPortfolio, FetchGoldTransactionHistory, FetchGoldChartData, BuyGold, SellGold
- Repository: Actor-based GoldRepository
- Network layer: Network+Gold models
- DI: Container+GoldUseCases, Container+GoldRepositories
- Views: Buy, Sell, Portfolio, PriceChart, Lander, Transactions, GoldHome, Placeholder
- Buy flow views: BuyGoldView (numpad, presets, amount/weight toggle, price lock), BuyReviewView (3% fee, bank selector, countdown), GoldKYCBottomSheet, GoldAddedView (success)
- Buy flow ViewModels: BuyGoldViewModel (validation, KYC gating, price loading), BuyReviewViewModel (fee calc, pay gating)
- Sell flow views: WhySellingSheet, RetentionSheet, RetentionNudgeView, SelectBankView, AccountDetailsView, SellReviewView (all Figma-matched)
- Sell flow ViewModels: SellGoldViewModel (friction flow), SellReviewViewModel, SelectBankViewModel, AccountDetailsViewModel
- 13 Figma assets: gold_coin_stack_1/2/3, gold_vault_shelf/mid_rail/top_rail, gold_partner_brinks/goldwise, gold_avatar_ring, gold_user_avatar, gold_help_circle, gold_maximize_icon, gold_pro_tag
- Unit tests: **453 total** — 102 foundation + 66 Lander + 37 BuyVM + 17 BuyReviewVM + 33 SellVM + 26 SellReviewVM + 15 SelectBankVM + 16 AccountDetailsVM + 23 SellFrictionFlow + misc
- UI component standards: gold-ui-component-standards.md
- Gold Landing Page: GoldLanderView replaced with Figma-matched design (7 sections: Hero, Trust Badges, Returns Calculator, Value Cards, Comparison, FAQ, Partners)
- GoldLanderViewModel with calculator logic (step 500, min 500, max 1M, rates: 1Y ~8%, 3Y ~30%, 5Y ~60%)
- Localization: 42 new keys for buy flow strings in en.lproj/Localizable.strings

### Pending (iOS)
- Pass `isLongTermUser` to SellReviewView (not yet wired through route — ReviewVM needs route param or independent detection)
- Sell presets mismatch: current 25/50/75/100% → Figma shows 10/20/40/Sell All with "POPULAR" badge
- Wire Landing Page to real API data (gains percent, returns)
- API timing tracking for Gold endpoints
- Partner logos ✅ arrived from Figma
- Disclaimer copy (pending legal review)
- Certificates view (placeholder)
- M2 PR creation for Reviewer A's review

### Recent Changes (iOS)
- **Live Price Polling**: 5s interval in GoldLanderViewModel (Task-based, cancellation-safe)
- **ORDER_COMPLETED fix**: Added `.orderCompleted = "ORDER_COMPLETED"` to GoldOrderStatus enum
- **Partner logos**: Arrived and exported to Assets.xcassets/Gold/

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
| Android: chart library | **Vico 2.4.3** (`compose-m3`) — decided March 11, 2026. Integrated in Returns Calculator. |

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
| Partner logos | ✅ Arrived from Figma — exported to both platforms |
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
4. Disclaimer — legal copy pending review

### Key Patterns (iOS Gold)
- Protocol-based market config: `GoldMarketConfigurable` + UAEGoldMarketConfig / UKGoldMarketConfig
- Formatters separate from models: `GoldPriceFormatter`
- Actor-based repository for thread safety
- `ModelConversionError.failedToConvertFromNetworkModel` for domain conversion failures
- `Network+GoldPrice.swift` file naming convention
- No `.singleton` on use cases (stateless)
- Cache with TTL for polled data (price cache = 30 seconds)

## Android
### M1 Branch (`feature/wealth-module-gold-onboarding`)
- **PR #1512**: Approved by Reviewer B ✅, merged
- **Branch**: `feature/wealth-module-gold-onboarding` → `feature/wealth-module`

### M2 Branch (`feature/wealth-module-gold-buy-sell-flow`) — PUSHED
- **Status**: All screens built, pushed to origin. Next: create PR for Reviewer B.
- **Pattern**: MVI (GoldHomeFeature with State/Event/Command)
- **Stats**: 76 Kotlin source files, 14 test files, 306 tests

### Completed (Android)
- **App layer**: GoldColors, GoldHomeFragment, GoldHomeViewModel, GoldHomeFeature (expanded MVI), GoldHomeScreen (Compose), 6 use cases, GoldAmountValidator
- **Data layer**: GoldService (Retrofit), GoldRemoteDataSource, GoldRepository, model files (GoldPrice, GoldPortfolio, etc.)
- **Gold Landing Page**: 7 section composables (Hero, Trust Badges, Returns Calculator, Value Cards, Comparison, FAQ, Partners)
- **MVI expansion**: 7 new Events, 3 new Commands
- **Buy flow**: Buy entry, KYC sheet, Buy review, navigation + tests
- **Sell flow**: Sell entry, WhySheet, RetentionSheet, SelectBank, AccountDetails, SellReview, RetentionNudge — all with MVI pattern
- **Chart**: Custom Figma-matched bar composables (replaced Vico for Returns Calculator)
- **Localization**: All hardcoded strings localized
- **Reviewer B review feedback** (commit `76a92917a0`):
  - Extracted transaction grouping from UI → `GoldTransactionGrouper` utility (Today/Yesterday/date labels, java.time APIs)
  - Moved alphabetical bank grouping from `SelectBankScreen` composable → `SelectBankFeature.State.groupedBanks` computed property
  - Added 26 @Preview functions in `GoldScreenPreviews.kt` — all 12 screens (loading/content/error states) + reusable components (LivePriceBanner, SectionHeader, FeatureBadge) + portfolio components
- **Tests**: 306 total — GoldSellFeatureTest (43), GoldSellReviewFeatureTest (18), SelectBankFeatureTest (11), AccountDetailsFeatureTest (13), GoldHomeUpdateTest (33), GoldLanderSectionTests (55), GoldLanderSnapshotTests (18), GoldRemoteDataSourceTest (32), GoldAmountValidatorTest (21), GoldDomainModelTest (16), GoldConstantsTest (9), GoldMarketTest (12), GoldChartDataTest (14), GoldUseCaseTest (11)

### Recent Changes (Android)
- **Live Price Polling**: 5s interval in GoldHomeViewModel (coroutine-based). Fixed `firstOrNull()` bug — must use `firstOrNull { it !is Resource.Loading }`.
- **Toolbar Live Price Pill**: `GoldToolbarPricePill.kt` — capsule composable overlaid on HomeToolbar
- **ORDER_COMPLETED fix**: GoldBuyReviewFeature handles `ORDER_COMPLETED` as success + `PAYMENT_FAILED` as failure
- **Partner logos**: Arrived from Figma, exported to `res/drawable-xxxhdpi/`

### Pending (Android)
- Fix cart API 500 error (`POST /wealth/v1/digital-metal/buy/cart` returns HTTP 500)
- Wire Landing Page to real API data
- Partner logos ✅ arrived from Figma
- Disclaimer copy (pending legal review)
- Remove debug logging from GoldRepository.createBuyCart (after 500 fix)
- M2 PR creation for Reviewer B's review
