---
name: Designer S Design Feedback — Gold M2
description: 110+ design issues from Designer S's April 4 2026 review of Gold buy/sell flows across iOS and Android
type: project
---

# Designer S Design Feedback — Gold M2 Buy/Sell Flows

**Source**: Figma Gold Master, node `803:12512` (section "April 4, 2026")
**Reviewed**: ~40 side-by-side screenshots (iOS left, Android right)
**Date extracted**: 2026-04-06

---

## Summary

Designer S documented the current state of both platforms by placing side-by-side iOS vs Android screenshots in Figma. The issues are the **visual and functional differences** between the two implementations. iOS is generally closer to the Figma design spec; Android has several gaps.

### Severity Classification
- **P0 (Critical Bug)**: Crashes, error toasts, broken flows
- **P1 (Major Gap)**: Missing features, wrong screen states
- **P2 (Visual Polish)**: Typography, spacing, color, formatting differences
- **P3 (Minor)**: Inconsistencies that don't affect functionality

---

## P0 — Critical Bugs (Fix Immediately)

### ~~P0-1: Android — "StandaloneCoroutine was cancelled" error (BUY flow)~~ ✅ RESOLVED
- **Figma nodes**: `778:17089`, `802:12505`
- **Status**: Fixed — no longer reproducing after develop merge fixes (2026-04-06)

### P0-2: Android — Buy flow not navigating to success animation
- **Figma nodes**: `778:17087`, `778:17088`, `778:17089`
- **Screen**: After Checkout payment completes
- **Issue**: iOS shows gold coins success animation → transaction details. Android stays on Checkout WebView payment amount page or shows blank screen with coroutine error.
- **Platform**: Android only
- **Root cause**: Payment completion callback not properly triggering navigation to success screen
- **Fix**: Fix Checkout payment result handling → navigate to success animation → poll order status

---

## P1 — Major Gaps (Must Fix Before Release)

### P1-1: Android — Missing gold bar emoji/illustration on Buy entry screen
- **Figma node**: `778:17078`
- **Screen**: Buy Gold entry (0g state)
- **Issue**: iOS shows gold bar 🪙 illustration between amount and preset chips. Android has empty space.
- **Platform**: Android
- **Fix**: Add gold bar illustration to buy entry screen between amount display and preset chips

### ~~P1-2: Android — Weight unit inconsistency ("gm" vs "g")~~ ✅ RESOLVED
- **Figma nodes**: `778:17081`, `778:17098`, `778:17105`
- **Screen**: Confirm Purchase, Confirm Sell, Review screens
- **Issue**: Android shows "gm" (e.g., "5 gm × AED 566.83/gm", "22.867 gm"). iOS shows "g" (e.g., "5g × AED 566.83/g"). Figma design uses "g".
- **Platform**: Android
- **Fix**: Change all "gm" occurrences to "g" across buy/sell review screens

### ~~P1-3: Android — Confirm Purchase amount color~~ ✅ RESOLVED
- **Figma node**: `778:17081`
- **Screen**: Confirm Purchase (Buy Review)
- **Issue**: Android shows amount "AED 2,834.15" in gradient purple text. iOS shows it in black. Figma design uses black.
- **Platform**: Android
- **Status**: Fixed — buy amount now uses black text (commit `d7597f6e37`)

### P1-4: Android — Missing profit nudge on sell
- **Figma node**: `778:17097`
- **Screen**: Sell Gold entry, when user has profits
- **Issue**: iOS shows "You've earned AED 800.00 profit per gram so far — Selling now ends your compounding streak" nudge card with illustration. Android doesn't show this.
- **Platform**: Android
- **Fix**: Implement profit nudge card on sell entry screen (backend may need to provide profit data)

### ~~P1-5: Android — Sell "Sell All" shows excessive decimal precision~~ ✅ RESOLVED
- **Figma node**: `778:17096`
- **Screen**: Sell Gold entry with Sell All
- **Issue**: Android shows "114.33694 g" (5+ decimal places). Should cap at 3 decimal places max.
- **Platform**: Android
- **Status**: Fixed — 100% preset capped with `.setScale(3, RoundingMode.DOWN)` (commit `b2539b330b`)

