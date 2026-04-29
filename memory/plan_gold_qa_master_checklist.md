---
name: Gold QA Master Checklist
description: Consolidated checklist from QA readiness tracker, Designer S Figma feedback, and QA P0 items — single source of truth for what's done and what's left
type: project
---

# Gold QA Master Checklist

**Sources consolidated:**
1. QA Readiness Tracker (CSV — 50 items from Designer D/QA Lead/Developer)
2. Designer S Figma Feedback (43 items from April 4 review)
3. QA P0 test cases (49 P0 test cases)

**Last updated:** 2026-04-08

---

## DONE (15 items)

| # | Task | Source | Owner |
|---|------|--------|-------|
| 1 | Copies closure | QA Tracker | Designer D — done |
| 2 | Rupee symbol on calculator switch to AED | QA Tracker | Developer — done |
| 3 | P0-1: StandaloneCoroutine crash fix | Designer S | Developer |
| 4 | P0-2: Buy flow → 7-part confirmation animation (Android) | Designer S + QA | Developer |
| 5 | P1-2: Weight unit "gm" → "g" (13 files) | Designer S + QA #21 | Developer |
| 6 | P1-3: Buy confirm amount gradient → black | Designer S | Developer |
| 7 | P1-5: Sell All decimal precision capped at 3 | Designer S | Developer |
| 8 | P1-6: Sell confirm AED amount as primary (not weight) | Designer S | Developer |
| 9 | P1-7: Sell price pill shows actual price (not "---") | Designer S | Developer |
| 10 | P1-8: Sell success animation (Android) | Designer S | Developer |
| 11 | P2-3: "Total Payout" → "Total Receivable" | Designer S | Developer |
| 12 | P2-8: AED amounts comma-grouped | Designer S + QA #42 | Developer |
| 13 | Backend sell null account_holder_name | Blocker | Backend — resolved |
| 14 | paymentMode → paymentInstrument API rename | API | Developer |
| 15 | New endpoints: payment-instruments + invoice-download | API | Developer |

---

## NOT DONE — Client (Developer) — Ready to implement

| # | Task | Source | Platform | Notes |
|---|------|--------|----------|-------|
| 16 | Default to amount mode (not weight) for first purchase | QA #20 + Designer S P0 | Both | Retain preference after first |
| 17 | Buy mode preservation bug (toggling amount/weight changes values) | QA #31 | Both | Video available |
| 18 | Min sell amount = AED 5 (not 2 AED) | QA #39 + Designer S P0 | Both | |
| 19 | Max buy amount = 55,000 (not 5,00,000) | QA #19 | Both | Currently 500K for testing |
| 20 | Decimal places: AED = 2, weight = 5 | QA #26, #27 | Both | |
| 21 | 0.0 should display as "0" (no trailing decimal) | QA #16 | Both | |
| 22 | P1-9: iOS sell success Lottie upgrade | Designer S | iOS | GoldSellSuccessView exists |
| 23 | Confirmation loader Lotties (7-part: money + gold coins + machine) | QA #34 + Designer S P0-2 | iOS | Android done ✅ |
| 24 | Sell flow loader copies (currently shows buy copies) | QA #50 | Both | "securing payment, adding to vault" → sell-specific |
| 25 | Transaction details page — new design | QA #35 | Both | SDUI wiring needed |
| 26 | Transaction details — assets not present | QA #40 | Both | |
| 27 | Transaction details — terminal state blue dot removal | QA #41 | Both | Transient = blue dot, terminal = no dot |
| 28 | Invoice flow doesn't work | QA #36 | Both | Endpoint wired, needs UI integration |
| 29 | "Get help" on transaction details does nothing | QA #37 | Both | |
| 30 | Price lock starts at 3:54 every time | QA #17 | Both | Should start at 5:00 |
| 31 | "Price updated. Locked for 5 min" text should fade after 3s | QA #18 | Both | |
| 32 | Price lock refresh button color mismatch | QA #23 | Both | Should match pill strip color |
| 33 | Order form → confirmation page transition slow (~1s) | QA #29 | Both | |
| 34 | Refreshing price on confirmation threw "UNKNOWN ERROR" | QA #30 | Both | Video available |
| 35 | Remove gold bar illustration from order form | QA #28 | Both | Contradicts Designer S P2-2 — needs alignment |
| 36 | Remove "why buy on aspora" cards from lander | QA #12 | Both | |
| 37 | Vault shows gold despite having 0g | QA #15 | Both | Show empty state |
| 38 | Home page margins off — gap at top | QA #38 | Both | Image available |
| 39 | Skip KYC journey — lander CTA "Buy Gold" until first buy | QA #14 | Both | Then show vault home |
| 40 | "Check remaining gold balance" isn't inside a button | QA #51 | Both | |
| 41 | Remove friction popup from sell flow | QA #44 | Both | Why-selling + retention sheets |
| 42 | IBAN keyboard covers CTA after help section | QA #46 | iOS | |
| 43 | Apple glass effect on popups | QA #49 | iOS | Use standard sheet style |
| 44 | Calculator not compounding returns | QA #7 | iOS | |
| 45 | Gold returns on calculator not following true value | QA #10 | Both | |
| 46 | Investment amount in calculator goes into two lines | QA #11 | Both | "AED" and number in separate rows — photo |
| 47 | 24x7 Aspora guide redirects to FAQs | QA #13 | Both | |
| 48 | Fix Figma comments | QA #32 | Both | |
| 49 | Instrumentation (analytics events) | QA #3 | Both | |
| 50 | Lander gold bar asset | QA #4 | Both | |
| 51 | Vault home page assets | QA #5 | Both | |
| 52 | Update lander trust markers copies | QA #8 | Both | |

