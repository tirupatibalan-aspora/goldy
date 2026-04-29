# Example Reviews

Real-world examples of how the Claude Code Review bot reviews iOS and Android PRs.

## Example 1: iOS Force Unwrap (Blocked)

**File**: `Aspora/Gold/Repository/GoldRepositoryImpl.swift`

```swift
// ❌ BAD CODE
actor GoldRepositoryImpl: GoldRepository {
    func getPrice(market: GoldMarket) async throws -> GoldPrice {
        let network = try await cacheableService.fetch(request: ...)
        guard let price = GoldPrice(from: network, market: market) else {
            throw ModelConversionError.failedToConvertFromNetworkModel
        }
        let currency = market.currency! // FORCE UNWRAP HERE
        return GoldPrice(price: price.buyPrice, currency: currency)
    }
}
```

### Bot Review

```
VERDICT: CHANGES_REQUESTED

SUMMARY: Force unwrap on Currency will crash if optional is nil.

ISSUES:
- [GoldRepositoryImpl.swift:8]: Force unwrap on `market.currency!`.
  Fix: Change to optional binding or return nil from failable init.

  Refactor:
  guard let currency = market.currency else {
      throw ModelConversionError.failedToConvertFromNetworkModel
  }

POSITIVES:
- Correct use of CacheableService pattern
- Proper error handling with ModelConversionError
- Good separation between network and domain models

NEXT_STEPS: Remove force unwrap and handle the optional case explicitly.
```

---

## Example 2: Android Missing Tests (Blocked)

**Files**:
- `app-android/gold/src/main/kotlin/com/aspora/gold/GoldBuyFeature.kt`

No test file provided.

### Bot Review

```
VERDICT: CHANGES_REQUESTED

SUMMARY: Feature logic present but critical test file is missing.

ISSUES:
- [GoldBuyFeature.kt:1]: No corresponding GoldBuyFeatureTest.kt file found.
  Fix: Create GoldBuyFeatureTest.kt with minimum 25 test methods covering:
       1. Init state and commands
       2. State transitions for each Event type
       3. Command emission verification
       4. Edge cases (boundaries, null values)
       5. Computed properties (formatting, derived state)

  Include regions for each Event type:
  // region init
  @Test fun 'init returns Loading state'()
  // endregion

  // region Event.ScreenLoaded
  @Test fun 'ScreenLoaded emits FetchData command'()
  // endregion

POSITIVES:
- Proper MVI structure with State/Event/Command separation
- Correct use of sealed interfaces for exhaustive when
- BigDecimal used for all monetary values
- Dagger Hilt DI configured correctly

NEXT_STEPS: Add comprehensive test file before re-requesting review.
```

---

## Example 3: iOS Task Cancellation Issue (Changes Requested)

**File**: `Aspora/Gold/ViewModel/GoldLanderViewModel.swift`

```swift
// ❌ BAD CODE
@MainActor
final class GoldLanderViewModel: ObservableObject {
    @Published private(set) var goldPrice: GoldPrice?
    @Injected(\.fetchGoldPriceUseCase) private var useCase

    private var loadTask: Task<Void, Never>?

    func loadPrice() {
        loadTask?.cancel()
        loadTask = Task {
            do {
                let price = try await useCase.invoke(market: market)
                goldPrice = price  // MISSING: check if cancelled
            } catch {
                // error handling
            }
        }
    }
}
```

### Bot Review

```
VERDICT: CHANGES_REQUESTED

SUMMARY: Race condition: missing cancellation check after await.

ISSUES:
- [GoldLanderViewModel.swift:13]: Missing cancellation check after await.
  Fix: Add `guard !Task.isCancelled else { return }` after each await point:

  let price = try await useCase.invoke(market: market)
  guard !Task.isCancelled else { return }
  goldPrice = price

  Without this, if loadPrice() is called twice in quick succession,
  the first task's await may complete after the second task starts,
  causing stale data to overwrite the latest price.

POSITIVES:
- Good use of task-based pattern with cancel()
- Proper error handling in catch block
- Correct @MainActor and @Published usage
- Clean dependency injection

NEXT_STEPS: Add cancellation checks after each await point.
```

---

## Example 4: Android Design Token Violation (Changes Requested)

**File**: `app-android/gold/src/main/kotlin/com/aspora/gold/GoldBuyScreen.kt`

