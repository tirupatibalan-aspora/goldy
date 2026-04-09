# Vance iOS

**Repo**: your-org/app-ios
**Language**: Swift 6 | **Min iOS**: 16.4+ | **Xcode**: 16.4+
**Architecture**: Clean Architecture + MVVM with SwiftUI

## Directory Structure
```
Aspora/
├── App/                    # Entry point, configs, constants
├── Domain/                 # Business logic (Models/, UseCase/)
├── Data/                   # DTOs & API response models
├── Repository/             # Data access abstraction (protocol-based)
├── Core/                   # Infrastructure (DI, Network, Services, Stores, Managers, Analytics)
├── UserInterface/          # SwiftUI (Views/, Components/, SDUI/, Modifiers/, Styles/)
├── Coordinator/            # Route definitions
├── Router/                 # Navigation state management
└── Resources/              # Assets, Fonts, Lottie, Localization (en only)
```

## Key Patterns
- **UseCase**: Protocol (Sendable) + final class impl. Newer modules use `async throws`; older use `Result<T, Error>`
- **Repository**: Actor-based for thread safety (Gold module pattern). Protocol inherits from `Actor`
- **ViewModel**: `@MainActor`, `ObservableObject`, `@Published private(set)`, `LoadingState<T>`
- **DI**: Factory library. `@Injected(\.useCase)` in ViewModels. Registration in `Core/DI/Container+*.swift`
- **Navigation**: Router (`@Published var path: [Route]`) + Coordinator enums + `NavigationStack`
- **Network → Domain**: `Network+X.swift` naming. Failable init `init?(from network:)`. Use `ModelConversionError` on failure
- **Protocol-based config**: `GoldMarketConfigurable` — strategy pattern per market (UAE, UK)
- **Formatters**: Separate from models (e.g., `GoldPriceFormatter`)
- **Theme**: `@Environment(\.theme) var theme` — fonts, colors, spacing. No hardcoded values

## DI Rules
- Use cases: **never** `.singleton` (stateless, recreated per use)
- Repositories & data sources: `.singleton` OK (actor-isolated)

## Build Configs
| Config | Usage |
|--------|-------|
| Debug | Local dev on simulator |
| DebugProd | Debug against production API |
| Stage-Release | TestFlight QA |
| Release | App Store |

## Dependencies
SPM: Firebase, Mixpanel, AppsFlyer, MoEngage, Kingfisher, Lottie, Factory (DI), R.swift, SwiftLint, TrueLayer, Checkout Frames, Plaid Link, Persona, Sardine, Google Sign-In, DeviceKit, Netfox
CocoaPods: TensorFlowLiteC, PureLiveSDK (deprecated)

## Feature Modules (Views/)
Gold (Buy, Sell, Portfolio, PriceChart, Lander, Transactions, Placeholder), Canvas, BBPS, CompareRates, HelpAndSupport, Login, EmailLogin, Onboarding, Transfer, AddBankDetails, IdentityVerification, Chat, DynamicForm, NREAccount, and many more

## Known Issues
1. BankingSDK: xcodebuild from CLI fails (pre-existing, builds fine in Xcode)
2. No French localization — English only (en.lproj)
3. Existing `Currency` struct — always reuse, never create custom
4. R.swift needs build to regenerate after adding strings

## Current Active Work
- **M1 PR #1484 MERGED** — `feature/wealth-module-gold-onboarding` → `feature/wealth-module` (Reviewer A approved, 2026-03-13)
- **M2 branch**: `feature/wealth-module-gold-buy-sell-flow` — All 10 screens built, 453 tests, pushed to origin
- **Live Price Polling**: 5s interval in GoldLanderViewModel (Task-based, cancellation-safe)
- **ORDER_COMPLETED**: `.orderCompleted` added to `GoldOrderStatus` enum, BuyReviewViewModel handles it as success
- **Partner logos**: Arrived from Figma
- Next: Create M2 PR for Reviewer A's review
- Pending: Wire sell flow to real API, portfolio API wiring, SIP/Coins screens, certificates

## Testing
- Framework: Swift Testing (@Suite, @Test, #expect)
- Location: VanceTests/Tests/
- Gold tests: VanceTests/Tests/Gold/