---

## NOT DONE — Needs Designer S/Design Alignment

| # | Task | Source | Notes |
|---|------|--------|-------|
| 53 | Spacing audit across all screens | Designer S P0 | Needs walkthrough |
| 54 | Color audit across all screens | Designer S P0 | Needs walkthrough |
| ~~55~~ | ~~Gold bar illustration on buy entry~~ | ~~Designer S P2-2~~ | **RESOLVED — REMOVE** (moved to client-ready #35) |
| 56 | Aspora loader animation | Designer S P1 | Need asset |
| 57 | Vault redesign | Designer S P2 | Future |
| 58 | Sell processing animation alignment | Designer S P3 | |
| 59 | Transaction confirmation Lotties | QA #6 | Need final assets from Designer S |

---

## NOT DONE — Needs Backend (QA Lead)

| # | Task | Source | Owner | Notes |
|---|------|--------|-------|-------|
| 60 | Remove "xyz people bought gold in past 24 hours" | QA #22 | QA Lead | Backend removal |
| 61 | Popular weights: 0.1g, 1g, 5g, 20g (popular on 1g) | QA #24 | QA Lead | Backend config |
| 62 | Popular amounts: 100, 500, 2000, 5000 (popular on 500) | QA #25 | QA Lead | Backend config |
| 63 | "Cart not found and expired" on back from webview | QA #33 | QA Lead | Cart lifecycle |
| 64 | Remove "payouts usually arrive in 5 min" from sell | QA #43 | QA Lead | Backend copy |
| 65 | IBAN auto-fetch not working | QA #45 | QA Lead | API not on staging? |
| 66 | Are we running IBAN API on staging? | QA #47 | QA Lead | |
| 67 | Apple Pay not allowed in buy flow? | QA #48 | QA Lead | Payment instruments config |
| 68 | Profit nudge card — backend profit-per-gram data | Designer S P1-4 | QA Lead | |
| 69 | Strikeout price | Designer S P2 | QA Lead | Needs pricing endpoint |

---

## NOT DONE — P2/Future (not blocking QA)

| # | Task | Source | Notes |
|---|------|--------|-------|
| 70 | IBAN caching | Designer S P2 | |
| 71 | IBAN screen price pill | Designer S P2-6 | |
| 72 | Bank list overflow handling | Designer S P2-7 | |
| 73 | SIP/Coins screens | Future | Placeholders exist |
| 74 | Gold certificate download | Future | |
| 75 | AML checkpoints | Future | Enable once backend deploys SumSub |

---

## Summary

| Category | Count |
|----------|-------|
| **Done** | 15 |
| **Client — ready to implement** | 37 |
| **Needs design alignment** | 7 |
| **Needs backend** | 10 |
| **P2/Future** | 6 |
| **TOTAL** | 75 |

## Conflicts / Decisions Needed

1. ~~**Gold bar illustration**~~: RESOLVED — REMOVE it from buy entry (QA #28 wins over Designer S P2-2)
2. ~~**Max buy amount**~~: RESOLVED — Revert 500K → 55K before QA drop
3. ~~**Friction popup in sell**~~: RESOLVED — Remove on Android for now (why-selling + retention sheets). iOS keep as-is.
