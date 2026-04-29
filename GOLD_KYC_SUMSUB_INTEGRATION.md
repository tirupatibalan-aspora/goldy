# Gold Module — SumSub KYC Integration

## Overview

The Gold module requires identity verification (KYC) before users can buy or sell gold. This document covers the end-to-end SumSub KYC integration wired into the Gold buy flow on both iOS and Android, what the backend needs to support, and all edge cases.

> **Key distinction**: Gold KYC is separate from Remittance KYC. A user may be KYC-verified for remittance but still need verification for wealth/gold products. The backend must serve a **Gold-specific KYC workflow** when the SDUI KYC endpoint is called for a Gold user.

---

## Architecture

### Current Flow (Client-Side — Implemented)

```
┌─────────────────────────────────────────────────────────────────┐
│  User taps "Get Started" on Gold Lander                         │
│       │                                                         │
│       ▼                                                         │
│  portfolio.needsKYC == true?                                    │
│       │ YES                        │ NO                         │
│       ▼                            ▼                            │
│  Show KYC Bottom Sheet      Navigate to Buy Flow                │
│       │                                                         │
│       ▼                                                         │
│  User taps "Continue to KYC"                                    │
│       │                                                         │
│       ▼                                                         │
│  POST /wealth/v1/digital-metal/onboarding/onboard               │
│       │                                                         │
│       ├── 200 OK ──────────────────────────────────┐            │
│       │                                            ▼            │
│       │                                   Navigate to SDUI      │
│       │                                   KYC Workflow           │
│       │                                   (SumSub SDK)          │
│       │                                            │            │
│       │                                            ▼            │
│       │                                   User completes        │
│       │                                   identity verification │
│       │                                            │            │
│       │                                            ▼            │
│       │                                   Returns to Gold       │
│       │                                   Lander                │
│       │                                            │            │
│       │                                            ▼            │
│       │                                   Portfolio polling     │
│       │                                   refreshes status      │
│       │                                            │            │
│       │                                            ▼            │
│       │                                   needsKYC = false      │
│       │                                   User can buy gold     │
│       │                                                         │
│       ├── 409 Conflict (already onboarded) ──► Same as 200     │
│       │                                                         │
│       └── Error ──────────────────────────► Show error toast    │
│                                              User stays on      │
│                                              bottom sheet       │
└─────────────────────────────────────────────────────────────────┘
```

### SDUI KYC Workflow (Existing Infrastructure)

Both platforms use a **Server-Driven UI (SDUI)** framework to render the KYC verification flow. The client fetches a workflow from the backend, which returns screens containing SDK payloads (SumSub access tokens). The client then launches the SumSub SDK with these tokens.

```
Client                         Backend                      SumSub
  │                              │                            │
  │  GET /workflow/v2/kyc        │                            │
  │─────────────────────────────►│                            │
  │                              │  Create applicant          │
  │                              │───────────────────────────►│
  │                              │  ◄── Access token ─────────│
  │  ◄── SDUI workflow ──────────│                            │
  │  (contains SumSub token)     │                            │
  │                              │                            │
  │  Launch SumSub SDK ─────────────────────────────────────►│
  │  (token from workflow)       │                            │
  │                              │                            │
  │  ◄── SDK callbacks ──────────────────────────────────────│
  │  (complete/submit/cancel)    │                            │
  │                              │                            │
  │  Trigger SDUI actions ──────►│                            │
  │  (onComplete/onSubmit)       │  Webhook: status update    │
  │                              │◄───────────────────────────│
  │                              │  Update portfolio status   │
  │                              │                            │
  │  GET /portfolio ────────────►│                            │
  │  ◄── onboarding_status:     │                            │
  │      ONBOARDED               │                            │
```

---

## API Endpoints

### 1. Gold Onboarding — `POST /wealth/v1/digital-metal/onboarding/onboard`

Registers the user's intent to use Gold. Must be called before KYC to create the Gold account.

| Field | Value |
|-------|-------|
| **Method** | `POST` |
| **Path** | `/wealth/v1/digital-metal/onboarding/onboard` |
| **Body** | Empty (no JSON body) |
| **Auth** | Bearer token (standard auth) |

#### Required Headers

