# Gold Module: Why We Should NOT Reuse ReviewTransfer Screen

**Date:** 2026-03-18
**Author:** Team
**Context:** Tech lead suggested reusing the existing ReviewTransfer (remittance) screen for Gold buy/sell review flows

---

## TL;DR

The existing ReviewTransfer screen is a **1,400-line (Android) / 2,700-line (iOS) monolith** built for remittance with 5+ payment SDK integrations. Gold review screens are **~300 lines each**, already built, tested, and use a completely different API + data model. Merging them would increase complexity without saving code. **Instead, we should extract only the shared WebView component.**

---

## 1. Size & Complexity Comparison

| Metric | ReviewTransfer (Remittance) | Gold Buy Review | Gold Sell Review |
|--------|---------------------------|-----------------|------------------|
| **Android LOC** | 1,377 lines (Fragment+XML) | 492 lines (Compose) | 333 lines (Compose) |
| **iOS View LOC** | 1,126 lines | 228 lines | 391 lines |
| **iOS ViewModel LOC** | 1,577 lines | 216 lines | 264 lines |
| **Total per platform** | ~2,900 lines | ~700 lines | ~600 lines |
| **Architecture** | Fragment+XML (Android), Massive MVVM (iOS) | Jetpack Compose + MVI | Jetpack Compose + MVI |

Gold screens are **4-5x smaller** because they do one thing well.

---

## 2. Completely Different API Flows

### Remittance Flow
```
Quote (POST /appserver/quote/{from}/{to})
  → Order (POST /appserver/v3/order)
    → PaymentController routes to SDK (GPay / Plaid / Checkout.com / TrueLayer / Lean)
      → Poll payment status
```

### Gold Buy Flow
```
Create Cart (POST /wealth/v1/digital-metal/cart/create)
  → Cart Summary (GET /wealth/v1/digital-metal/cart/summary)
    → Initiate Order (POST /wealth/v1/digital-metal/order/initiate)
      → Payment URL → WebView
        → Poll Order Status (GET /wealth/v1/digital-metal/order/status)
```

### Gold Sell Flow
```
Create Cart (mode=SELL)
  → Cart Summary (paymentMode=bank)
    → User selects bank account
      → Initiate Order
        → Poll Order Status (direct payout, no WebView)
```

**Zero shared API endpoints. Zero shared data models.**

---

## 3. Different Payment Methods

| | ReviewTransfer | Gold Buy | Gold Sell |
|---|---|---|---|
| Google Pay | Yes | No | No |
| Checkout.com (Cards/3DS) | Yes | No | No |
| Plaid (Bank Linking) | Yes | No | No |
| TrueLayer (Open Banking) | Yes | No | No |
| Lean Tech | Yes | No | No |
| UAE Manual Transfer | Yes | No | No |
| **Payment URL WebView** | **No** | **Yes** | No |
| **Direct Bank Payout** | No | No | **Yes** |

ReviewTransfer orchestrates **6 payment methods** via PaymentController.
Gold Buy uses **1 method** (WebView URL). Gold Sell uses **bank payout** (no payment gateway at all).

---

## 4. Different UI Layouts

### ReviewTransfer Shows:
- Recipient name & details
- Exchange rate (FX conversion)
- Delivery time estimate
- Transfer fees breakdown
- Payment method picker (cards, banks, wallets)
- KYC status checks
- Firebase promotional banners
- Promo code input

### Gold Buy Review Shows:
- "You're buying" amount card
- Live price rate pill (1gm = AED XXX)
- Price lock countdown timer
- Fee breakdown (platform fee, GST)
- Total payable
- Single "Pay" CTA → WebView

### Gold Sell Review Shows:
- "You're selling" amount card
- Live price rate pill
- Price lock countdown timer
- Fee breakdown
- Payout amount to bank
- Bank account selector
- Retention nudge (for long-term users)
- "Confirm Sell" CTA

**No shared UI sections between remittance and Gold.**

---

## 5. What Happens If We Force-Merge Them

