# Company Context

## About
Aspora (consumer brand: **Vance**) — Cross-border money transfer fintech app. Targets NRIs and international remittance users. Supports India, UK, UAE corridors.

## Products
- **Vance iOS** — SwiftUI app on App Store
- **Vance Android** — Kotlin app on Play Store
- Both share the same backend APIs, feature set, and design system

## Tools & Systems
| Tool | Used for |
|------|----------|
| GitHub | Source control (Vance-Club org) |
| Xcode | iOS development |
| Android Studio | Android development |
| Firebase | Analytics, Crashlytics, Remote Config, Auth, Firestore |
| Mixpanel | Product analytics |
| AppsFlyer | Attribution tracking |
| MoEngage | Push notifications, engagement |
| Smartlook | Session recording |
| Fastlane | iOS CI/CD automation |
| CocoaPods + SPM | iOS dependencies (hybrid) |
| Gradle (Kotlin DSL) | Android build system |

## Payment & Verification Providers
| Provider | Purpose |
|----------|---------|
| Plaid | Bank account linking (US) |
| TrueLayer | Open banking payments (UK) |
| Checkout.com | Card payments, 3DS |
| Persona | KYC/Identity verification |
| SumSub | KYC verification |
| Sardine | Fraud detection |

## Feature Areas
| Feature | Description |
|---------|-------------|
| Remittance/Send | Core money transfer (INR, GBP, AED, USD corridors) |
| Gold/Wealth | Buy/sell gold investments (new, active dev) |
| BBPS | Bharat Bill Payment System (India) |
| NRE/NRO | Non-resident bank accounts (India) |
| Compare Rates | FX rate comparison with competitors |
| Referral & Rewards | User growth & engagement |
| Server-Driven UI | Dynamic screens defined by backend JSON |
| Canvas (Home V3) | New server-driven home screen (iOS) |

## Architecture Principles
- Clean Architecture on both platforms
- MVVM as primary pattern (MVI for Android Gold module)
- Repository pattern for data access
- Feature-based package organization (not layer-based)
- Server-driven UI for dynamic content
- Protocol/interface-based abstractions
