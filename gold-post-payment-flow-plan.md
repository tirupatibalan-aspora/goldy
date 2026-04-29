# Gold Post-Payment Flow — 3-Phase Polling Architecture

## Overview

After the user completes payment on the Checkout.com WebView, we implement a 3-phase tiered polling flow that provides a smooth UX while waiting for order confirmation from the backend.

**Lottie Asset:** `goldStageFinal.json` (from `common_assets/`, ~230KB, embedded images)

---

## Flow Diagram

```
Payment WebView
"Your payment was successful"
         │
         ▼
 ┌──────────────────┐
 │  PHASE 1 (2s)    │  Stay on WebView success page
 │  Start polling    │  Poll order status every 2s
 │                   │
 │  Got ORDER_       │──YES──▶  Phase 3: Gold Added Screen
 │  COMPLETED?       │          (skip Lottie entirely)
 │                   │
 │  2s elapsed?      │──YES──▶  Dismiss WebView → Phase 2
 └──────────────────┘
         │
         ▼
 ┌──────────────────┐
 │  PHASE 2 (10s)   │  Lottie waiting screen
 │  goldStageFinal   │  Continue polling every 2s
 │                   │
 │  Got ORDER_       │──YES──▶  Phase 3: Gold Added Screen
 │  COMPLETED?       │
 │                   │
 │  10s elapsed?     │──YES──▶  Transaction Detail Screen
 │  (no response)    │          (shows status progress bar)
 └──────────────────┘
         │
         ▼
 ┌──────────────────┐
 │  PHASE 3          │  "Gold added to your locker in X.XX sec"
 │  Gold Added       │  Certificate card + ownership details
 │  Screen           │  Timer shows actual elapsed since payment
 └──────────────────┘
```

---

## Phase 1: WebView Success Detection (2 seconds)

### Current Behavior
- WebView detects `"payment was successful"` via JavaScript injection (`document.body.innerText.toLowerCase().includes('payment was successful')`)
- Waits 2 seconds on success page, then dismisses and navigates

### New Behavior
- On success detection, **start polling immediately** while still on the WebView
- Record `paymentSuccessTimestamp` (used to calculate total elapsed time for Phase 3)
- After 2 seconds:
  - If `ORDER_COMPLETED` received → dismiss WebView → navigate directly to **Phase 3** (Gold Added)
  - If not yet completed → dismiss WebView → navigate to **Phase 2** (Lottie screen)

### Implementation Notes

**iOS** (`GoldPaymentWebView.swift` + `GoldSellBuyReviewViewModel.swift`):
- `onPaymentSuccess()` callback already fires after 2s delay
- Add: start polling in ViewModel immediately when success is detected (before the 2s UX delay)
- Add: track `paymentSuccessTimestamp = Date()`
- Modify: `onPaymentCompleted(router:)` to check if poll already succeeded
  - If `orderCompleted == true` → navigate to `.buySuccess`
  - If not → navigate to new `.goldProcessing` route (Phase 2)

**Android** (`GoldOrderReviewScreen.kt` + `GoldOrderReviewViewModel.kt`):
- `onPaymentSuccess()` already fires after 2s `postDelayed`
- Add: emit `Event.PaymentSuccessDetected` immediately (not after 2s) to start polling
- Keep the 2s delay for WebView dismiss
- Modify: `Event.PaymentWebViewDismissed` handler:
  - If poll succeeded → navigate to success
  - If not → navigate to Lottie screen

---

## Phase 2: Lottie Waiting Screen (10 seconds max)

### New Screen — `GoldProcessingView` / `GoldProcessingScreen`

A simple full-screen view with:
- `goldStageFinal.json` Lottie animation (centered, looping)
- Text below: "Processing your gold purchase..." (localized)
- Optional: subtle progress text updates ("Securing your gold...", "Almost there...")
- No back button / non-dismissable

### Polling Logic
- Continue polling every 2 seconds (reuse existing `PollOrderStatusUseCase`)
- Start a 10-second timeout timer
- **If `ORDER_COMPLETED` within 10s** → navigate to Phase 3 (Gold Added screen)
- **If 10s elapsed without `ORDER_COMPLETED`** → navigate to Transaction Detail screen
  - The Transaction Detail screen already has the status timeline/progress bar section
  - User can see their order is being processed
  - They can come back later from the transaction list

### Asset Placement
- **iOS**: Copy `goldStageFinal.json` to `Resources/Lottie/goldStageFinal.json`
- **Android**: Copy `goldStageFinal.json` to `app/src/main/res/raw/gold_stage_final.json`

### iOS Implementation
- New file: `UserInterface/Views/Gold/Processing/GoldProcessingView.swift`
- New file: `UserInterface/Views/Gold/Processing/GoldProcessingViewModel.swift`
- Uses existing `LottieView("goldStageFinal", loopMode: .loop)` pattern (same as `TransferPollingView`)
- ViewModel receives `orderId` + `paymentSuccessTimestamp`
- Polls using `PollOrderStatusUseCase`
- Navigation: add `.goldProcessing(orderId:timestamp:)` to `GoldRoute`

### Android Implementation
- New file: `ui/gold/processing/GoldProcessingFragment.kt`
- New file: `ui/gold/processing/GoldProcessingScreen.kt` (Compose)
- Uses `com.airbnb.lottie.compose.LottieAnimation` with `R.raw.gold_stage_final`
- ViewModel or Fragment handles polling + timeout
- Navigation: add `GOLD_PROCESSING` route

---

## Phase 3: Gold Added Screen (existing)

### Current State
- **iOS**: `GoldAddedView.swift` — static certificate card with dummy data
- **Android**: `GoldAddedScreen.kt` — animated beam/glow effect, auto-dismisses after 3s