| Header | Description | Example |
|--------|-------------|---------|
| `X-User-Id` | Authenticated user's ID | `"usr_abc123"` |
| `X-Country` | Market/region code | `"AE"` |

#### Response — `200 OK`

```json
{
  "user_id": "usr_abc123",
  "status": "KYC_REQUIRED",
  "ext_user_id": "safegold_ext_456",
  "kyc_product": "WEALTH",
  "kyc_provider": "SUMSUB",
  "kyc_status": "NOT_STARTED"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | `string?` | Vance user ID |
| `status` | `string?` | Onboarding status: `KYC_REQUIRED`, `ONBOARDED`, `BYPASSED`, `FAILED` |
| `ext_user_id` | `string?` | External partner (SafeGold) user ID |
| `kyc_product` | `string?` | KYC product type — **must be `"WEALTH"` for Gold users** |
| `kyc_provider` | `string?` | KYC provider — `"SUMSUB"`, `"PERSONA"`, etc. |
| `kyc_status` | `string?` | Current KYC verification status |

#### Response — `409 Conflict`

User already onboarded. Both platforms treat this as success (idempotent).

```json
{
  "error_code": "ONBOARDING_ALREADY_COMPLETE",
  "message": "User is already onboarded for this product"
}
```

### 2. Portfolio — `GET /wealth/v1/digital-metal/portfolio`

Returns user's gold portfolio including `onboarding_status` — the single source of truth for KYC gating.

| Header | Description | Example |
|--------|-------------|---------|
| `X-User-Id` | Authenticated user's ID | `"usr_abc123"` |
| `X-Country` | Market/region code | `"AE"` |

#### Response — `200 OK`

```json
{
  "current_value": 1500.00,
  "invested_amount": 1000.00,
  "total_returns": 500.00,
  "total_returns_percent": 50.0,
  "currency": "AED",
  "onboarding_status": "ONBOARDED",
  "holdings": [...],
  "computed_at": "2026-04-01T10:30:00Z"
}
```

#### `onboarding_status` Values

| Value | Meaning | Client Behavior |
|-------|---------|----------------|
| `KYC_REQUIRED` | Fresh user, needs identity verification | Show KYC gate, block buy/sell |
| `ONBOARDED` | KYC complete, user can trade | Allow buy/sell |
| `BYPASSED` | Whitelisted (e.g., internal/test users) | Allow buy/sell |
| `FAILED` | Previous KYC attempt failed, needs retry | Show KYC gate, block buy/sell |

### 3. SDUI KYC Workflow — `GET /workflow/v2/kyc`

Fetches the server-driven KYC verification workflow. The backend determines which flow to serve based on the user's context (product type, market, KYC provider).

| Field | Value |
|-------|-------|
| **Method** | `GET` |
| **Path** | `/workflow/v2/kyc` |
| **Query Params** | `preferred_tier` (optional) |
| **Auth** | Bearer token |

#### Response

Returns an SDUI workflow containing screens with SDK action payloads (SumSub access token, applicant ID, etc.). The client renders these screens and launches the SDK when an `OPEN_SDK_ACTION` is encountered.

---

## Backend Requirements

### 1. Gold-Specific KYC Workflow (CRITICAL)

**The `/workflow/v2/kyc` endpoint must serve a Gold/Wealth-specific KYC flow when the user's pending product is Gold.**

Current behavior (remittance):
- Backend creates a SumSub applicant for the `REMITTANCE` product
- Returns SDUI screens for remittance KYC verification

Required behavior (Gold):
- Backend detects user has called `/wealth/v1/digital-metal/onboarding/onboard` and `kyc_product = "WEALTH"`
- Creates a SumSub applicant for the `WEALTH` product type
- Returns SDUI screens tailored for Gold KYC (may have different document requirements, compliance checks, etc.)
- SumSub `levelName` / `flowName` should correspond to the Gold/Wealth verification level

**Implementation options:**

| Option | Approach | Client Change |
|--------|----------|---------------|
| A (Recommended) | Backend checks user context from onboard API and serves appropriate workflow | None — existing `/workflow/v2/kyc` works |
| B | New endpoint `/workflow/v2/wealth-kyc` | Client passes different workflow ID |
| C | Pass `product=wealth` query param to `/workflow/v2/kyc` | Client adds query param |

**We recommend Option A** — no client changes needed. The backend already knows the user's product context from the onboard call.

### 2. SumSub Applicant Configuration

When creating a SumSub applicant for Gold KYC:

| Config | Value | Notes |
|--------|-------|-------|
| `levelName` | Gold/Wealth-specific level | Must match SumSub dashboard config |
| `externalUserId` | Vance user ID | Links SumSub applicant to Vance user |
| `type` | `"individual"` | Standard KYC |
| `fixedInfo.country` | From `X-Country` header | UAE = `"AE"` |

### 3. Webhook Integration

SumSub sends webhooks when verification status changes. The backend must:

1. **Listen for SumSub webhooks** (`applicantReviewed`, `applicantPending`, etc.)
2. **Update portfolio `onboarding_status`** based on webhook result:
   - `GREEN` (approved) → `ONBOARDED`
   - `RED` (rejected) → `FAILED`
   - `PENDING` → keep as `KYC_REQUIRED` (client polls portfolio)
3. **Propagate status within 5 seconds** — the client polls portfolio every 30s, so status should be updated promptly

### 4. Token Generation & Refresh

| Requirement | Details |
|-------------|---------|
| **Access token** | Must be included in SDUI workflow response payload |
| **Token TTL** | Recommended: 10-30 minutes |
| **Token refresh** | SumSub SDK calls `tokenExpirationHandler` when expired — backend must support token refresh endpoint |
| **Refresh endpoint** | Existing SDUI token refresh mechanism (client already handles this) |

### 5. Idempotent Onboarding

The onboard endpoint is already idempotent (409 on re-call). Ensure:
- Calling onboard multiple times doesn't create duplicate SumSub applicants
- The `ext_user_id` (SafeGold) is stable across retries
- KYC status is preserved across onboard re-calls

---

## Edge Cases & Error Handling

### User-Facing Scenarios

| # | Scenario | Client Behavior | Backend Requirement |
|---|----------|----------------|---------------------|
| 1 | **Fresh user, no KYC** | Shows KYC bottom sheet → onboard → SumSub → returns to lander | Onboard creates Gold account + returns `KYC_REQUIRED` |
| 2 | **User already KYC-verified for remittance** | If portfolio returns `KYC_REQUIRED`, still gates Gold. Gold KYC is separate. | Backend must NOT auto-approve Gold KYC based on remittance KYC status |
| 3 | **User already KYC-verified for Gold** | `needsKYC = false` → skips bottom sheet → goes straight to buy | Portfolio returns `ONBOARDED` or `BYPASSED` |
| 4 | **User completes SumSub but webhook delayed** | Returns to lander, portfolio still shows `KYC_REQUIRED`, user sees KYC gate again | Backend should process webhook < 5s. Client polls every 30s. |
| 5 | **User cancels SumSub mid-flow** | Returns to Gold lander. Portfolio unchanged (`KYC_REQUIRED`). Can retry. | No action needed — SumSub applicant preserved for retry |
| 6 | **SumSub rejects user** | Returns to lander. Portfolio shows `FAILED`. KYC gate shows again. | Webhook updates status to `FAILED`. User can retry. |
| 7 | **User re-attempts after rejection** | Same flow: bottom sheet → onboard (409, treated as success) → SumSub | SumSub applicant retains rejection history. Backend may need to create new applicant or reset. |
| 8 | **Network error during onboard API** | Error toast shown. User stays on bottom sheet. Can retry. | Standard error response |
| 9 | **Network error during SDUI workflow fetch** | SDUI framework shows error screen with retry | Standard SDUI error handling |
| 10 | **SumSub SDK token expires mid-verification** | SDK triggers `tokenExpirationHandler` → client requests refresh → continues | Backend must support token refresh without losing progress |
| 11 | **User kills app during SumSub flow** | On next launch, portfolio still `KYC_REQUIRED`. SumSub applicant preserved. User can restart. | SumSub applicant state is persistent server-side |
| 12 | **Bypassed user (internal/test)** | `needsKYC = false`, no KYC gate | Backend returns `BYPASSED` in portfolio |
| 13 | **Country not supported for Gold KYC** | Onboard API should return appropriate error | Return 400/403 with clear error message |
| 14 | **User session expired** | Android: "User session not found" error. iOS: auth token refresh or login redirect | Standard auth flow |
| 15 | **Multiple concurrent onboard calls** | Both succeed (idempotent). Only one SumSub applicant created. | Backend must be idempotent (dedup by user_id + product) |
| 16 | **SumSub SDK not available (e.g., old OS)** | SDUI workflow should gracefully degrade or show alternative | Backend can serve non-SDK fallback (e.g., web-based KYC) |

### Race Conditions

| Scenario | Mitigation |
|----------|-----------|
| User completes KYC but portfolio poll hasn't refreshed yet | Portfolio polls every 30s. User may see stale `KYC_REQUIRED` for up to 30s after completion. Force-refresh on lander reappear could help. |
| Webhook arrives before user returns to app | Portfolio status updated. Next poll picks it up. No issue. |
| Two tabs/devices attempting KYC simultaneously | SumSub deduplicates by `externalUserId`. Backend deduplicates by user_id. |
| Onboard succeeds but SDUI workflow fails to load | User returns to lander, still sees KYC gate, can retry. Onboard is idempotent. |

### SumSub-Specific Edge Cases

| Scenario | SumSub Behavior | Our Handling |
|----------|----------------|-------------|
| Document upload fails | SDK shows retry within flow | No client action needed — SDK handles retries |
| Liveness check fails | SDK allows re-attempt (configurable) | Backend configures retry policy in SumSub dashboard |
| User submits but review is pending | SDK callback: `onSubmit` (status: PENDING) | Client returns to lander. Status remains `KYC_REQUIRED` until webhook arrives. |
| Auto-approval by SumSub | Webhook: `applicantReviewed` with `GREEN` | Backend updates to `ONBOARDED` immediately |
| Manual review required | Webhook delayed (hours/days) | User sees `KYC_REQUIRED` until review completes. Could show "Under Review" state. |
| SumSub maintenance/outage | SDK fails to load | SDUI shows error screen. User can retry later. |

---

## Platform Implementation Details

### iOS

| File | Change |
|------|--------|
| `GoldLanderViewModel.swift` | `onKYCProceed()` → after onboard success, calls `goldRouter?.navigateToProfile(.kycFlow(preferredTier: nil))` |
| `GoldRouter.swift` | Already has `navigateToProfile(_ route: ProfileRoute)` (line 132) — no changes needed |
| `ProfileRouter.swift` | Already builds `SDUIRootView` with workflow `"rm_uk_kyc_workflow"` — no changes needed |

**Portfolio refresh on return**: SwiftUI `.task {}` modifier re-triggers when NavigationStack pops back to lander. Portfolio polling (30s interval) automatically restarts.

### Android

| File | Change |
|------|--------|
| `GoldHomeFeature.kt` | Added `Command.Output.NavigateToKYC`. `OnboardingSuccess` → emits `NavigateToKYC` |
| `GoldHomeFragment.kt` | Handles `NavigateToKYC` → `appNavigation.navigateTo(Route.SERVER_DRIVEN, bundleOf(NavArgs.PARCEL to ServerDrivenParcel()))` |
| `GoldHomeUpdateTest.kt` | 4 new KYC tests + fixed broken `BuyGoldClick` test |

**Portfolio refresh on return**: Fragment `onResume` → ViewModel's portfolio polling (30s interval) restarts automatically.

---

## Testing Checklist

### Functional Tests

- [ ] Fresh user → "Get Started" → KYC bottom sheet shows
- [ ] "Continue to KYC" → onboard API called → SumSub opens
- [ ] Complete SumSub → return to lander → portfolio refreshes → can buy
- [ ] Cancel SumSub → return to lander → still sees KYC gate
- [ ] Already-onboarded user (409) → SumSub still opens (idempotent)
- [ ] KYC rejected user → return to lander → sees KYC gate → can retry
- [ ] Bypassed user → no KYC gate → straight to buy
- [ ] Network error on onboard → error toast → user stays on sheet

### Integration Tests

- [ ] Onboard API → correct headers (`X-User-Id`, `X-Country`)
- [ ] SDUI workflow returns Gold-specific SumSub configuration
- [ ] SumSub token valid and matches Gold applicant level
- [ ] Webhook updates portfolio status within 5 seconds
- [ ] Token refresh works during long verification sessions

### Unit Tests (Existing)

**Android** (`GoldHomeUpdateTest.kt`):
- `KYCProceedClick sets isOnboardingInProgress and emits OnboardUser`
- `KYCDismiss hides KYC bottom sheet`
- `OnboardingSuccess hides sheet and emits NavigateToKYC`
- `OnboardingError resets progress and emits ShowError`
- `BuyGoldClick shows KYC bottom sheet when needsKYC`
- `BuyGoldClick emits NavigateToBuy when KYC not needed`

---

## Open Questions for Backend

1. **Does `/workflow/v2/kyc` already differentiate by product?** If user has called Gold onboard, does the workflow endpoint automatically serve a Wealth KYC flow? Or do we need a new endpoint / query param?

2. **SumSub level name for Gold**: What `levelName` is configured in the SumSub dashboard for Gold/Wealth verification? Is it different from remittance?

3. **Manual review timeline**: If SumSub requires manual review, what's the expected turnaround? Should we show an "Under Review" state in the Gold lander instead of `KYC_REQUIRED`?

4. **Re-KYC after rejection**: When a user is rejected and retries, does the backend create a new SumSub applicant or reset the existing one?

5. **Cross-product KYC sharing**: If a user completes Gold KYC, does that satisfy remittance KYC too (or vice versa)? The current implementation treats them as independent.

6. **Webhook reliability**: Is there a fallback polling mechanism if SumSub webhooks are delayed? Should the client poll a KYC-specific endpoint after SumSub completes?

---

## Sequence Diagram — Complete Happy Path

```
User            App (iOS/Android)     Vance Backend         SumSub
 │                    │                     │                  │
 │  Tap "Get Started" │                     │                  │
 │───────────────────►│                     │                  │
 │                    │  GET /portfolio      │                  │
 │                    │────────────────────►│                  │
 │                    │  ◄─ KYC_REQUIRED ───│                  │
 │                    │                     │                  │
 │  ◄─ KYC Sheet ─────│                     │                  │
 │                    │                     │                  │
 │  Tap "Continue"    │                     │                  │
 │───────────────────►│                     │                  │
 │                    │  POST /onboard       │                  │
 │                    │────────────────────►│                  │
 │                    │  ◄─ 200 OK ─────────│                  │
 │                    │                     │                  │
 │                    │  GET /workflow/v2/kyc│                  │
 │                    │────────────────────►│                  │
 │                    │                     │  Create applicant │
 │                    │                     │─────────────────►│
 │                    │                     │  ◄─ Token ────────│
 │                    │  ◄─ SDUI workflow ───│                  │
 │                    │                     │                  │
 │  ◄─ SumSub SDK ────│                     │                  │
 │                    │                     │                  │
 │  [Verify identity] │                     │                  │
 │                    │                     │                  │
 │  SDK complete ────►│                     │                  │
 │                    │  SDUI action ───────►│                  │
 │                    │                     │  ◄─ Webhook ──────│
 │                    │                     │  (approved)       │
 │                    │                     │  Update portfolio │
 │                    │                     │  → ONBOARDED      │
 │                    │                     │                  │
 │  ◄─ Back to Lander │                     │                  │
 │                    │  GET /portfolio      │                  │
 │                    │────────────────────►│                  │
 │                    │  ◄─ ONBOARDED ──────│                  │
 │                    │                     │                  │
 │  ◄─ Buy enabled ───│                     │                  │
 │                    │                     │                  │
 │  Tap "Buy Gold"    │                     │                  │
 │───────────────────►│                     │                  │
 │  ◄─ Buy Flow ──────│                     │                  │
```

---

## Commits

| Platform | Commit | Description |
|----------|--------|-------------|
| iOS | `df479f06f` | `feat(gold): wire SumSub KYC verification into Gold buy flow` |
| Android | `a84241ae39` | `feat(gold): wire SumSub KYC verification into Gold buy flow` |

Both on branch `feature/wealth-module-gold-buy-sell-flow`.
