# Gold Transaction Detail Screen — Analysis & Recommendation

**Date**: 2026-03-18
**Figma**: [Transaction Details (Gold)](https://www.figma.com/design/YOUR_FILE_ID/Your-App?node-id=XXXXX&m=dev)
**Related**: `gold-order-review-screen-analysis.md` (Review Order screen analysis)

---

## 1. What Figma Shows

The Gold Transaction Detail screen has the **same overall layout** as the remittance Transaction Details screen, with **4 conditional header types** based on transaction status.

### Page Structure (top to bottom)

| Section | Description |
|---------|-------------|
| **Nav Bar** | Back + "Transaction Details" + Help icon |
| **Header** | **4 TYPES** — changes based on status (see below) |
| **Transaction Card** | Gray card: title, subtitle, amount + right-side illustration |
| **Status Timeline** | Vertical stepper (green=done, blue=current, red=failed, gray=pending) |
| **More Details** | Expandable: Transfer ID (copyable), Payment made, Payment method |
| **Download Documents** | Conditional: Invoice (buy) / Sell receipt (sell) — PDF download |
| **Quote Card** | Conditional: Founder quote with signature (delayed/refund states) |
| **Help Row** | "Have a question?" + "Get help" button |
| **Footer** | "Safe and encrypted" or partner logo |

### 4 Header Types

| # | Type | Figma Node | Background | Content | Condition |
|---|------|-----------|-----------|---------|-----------|
| 1 | **Success** | 30444:21096 | Purple gradient | Referral stamp card + share buttons (Copy link, WhatsApp, SMS, More) + carousel dots | Buy/Sell completed |
| 2 | **Delayed** | 30444:24162 | Light gray (#F7F7FA) | Agent avatar + "Taking longer than expected. Escalated to priority." + "Request a callback" CTA + "Your money is safe with us" | Transaction stuck |
| 3 | **Refund In Progress** | 30444:24304 | Light lavender (#EDEDF5) | Purple heart 3D emoji + "Refund in progress" + description (amount, account, ETA) | Purchase failed, refund initiated |
| 4 | **Refund Completed** | 30444:24433 | Light green (#E8F5E9) | Purple heart 3D emoji + "Refund Completed!" + amount credited + carousel dots | Refund finished |

### Transaction Card Variants

| State | Title | Subtitle | Right Image |
|-------|-------|----------|-------------|
| Success (buy) | "2.3g Gold bought" | "Added to locker in 2s" | Gold coin in vault |
| Success (sell) | "2.3g Gold sold" | "Added to locker in 2s" | Gold coin in vault |
| Delayed | "Delayed by" | "ETA by 10 AM IST" | Globe animation |
| Refund In Progress | "Refund to you" | "Expected by 11:00 pm" | Globe animation |
| Refund Completed | "Refund to you" | "Sending to original source" | Green checkmark |

### Status Timeline Steps

| State | Steps |
|-------|-------|
| **Success (sell)** | Sell order in progress → Gold debited from vault → Payout initiated → Funds credited |
| **Success (buy)** | (similar, buy-specific steps) |
| **Delayed (buy)** | Payment secured → Purchasing gold (stuck/current) → Crediting to vault → Gold credited |
| **Refund in progress** | Payment secured ✅ → Gold purchase failed ❌ → Refund initiated 🔵 → Refund Complete ⚪ |
| **Refund completed** | Payment secured ✅ → Gold purchase failed ✅ → Refund initiated ✅ → Refund Complete ✅ |

---

## 2. Existing Remittance Implementation

### iOS (`vance-ios`)

| Aspect | Detail |
|--------|--------|
| **View** | `TransactionDetailsView.swift` (SwiftUI) |
| **ViewModel** | `TransactionDetailsViewModel.swift` |
| **Architecture** | **SDUI (Server-Driven)** — hero section, timeline, CTAs all driven by API response |
| **Hero Section** | `TransactionDetailsHeroSection` model with `TextConfig`, `bgColor`, `textBgColor`, `footerText`, `logo` |
| **Timeline** | `TransactionStepperView.swift` — shared component using `TransferStatusStepper` model with `TransferStateStatus` enum (NEW, ACTIVE, PENDING, COMPLETED, FAILED_INTERMEDIATE, FAILED) |
| **Navigation** | `TransferRoute.transactionDetails(orderId:)` — passes `orderId`, ViewModel fetches via API |
| **Polling** | Recursive `Task.sleep` with `nextApiCallAfterMs` from API response |
| **Data Flow** | API → `Network.TransactionDetails` → `TransactionDetails` domain model → ViewModel → View |

### Android (`vance-android`)

| Aspect | Detail |
|--------|--------|
| **Fragment** | `TransactionDetailsFragment.kt` (XML + DataBinding, **NOT Compose**) |
| **ViewModel** | `TransferDetailsViewModel.kt` |
| **Architecture** | **SDUI (Server-Driven)** — fully API-driven layout |
| **Hero Section** | `HeroSection` model with `ComponentText`, `ComponentColor`, `footerText` |
| **Timeline** | `TransferStatusStepAdapter` + `TransferStatusStepViewHolder` — RecyclerView-based, `Step.Status` enum (NEW, ACTIVE, PENDING, COMPLETED, FAILED_INTERMEDIATE, FAILED) |
| **Navigation** | `Route.TRANSACTION_DETAILS` + `TransactionDetailsParcel(orderId)` |
| **Polling** | `pollTransferDetails()` with 5s default interval, configurable via API `pollingDuration` |
| **Data Flow** | API → `TransferDetailsResponse` → ViewModel → Fragment (DataBinding) |

### Key Insight: Both Platforms Are FULLY SDUI

The remittance Transaction Details screen is **100% server-driven**:
- Header colors, text, icons → from API
- Timeline steps (count, order, content, statuses) → from API
- CTA buttons (title, action, payload) → from API
- Reward blocks, guarantee timers, callback cards → from API
- **No hardcoded states in UI layer** — everything comes from backend JSON

---

## 3. Existing Gold Implementation

### iOS
- **`GoldTransactionDetailView.swift`** — EXISTS but is a **STUB with dummy data**
- Has purple gradient header, carousel (Rating → Referral), transaction card, collapsible details, download docs, help section
- **No API wiring** — all hardcoded
- Route: `GoldRoute.transactionDetail(transactionId:)`

### Android
- **No Gold transaction detail screen exists yet**
- Gold transaction list (`GoldTransactionListScreen.kt`) exists in Compose
- No `Route.GOLD_TRANSACTION_DETAILS` defined
- Gold transaction model has `GoldTransactionStatus`: INITIATED, SUCCESS, FAILED, REFUNDED

---

## 4. Analysis: Reuse vs Build Separate

### Option A: Reuse Remittance Screen

**How**: Backend serves Gold transaction details in the same `TransferDetailsResponse` / `TransactionDetails` format. Gold module just navigates to the existing screen with `orderId`.

| Pros | Cons |
|------|------|
| Zero UI work on both platforms | **Backend dependency** — needs backend team to build Gold-specific response in remittance format |
| Automatic support for all 4 header types (already SDUI) | Gold-specific visuals (vault image, coin, heart emoji) need backend to serve correct assets |
| Polling, error handling, retry all built | **Tight coupling** — Gold tied to remittance screen's evolution |
| Download receipt already works | Android screen is XML Fragment — inconsistent with Gold module (Compose) |
| Timeline stepper battle-tested | Gold may need different bottom sections (no "Send Again", different documents) |
| "Request callback" + "Your money is safe" already built | Rating stars / NPS specific to Gold may not fit remittance template |

### Option B: Build Gold-Specific Screen

**How**: Create new `GoldTransactionDetailView` (iOS) / `GoldTransactionDetailScreen` (Android) native screens in the Gold module.

| Pros | Cons |
|------|------|
| **No backend dependency** for UI — can ship with current API | More UI code to build and maintain |
| Matches Gold module's native approach (SwiftUI / Compose) | Need to implement timeline stepper, polling, error handling |
| Full control over Gold-specific visuals and UX | Duplicates some patterns from remittance |
| Can iterate independently of remittance | Need to handle all 4 header states ourselves |
| Android stays Compose (consistent with Gold module) | |
| Can add Gold-specific features (rating, documents, vault image) easily | |

### Option C: Hybrid — Build Gold Screen, Reuse Shared Components

**How**: Build Gold-specific screens but reuse existing shared components where possible.

| Reuse | Build New |
|-------|-----------|
| iOS: `TransactionStepperView` (timeline) | Gold-specific header (4 types) |
| iOS: `ConfigurableText` (if API serves TextConfig) | Gold transaction card (vault image, coin) |
| Polling pattern (copy from remittance ViewModel) | Download documents section |
| Status enums (`TransferStateStatus`) | Rating/NPS section (success header) |
| | Referral share section (success header) |
| | "Request a callback" section (delayed header) |
| | Refund info section (refund headers) |

---

## 5. Recommendation: **Option C — Hybrid (Build Gold Screen, Reuse Components)**

### Rationale

1. **Backend is not ready** — Gold transaction detail API doesn't exist yet in remittance format. Building SDUI integration means waiting for backend, which blocks M2.

2. **Consistency** — Gold module is 100% native (SwiftUI on iOS, Compose on Android). Remittance Transaction Details is SDUI (iOS: hybrid, Android: XML Fragment). Reusing it would break the pattern.

3. **Android is XML, Gold is Compose** — The remittance screen is a Fragment with XML DataBinding. Gold module is entirely Jetpack Compose. Reusing means navigating from Compose to XML Fragment, which is awkward and inconsistent.

4. **iOS stub already exists** — `GoldTransactionDetailView.swift` is already scaffolded with the right structure. Just needs real data + the 4 header types.

5. **Timeline stepper is reusable (iOS)** — `TransactionStepperView.swift` is a standalone component that takes `TransferStatusStepper` model. Gold can use it directly.

6. **Gold has unique needs** — Rating/NPS stars, referral share, vault/coin images, sell receipt vs invoice — these are Gold-specific and don't exist in remittance.

7. **Decoupled evolution** — Gold can iterate on its transaction detail independently without affecting remittance (a critical, battle-tested flow).

### What to Reuse

| Component | iOS | Android |
|-----------|-----|---------|
| **Timeline Stepper** | `TransactionStepperView` (use directly) | Build Compose equivalent (remittance is XML) |
| **Status Enums** | `TransferStateStatus` (NEW, ACTIVE, PENDING, COMPLETED, FAILED_INTERMEDIATE, FAILED) | Same enum pattern |
| **Polling Pattern** | Copy from `TransactionDetailsViewModel` | Copy from `TransferDetailsViewModel` |
| **Help/Support Row** | Build (simple row) | Build (simple row) |
| **Download Documents** | Already stubbed in Gold detail view | Build in Compose |

### What to Build New

| Component | Description |
|-----------|-------------|
| **Header (4 types)** | Enum-driven: Success (purple + referral), Delayed (gray + callback), Refund In Progress (lavender + info), Refund Completed (green + confirmation) |
| **Transaction Card** | Gray card with title, subtitle, amount, right-side image (vault/globe/checkmark) |
| **Rating/NPS** | Star rating + submit (success state only) |
| **Referral Share** | Stamp card + share buttons (success state only) |
| **Callback Request** | Agent avatar + "Request a callback" CTA (delayed state only) |
| **More Details (expandable)** | Transfer ID, Payment made, Payment method |

### Estimated Scope

| Platform | Files | Complexity |
|----------|-------|-----------|
| **iOS** | Update existing `GoldTransactionDetailView.swift` + ViewModel. Add header enum + 4 header subviews. Wire API. | Medium — stub exists, timeline reusable |
| **Android** | New `GoldTransactionDetailScreen.kt` + ViewModel + Feature (MVI). Build Compose timeline stepper. Wire API. | Medium-High — no stub, timeline needs Compose build |

---

## 6. Figma Node Reference

| Element | Node ID |
|---------|---------|
| Main screen (sell success) | 30444:21456 |
| Full screen — buy success | 30444:21094 |
| Full screen — delayed | 30444:24157 |
| Full screen — refund in progress | 30444:24299 |
| Full screen — refund completed | 30444:24428 |
| Header Type 1 — Success | 30444:21096 |
| Header Type 2 — Delayed | 30444:24162 |
| Header Type 3 — Refund In Progress | 30444:24304 |
| Header Type 4 — Refund Completed | 30444:24433 |

---

## 7. Open Questions

1. **Gold Transaction Detail API** — Does backend plan to serve Gold details in the same format as remittance (`TransferDetailsResponse`)? If yes, Option A becomes viable later.
2. **Rating/NPS** — Is the star rating component reusable from elsewhere in the app, or Gold-specific?
3. **Referral share** — Is the referral stamp card + share buttons a shared component or needs building?
4. **"Request a callback"** — Is `OutboundCallBottomSheetCoordinator` (iOS) / `PlusCallbackNotificationCard` (Android) reusable for Gold?
5. **Timeline steps** — Will Gold steps come from backend or be defined client-side based on `GoldTransactionStatus`?
6. **Document download** — API for Gold invoice/receipt download — exists?
