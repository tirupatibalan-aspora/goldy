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
- **Files**: 19 Kotlin source files (GoldHomeFragment, GoldHomeViewModel, GoldHomeScreen, GoldHomeFeature, 6 use cases, GoldAmountValidator, 7 section composables)
- **Data layer**: GoldService (Retrofit), GoldRemoteDataSource, GoldRepository, 8+ model files
- **Landing Page**: Built — 7 section composables (Hero, Trust Badges, Returns Calculator, Value Cards, Comparison, FAQ, Partners)
- **MVI expansion**: 7 new Events, 3 new Commands for Landing Page interactions
- **Tests**: 8 test files, 25 MVI tests (up from 4 files/8 tests)

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
- `feature/wealth-module-gold-onboarding` — Gold module development
- `feature/ukSdComponents` — UK server-driven UI components (Address view, picker)
