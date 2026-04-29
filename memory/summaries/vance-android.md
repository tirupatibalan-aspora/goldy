# vance-android — Summary

| Field | Value |
|-------|-------|
| **Branch** | `feature/wealth-module-gold-qa-fixes` |
| **Last Commit** | 120363bff5 fix: Partners section — show only O Gold, update text labels per Figma |
| **Last Activity** | 2026-04-10 |
| **Total Changelogs** | 36 |

## Recent Changes (14 days)

- **2026-04-10** — fix: Display weight in grams, not milligrams on lander hero
- **2026-04-10** — feat: Tier-based vault illustrations — 11 weight tiers from Figma
- **2026-04-10** — fix: Partners section — show only O Gold, update text labels per Figma
- **2026-04-09** — fix(gold): fix backstack — processing screen visible on back after success/failed
- **2026-04-09** — docs: add Gold Module Handbook — single source of truth for Android
- **2026-04-09** — fix(gold): auto-refresh cart on timer expiry for buy mode (P0 QA fix)
- **2026-04-09** — docs: update Goldy description in handbook
- **2026-04-09** — fix(gold): use tier-based vault image instead of hardcoded locker
- **2026-04-09** — docs: add PR #XXXX and Goldy README links to handbook
- **2026-04-09** — docs: update handbook — Goldy workspace structure + reserved commands
- **2026-04-08** — fix(gold): QA quick wins batch 2 — defaults, min sell, lander cleanup
- **2026-04-08** — fix: revert max buy to 55K + remove sell friction sheets
- **2026-04-08** — fix(gold): QA quick wins — decimal limits, zero display, sell loader copies
- **2026-04-07** — feat(gold): 7-part segmented confirmation animation (P0-2, P1-8)
- **2026-04-07** — refactor(gold): rename paymentMode → paymentInstrument across API contract
- **2026-04-07** — fix(gold): Designer S design feedback — tabular numbers, remove borders, hide persistent subtitle
- **2026-04-07** — feat(gold): add payment-instruments and invoice-download endpoints + fix stale tests
- **2026-04-07** — Merge pull request #XXXX from your-org/feature/wealth-module-gold-buy-sell-flow
- **2026-04-06** — fix(gold): sell confirm shows AED amount as primary, not weight
- **2026-04-06** — fix(P1-3): Confirm Purchase amount in black instead of gradient

## Feature Areas

- **feat**: 4 commits
- **fix**: 24 commits
- **refactor**: 1 commits
- **docs**: 4 commits
- **style**: 1 commits

## Frequently Modified Files (last 50 commits)

```
49 
8 app/src/main/res/values/strings.xml
6 app/src/main/java/tech/vance/app/ui/gold/sell/logic/GoldSellFeature.kt
6 app/src/main/java/tech/vance/app/ui/gold/review/logic/GoldOrderReviewFeature.kt
5 app/src/test/java/tech/vance/app/ui/gold/sell/logic/GoldSellFeatureTest.kt
5 app/src/test/java/tech/vance/app/ui/gold/review/logic/GoldOrderReviewFeatureTest.kt
4 GOLD_MODULE_HANDBOOK.md
4 app/src/main/java/tech/vance/app/ui/gold/review/ui/GoldOrderReviewScreen.kt
3 data-layer/src/main/java/tech/vance/app/data_layer/network/gold/repository/GoldRepository.kt
3 app/src/test/java/tech/vance/app/ui/gold/GoldFormatterTest.kt
3 app/src/test/java/tech/vance/app/ui/gold/buy/logic/GoldBuyFeatureTest.kt
3 app/src/main/java/tech/vance/app/ui/gold/home/ui/sections/GoldExistingUserHeroSection.kt
3 app/src/main/java/tech/vance/app/ui/gold/GoldFormatter.kt
3 app/src/main/java/tech/vance/app/ui/gold/buy/logic/GoldBuyFeature.kt
3 .claude/skills/generate-ids/SKILL.md
```
