---
name: Payment Method Selection & Sell Bank Flow Plan
description: Plan for buy flow payment method bottom sheet + sell flow IBAN Figma alignment
type: project
---

# Payment Method Selection & Sell Bank IBAN Flow

## Figma References
- **Buy — Select Payment Method bottom sheet**: Node 58-17669 (user screenshot provided)
- **Sell — Share UAE bank IBAN**: Node 55-14905 (user screenshot provided)
- **Sell — Fetching account details overlay**: Node 55-14964 (user screenshot provided)

---

## Task 3: Sell IBAN Screen — Figma Gap Analysis (PRIORITY)

### Figma 55-14905 vs Current Code

| # | Element | Figma | iOS Current | Android Current | Fix |
|---|---------|-------|-------------|-----------------|-----|
| 1 | **Help icon (?)** | Circle icon top-right | ❌ Missing | ❌ Missing | Add help icon next to back arrow |
| 2 | **Price lock pill** | "Price locked at AED 592.25/g for 2:59" below nav | ❌ Missing | ❌ Missing | Pass price lock data from review → IBAN screen, add pill |
| 3 | **Title** | "Share your UAE bank IBAN" (H1 bold) | ❌ Uses "Account details" | ❌ Uses "Account details" | Update string resource |
| 4 | **Input placeholder** | "IBAN Number" | ❌ Uses "Bank account number" | ❌ Uses "Bank account number" | Update string resource |
| 5 | **Orange cursor** | Orange vertical bar (2×20) | ✅ Has it | ❌ Missing (uses Material TextField) | Add custom cursor indicator on Android |
| 6 | **Scan icon** | Red/orange QR scan icon (right side) | ✅ Has it | ❌ Missing | Add scan icon on Android |
| 7 | **Test deposit note** | ❌ NOT shown in Figma for sell IBAN | ❌ Shows "test deposit of ₹1" | ❌ Shows test deposit note | Remove or hide for sell flow |
| 8 | **Auto-fetch banner** | Purple icon + "Auto-fetch details from a text or image?" | ✅ Has it | ✅ Has it (emoji icon) | Android: replace emoji with proper icon |
| 9 | **CTA text** | "Verify Bank Account" (disabled: light lavender) | ❌ "Continue" | ❌ "Continue" | Update string resource |
| 10 | **CTA style** | Rounded purple button, disabled = lavender | ✅ AsporaButton | ❌ Custom Box button | Android: use PlusButtonLarge |
| 11 | **Numpad** | Custom T9 numpad (digits + ABC sub-labels) | ✅ Custom numpad | ❌ System keyboard | Android: add custom numpad composable |
| 12 | **Background** | Light gray (#F7F7FA) | ✅ fillsSurfaceGray7 | ❌ fillsSurfaceWhite | Android: fix background |

### Figma 55-14964 — Verification Overlay
| # | Element | Figma | iOS | Android | Fix |
|---|---------|-------|-----|---------|-----|
| 1 | **Price lock pill** | Shown on overlay too | ❌ Not on overlay | ❌ Not on overlay | Add pill above verification content |
| 2 | **Card layout** | Green tinted card with "Fetching account details..." + IBAN below | ❌ Simple centered spinner | ❌ Simple centered spinner | Redesign overlay to match card layout |
| 3 | **IBAN display** | Shows "IBAN 7923 7937 3891" | ❌ Not shown | ❌ Not shown | Show masked IBAN in overlay |
| 4 | **Step text** | "Verifying account number..." (green text) | ✅ Step text exists | ✅ Step text exists | Update styling to green |
| 5 | **Back arrow** | Present on overlay | ❌ No back on overlay | ❌ No back on overlay | Add back nav on overlay |

---

## iOS Changes (AccountDetailsView.swift)

### 1. Add help icon to top bar
```swift
HStack {
    Button(action: { router.tabRouter?.path.removeLast() }) { /* back */ }
    Spacer()
    Button(action: { router.showHelp() }) {
        Image(systemName: "questionmark.circle")
            .font(.system(size: 24))
            .foregroundColor(theme.p91Colors.text.base600)
    }
}
```

### 2. Add price lock pill (pass data via init)
- Add `priceLockText: String?` and `priceLockTime: String?` params
- Render `GoldPriceLockPill` below nav bar (reuse existing component)

### 3. Update strings
- Title: "Share your UAE bank IBAN" (new string key)
- Placeholder: "IBAN Number" (new string key)
- CTA: "Verify Bank Account" (new string key)

### 4. Remove test deposit note
- Remove or conditionally hide the "test deposit" text for sell flow

### 5. Redesign verification overlay (Figma 55-14964)
- Add back arrow + price lock pill
- Green-tinted card with "Fetching account details..." title
- Show masked IBAN: "IBAN XXXX XXXX XXXX"
- Green "Verifying account number..." step text

---

## Android Changes (AccountDetailsScreen.kt)

### 1. Add help icon to top bar
### 2. Add price lock pill (pass via Feature.State)
### 3. Update strings
### 4. Remove test deposit note
### 5. Add orange cursor indicator + scan icon to input
### 6. Fix CTA: use PlusButtonLarge
### 7. Add custom numpad composable (match iOS)
### 8. Fix background: fillsSurfaceGray7 (#F7F7FA)
### 9. Fix auto-fetch banner icon (emoji → proper drawable)
### 10. Redesign verification overlay

---

## Buy Flow — Payment Method Bottom Sheet

### Task 1: iOS (GoldSellBuyReviewView.swift)
1. Add `@Published var showPaymentMethodSheet = false` to ViewModel
2. Wire TODO at line 504 to `showPaymentMethodSheet = true`
3. Add bottom sheet overlay with 4 payment method rows
4. On selection: dismiss sheet, update row display

### Task 2: Android (GoldOrderReviewScreen.kt + Feature.kt)
1. Add `showPaymentMethodSheet` state + events
2. Fix `ChangePaymentMethodClick` to open payment sheet (not bank selector)
3. Add `ModalBottomSheet` composable with 4 rows

---

## Implementation Order
1. **Sell IBAN screen Figma fixes** (both platforms) — biggest gap
2. **Verification overlay redesign** (both platforms)
3. **Buy payment method bottom sheet** (both platforms)

## Files to Modify
### iOS
- `AccountDetailsView.swift` — help icon, pill, title, strings, overlay
- `AccountDetailsViewModel.swift` — pass price lock data
- `GoldSellBuyReviewView.swift` — payment method bottom sheet
- `GoldSellBuyReviewViewModel.swift` — payment method state
- `Localizable.strings` — new string keys

### Android
- `AccountDetailsScreen.kt` — help icon, pill, cursor, scan icon, numpad, CTA, overlay, bg
- `AccountDetailsFeature.kt` — price lock state
- `GoldOrderReviewScreen.kt` — payment method bottom sheet
- `GoldOrderReviewFeature.kt` — payment method events/state
- `strings.xml` — new string keys
