# Gold Buy & Sell Flow — Complete Architecture Reference

> Last updated: 2026-03-16
> Status: Pre-implementation reference (no code changes yet)

---

## Table of Contents

1. [Flow Overview](#flow-overview)
2. [Buy Flow — Step by Step](#buy-flow)
3. [Sell Flow — Step by Step](#sell-flow)
4. [API Endpoints](#api-endpoints)
5. [Backend Architecture](#backend-architecture)
6. [GOMS Workflow State Machine](#goms-workflow-state-machine)
7. [Key Entities](#key-entities)
8. [Changes from Current Implementation](#changes-from-current-implementation)
9. [Sell Flow — What's Different from Buy](#sell-flow-differences)
10. [Implementation Notes](#implementation-notes)

---

## Flow Overview

### Buy Flow (4 steps)
```
Create Cart → Order Summary → Initiate Order → Poll Status
```

### Sell Flow (5 steps)
```
Create Cart → Order Summary → Beneficiary List / Add Beneficiary → Initiate Order → Poll Status
```

Both flows share the same base endpoints (unified `/cart/` path). The `mode` field (`BUY` or `SELL`) in the Create Cart request determines the flow variant.

---

## Buy Flow

### Step 1: Create Cart

**Purpose**: Lock a gold price for the user and create a transient cart in Redis.

```
POST /digital-metal/cart/create
```

**Request Body**:
```json
{
  "metalType": "GOLD",
  "mode": "BUY"
}
```

> **Change**: `paymentMode` field has been **removed** from the create cart request. Previously it was included here.

**Response** (key fields):
```json
{
  "cartId": "uuid-string",
  "metalType": "GOLD",
  "mode": "BUY",
  "buyPrice": 250.50,
  "sellPrice": 248.00,
  "priceLockedUntil": "2026-03-16T12:05:00Z",
  "currency": "AED"
}
```

**Backend behavior**:
- Fetches live price from OGold vendor API
- Stores cart in Redis with TTL matching price lock duration
- Cart expires automatically when price lock expires
- No DB write at this stage (Redis only)

---

### Step 2: Order Summary

**Purpose**: User enters amount/weight, backend calculates breakdown (taxes, fees, final amount).

```
POST /digital-metal/cart/{cartId}/summary
```

**Request Body**:
```json
{
  "valueMode": "AMOUNT",
  "amount": 500.00,
  "paymentMode": "Ogold_Webview"
}
```

> **Changes**:
> - `paymentMode` has **moved here** from Initiate Order. It's now part of the Summary request body.
> - For **buy**: `paymentMode` = `"Ogold_Webview"`
> - For **sell**: `paymentMode` = `"bank"`
> - Field was previously called `buyMode` in the response. Now called `valueMode` (applies to both buy and sell).

**`valueMode` options**:
- `AMOUNT` — user entered a currency amount (e.g., "I want to spend AED 500")
- `WEIGHT` — user entered a weight (e.g., "I want to buy 1.75g")

**Conditional fields**: `amount` required if `valueMode=AMOUNT`, `weight` required if `valueMode=WEIGHT`.

**Response — 200 OK**:
```json
{
  "cartId": "cart_7f3a9b",
  "metalType": "GOLD",
  "valueMode": "AMOUNT",
  "pricePerGram": 285.50,
  "amount": 500.00,
  "weight": 1.75,
  "fees": 5.00,
  "tax": 2.50,
  "netAmount": 507.50,
  "currency": "AED",
  "state": "FINALIZED"
}
```

> **Response field changes from previous spec**:
> - `buyPrice` → `pricePerGram` (generic for buy/sell)
> - `platformFee` → `fees`
> - `totalPayable` → `netAmount`
> - `priceLockedUntil` removed (cart state managed server-side)
> - `mode` removed from response (client already knows it)
> - New field: `state: "FINALIZED"` — cart transitions to FINALIZED state after summary

**Errors**:
| Status | Reason |
|--------|--------|
| `400` | Missing amount/weight for given valueMode |
| `404` | Cart not found |
| `409` | Cart already has an order or is expired |

---

### Step 3: Initiate Order

**Purpose**: Submits the finalized cart as an order to the vendor. Cart must be in `FINALIZED` state (i.e., summary has been called).

```
POST /digital-metal/cart/{cartId}/order
```

> **Endpoint change**: Was `/cart/{cartId}/initiate`, now `/cart/{cartId}/order`.

**Request Body**:
```json
{
  "beneficiaryAccountId": "ba_01HXYZ"
}
```

> **Changes from current implementation**:
> - Old body had `postscript` + `paymentMeta` (complex objects) + `paymentMode`
> - New body has **only** `beneficiaryAccountId` — much simpler
> - `paymentMode` has moved to the Summary request (Step 2)
> - `beneficiaryAccountId` = payment source (buy) or payout destination (sell)

**Response — 201 Created**:
```json
{
  "orderId": "ord_x9k2m4",
  "status": "AWAITING_PAYMENT"
}
```

> **Response changes**:
> - `transactionId` → `orderId`
> - `status` starts as `"AWAITING_PAYMENT"` (not `"INITIATED"`)
> - `paymentUrl` and `redirectUrl` removed from response

**Errors**:
| Status | Reason |
|--------|--------|
| `404` | Cart not found |
| `404` | Beneficiary account not found or doesn't belong to user |
| `409` | Cart not finalized, already ordered, or expired |

**Backend behavior**:
1. Validates cart is in `FINALIZED` state
2. Validates `beneficiaryAccountId` belongs to user
3. Creates order in DB with status `AWAITING_PAYMENT`
4. Calls OGold vendor API to create the order
5. Triggers GOMS workflow for state management

---

### Step 4: Poll Status

**Purpose**: Client polls until the order reaches a terminal state.

```
GET /digital-metal/order/{orderId}/status
```

> **Note**: Uses `orderId` returned from Initiate Order (was `transactionId` in old spec).

**Response**:
```json
{
  "orderId": "ord_x9k2m4",
  "status": "ORDER_COMPLETED",
  "metalType": "GOLD",
  "amount": 500.00,
  "weight": 1.75,
  "completedAt": "2026-03-16T12:06:30Z"
}
```

**Terminal states**:
| Status | Meaning |
|--------|---------|
| `ORDER_COMPLETED` | Success — gold added to vault |
| `PAYMENT_FAILED` | Payment failed — no gold purchased |
| `ORDER_FAILED` | Backend/vendor error — investigate |
| `CANCELLED` | User or system cancelled |

**Non-terminal states** (keep polling):
| Status | Meaning |
|--------|---------|
| `INITIATED` | Order created, payment pending |
| `PAYMENT_PROCESSING` | Payment in progress |
| `PAYMENT_COMPLETED` | Payment done, gold allocation pending |
| `PROCESSING` | Backend processing |

**Polling strategy**: 3-second intervals, max ~60 attempts (3 minutes timeout).

---

## Sell Flow

### Step 1: Create Cart (same endpoint)

```
POST /digital-metal/cart/create
```

```json
{
  "metalType": "GOLD",
  "mode": "SELL"
}
```

### Step 2: Order Summary (same endpoint)

```
POST /digital-metal/cart/{cartId}/summary
```

```json
{
  "valueMode": "AMOUNT",
  "amount": 500.00,
  "paymentMode": "bank"
}
```

> For sell, `paymentMode` = `"bank"` (vs `"Ogold_Webview"` for buy). Backend uses `sellPrice` for calculations.

### Step 3: Beneficiary Selection (sell-only)

Before initiating the sell order, the user must select or add a bank account for payout.

#### 3a. List All Beneficiary Accounts

```
GET /digital-metal/beneficiary-accounts
Headers: X-User-Id: {userId}
```

**Response — 200 OK** (array, empty `[]` if none exist):
```json
[
  {
    "id": "ba_01HXYZ",
    "userId": "usr_abc123",
    "bankName": "Emirates NBD",
    "ibanNumber": "AE070331234567890123456",
    "accountName": "Ahmed Al Maktoum",
    "verified": false,
    "createdAt": "2026-03-16T12:00:00Z",
    "updatedAt": "2026-03-16T12:00:00Z"
  },
  {
    "id": "ba_02HXYZ",
    "userId": "usr_abc123",
    "bankName": "Abu Dhabi Commercial Bank",
    "ibanNumber": "AE460261234567890123456",
    "accountName": "Ahmed Al Maktoum",
    "verified": true,
    "createdAt": "2026-03-10T08:30:00Z",
    "updatedAt": "2026-03-12T14:00:00Z"
  }
]
```

#### 3b. Fetch Single Beneficiary Account

```
GET /digital-metal/beneficiary-accounts/{id}
Headers: X-User-Id: {userId}
```

**Response — 200 OK**: Single beneficiary object (same shape as list item).

**Errors**: `404` if account not found or doesn't belong to user.

#### 3c. Create Beneficiary Account (if none exist or adding new)

```
POST /digital-metal/beneficiary-accounts
Headers: X-User-Id: {userId}, Content-Type: application/json
```

**Request Body**:
```json
{
  "bankName": "Emirates NBD",
  "ibanNumber": "AE070331234567890123456",
  "accountName": "Ahmed Al Maktoum"
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `bankName` | string | Yes | max 100 chars |
| `ibanNumber` | string | Yes | max 34 chars |
| `accountName` | string | Yes | max 100 chars |

**Response — 201 Created**:
```json
{
  "id": "ba_01HXYZ",
  "userId": "usr_abc123",
  "bankName": "Emirates NBD",
  "ibanNumber": "AE070331234567890123456",
  "accountName": "Ahmed Al Maktoum",
  "verified": false,
  "createdAt": "2026-03-16T12:00:00Z",
  "updatedAt": "2026-03-16T12:00:00Z"
}
```

**Errors**:
| Status | Reason |
|--------|--------|
| `400` | Validation failed (missing/invalid fields) |
| `409` | Duplicate IBAN for the same user |

> **Key differences from earlier assumption**: Endpoint path is `/digital-metal/beneficiary-accounts` (not `/beneficiary/list` or `/beneficiary/add`). Fields are `bankName` + `ibanNumber` + `accountName` (UAE IBAN-based, not IFSC-based). Response includes `verified` boolean flag — newly added accounts start as `verified: false`.

### Step 4: Initiate Order (same endpoint)

```
POST /digital-metal/cart/{cartId}/order
```

```json
{
  "beneficiaryAccountId": "ba_01HXYZ"
}
```

For sell, `beneficiaryAccountId` = the bank account where proceeds will be deposited. `paymentMode` was already set to `"bank"` in the Summary step.

### Step 5: Poll Status (same endpoint)

Same polling mechanism as buy flow. Terminal state `ORDER_COMPLETED` means gold sold and payout initiated.

---

## API Endpoints

| Step | Method | Path | Notes |
|------|--------|------|-------|
| Create Cart | POST | `/digital-metal/cart/create` | Unified (was `/buy/cart/create`) |
| Order Summary | POST | `/digital-metal/cart/{cartId}/summary` | `paymentMode` now in request body |
| Initiate Order | POST | `/digital-metal/cart/{cartId}/order` | Was `.../initiate`, body = `beneficiaryAccountId` only |
| Poll Status | GET | `/digital-metal/order/{orderId}/status` | Uses `orderId` (was `transactionId`) |
| List Beneficiaries | GET | `/digital-metal/beneficiary-accounts` | Sell flow only, returns `[]` if empty |
| Get Beneficiary | GET | `/digital-metal/beneficiary-accounts/{id}` | Sell flow only, 404 if not owned |
| Create Beneficiary | POST | `/digital-metal/beneficiary-accounts` | Sell flow only, 409 on duplicate IBAN |
| Live Price | GET | `/wealth/v1/digital-metal/prices/live` | Unchanged |
| Portfolio | GET | `/wealth/v1/digital-metal/portfolio` | Unchanged |

**Key path change**: `/buy/` removed from cart endpoints → now a single unified path for both buy and sell.

---

## Backend Architecture

```
┌─────────────────────────────────────────────────────┐
│                    API Gateway                       │
│              (Auth, Rate Limiting)                   │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              Gold Controllers (Go)                   │
│  CartController / OrderController / PriceController  │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              Gold Services (Go)                      │
│  CartService / OrderService / PriceService           │
│  ┌─────────────────────────────────────────────┐    │
│  │ Business Logic:                              │    │
│  │  - Price locking & cart TTL                  │    │
│  │  - Amount/weight calculation                 │    │
│  │  - Tax & fee computation                     │    │
│  │  - Order validation                          │    │
│  └─────────────────────────────────────────────┘    │
└──────────┬────────────────────────┬─────────────────┘
           │                        │
┌──────────▼──────────┐  ┌─────────▼──────────────────┐
│   Provider Layer     │  │   GOMS (Go)                │
│                      │  │   Generic Order Mgmt Svc   │
│  OGoldProvider       │  │                            │
│  - Buy order         │  │  Workflow state machine:   │
│  - Sell order        │  │  INITIATED                 │
│  - Price fetch       │  │    → PAYMENT_PROCESSING    │
│  - Balance check     │  │    → PAYMENT_COMPLETED     │
│                      │  │    → PROCESSING            │
│  PaymentProvider     │  │    → ORDER_COMPLETED       │
│  - Webview payment   │  │    (or PAYMENT_FAILED /    │
│  - Status callback   │  │     ORDER_FAILED)          │
└──────────┬──────────┘  └─────────┬──────────────────┘
           │                        │
┌──────────▼──────────┐  ┌─────────▼──────────────────┐
│   OGold Vendor API   │  │   PostgreSQL               │
│   (External)         │  │   TransactionEntity        │
│                      │  │   (optimistic locking)     │
│   Gold price feed    │  │                            │
│   Buy/Sell execution │  ├─────────────────────────────┤
│   Balance mgmt       │  │   Redis                    │
│                      │  │   Cart (TTL-based expiry)  │
│                      │  │   Price lock cache         │
└──────────────────────┘  └────────────────────────────┘
```

### Key Components

| Component | Language | Responsibility |
|-----------|----------|----------------|
| **Gold Controllers** | Go | HTTP handlers, request validation, routing |
| **Gold Services** | Go | Core business logic (pricing, cart, order) |
| **OGold Provider** | Go | Adapter for OGold vendor API (UAE gold partner) |
| **GOMS** | Go | Generic Order Management Service — workflow orchestrator |
| **Redis** | — | Transient cart storage with TTL-based price lock |
| **PostgreSQL** | — | Persistent transaction records with optimistic locking |

---

## GOMS Workflow State Machine

```
                    ┌───────────┐
                    │ INITIATED │
                    └─────┬─────┘
                          │
                    ┌─────▼──────────────┐
                    │ PAYMENT_PROCESSING  │
                    └─────┬──────────┬───┘
                          │          │
                   success│          │failure
                          │          │
              ┌───────────▼──┐  ┌───▼──────────┐
              │   PAYMENT_   │  │  PAYMENT_    │
              │   COMPLETED  │  │  FAILED      │ ← Terminal
              └───────┬──────┘  └──────────────┘
                      │
              ┌───────▼──────┐
              │  PROCESSING  │
              └───────┬──┬───┘
                      │  │
               success│  │failure
                      │  │
          ┌───────────▼┐ ┌▼─────────────┐
          │   ORDER_   │ │  ORDER_      │
          │ COMPLETED  │ │  FAILED      │ ← Terminal
          └────────────┘ └──────────────┘
              ↑ Terminal
```

**GOMS responsibilities**:
- Owns the state machine transitions
- Calls OGold vendor API for gold allocation (after payment confirmed)
- Updates `TransactionEntity` status in DB
- Handles retries and idempotency
- Sends webhook/callback to notify frontend-facing service

---

## Key Entities

### Cart (Redis — transient)

| Field | Type | Description |
|-------|------|-------------|
| `cartId` | UUID | Unique cart identifier |
| `metalType` | String | `GOLD` (future: `SILVER`) |
| `mode` | String | `BUY` or `SELL` |
| `buyPrice` | Decimal | Locked buy price per gram |
| `sellPrice` | Decimal | Locked sell price per gram |
| `priceLockedUntil` | Timestamp | When price lock expires |
| `amount` | Decimal | User-entered amount (after summary) |
| `weight` | Decimal | Calculated weight (after summary) |
| `valueMode` | String | `AMOUNT` or `WEIGHT` |
| `tax` | Decimal | Computed tax |
| `totalPayable` | Decimal | Final amount |
| `TTL` | Duration | Auto-expiry tied to price lock |

### Order / TransactionEntity (PostgreSQL — persistent)

| Field | Type | Description |
|-------|------|-------------|
| `orderId` | String | Primary key (e.g., `ord_x9k2m4`) |
| `userId` | UUID | FK to user |
| `cartId` | UUID | Source cart reference |
| `mode` | String | `BUY` or `SELL` |
| `status` | String | Current GOMS state |
| `amount` | Decimal | Transaction amount |
| `weight` | Decimal | Gold weight |
| `metalType` | String | `GOLD` |
| `vendorOrderId` | String | OGold order reference |
| `paymentMode` | String | `Ogold_Webview` |
| `beneficiaryAccountId` | UUID | Payment source (buy) or payout dest (sell) |
| `version` | Int | Optimistic locking column |
| `createdAt` | Timestamp | |
| `updatedAt` | Timestamp | |

### BeneficiaryAccount (PostgreSQL — persistent)

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Prefixed ID (e.g., `ba_01HXYZ`) |
| `userId` | String | Owner user ID |
| `bankName` | String | Bank display name (max 100 chars) |
| `ibanNumber` | String | UAE IBAN (max 34 chars) |
| `accountName` | String | Account holder name (max 100 chars) |
| `verified` | Boolean | Whether account is verified (starts `false`) |
| `createdAt` | Timestamp | |
| `updatedAt` | Timestamp | |

**Constraints**: Unique `(userId, ibanNumber)` — duplicate IBAN for same user returns `409 Conflict`.

---

## Changes from Current Implementation

### 1. API Path — Remove `/buy/` and `/wealth/v1/` prefix changes

| Current | New |
|---------|-----|
| `/wealth/v1/digital-metal/buy/cart/create` | `/digital-metal/cart/create` |
| `/wealth/v1/digital-metal/buy/cart/{id}/summary` | `/digital-metal/cart/{id}/summary` |
| `/wealth/v1/digital-metal/buy/cart/{id}/initiate` | `/digital-metal/cart/{id}/order` |
| `/wealth/v1/digital-metal/transaction/{txnId}/status` | `/digital-metal/order/{orderId}/status` |

> Note: `initiate` → `order`, `transaction` → `order`, `transactionId` → `orderId`

### 2. Create Cart — Remove `paymentMode`

| Current Body | New Body |
|-------------|----------|
| `{ metalType, mode, paymentMode }` | `{ metalType, mode }` |

`paymentMode` moved to **Order Summary** request (not Initiate Order).

### 3. Order Summary — `paymentMode` moved here + response field renames

**Request changes**:
| Current Request | New Request |
|----------------|-------------|
| `{ amount, valueMode }` | `{ valueMode, amount/weight, paymentMode }` |

- `paymentMode` is now part of the summary request body
- Buy: `"Ogold_Webview"`, Sell: `"bank"`

**Response field renames**:
| Current | New |
|---------|-----|
| `buyMode` | `valueMode` |
| `buyPrice` | `pricePerGram` |
| `platformFee` | `fees` |
| `totalPayable` | `netAmount` |
| (none) | `state: "FINALIZED"` (new) |
| `priceLockedUntil` | (removed) |
| `mode` | (removed from response) |

### 4. Initiate Order — Path + body simplified further

| Aspect | Current | New |
|--------|---------|-----|
| Path | `/cart/{id}/initiate` | `/cart/{id}/order` |
| Body | `{ postscript, paymentMeta }` or `{ beneficiaryAccountId, paymentMode }` | `{ beneficiaryAccountId }` only |
| Response ID | `transactionId` | `orderId` |
| Response status | `"INITIATED"` | `"AWAITING_PAYMENT"` |
| Response extras | `paymentUrl`, `redirectUrl` | (removed) |

`paymentMode` is no longer here — it's in the Summary step.

### 5. Status Polling — ID change

| Current | New |
|---------|-----|
| `GET .../transaction/{transactionId}/status` | `GET .../order/{orderId}/status` |

Terminal states `ORDER_COMPLETED` and `PAYMENT_FAILED` handling remains the same.

---

## Sell Flow Differences

| Aspect | Buy | Sell |
|--------|-----|------|
| `mode` in Create Cart | `"BUY"` | `"SELL"` |
| Price used | `buyPrice` | `sellPrice` |
| Beneficiary step | Not needed (or pre-set) | **Required** — user selects/adds bank account |
| `beneficiaryAccountId` in Initiate | Payment source account | Payout destination bank account |
| Payment URL in response | May have webview URL | Typically no webview (backend-initiated payout) |
| Extra endpoints needed | None | `GET /beneficiary-accounts`, `GET /beneficiary-accounts/{id}`, `POST /beneficiary-accounts` |

### What Can Be Reused for Sell

- **Create Cart** — same endpoint, just `mode: "SELL"`
- **Order Summary** — same endpoint, calculations use sell price
- **Initiate Order** — same endpoint and body shape
- **Poll Status** — identical
- **Network models** — same request/response structures (mode field differentiates)
- **ViewModels** — buy review/sell review have similar state machines
- **Status polling logic** — identical timer + terminal state handling

### What's New for Sell

- **Beneficiary list/add screens** — already built (SelectBankView/Screen, AccountDetailsView/Screen)
- **Beneficiary API layer** — 3 endpoints:
  - `GET /digital-metal/beneficiary-accounts` — list all (returns `[]` if empty)
  - `GET /digital-metal/beneficiary-accounts/{id}` — fetch single
  - `POST /digital-metal/beneficiary-accounts` — create new (`bankName`, `ibanNumber`, `accountName`)
- **Beneficiary model** — `BeneficiaryAccount` with `id`, `userId`, `bankName`, `ibanNumber`, `accountName`, `verified`, `createdAt`, `updatedAt`
- **Flow wiring** — Create Cart → Summary → **Beneficiary selection** → Initiate → Poll
- **Note**: Newly created beneficiary accounts start with `verified: false`. The `beneficiaryAccountId` passed to Initiate Order is the `id` from the beneficiary response (e.g., `"ba_01HXYZ"`).

---

## Implementation Notes

### Platform-Specific Files to Update

**iOS**:
- `GoldRemoteDataSource` — update endpoint paths (remove `/buy/`, `initiate` → `order`)
- `Network+GoldCart.swift` — update Create Cart request (remove `paymentMode`)
- `Network+GoldOrderSummary.swift` — add `paymentMode` to request, rename response fields (`buyMode` → `valueMode`, `buyPrice` → `pricePerGram`, `platformFee` → `fees`, `totalPayable` → `netAmount`, add `state`)
- `Network+GoldInitiateOrder.swift` — body is now only `beneficiaryAccountId` (remove `paymentMode`, `postscript`, `paymentMeta`). Response returns `orderId` (not `transactionId`), status = `AWAITING_PAYMENT`
- `BuyReviewViewModel` — update request construction, pass `paymentMode` to summary, use `orderId` for polling
- Add beneficiary network models (`Network+BeneficiaryAccount.swift`) — fields: `id`, `bankName`, `ibanNumber`, `accountName`, `verified`
- Add `BeneficiaryAccount` domain model
- Add `FetchBeneficiaryAccountsUseCase` + `CreateBeneficiaryAccountUseCase`
- Add repository methods for list/create beneficiary
- Wire SelectBankView to use real beneficiary list API
- Wire AccountDetailsView to use real create beneficiary API (bankName + ibanNumber + accountName)

**Android**:
- `GoldApiService` — update endpoint paths (remove `/buy/`, `initiate` → `order`)
- `CreateCartRequest` — remove `paymentMode`
- `OrderSummaryRequest` — add `paymentMode` field (buy = `"Ogold_Webview"`, sell = `"bank"`)
- `OrderSummaryResponse` — rename `buyMode` → `valueMode`, `buyPrice` → `pricePerGram`, `platformFee` → `fees`, `totalPayable` → `netAmount`, add `state`
- `InitiateOrderRequest` — body is now only `beneficiaryAccountId` (remove `paymentMode`)
- `InitiateOrderResponse` — returns `orderId` (not `transactionId`), status = `AWAITING_PAYMENT`
- `GoldBuyReviewFeature` — update request construction, pass `paymentMode` to summary, use `orderId` for polling
- Add beneficiary network models (`BeneficiaryAccountResponse`, `CreateBeneficiaryRequest`) — fields: `id`, `bankName`, `ibanNumber`, `accountName`, `verified`
- Add `BeneficiaryAccount` domain model
- Add `FetchBeneficiaryAccountsUseCase` + `CreateBeneficiaryAccountUseCase`
- Add repository methods for list/create beneficiary
- Wire SelectBankScreen to use real beneficiary list API
- Wire AccountDetailsScreen to use real create beneficiary API (bankName + ibanNumber + accountName)

### Error Handling

| Scenario | Handling |
|----------|----------|
| Cart expired (price lock timeout) | Show "Price expired" → re-create cart |
| Payment failed | Show failure screen with retry option (new cart) |
| Order failed | Show error with support contact |
| Network error during polling | Continue polling (don't reset) |
| Beneficiary add fails (400) | Show inline validation error, allow retry |
| Beneficiary duplicate IBAN (409) | Show "Account already added" message |
| Beneficiary not found (404) | Remove from local list, refresh |

### Security Considerations

- Cart IDs are UUIDs — no sequential guessing
- Price lock prevents price manipulation between cart creation and payment
- Optimistic locking on TransactionEntity prevents double-processing
- `beneficiaryAccountId` validated server-side against user's verified accounts
- Payment via `Ogold_Webview` keeps sensitive payment data off-client
