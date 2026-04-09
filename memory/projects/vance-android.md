# Vance Android

**Repo**: Multi-module Gradle project (Kotlin DSL)
**Language**: Kotlin | **Min SDK**: 24 | **Target/Compile SDK**: 35
**Architecture**: Clean Architecture + MVVM (Gold module uses MVI), Dagger Hilt

## Module Structure
```
├── app/                    # Main app module (UI, Navigation, DI)
├── data-layer/             # Data layer (APIs, Room DB, repositories, models)
├── utils/                  # Shared utilities, extensions, constants
├── analytics/              # Analytics integrations (Mixpanel, GA, AppsFlyer, etc.)
├── baselineprofile/        # App startup optimization
├── banking-sdk/            # External banking SDK integration
└── build.gradle.kts        # Root gradle config (ktlint, Detekt)
```

## Key Patterns
- **Fragment-based navigation** with Jetpack Navigation + NavRouter
- **BaseViewModel** for common ViewModel functionality (loading, errors)
- **Base\* classes**: BaseFragment, BaseDialogFragment, BaseBottomSheetDialogFragment, BaseActivity
- **Custom views**: Plus* prefix (PlusButton, PlusEditText, PlusBanner)
- **Extension functions**: heavy usage, organized in extension/ packages
- **Package organization**: by feature, not by layer (ui/home/, ui/send/, ui/gold/)
- **ViewBinding** for type-safe view references
- **Coroutines**: viewModelScope / lifecycleScope
- **Safe Args** with @Parcelize for navigation arguments

## Server-Driven UI (SDUI)
- SDFragment → RecyclerView → SDViewAdapter → SDViewHolderFactory → ViewHolders
- Adding new component: data model → ViewHolder → register in SDViewHolderFactory
- EventBus for component interactions

## Gold Module (Android)
- **Location**: app/ui/gold/ + data-layer/network/gold/
- **Pattern**: MVI (GoldHomeFeature with State/Event/Command)
- **Stats**: 76 Kotlin source files, 14 test files, 306 tests
- **M1 (Landing Page)**: PR #1512 merged. 7 sections (Hero, Trust Badges, Returns Calculator, Value Cards, Comparison, FAQ, Partners)
- **M2 (Buy & Sell)**: All screens built, pushed to origin. Pending PR for Reviewer B.
- **Chart**: Custom Figma-matched bar composables (Vico 2.4.3 evaluated, replaced with custom implementation for pixel-perfect Figma matching)
- **Buy flow**: Buy entry, KYC sheet, Buy review — all with MVI + tests
- **Sell flow**: Sell entry, WhySheet, RetentionSheet, SelectBank, AccountDetails, SellReview, RetentionNudge — all with MVI + tests
- **Reviewer B review feedback**: Extracted transaction grouping from UI (GoldTransactionGrouper), added 26 @Preview functions (GoldScreenPreviews.kt)
- **Live Price Polling**: 5s interval in GoldHomeViewModel, toolbar pill (`GoldToolbarPricePill.kt`)
- **ORDER_COMPLETED**: Recognized as terminal success in Feature + ViewModel polling
- **Known issue**: Cart API 500 — debug logging in GoldRepository.createBuyCart
- **Partner logos**: ✅ Arrived from Figma
- **Pending**: Fix cart API 500, wire to real API, disclaimer, remove debug logging, M2 PR for Reviewer B

## Build Variants
- debug, dev_test (minified debug), release (ProGuard/R8), release_test
- Build with: `./gradlew assembleDebug`, `./gradlew assembleRelease`

## Code Quality
- **ktlint**: `./gradlew ktlintFormat` (wildcard imports allowed)
- **Detekt**: `./gradlew detekt` (config: config/detekt/detekt.yml)

## Testing
- Unit: JUnit, MockK, Turbine (Flow), Coroutines Test
- Instrumented: Espresso, UI Automator
- Run: `./gradlew test`, `./gradlew connectedAndroidTest`

## Third-Party Integrations
Plaid, TrueLayer, Checkout.com, Persona, SumSub, Sardine, Firebase (Auth, Firestore, Messaging, Crashlytics, Remote Config)

## Feature Packages (app/ui/)
gold, home, send, transfer, beneficiary, profile, onboarding, bbps, referral, rewards, kyctier, notifications, rate_alert, nre_nro_accounts, server_driven, compare_rates, outbound_call, and more

## Active Branches
- `feature/wealth-module-gold-buy-sell-flow` — M2 Buy & Sell flows (current)
- `feature/wealth-module-gold-onboarding` — M1 Landing Page (merged)
- `feature/ukSdComponents` — UK server-driven UI components (Address view, picker)