```kotlin
// ❌ BAD CODE
@Composable
fun GoldBuyScreen(state: State, accept: (Event) -> Unit) {
    AppScreen(
        topBar = { PlusTopBarWithBack(title = "Buy Gold") }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(20.dp)  // ❌ MAGIC NUMBER
        ) {
            Text(
                "Enter Amount",
                fontSize = 18.sp,  // ❌ HARD-CODED FONT
                color = Color(0xFF6366F1),  // ❌ HARD-CODED COLOR
            )
        }
    }
}
```

### Bot Review

```
VERDICT: CHANGES_REQUESTED

SUMMARY: Hard-coded colors, fonts, and spacing instead of design tokens.

ISSUES:
- [GoldBuyScreen.kt:10]: Magic number padding (20.dp).
  Fix: Use design token: `.padding(horizontal = 2xl)` or `.padding(3xl)`

  Available tokens: xs (4dp), sm (8dp), md (12dp), lg (16dp), xl (20dp), 2xl (24dp), 3xl (32dp)

- [GoldBuyScreen.kt:15]: Hard-coded fontSize (18.sp).
  Fix: Use Theme.typography.BodyL or Theme.typography.HeadingM

  let style = Theme.typography.BodyL

- [GoldBuyScreen.kt:16]: Hard-coded color (0xFF6366F1).
  Fix: Use Theme.colors.primaryGreen or appropriate theme color.

  color = Theme.colors.primaryGreen

POSITIVES:
- Good AppScreen wrapper for consistent theming
- Proper state-driven rendering with when
- Correct component structure
- Good separation of concerns

NEXT_STEPS: Replace all hard-coded design values with Theme tokens.
```

---

## Example 5: iOS Caching Issue (Changes Requested)

**File**: `Aspora/Gold/ViewModel/GoldPriceViewModel.swift`

```swift
// ❌ BAD CODE
@MainActor
final class GoldPriceViewModel: ObservableObject {
    @Published private(set) var goldPrice: GoldPrice?

    var formattedPrice: String {  // ❌ COMPUTED PROPERTY RECOMPUTES EVERY TIME
        guard let price = goldPrice else { return "--" }
        return GoldPriceFormatter.formatPrice(price, market: market)
    }

    func loadPrice() {
        // ... load and set goldPrice
    }
}
```

### Bot Review

```
VERDICT: CHANGES_REQUESTED

SUMMARY: Computed property recalculates formatting on every access.

ISSUES:
- [GoldPriceViewModel.swift:6]: formattedPrice recalculates every time it's accessed.
  Fix: Cache as @Published property instead:

  @Published private(set) var formattedPrice: String = "--"

  Then update it in loadPrice():
  formattedPrice = GoldPriceFormatter.formatPrice(price, market: market)

  Reason: SwiftUI accesses computed properties on every render. Formatting
  is an expensive operation. Cache it to avoid wasteful recalculation.

POSITIVES:
- Correct separation of formatting logic to GoldPriceFormatter
- Good use of @Published for reactive updates
- Proper optional handling

NEXT_STEPS: Convert computed property to @Published cached value.
```

---

## Example 6: Android Exhaustive When Issue (Blocked)

**File**: `app-android/gold/src/main/kotlin/com/aspora/gold/GoldHomeScreen.kt`

```kotlin
// ❌ BAD CODE
@Composable
fun GoldHomeScreen(state: State, accept: (Event) -> Unit) {
    AppScreen {
        when (state.screenState) {  // ❌ MISSING ERROR CASE
            is State.ScreenState.Loading -> LoadingContent()
            is State.ScreenState.Success -> SuccessContent(state)
            // Missing: is State.ScreenState.Error
        }
    }
}
```

### Bot Review

```
VERDICT: CHANGES_REQUESTED

SUMMARY: When statement on sealed interface is not exhaustive—missing Error case.

ISSUES:
- [GoldHomeScreen.kt:7]: Non-exhaustive when on State.ScreenState.
  Fix: Add missing case:

  when (state.screenState) {
      is State.ScreenState.Loading -> LoadingContent()
      is State.ScreenState.Success -> SuccessContent(state)
      is State.ScreenState.Error -> ErrorContent(
          message = state.screenState.message,
          onRetry = { accept(Event.RetryClick) }
      )
  }

POSITIVES:
- Good structure with sealed interface for state
- Proper AppScreen wrapper
- Clean separation of content by state

NEXT_STEPS: Handle all cases in sealed interface. Compile won't succeed without this.
```

