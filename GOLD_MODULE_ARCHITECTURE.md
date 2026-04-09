# Gold Module Architecture — Single Source of Truth

> **Built entirely via vibe coding with Claude** across iOS and Android.
> M1 (Landing Page) merged. M2 (Buy & Sell Flows) — PRs open.

| | iOS | Android |
|---|---|---|
| **PR** | [#1520](https://github.com/your-org/app-ios/pull/XXX) | [#1548](https://github.com/your-org/app-android/pull/XXX) |
| **Branch** | `feature/wealth-module-gold-buy-sell-flow` | `feature/wealth-module-gold-buy-sell-flow` |
| **Target** | `feature/wealth-module` | `feature/wealth-module` |
| **Files** | 244 changed, +16,048 / -585 | 164 changed, +19,591 / -494 |
| **Commits** | 70 | 75 |
| **Tests** | 184 | 306 |
| **Reviewer** | Reviewer A | Reviewer B |

---

## 1. High-Level Architecture

Both platforms follow **Clean Architecture** with clear separation of concerns. iOS uses **MVVM**, Android uses **MVI** (Model-View-Intent) for feature logic with MVVM for simpler screens.

```
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION                           │
│                                                             │
│  iOS: SwiftUI Views + ObservableObject ViewModels           │
│  Android: Compose Screens + MVI Features + ViewModels       │
│           + Fragments (navigation hosts)                    │
├─────────────────────────────────────────────────────────────┤
│                       DOMAIN                                │
│                                                             │
│  Use Cases (1 per business action)                          │
│  Domain Models (platform-agnostic business entities)        │
│  Validators (amount/weight validation)                      │
├─────────────────────────────────────────────────────────────┤
│                        DATA                                 │
│                                                             │
│  Repository (protocol/interface + implementation)           │
│  Network Models (snake_case API responses)                  │
│  API Service (Retrofit / CacheableService)                  │
│  Model Mapping (Response → Domain)                          │
└─────────────────────────────────────────────────────────────┘
```

### Platform Comparison

| Layer | iOS | Android |
|-------|-----|---------|
| **UI** | SwiftUI Views | Jetpack Compose Screens |
| **State** | `@Published` properties on `ObservableObject` | `StateFlow<State>` via MVI Feature |
| **Navigation** | `GoldRouter` + `GoldRoute` enum + `NavigationStack` | Jetpack Navigation + `Route` enum + Fragments |
| **ViewModel** | `@MainActor ObservableObject` | `BaseMviViewModel<S, E, C, O>` (Hilt-injected) |
| **Use Cases** | `protocol + Impl`, `async throws` | `class`, returns `Flow<Resource<T>>` |
| **Repository** | `actor GoldRepositoryImpl` (thread-safe) | `GoldRepositoryImpl` (coroutine-based) |
| **DI** | Factory (`@Injected`) | Dagger Hilt (`@Inject`, `@HiltViewModel`) |
| **Network** | `CacheableService` + `RequestBuilder` | Retrofit + `GoldService` interface |
| **Testing** | Swift Testing (`@Suite`, `@Test`, `#expect`) | JUnit + MockK + Turbine |

---

## 2. User Flows

### 2.1 Buy Gold Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│  Gold Home   │────>│  Buy Entry   │────>│  KYC Bottom Sheet│
│  (Hero CTA)  │     │  (Numpad)    │     │  (if needsKYC)   │
└──────────────┘     └──────┬───────┘     └────────┬─────────┘
                            │                      │
                     Enter amount/grams      Complete KYC
                     Select preset           onboardUser()
                            │                      │
                            v                      v
                     ┌──────────────┐     ┌──────────────────┐
                     │ Create Cart  │────>│  Order Review    │
                     │ createCart() │     │  (Summary + Pay) │
                     └──────────────┘     └────────┬─────────┘
                                                   │
                                            Tap "Pay Now"
                                          initiateOrder()
                                                   │
                                                   v
                     ┌──────────────┐     ┌──────────────────┐
                     │  Processing  │<────│  Payment WebView │
                     │  (Polling)   │     │  (3DS / Checkout)│
                     └──────┬───────┘     └──────────────────┘
                            │
                    Poll every 2s
                   pollOrderStatus()
                            │
              ┌─────────────┼─────────────┐
              v             v             v
      ORDER_COMPLETED  TIMEOUT(10s)  PAYMENT_FAILED
              │             │             │
              v             v             v
     ┌────────────┐  ┌───────────┐  ┌──────────┐
     │  Success   │  │  Txn      │  │  Error   │
     │  (Cert)    │  │  Detail   │  │  (Toast) │
     └────────────┘  │ (polling) │  └──────────┘
                     └───────────┘
```

### 2.2 Sell Gold Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│  Gold Home   │────>│  Sell Entry  │────>│ "Why Selling?"   │
│ (Sell button)│     │  (% presets) │     │  (Friction sheet)│
└──────────────┘     └──────────────┘     └────────┬─────────┘
                                                   │
                                            Select reason
                                                   │
                                                   v
                     ┌──────────────────┐  ┌──────────────────┐
                     │  Retention Sheet │  │  Select Bank     │
                     │  (if long-term)  │──>│  (Beneficiary)   │
                     └──────────────────┘  └────────┬─────────┘
                                                    │
                                             Select/Add bank
                                                    │
                                                    v
                     ┌──────────────────┐  ┌──────────────────┐
                     │  Order Review    │──>│  Processing      │
                     │  (Sell summary)  │  │  (Poll status)   │
                     └──────────────────┘  └────────┬─────────┘
                                                    │
                                                    v
                                           ┌──────────────┐
                                           │   Success     │
                                           └──────────────┘
```

### 2.3 Transaction History Flow

```
┌──────────────┐     ┌───────────────────┐     ┌──────────────────┐
│  Gold Home   │────>│  Transaction List │────>│ Transaction      │
│ ("View all") │     │  (Paginated,      │     │ Detail           │
└──────────────┘     │   date-grouped)   │     │ (4 header types) │
                     └───────────────────┘     └──────────────────┘
```

**Transaction Detail — 4 Header Types:**

| Header | Background | When |
|--------|-----------|------|
| Success | Purple gradient | `status == SUCCESS` |
| Delayed | Gray | `status == INITIATED` (>10min) |
| Refund In Progress | Lavender | `status == REFUND_INITIATED` |
| Refund Completed | Green | `status == REFUNDED` |

### 2.4 Landing Page — Section Order

**Fresh User:**
```
Hero (CTA: "Buy digital gold" / "Complete KYC to Unlock")
  → Returns Calculator (amount + period selector)
  → Value Cards ("Why buy on Aspora?")
  → Comparison Table (Gold vs FD)
  → Help & Support
  → Partners & Disclaimer
```

**Existing User:**
```
Hero (Portfolio value + gains badge + vault tier + Sell/Buy buttons)
  → Setup Gold SIPs (Daily / Monthly)
  → Gold Coins (Convert to physical)
  → Recent Transactions (latest 3 + "View all")
  → Download Documents (Tax Report + Holding Certificate)
  → Help & Support
  → Partners & Disclaimer
```

---

## 3. Data Flow — End to End

### iOS Data Flow

```
SwiftUI View
  │  @Published state subscriptions
  v
@MainActor ObservableObject ViewModel
  │  @Injected(\.fetchGoldPriceUseCase)
  v
UseCase (protocol + Impl, async throws, Sendable)
  │  invoke() → repository call
  v
actor GoldRepositoryImpl
  │  CacheableService.fetchWithNoCache(request)
  v
RequestBuilder → Request<Network.GoldPrice>
  │  HTTP call
  v
API Response (JSON, snake_case)
  │  Codable + CodingKeys mapping
  v
Network.GoldPrice → GoldPrice (failable init)
  │  init?(from: Network.GoldPrice, market:)
  v
ViewModel @Published property updated → View re-renders
```

### Android Data Flow

```
Compose Screen (observes StateFlow)
  │  viewModel.state.collectAsStateWithLifecycle()
  v
BaseMviViewModel (Hilt-injected)
  │  Feature.update(state, event) → new State + Commands
  │  CoroutineScope.execute(command) → side effects
  v
UseCase (returns Flow<Resource<T>>)
  │  repository.getGoldPrice(userId, market)
  v
GoldRepositoryImpl
  │  serviceProvider.getGoldService().getGoldPrice()
  v
GoldService (Retrofit interface, suspend functions)
  │  HTTP call
  v
API Response (JSON, snake_case)
  │  @SerializedName mapping
  v
GoldPriceResponse → GoldPrice (domain model)
  │  GoldRemoteDataSource.mapPrice()
  v
Resource.Success(data) → Feature Event → State update → Compose recomposition
```

### Android MVI Detail

```
┌─────────────────────────────────────────────────────────────────┐
│                     MVI Architecture                            │
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐ │
│  │  Screen   │───>│  Event   │───>│ Feature  │───>│  State   │ │
│  │ (Compose) │    │ (sealed) │    │ .update()│    │ (data    │ │
│  │           │<───│          │    │ pure fn  │    │  class)  │ │
│  └──────────┘    └──────────┘    └─────┬─────┘    └──────────┘ │
│       ^                               │                  │     │
│       │                               v                  │     │
│       │                        ┌──────────┐              │     │
│       │                        │ Command  │              │     │
│       │                        │ (sealed) │              │     │
│       │                        └─────┬────┘              │     │
│       │                              │                   │     │
│       │                              v                   │     │
│       │                       ┌───────────┐              │     │
│       │                       │ ViewModel │              │     │
│       │                       │ .execute()│──────────────┘     │
│       │                       │ (side fx) │                    │
│       │                       └─────┬─────┘                    │
│       │                             │                          │
│       │                             v                          │
│       │                      ┌───────────┐                     │
│       └──────────────────────│  Output   │                     │
│          (navigation,        │ (sealed)  │                     │
│           toasts)            └───────────┘                     │
│                                                                 │
│  Fragment observes Output → handles navigation & system events │
└─────────────────────────────────────────────────────────────────┘
```

**Key properties of MVI Features:**
- **Pure functions** — no Android dependencies, fully testable
- `init()` returns initial `State` + startup `Commands`
- `update(state, event)` returns new `State` + `Commands`
- ViewModel's `execute(command)` runs side effects (API calls)
- Fragment collects `Output` for navigation

---

## 4. API Integration

### Endpoints (Shared Backend)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/wealth/v1/digital-metal/prices/live` | GET | Live buy/sell prices |
| `/wealth/v1/digital-metal/portfolio` | GET | User holdings & returns |
| `/wealth/v1/digital-metal/transactions` | GET | Paginated transaction history |
| `/wealth/v1/digital-metal/chart` | GET | Historical price chart |
| `/wealth/v1/digital-metal/cart` | POST | Create buy/sell cart |
| `/wealth/v1/digital-metal/cart/{cartId}/summary` | POST | Order breakdown (fees, tax) |
| `/wealth/v1/digital-metal/cart/{cartId}/order` | POST | Initiate payment |
| `/wealth/v1/digital-metal/cart/{orderId}/order/status` | GET | Poll order completion |
| `/wealth/v1/digital-metal/onboard` | POST | KYC onboarding |
| `/wealth/v1/digital-metal/beneficiary` | GET/POST | Bank accounts (sell flow) |
| `/wealth/v1/digital-metal/certificate/{txId}` | GET | Download certificate |

### Headers
- `X-User-Id` — required on all endpoints
- `X-Country` — required on portfolio, prices, transactions (default: `"AE"`)

### Cart-Based Order Flow
```
createCart(metalType, mode, market)
    → cartId
        → getOrderSummary(cartId, amount/weight, paymentMode)
            → { fees, tax, netAmount, priceExpiresAt }
                → initiateOrder(cartId, beneficiaryAccountId?)
                    → { orderId, paymentUrl }
                        → pollOrderStatus(orderId) [every 2s]
                            → ORDER_COMPLETED | PAYMENT_FAILED | INITIATED
```

### Terminal States
| Status | Meaning | Action |
|--------|---------|--------|
| `ORDER_COMPLETED` | Payment + gold allocation done | Navigate to Success |
| `PAYMENT_FAILED` | Payment declined/timed out | Show error, pop to review |
| `INITIATED` | Still processing | Continue polling |

---

## 5. File Structure — Side by Side

### iOS

```
Aspora/
├── Domain/Models/Gold/           # 15 domain models
│   ├── GoldPrice.swift
│   ├── GoldPortfolio.swift
│   ├── GoldTransaction.swift
│   ├── OrderSummary.swift
│   ├── BuyCart.swift
│   ├── GoldOrderResult.swift
│   ├── BeneficiaryAccount.swift
│   └── Common/
│       ├── GoldMarket.swift
│       ├── GoldMarketConfigurable.swift
│       ├── UAEGoldMarketConfig.swift
│       └── UKGoldMarketConfig.swift
│
├── Domain/UseCase/Gold/          # 13 use cases
│   ├── FetchGoldPriceUseCase.swift
│   ├── FetchGoldPortfolioUseCase.swift
│   ├── FetchGoldTransactionHistoryUseCase.swift
│   ├── CreateBuyCartUseCase.swift
│   ├── FetchOrderSummaryUseCase.swift
│   ├── InitiateOrderUseCase.swift
│   ├── PollOrderStatusUseCase.swift
│   ├── OnboardGoldUseCase.swift
│   ├── FetchBeneficiaryAccountsUseCase.swift
│   └── CreateBeneficiaryAccountUseCase.swift
│
├── Repository/Gold/              # Actor-based repository
│   ├── GoldRepository.swift      # Protocol
│   └── GoldRepositoryImpl.swift  # Actor implementation
│
├── Core/
│   ├── DI/
│   │   ├── Container+GoldRepositories.swift
│   │   └── Container+GoldUseCases.swift
│   ├── Network/Models/Gold/      # 11 response models
│   │   ├── Network+GoldPrice.swift
│   │   ├── Network+GoldPortfolio.swift
│   │   ├── Network+GoldTransaction.swift
│   │   ├── Network+OrderSummary.swift
│   │   ├── Network+OrderStatus.swift
│   │   └── Network+BuyCart.swift
│   └── Network/Request/Builder/Gold/  # 13 request builders
│
├── Coordinator/Gold/
│   └── GoldRoute.swift           # 30+ route cases
│
├── Router/Gold/
│   └── GoldRouter.swift          # View factory
│
├── UserInterface/Views/Gold/     # 46 screen/VM files
│   ├── GoldHome/
│   ├── Lander/ + Sections/ (11 sections)
│   ├── Buy/
│   ├── Sell/
│   ├── Transactions/
│   ├── Processing/
│   └── Success/
│
├── UserInterface/Components/Gold/ # 8 shared components
│   ├── GoldLivePriceBanner.swift
│   ├── GoldLockTimerPill.swift
│   ├── GoldFeatureBadge.swift
│   └── GoldTransactionRowView.swift
│
└── UserInterface/Styles/Gold/
    └── GoldColors.swift          # 30+ color constants
```

### Android

```
app/src/main/java/tech/vance/app/
├── ui/gold/
│   ├── home/
│   │   ├── GoldHomeFragment.kt
│   │   ├── logic/GoldHomeFeature.kt      # MVI (29 tests)
│   │   ├── viewmodel/GoldHomeViewModel.kt
│   │   └── ui/
│   │       ├── GoldHomeScreen.kt
│   │       ├── components/ (4 composables)
│   │       └── sections/ (11 section composables)
│   │
│   ├── buy/
│   │   ├── GoldBuyFragment.kt
│   │   ├── logic/GoldBuyFeature.kt       # MVI
│   │   ├── viewmodel/GoldBuyViewModel.kt
│   │   └── ui/
│   │       ├── GoldBuyScreen.kt
│   │       └── GoldKYCBottomSheet.kt
│   │
│   ├── sell/
│   │   ├── GoldSellFragment.kt
│   │   ├── logic/GoldSellFeature.kt      # MVI
│   │   ├── viewmodel/GoldSellViewModel.kt
│   │   ├── ui/
│   │   │   ├── GoldSellScreen.kt
│   │   │   ├── GoldWhySellingBottomSheet.kt
│   │   │   └── GoldRetentionBottomSheet.kt
│   │   └── bank/                          # Sell-specific bank flow
│   │       ├── SelectBankFragment.kt
│   │       ├── AccountDetailsFragment.kt
│   │       ├── logic/ (2 MVI Features)
│   │       ├── viewmodel/ (2 ViewModels)
│   │       └── ui/ (2 Compose screens)
│   │
│   ├── review/
│   │   ├── GoldOrderReviewFragment.kt
│   │   ├── logic/GoldOrderReviewFeature.kt # MVI (52 tests)
│   │   ├── viewmodel/GoldOrderReviewViewModel.kt
│   │   └── ui/GoldOrderReviewScreen.kt
│   │
│   ├── processing/
│   │   ├── GoldProcessingFragment.kt
│   │   ├── GoldProcessingViewModel.kt
│   │   └── GoldProcessingScreen.kt
│   │
│   ├── success/
│   │   ├── GoldSuccessFragment.kt
│   │   └── GoldAddedScreen.kt
│   │
│   ├── transactions/
│   │   ├── GoldTransactionListFragment.kt
│   │   ├── GoldTransactionListViewModel.kt
│   │   ├── GoldTransactionListScreen.kt
│   │   └── detail/
│   │       ├── GoldTransactionDetailFragment.kt
│   │       ├── GoldTransactionDetailViewModel.kt
│   │       └── GoldTransactionDetailScreen.kt
│   │
│   ├── usecase/ (13 use cases)
│   ├── validator/GoldAmountValidator.kt
│   ├── GoldColors.kt             # 140+ color constants
│   ├── GoldFormatter.kt
│   ├── GoldEntryMode.kt
│   ├── GoldLockTimerPill.kt
│   └── GoldAmountEntryScreen.kt  # Shared buy/sell entry UI
│
├── data_layer/network/gold/
│   ├── service/GoldService.kt    # Retrofit (12 endpoints)
│   ├── repository/GoldRepository.kt
│   ├── datasource/GoldRemoteDataSource.kt
│   └── model/
│       ├── domain/ (8 domain models)
│       └── response/ (16 response models)
│
└── app/src/test/.../ui/gold/     # 17 test files, 306 tests
```

---

## 6. Shared Components (Cross-Platform Parity)

| Component | iOS | Android | Purpose |
|-----------|-----|---------|---------|
| **Amount Entry** | `GoldAmountEntryView` | `GoldAmountEntryScreen` | Numpad + gram/amount toggle + presets |
| **Lock Timer Pill** | `GoldLockTimerPill` | `GoldLockTimerPill` | White capsule, gray progress shrinks R→L |
| **Live Price Banner** | `GoldLivePriceBanner` | `GoldLivePriceBanner` | Price + change % with up/down arrow |
| **Feature Badge** | `GoldFeatureBadge` | `GoldFeatureBadge` | Green "New" badge for SIP/Coins |
| **KYC Bottom Sheet** | `GoldKYCBottomSheet` | `GoldKYCBottomSheet` | KYC requirement modal |
| **Why Selling Sheet** | `WhySellingSheet` | `GoldWhySellingBottomSheet` | Reason selection chips |
| **Retention Sheet** | `RetentionSheet` | `GoldRetentionBottomSheet` | Profit incentive to keep holding |
| **Colors** | `GoldColors.swift` (30+) | `GoldColors.kt` (140+) | Centralized color tokens |
| **Order Review** | `GoldSellBuyReviewView` | `GoldOrderReviewScreen` | Unified buy/sell summary |
| **Transaction Row** | `GoldTransactionRowView` | `TransactionRow` (inline) | Buy/sell with weight + amount |

---

## 7. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Unified Review Screen** | Single screen with `OrderReviewMode` enum (.buy / .sell) eliminates code duplication. Old separate buy/sell review files deleted. |
| **MVI for Android Features** | Pure functions (`update(state, event)`) are fully testable without Android deps. 306 tests prove correctness. |
| **Actor-based Repository (iOS)** | Thread safety for concurrent async calls without manual locking. |
| **Cart-based API flow** | Backend requires cart → summary → initiate → poll. Can't skip steps. |
| **3-phase post-payment polling** | WebView → Processing screen (10s) → Transaction Detail (continues polling). Handles slow payment providers. |
| **Gold-specific screens (not SDUI)** | Remittance uses SDUI + XML Fragments. Gold needs native SwiftUI/Compose for rich animations, Figma parity, and offline-first feel. |
| **Gold-specific bank screens** | Remittance bank screens are tightly coupled to transfer flow. Gold sell needs different fields (beneficiary, IBAN). Not reusable. |
| **No portfolio screen** | Removed in M2. Existing user hero shows portfolio summary inline. Full portfolio deferred. |
| **KYC checks both statuses** | Backend returns `FAILED` for some users who should see KYC prompt. Check both `KYC_REQUIRED` and `FAILED`. |
| **ResourceProvider for Android errors** | MVI Features are pure Kotlin (no `Context`). Error strings use `@StringRes Int` in Feature, resolved via `ResourceProvider` in ViewModel. |
| **`PlusButtonLarge` only for primary** | App's branded button doesn't support secondary style. Sell button uses raw `Box` with gray background per CLAUDE.md exception. |

---

## 8. Live Price Polling

Both platforms poll the live gold price every 5 seconds while the Gold tab is visible.

### iOS
```swift
// GoldLanderViewModel
private var pricePollingTask: Task<Void, Never>?

func startPricePolling() {
    pricePollingTask?.cancel()
    pricePollingTask = Task {
        while !Task.isCancelled {
            let price = try await fetchGoldPriceUseCase.invoke(market: market)
            goldPrice = price  // @Published → triggers SwiftUI re-render
            try await Task.sleep(nanoseconds: 5_000_000_000)
        }
    }
}
```

### Android
```kotlin
// GoldHomeViewModel
private var pricePollingJob: Job? = null

fun startPricePolling() {
    pricePollingJob?.cancel()
    pricePollingJob = viewModelScope.launch {
        while (isActive) {
            fetchGoldPriceUseCase.execute().collect { resource ->
                when (resource) {
                    is Resource.Success -> accept(Event.PriceLoaded(resource.data))
                    is Resource.Error -> { /* keep last known price */ }
                }
            }
            delay(5_000)
        }
    }
}
```

---

## 9. Testing Strategy

### iOS — 184 Tests
- **Swift Testing** framework (`@Suite`, `@Test`, `#expect`)
- ViewModel tests (state transitions, async loading)
- UseCase tests (repository mocking)
- Domain model tests (failable init, enums)
- `MockGoldRepository` + `GoldTestFixtures`

### Android — 306 Tests
- **JUnit** + **MockK** + **Turbine** (Flow testing)
- MVI Feature tests (pure state transitions — 81 tests for Home + Review alone)
- ViewModel tests (command execution, side effects)
- UseCase tests (Resource wrapping)
- Validator tests (edge cases)
- Domain model tests

### What Makes MVI Features So Testable

```kotlin
// No mocks needed — pure function testing
@Test
fun `PriceLoaded updates state with formatted price`() {
    val state = State(goldPrice = null)
    val price = GoldPrice(buyPrice = BigDecimal("350.50"), ...)
    val result = GoldHomeFeature.update(state, Event.PriceLoaded(price))
    assertEquals(price, result.state.goldPrice)
    assertTrue(result.commands.isEmpty()) // No side effects
}
```

---

## 10. Asset Pipeline (Figma → Code)

All assets extracted from Figma using `figma-console` MCP plugin:

| Asset Type | iOS Location | Android Location | Count |
|-----------|-------------|-----------------|-------|
| Vault tiers | `Assets.xcassets/Gold/` | `res/drawable-xxxhdpi/` | 5 |
| Partner logos | `Assets.xcassets/Gold/` | `res/drawable-xxxhdpi/` | 4 |
| Trust badges | `Assets.xcassets/Gold/` | `res/drawable-xxxhdpi/` | 3 |
| Certificate assets | `Assets.xcassets/Gold/` | `res/drawable-xxxhdpi/` | 4 |
| Coin product | `Assets.xcassets/Gold/` | `res/drawable-xxxhdpi/` | 1 |
| Marble pedestal | `Assets.xcassets/Gold/` | `res/drawable-xxxhdpi/` | 1 |
| Lottie animations | `Resources/Lottie/` | `res/raw/` | 2 |

**Lesson learned**: SVGs with `mask-type:alpha` render semi-transparent on iOS. Use PNG @3x instead.

---

## 11. PR Standards Enforced

These standards were enforced across both platforms before PR submission:

| Standard | Rule |
|----------|------|
| **No hardcoded strings in Views** | All user-facing text via `R.string.*` (Android) / `R.string.localizable.*` (iOS) |
| **No hardcoded colors** | All colors via `GoldColors.*` or `Theme.colors.*` — zero raw hex in UI files |
| **No business logic in Views** | Views only bind to ViewModel properties. Formatting, validation, conditionals live in VM/Feature. |
| **Figma exact values** | Gradient stops, icon sizes, spacing, font weights match Figma. Node IDs in comments. |
| **Localization complete** | ~140 strings (Android) / ~400 strings (iOS) — all localized |
| **Color centralization** | 140+ constants in `GoldColors.kt`, 30+ in `GoldColors.swift` |
| **Error messages via ResourceProvider** | Android ViewModels use `ResourceProvider.getString()`, Features use `@StringRes Int` |

---

## 12. What's Remaining (Post-M2)

| Item | Status | Both Platforms |
|------|--------|---------------|
| Transaction Detail — full backend-to-frontend wiring | Pending | UI built, needs complete API data mapping |
| SIP screens (Daily/Monthly) | Placeholder | Navigation wired, screens not built |
| Gold Coins screen | Placeholder | Navigation wired, screen not built |
| Gold certificate download | Not started | API exists, UI not wired |
| Documents section — real data | Not started | Currently dummy data |
| Bank verification flow | Not started | "Fetching account details..." screen |
| iOS Account Details screen (IBAN) | Not built | Android has it |
| Extract shared PaymentWebView | Post-M2 | Currently duplicated in Gold + Remittance |
| Extract shared OrderStatusPoller | Post-M2 | Pattern exists in both modules |

---

## 13. Module Statistics

| Metric | iOS | Android |
|--------|-----|---------|
| **Total Gold files** | ~100+ | 76+ |
| **Screens** | 14 | 12 |
| **ViewModels** | 12 | 10+ |
| **MVI Features** | — | 6 |
| **Use Cases** | 13 | 13 |
| **Domain Models** | 15 | 8 |
| **Network Models** | 11 | 16 |
| **Tests** | 184 | 306 |
| **Color Constants** | 30+ | 140+ |
| **Localized Strings** | ~400 | ~140 |
| **Figma Assets** | 23+ | 15+ |
| **API Endpoints** | 12 | 12 |

---

*Last updated: March 23, 2026*
*Built with Claude via vibe coding — iOS PR #1520, Android PR #1548*