### ~~P1-6: Android — Sell confirm shows weight instead of amount as primary~~ ✅ RESOLVED
- **Figma nodes**: `778:17100`, `778:17101`, `778:17105`
- **Screen**: Confirm Sell
- **Issue**: Android shows "22.867 gm" as primary heading (weight-focused). iOS shows "AED 10,481.25" as primary (amount-focused).
- **Platform**: Android
- **Status**: Fixed — sell review now shows AED amount large, weight as subtitle (commit `eefaa0e935`)

### ~~P1-7: Android — Sell confirm price pill shows "---" for price~~ ✅ RESOLVED
- **Figma node**: `778:17100`
- **Screen**: Confirm Sell
- **Issue**: Android price lock pill shows "Price locked at --- for 03:38" (missing price value).
- **Platform**: Android
- **Status**: Fixed — derive pricePerGram from amount/weight in initSell() (commit `cd42cbaed1`)

### P1-8: Android — Missing sell success animation
- **Figma node**: `778:17106`
- **Screen**: After sell swipe
- **Issue**: iOS shows green bracelet/ring animation during sell processing. Android stays on Confirm Sell with loading state.
- **Platform**: Android
- **Fix**: Add sell processing/success animation (Lottie)

### P1-9: iOS — Sell success screen missing
- **Figma node**: `778:17107`
- **Screen**: After sell completes
- **Issue**: Android shows "Gold Sold Successfully" screen with payout summary + "View my Vault" + "View Details" buttons. iOS only shows animation without a summary screen.
- **Platform**: iOS
- **Fix**: Add sell success summary screen matching Android's implementation (or match Figma spec)

### P1-10: Android — Transaction history showing home screen
- **Figma node**: `778:17110`
- **Screen**: Transaction history / "View all" from lander
- **Issue**: iOS shows "Recent transactions" full list. Android screenshot shows home screen instead of Gold transaction history.
- **Platform**: Android
- **Fix**: Verify "View all" from lander navigates to Gold transaction history screen (may be a recording artifact)

---

## P2 — Visual Polish

### P2-1: Android — Confirm Purchase amount formatting
- **Figma node**: `778:17081`
- **Screen**: Confirm Purchase (Buy)
- **Issue**: Android "AED" prefix is in gradient purple. iOS has it in gray "You're buying" label with black amount.
- **Platform**: Android
- **Fix**: Match iOS styling — gray "You're buying" label, black amount

### P2-2: Android — Buy Gold entry missing gold bar area
- **Figma node**: `778:17078`
- **Screen**: Buy Gold entry
- **Issue**: iOS has a cream/beige background area with gold bar illustration between the amount display and preset chips. Android has a flat white background.
- **Platform**: Android
- **Fix**: Add cream/beige background section with gold bar illustration

### ~~P2-3: Android — Confirm Sell "Total Payout" label capitalization~~ ✅ RESOLVED
- **Figma node**: `778:17105`
- **Screen**: Confirm Sell
- **Issue**: Android shows "Total Payout:" (title case). Figma uses "Total Receivable".
- **Platform**: Android
- **Status**: Fixed — string changed to "Total Receivable" (commit `c400d8decb`)

### P2-4: Android — Sell entry missing minimum sell amount warning styling
- **Figma node**: `778:17094`
- **Screen**: Sell Gold entry (1g — below minimum)
- **Issue**: iOS shows clear red warning "⊘ Minimum sell amount: 5" with red text. Need to verify Android shows same.
- **Platform**: Both — verify consistency
- **Fix**: Ensure minimum sell amount error uses red styling with warning icon

### P2-5: Android — Sell entry "Your total gold value" formatting
- **Figma node**: `778:17096`
- **Screen**: Sell Gold entry
- **Issue**: Android shows "Your total gold value: AED 62,199.30" correctly. iOS shows same. Good match — but verify comma formatting consistency with AED amounts across all screens.
- **Platform**: Both — verify
- **Fix**: Audit comma formatting in all AED amounts

### P2-6: Android — IBAN screen missing price lock pill
- **Figma node**: `778:17103`
- **Screen**: Share your UAE bank IBAN
- **Issue**: iOS shows price lock pill at top. Android IBAN screen doesn't show it.
- **Platform**: Android
- **Fix**: Add price lock pill to IBAN entry screen header