---

## Example 7: iOS Approved PR

**File**: `Aspora/Gold/Repository/GoldRepositoryImpl.swift`

```swift
// ✅ GOOD CODE
actor GoldRepositoryImpl: GoldRepository {
    private let cacheableService: CacheableService

    func getPrice(market: GoldMarket) async throws -> GoldPrice {
        let network = try await cacheableService.fetch(
            request: FetchGoldPriceRequestBuilder.build(market: market)
        )
        guard let price = GoldPrice(from: network, market: market) else {
            throw ModelConversionError.failedToConvertFromNetworkModel
        }
        return price
    }
}
```

### Bot Review

```
VERDICT: APPROVE

SUMMARY: Excellent implementation following all project patterns and safety standards.

POSITIVES:
- Proper actor-based concurrency
- Correct CacheableService pattern usage
- Safe optional handling with guard let
- Proper error handling with ModelConversionError
- Clean separation: network → domain model conversion
- Network+ naming convention would apply to request builder

NEXT_STEPS: Ready to merge! 🚀
```

---

## Example 8: Android Approved PR

**File**: `app-android/gold/src/main/kotlin/com/aspora/gold/GoldBuyFeature.kt`

```kotlin
// ✅ GOOD CODE
object GoldBuyFeature {
    data class State(
        val screenState: ScreenState = ScreenState.Loading,
        val buyPrice: BigDecimal = BigDecimal.ZERO,
        val amount: BigDecimal = BigDecimal.ZERO,
    ) {
        sealed interface ScreenState {
            data object Loading : ScreenState
            data object Lander : ScreenState
            data class Error(val message: String) : ScreenState
        }
    }

    sealed interface Event {
        data object ScreenLoaded : Event
        data class AmountChanged(val amount: BigDecimal) : Event
    }

    sealed interface Command {
        data object FetchPriceData : Command
        sealed interface Output : Command {
            data object NavigateBack : Output
        }
    }

    fun init(): Init<State, Command> = Init(
        state = State(),
        commands = setOf(Command.FetchPriceData)
    )

    fun update(state: State, event: Event): Update<State, Command> {
        return when (event) {
            is Event.ScreenLoaded -> update(
                state = state.copy(screenState = State.ScreenState.Lander),
                commands = setOf(Command.FetchPriceData)
            )
            is Event.AmountChanged -> {
                if (event.amount < BigDecimal.ZERO) {
                    update(state = state.copy(amount = BigDecimal.ZERO))
                } else {
                    update(state = state.copy(amount = event.amount))
                }
            }
        }
    }
}
```

### Bot Review

```
VERDICT: APPROVE

SUMMARY: Excellent MVI structure with proper state management and comprehensive test coverage.

POSITIVES:
- Perfect MVI pattern with State/Event/Command separation
- BigDecimal used correctly for all monetary values
- Data class State with nested sealed ScreenState interface
- Pure update function (no side effects)
- Proper command structure with Output nested interface
- Validation logic in state transitions (amount bounds checking)
- Matching GoldHomeUpdateTest with 28 test methods covering all paths
- Theme tokens used consistently throughout UI
- Proper Dagger Hilt DI in ViewModel
- Clear error handling with Error state

NEXT_STEPS: Ready to merge! 🚀
```

---

## Common Patterns

### What Gets Approved ✅

**iOS**:
- CacheableService for networking
- Actor repositories
- Task cancellation with proper checks
- Optional binding everywhere
- @Published for cached values
- Formatters in Core/Utils/

**Android**:
- MVI pattern (State/Event/Command)
- BigDecimal for money
- Sealed interfaces for exhaustive when
- Tests (25+ for features)
- Theme tokens only
- AppScreen wrapper

### What Gets Rejected ❌

**iOS**:
- Force unwraps
- Race conditions
- Side effects in computed properties
- Custom data sources instead of CacheableService
- Hard-coded strings

**Android**:
- Double/Float for money
- Missing tests
- Non-exhaustive when
- Business logic in UI
- Hard-coded design values
- No MVI structure

---

Use these examples to understand the bot's review patterns before submitting real PRs!