### The problems:
1. **if/else explosion** — Every section needs `if (isGold) { ... } else { ... }`. The 1,400-line file becomes 2,000+ lines.
2. **Two data models in one screen** — Need to support both `CreateQuoteResponse` AND `CartSummary` in the same ViewModel. Abstraction layer adds complexity.
3. **Payment routing mess** — ReviewTransfer uses PaymentController (6 methods). Gold uses WebView URL. Merging means Gold inherits all PaymentController dependencies it doesn't need.
4. **Regression risk** — Any change to remittance review could break Gold, and vice versa. Two teams stepping on each other.
5. **Testing complexity** — Currently Gold has clean, focused MVI feature tests. Merging means every test needs remittance context setup even when testing Gold.
6. **Architecture mismatch** — ReviewTransfer is Fragment+XML (Android). Gold is Jetpack Compose. We'd either rewrite ReviewTransfer to Compose (massive scope) or write Gold in XML (going backwards).

### Time estimate:
- Merging Gold into ReviewTransfer: **~2-3 weeks** (refactoring, abstracting, testing)
- Current Gold screens already built and working: **0 additional time**

---

## 6. What We SHOULD Reuse (Smart Approach)

Instead of merging entire screens, extract these **small, shared utilities**:

| Component | What It Does | Effort |
|---|---|---|
| **PaymentWebView** | Load payment URL + detect success via JS injection | ~1 day (already exists in Gold, can be promoted to shared) |
| **OrderStatusPoller** | Generic poll-until-terminal-state utility | ~0.5 day |
| **Price Lock Countdown** | Timer that counts down from lock expiry | ~0.5 day |

This gives us **shared infrastructure** without coupling unrelated business flows.

---

## 7. Summary

| Question | Answer |
|---|---|
| Do they share API endpoints? | No |
| Do they share data models? | No |
| Do they share payment methods? | No |
| Do they share UI layout? | No |
| Are Gold screens already built? | Yes (both platforms, tested) |
| Would merging save code? | No (adds abstraction overhead) |
| Would merging save time? | No (2-3 weeks to merge vs 0 for current) |
| What should we share? | WebView component + polling utility only |

**Recommendation:** Keep Gold review screens separate. Extract shared WebView and polling utilities into common modules that both flows can use independently.

---

## 8. Bank Selection & Account Details — Same Conclusion

Tech lead also asked about reusing remittance bank/beneficiary screens for Gold sell flow. Same answer: **Gold already has its own, remittance ones are NOT reusable.**

### What Gold Module Already Has

| Screen | Android | iOS | Status |
|--------|---------|-----|--------|
| **Select Bank** (list + search + status badges) | `SelectBankScreen.kt` (240 lines) | `SelectBankView.swift` (207 lines) | Built |
| **Account Details** (IBAN input + verification) | `AccountDetailsScreen.kt` (199 lines) | -- | Android only |
| **Use Cases** (fetch/create beneficiary) | `FetchBeneficiaryAccountsUseCase` + `CreateBeneficiaryAccountUseCase` | Same pattern | Built |

### Existing Remittance Bank Screens — Why NOT Reusable

| Screen | Platform | Lines | Why NOT |
|--------|----------|-------|---------|
| `SelectBankForAccountLinkingFragment` | Android | 176 | XML-based, tied to Lean SDK account linking |
| `BeneficiaryAccountDetailsFragment` | Android | 288 | View/edit existing beneficiary, not IBAN input |
| `AddBankDetailsView` + ViewModel | iOS | 544 | Old SwiftUI pattern, IFSC/Razorpay specific |

**Key reasons:**
1. **Architecture mismatch** — remittance is XML/old SwiftUI, Gold is Compose+MVI / modern SwiftUI
2. **SDK coupling** — remittance bank screens tied to Lean SDK, Razorpay IFSC validation
3. **Different purpose** — remittance = link bank for payment; Gold = select bank for sell payout
4. **Gold screens already built** — merging adds complexity for zero benefit

### Remaining Bank Screen Work

| Task | Android | iOS |
|------|---------|-----|
| Account Details screen (IBAN input) | Built | **NOT built — needs implementation** |
| Verification flow ("Fetching account details...") | Not built | Not built |
| Wire bank list API | Mock data | Mock data |
| Wire beneficiary API (fetch/create) | Placeholder | Placeholder |
| Wire account verification API (test deposit) | Placeholder | Placeholder |

---

*Generated for internal architecture discussion — Gold Module M2*
