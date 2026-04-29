# Plan: API Contract Changes — `feat/payment-instruments`

## Context
Backend deployed new API contracts on `feat/payment-instruments` branch:
1. `paymentMode` → `paymentInstrument` rename in order-preview + initiate-order
2. New `GET /digital-metal/payment-instruments` endpoint
3. New `GET /digital-metal/documents/invoices/{transactionId}/download` endpoint

## Changes Summary

### Breaking Change 1: `paymentMode` → `paymentInstrument`
- **order-preview request**: `payment_mode` → `payment_instrument`
- **order-preview response**: new `payment_instrument` field
- **initiate-order request**: new required `payment_instrument` field
- Values: `APPLE_PAY`, `CARD`, `WALAONE`, `BANK`

### New Endpoint 2: `GET /digital-metal/payment-instruments`
- Query param: `mode` (BUY/SELL, optional)
- Returns: `[{ "key": "CARD", "displayName": "Card" }, ...]`
- BUY → APPLE_PAY, CARD, WALAONE
- SELL → BANK

### New Endpoint 3: `GET /digital-metal/documents/invoices/{transactionId}/download`
- Header: `X-User-Id`
- Returns: `{ "downloadUrl": "https://..." }`

## Implementation — iOS

### 1. Rename `paymentMode` → `paymentInstrument` in request/response models
| File | Change |
|------|--------|
| `Aspora/Core/Network/Request/Body/Gold/OrderSummaryRequestBody.swift` | `paymentMode` → `paymentInstrument`, CodingKey `payment_mode` → `payment_instrument` |
| `Aspora/Core/Network/Models/Gold/Network+OrderSummary.swift` | Add `paymentInstrument: String?` field + CodingKey |
| `Aspora/Core/Network/Request/Body/Gold/InitiateOrderRequestBody.swift` | Add `paymentInstrument: String` field + CodingKey |

### 2. Update hardcoded values
| File | Line | Change |
|------|------|--------|
| `Aspora/UserInterface/Views/Gold/Buy/BuyGoldViewModel.swift` | ~406 | `paymentMode: "CARD"` → `paymentInstrument: "CARD"` |
| `Aspora/UserInterface/Views/Gold/Buy/GoldSellBuyReviewViewModel.swift` | ~473 | `paymentMode: "BANK"` → `paymentInstrument: "BANK"` |

### 3. New payment-instruments endpoint
| File | Action |
|------|--------|
| `Aspora/Core/Network/Models/Gold/Network+PaymentInstrument.swift` | NEW — response model |
| `Aspora/Core/Network/Request/Builder/Gold/FetchPaymentInstrumentsRequestBuilder.swift` | NEW — request builder |
| `Aspora/Domain/Models/Gold/PaymentInstrument.swift` | NEW — domain model |
| `Aspora/Domain/UseCase/Gold/FetchPaymentInstrumentsUseCase.swift` | NEW — use case |
| `Aspora/Repository/Gold/GoldRepository.swift` | Add `fetchPaymentInstruments(mode:)` |
| `Aspora/Core/DI/Container+UseCases.swift` | Register new use case |

### 4. New invoice download endpoint
| File | Action |
|------|--------|
| `Aspora/Core/Network/Models/Gold/Network+InvoiceDownload.swift` | NEW — response model |
| `Aspora/Core/Network/Request/Builder/Gold/DownloadInvoiceRequestBuilder.swift` | NEW — request builder |
| `Aspora/Domain/UseCase/Gold/DownloadInvoiceUseCase.swift` | NEW — use case |

## Implementation — Android

### 1. Rename `paymentMode` → `paymentInstrument`
| File | Change |
|------|--------|
| `data-layer/.../gold/model/response/BuyCartModels.kt` | `OrderSummaryRequest.paymentMode` → `paymentInstrument`, JSON key `payment_instrument` |
| `data-layer/.../gold/model/response/BuyCartModels.kt` | `OrderSummaryResponse` — add `paymentInstrument: String?` |
| `data-layer/.../gold/model/response/BuyCartModels.kt` | `InitiateOrderRequest` — add `paymentInstrument: String` |

### 2. Update hardcoded values
| File | Line | Change |
|------|------|--------|
| `app/.../gold/usecase/FetchOrderSummaryUseCase.kt` | ~23 | default param `paymentMode` → `paymentInstrument` |
| `app/.../gold/review/viewmodel/GoldOrderReviewViewModel.kt` | ~175 | `paymentMode = "BANK"` → `paymentInstrument = "BANK"` |

### 3. New payment-instruments endpoint
| File | Action |
|------|--------|
| `data-layer/.../gold/model/response/BuyCartModels.kt` | Add `PaymentInstrumentResponse` data class |
| `data-layer/.../gold/service/GoldService.kt` | Add `getPaymentInstruments(@Query mode)` |
| `data-layer/.../gold/repository/GoldRepository.kt` | Add interface + impl method |
| `app/.../gold/model/domain/PaymentInstrument.kt` | NEW — domain model |

### 4. New invoice download endpoint
| File | Action |
|------|--------|
| `data-layer/.../gold/model/response/BuyCartModels.kt` | Add `InvoiceDownloadResponse` |
| `data-layer/.../gold/service/GoldService.kt` | Add `downloadInvoice(@Path transactionId)` |
| `data-layer/.../gold/repository/GoldRepository.kt` | Add interface + impl method |

## Verification
1. Buy flow: order-preview sends `payment_instrument: "CARD"` → response includes `payment_instrument`
2. Sell flow: initiate-order sends `payment_instrument: "BANK"`
3. New endpoints compile and models parse correctly
4. Existing tests updated for renamed fields