### Changes Needed
- Accept `elapsedSeconds: Double` parameter (calculated from `paymentSuccessTimestamp`)
- Display actual elapsed time: "Gold added to your locker in **X.XX sec**"
- iOS: The "Credited at Aspora speed!" badge + green time text already exist in the view

---

## Terminal States Reference

| Status | Action |
|--------|--------|
| `ORDER_COMPLETED` / `COMPLETED` | Navigate to Gold Added (Phase 3) |
| `PAYMENT_FAILED` / `ORDER_FAILED` / `CREATE_FAILED` / `FAILED` | Show error toast, pop back to review |
| `AWAITING_FULFILLMENT` (sell only) | Navigate to success (sell) |
| `FULFILLMENT_FAILED` (sell only) | Show error toast |
| Any other status | Continue polling (non-terminal) |

---

## Files to Create/Modify

### New Files

| Platform | File | Purpose |
|----------|------|---------|
| iOS | `Views/Gold/Processing/GoldProcessingView.swift` | Lottie waiting screen UI |
| iOS | `Views/Gold/Processing/GoldProcessingViewModel.swift` | Polling + timeout logic |
| Android | `ui/gold/processing/GoldProcessingFragment.kt` | Fragment wrapper |
| Android | `ui/gold/processing/GoldProcessingScreen.kt` | Compose Lottie screen |

### Modified Files

| Platform | File | Change |
|----------|------|--------|
| iOS | `GoldSellBuyReviewViewModel.swift` | Start polling on success detection, track timestamp, route to Phase 2 or 3 |
| iOS | `GoldPaymentWebView.swift` | Minor: callback timing adjustment |
| iOS | `GoldRoute.swift` / `GoldRouter.swift` | Add `.goldProcessing` route |
| iOS | `GoldAddedView.swift` | Accept `elapsedSeconds` parameter |
| Android | `GoldOrderReviewViewModel.kt` | Start polling on success detection, track timestamp |
| Android | `GoldOrderReviewFeature.kt` | Add `NavigateToProcessing` command |
| Android | `GoldOrderReviewFragment.kt` | Handle navigation to processing screen |
| Android | `GoldSuccessFragment.kt` / `GoldAddedScreen.kt` | Accept elapsed time parameter |
| Both | `strings.xml` / `Localizable.strings` | Add processing screen strings |

### Asset Copies

| Source | Destination |
|--------|------------|
| `common_assets/goldStageFinal.json` | iOS: `Resources/Lottie/goldStageFinal.json` |
| `common_assets/goldStageFinal.json` | Android: `app/src/main/res/raw/gold_stage_final.json` |

---

## Timing Diagram (Happy Path)

```
t=0s    Payment success detected → start polling
t=0s    [Poll 1] → AWAITING_PAYMENT / PAYMENT_COMPLETED
t=2s    WebView dismissed → navigate to Phase 2 (Lottie)
t=2s    [Poll 2] → PAYMENT_COMPLETED
t=4s    [Poll 3] → ORDER_COMPLETED ✅
t=4s    Navigate to Gold Added: "added in 4.00 sec"
```

## Timing Diagram (Slow Backend → Transaction Detail with continued polling)

```
t=0s    Payment success detected → start polling
t=2s    WebView dismissed → navigate to Phase 2 (Lottie)
t=2s    [Poll 2] → PAYMENT_COMPLETED
t=4s    [Poll 3] → PAYMENT_COMPLETED
t=6s    [Poll 4] → PAYMENT_COMPLETED
t=8s    [Poll 5] → PAYMENT_COMPLETED
t=10s   [Poll 6] → PAYMENT_COMPLETED
t=12s   Timeout → navigate to Transaction Detail
        (shows status timeline, CONTINUES polling)
t=14s   [Poll 7] → PAYMENT_COMPLETED
t=16s   [Poll 8] → ORDER_COMPLETED ✅
t=16s   Transaction Detail header transitions to purple SUCCESS
        header (Figma 30444:21456) with rating stars,
        "Gold added to locker in 16.00s"
```

### Transaction Detail Polling (Phase 2 fallback)
When the Transaction Detail screen is opened from the Lottie timeout:
- It receives `orderId` + `paymentSuccessTimestamp` + `isPolling = true` flag
- Starts with DELAYED header type (shows processing status timeline)
- Continues polling every 2s using `PollOrderStatusUseCase`
- On `ORDER_COMPLETED`: animates header transition to SUCCESS (purple gradient + rating)
- On terminal failure: updates header to show error state
- Max additional polling: 120s (60 attempts) after entering Transaction Detail
- User can dismiss at any time — polling stops on leave

---

## Edge Cases

1. **Network error during polling**: Log error, retry on next interval. Don't break the flow.
2. **App backgrounded during Phase 2**: Continue timer. On foreground, if timeout exceeded, navigate to Transaction Detail.
3. **Payment failure detected during Phase 1/2**: Show error toast, dismiss to review screen. Don't show Lottie.
4. **Sell flow**: Sell doesn't use payment WebView (no Phase 1). If needed, sell could start at Phase 2 directly after order initiation.
5. **WebView closed by user (X button)**: Cancel polling. Return to review screen. Don't enter Phase 2.

---

## Notes

- The 2s Phase 1 window is already the existing UX delay — we're just using that time productively by polling
- The 10s Phase 2 timeout is a UX decision — most orders complete in <5s based on the "2.93 sec" shown in the Gold Added screenshot
- Transaction Detail screen is the fallback — it already has a working status timeline that shows order progress
- Polling interval stays at 2 seconds (matches existing `PollingStream.create(interval: 2)` on iOS, `delay(2000)` on Android)
