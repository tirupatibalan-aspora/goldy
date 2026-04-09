# vance-ios — Summary

| Field | Value |
|-------|-------|
| **Branch** | `feature/wealth-module-gold-buy-sell-flow` |
| **Last Commit** | 37f260ab8 fix(gold): use tier-based vault image instead of hardcoded locker |
| **Last Activity** | 2026-04-09 |
| **Total Changelogs** | 30 |

## Recent Changes (14 days)

- **2026-04-09** — fix(gold): migrate to design system tokens — fonts, spacing, images
- **2026-04-09** — fix(gold): use tier-based vault image instead of hardcoded locker
- **2026-04-08** — fix(gold): port Android QA fixes to iOS — defaults, decimals, lander, friction
- **2026-04-08** — fix(gold): use theme fonts instead of raw Font.custom/system
- **2026-04-07** — Merge pull request #1568 from Vance-Club/Update_analytics_app_version_format
- **2026-04-07** — Merge remote-tracking branch 'origin/dev' into feature/wealth-module
- **2026-04-07** — Feature/beneficiary revamp fixes (#1565)
- **2026-04-07** — Cu-86d2gvf7e Aspora Guarantee M1 (#1561)
- **2026-04-07** — fix(gold): Shreeyash design feedback — tabular numbers, remove borders, hide persistent subtitle
- **2026-04-07** — Merge pull request #1571 from Vance-Club/fix/86d239qpw_send_tab_navbar
- **2026-04-07** — fix(gold): add missing paymentInstrument to test factory helper
- **2026-04-07** — fix: resolve 5 iOS CI build errors — theme API, optional unwrap, MainActor
- **2026-04-07** — fix: increase test sleep to 1s for CI reliability (GoldLanderViewModelTests)
- **2026-04-07** — fixed mapping parameters when calling the patch user onboarding api with legacy onboarding version (#1570)
- **2026-04-07** — Merge pull request #1558 from Vance-Club/fix/86d23bux8_rates_comparision_load_time
- **2026-04-07** — Merge branch 'feature/wealth-module' into feature/wealth-module-gold-buy-sell-flow
- **2026-04-07** — fix(gold): add missing paymentInstrument to BuyReviewViewModelTests factory
- **2026-04-07** — fix: relax flaky loadPrice invoke count assertion (== 1 → >= 1)
- **2026-04-07** — feat(gold): add payment-instruments and invoice-download endpoints
- **2026-04-07** — refactor(gold): rename paymentMode → paymentInstrument across API contract

## Feature Areas

- **feat**: 2 commits
- **fix**: 15 commits
- **refactor**: 1 commits
- **chore**: 1 commits

## Frequently Modified Files (last 50 commits)

```
49 
5 VanceTests/Tests/Gold/GoldOrderUseCaseTests.swift
5 VanceTests/Tests/Gold/GoldLanderViewModelTests.swift
5 VanceTests/Tests/Gold/BuyReviewViewModelTests.swift
5 VanceTests/Tests/Gold/BuyGoldViewModelTests.swift
4 VanceTests/Tests/Gold/SellReviewViewModelTests.swift
4 VanceTests/Tests/Gold/SellGoldViewModelTests.swift
4 VanceTests/Tests/Gold/GoldTransactionDetailViewModelTests.swift
3 VanceTests/Mock/MockGoldRepository.swift
3 Aspora/UserInterface/Views/TabBar/SendTab/SendTabView.swift
3 Aspora/UserInterface/Views/Gold/Processing/GoldProcessingView.swift
3 Aspora/UserInterface/Views/Gold/Lander/GoldLanderView.swift
3 Aspora/UserInterface/Views/Gold/GoldAmountEntryView.swift
3 Aspora/UserInterface/Views/Gold/Buy/GoldSellBuyReviewView.swift
3 Aspora/UserInterface/Views/Gold/Buy/BuyGoldViewModel.swift
```