### P2-7: Android — Bank account list overflow
- **Figma node**: `778:17102`
- **Screen**: Select Account (sell flow, bank selection)
- **Issue**: Android shows very long scrollable list of "Emirates NBD" accounts (12+). Looks like test data issue but UX should handle long lists gracefully.
- **Platform**: Android
- **Fix**: Consider max visible items + scroll indicator, or paginate

### ~~P2-8: Android — Amount formatting without comma on Sell entry~~ ✅ RESOLVED
- **Figma node**: `778:17097`
- **Screen**: Sell Gold entry
- **Issue**: Android shows "AED 62199.30" (no comma). Should use comma grouping.
- **Platform**: Android
- **Status**: Fixed — equivalentDisplay and formattedBalance use GoldFormatter.formatCurrency() (commit `bc7fd47054`)

---

## P3 — Minor Issues

### P3-1: Android — Gold lander "Setup gold SIPs" section
- **Figma node**: `778:17077`
- **Screen**: Gold Lander (existing user)
- **Issue**: Android shows "Setup gold SIPs" section below buttons. iOS doesn't show this yet. This is a placeholder — fine for now.
- **Platform**: Android
- **Fix**: None — intentional placeholder

### P3-2: Android/iOS — Sell processing animation differences
- **Figma nodes**: `778:17106`, `778:17107`
- **Screen**: Sell processing
- **Issue**: iOS shows green ring animation. Android shows different success screen layout. Both work but look different.
- **Platform**: Both
- **Fix**: Align on final design for sell success/processing screens

### P3-3: Transaction Details — date formatting
- **Figma nodes**: `778:17091`, `778:17109`
- **Screen**: Transaction Details
- **Issue**: Android shows "Expected by (date)" as placeholder instead of actual date. iOS shows "Expected by 04 Apr 2026".
- **Platform**: Android
- **Fix**: Parse and format expected date from API response

---

## Implementation Plan

### Phase 1: P0 Fixes (Blockers)
1. **Android**: Fix StandaloneCoroutine cancellation error in buy flow
2. **Android**: Fix buy payment completion → success animation → transaction details navigation

### Phase 2: P1 Fixes (Must-have)
3. **Android**: Change weight unit "gm" → "g" everywhere
4. **Android**: Fix Confirm Purchase amount color (gradient purple → black)
5. **Android**: Fix sell weight decimal precision (cap at 3)
6. **Android**: Fix Confirm Sell primary display (amount, not weight)
7. **Android**: Fix sell confirm price pill showing "---"
8. **Android**: Add profit nudge card on sell entry
9. **Android**: Add sell success/processing animation
10. **iOS**: Add sell success summary screen
11. **Android**: Verify transaction history navigation from "View all"

### Phase 3: P2 Polish
12. **Android**: Add gold bar illustration to buy entry
13. **Android**: Fix "Total Payout" → "Total Receivable" label
14. **Android**: Add price lock pill to IBAN screen
15. **Android**: Fix AED amount comma formatting
16. **Android**: Fix Transaction Details expected date placeholder

### Files to Modify

**Android (estimate ~15 files)**:
- `ui/gold/buy/entry/` — gold bar illustration, amount formatting
- `ui/gold/buy/review/` — amount color, weight unit
- `ui/gold/buy/` — payment result handling, success animation
- `ui/gold/sell/entry/` — profit nudge, decimal precision, weight unit
- `ui/gold/sell/review/` — primary display swap, price pill, labels
- `ui/gold/sell/` — success animation
- `ui/gold/common/` — amount formatting utilities
- `ui/gold/transaction/` — date formatting

**iOS (estimate ~3 files)**:
- `Gold/Views/Sell/` — sell success summary screen
- `Gold/Components/` — any shared fixes

### NOT in Scope (Separate Tickets)
- SIP/Coins screens (placeholder — separate feature)
- Sell "Mind sharing why you're selling?" survey (already implemented on Android)
- Home screen differences (not Gold-specific)
- CI build failures (FragmentMainBinding — not Gold-related)
