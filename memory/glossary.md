# Glossary

Workplace shorthand, acronyms, and internal language for Vance/Aspora.

## Acronyms
| Term | Meaning | Context |
|------|---------|---------|
| SDUI | Server-Driven UI | Backend defines UI components as JSON; both platforms render dynamically |
| BBPS | Bharat Bill Payment System | Indian bill payments feature |
| NRE/NRO | Non-Resident External/Ordinary | Indian bank account types for NRIs |
| KYC | Know Your Customer | Identity verification (Persona, SumSub) |
| MVI | Model-View-Intent | Pattern used in Android Gold module (GoldHomeFeature) |
| MVVM | Model-View-ViewModel | Primary architecture pattern on both platforms |
| DI | Dependency Injection | Hilt (Android), Factory (iOS) |
| 3DS | 3D Secure | Card payment authentication via Checkout.com |
| P0/P1/P2/P3 | Priority levels | P0 = drop everything, P3 = nice to have |
| SPM | Swift Package Manager | iOS dependency management (alongside CocoaPods) |
| TTL | Time To Live | Cache expiration (e.g., gold price cache = 30 seconds on iOS) |
| CTA | Call to Action | Button/action element in UI |
| OTP | One-Time Password | SMS/email verification codes |
| CI/CD | Continuous Integration/Delivery | Xcode Cloud + Fastlane (iOS), GitHub Actions (Android) |

## Internal Terms
| Term | Meaning |
|------|---------|
| Vance | Consumer-facing brand name |
| Aspora | Company name / codebase namespace |
| Canvas | Home V3 — server-driven home screen (iOS) |
| Gold module | Wealth/investment feature for buying/selling gold |
| Plus* views | Custom Android views prefixed with "Plus" (PlusButton, PlusEditText, etc.) |
| SD components | Server-driven UI components |
| Canary settings | Debug/feature flags for iOS (local overrides) |
| Hot cache | CLAUDE.md working memory |
| EventBus | Cross-feature communication (Android data-layer) |

## Project Codenames
| Codename | Project |
|----------|---------|
| vance-ios | iOS app (GitHub: Vance-Club/vance-ios) |
| vance-android | Android app |
| Gold / Wealth module | Gold investment feature on both platforms |
| Canvas | Home V3 server-driven home screen |
| UK SD Components | UK-specific server-driven UI (address picker, etc.) |

## Nicknames → Full Names
| Nickname | Person |
|----------|--------|
| Paul | iOS code reviewer — reviews Gold module PRs |
