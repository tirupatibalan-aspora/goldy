---
name: Gold Vault Tier Images Plan
description: Wire tier-based vault illustrations on lander hero — 11 weight tiers from Designer D's Figma comments mapped to purple vault variants
type: project
---

# Plan: Gold Vault Tier-Based Illustrations

## Figma Reference
- **Node**: 813:17138 (coin/biscuit/bar assets)
- **Component set**: 813:17145 (`Coin-01`)
- **File**: Gold Master (`6obK4hFS4KxDiB8wIv1v9r`)

## Designer D's Weight Mapping (from Figma comments, 2026-04-04)

Designer D annotated each vault variant with exact weight ranges:

| # | Weight Range | Category | Visual | Asset Name |
|---|-------------|----------|--------|------------|
| 0 | 0g | No Gold | Empty purple vault | `gold-vault-empty` |
| 1 | >0g ≤0.1g | Coin | 1 small coin | `gold-vault-coin-01` |
| 2 | ≥0.3g <0.5g | Coin | 2 coins | `gold-vault-coin-02` |
| 3 | ≥0.5g <1g | Coin | 3 coins | `gold-vault-coin-03` |
| 4 | ≥1g <2g | Coin | Many coins | `gold-vault-coin-04` |
| 5 | ≥2g <3g | Biscuit | 1 biscuit | `gold-vault-biscuit-01` |
| 6 | ≥3g <5g | Biscuit | 2 biscuits | `gold-vault-biscuit-02` |
| 7 | ≥5g <10g | Biscuit | 3 biscuits | `gold-vault-biscuit-03` |
| 8 | ≥10g <20g | Biscuit | Many biscuits | `gold-vault-biscuit-04` |
| 9 | ≥20g <50g | Bar | 1+ bars | `gold-vault-bar-01` |
| 10 | ≥50g | Bar | Multiple bars | `gold-vault-bar-02` |

**Gap**: 0.1g to 0.3g not explicitly mentioned — assumed Coin-01 covers >0g to <0.3g.

**Note from Designer D**: "done. Do wait to change this until the updated scaling for the coins and bars comes from Designer S"
**Note from Designer S**: "FYI, the coins are bigger than biscuits, will update that and share"

> **BLOCKER**: Designer S said he'll update the coin/biscuit scaling. Assets may not be final. Need to confirm before exporting.

## Current State

### Existing assets (OLD silver design — DEAD):
| Asset | Design | Used? |
|-------|--------|-------|
| `gold-vault-0gm` | Silver vault, empty | NO |
| `gold-vault-0_1g` | Silver vault, 2 coins | NO |
| `gold-vault-1_5g` | Silver vault, coin stack | NO |
| `gold-vault-5_10g` | Silver vault, tall stack | NO |
| `gold-vault-10plus` | Silver vault, many coins | NO |

### Existing assets (NEW purple design — IN USE):
| Asset | Design | Used? |
|-------|--------|-------|
| `gold-hero-locker` | Purple vault + 2 coins | YES — static for ALL existing users |

### Code:
- `GoldVaultTier` enum: 5 tiers (`.empty`, `.tier0To1g`, `.tier1To5g`, `.tier5To10g`, `.tier10Plus`)
- `GoldVaultTier.fromWeight(Decimal)` — maps weight → tier (NEEDS EXPANSION to 11 tiers)
- `GoldLanderExistingUserHeroSection`: receives `vaultTier` but uses static `GoldImages.heroLocker`
- `GoldLanderViewModel.vaultTier` — computed from `portfolio.totalWeight`

## Implementation Tasks

### Task 1: Expand GoldVaultTier enum (11 tiers)

`Domain/Models/Gold/GoldPortfolio.swift`:
```swift
enum GoldVaultTier: Sendable, Equatable {
    case empty          // 0g
    case coin01         // >0g <0.3g
    case coin02         // ≥0.3g <0.5g
    case coin03         // ≥0.5g <1g
    case coin04         // ≥1g <2g
    case biscuit01      // ≥2g <3g
    case biscuit02      // ≥3g <5g
    case biscuit03      // ≥5g <10g
    case biscuit04      // ≥10g <20g
    case bar01          // ≥20g <50g
    case bar02          // ≥50g

    static func fromWeight(_ weight: Decimal) -> GoldVaultTier {
        if weight <= 0 { return .empty }
        if weight < 0.3 { return .coin01 }
        if weight < 0.5 { return .coin02 }
        if weight < 1 { return .coin03 }
        if weight < 2 { return .coin04 }
        if weight < 3 { return .biscuit01 }
        if weight < 5 { return .biscuit02 }
        if weight < 10 { return .biscuit03 }
        if weight < 20 { return .biscuit04 }
        if weight < 50 { return .bar01 }
        return .bar02
    }
}
```

### Task 2: Export 11 vault assets from Figma
- Export each variant as PNG @3x from Figma node 813:17138
- Add to `Assets.xcassets/Gold/` with proper imageset folders
- Naming: `gold-vault-empty`, `gold-vault-coin-01` through `gold-vault-bar-02`

### Task 3: Add images to GoldImages.swift
```swift
// MARK: - Vault Tiers (Figma 813:17138, Designer D weight mapping)
static func vaultImage(for tier: GoldVaultTier) -> Image {
    switch tier {
    case .empty:     return Image("gold-vault-empty")
    case .coin01:    return Image("gold-vault-coin-01")
    case .coin02:    return Image("gold-vault-coin-02")
    case .coin03:    return Image("gold-vault-coin-03")
    case .coin04:    return Image("gold-vault-coin-04")
    case .biscuit01: return Image("gold-vault-biscuit-01")
    case .biscuit02: return Image("gold-vault-biscuit-02")
    case .biscuit03: return Image("gold-vault-biscuit-03")
    case .biscuit04: return Image("gold-vault-biscuit-04")
    case .bar01:     return Image("gold-vault-bar-01")
    case .bar02:     return Image("gold-vault-bar-02")
    }
}
```

### Task 4: Wire into GoldLanderExistingUserHeroSection
Replace static image (line 61):
```swift
// Before:
GoldImages.heroLocker
// After:
GoldImages.vaultImage(for: vaultTier)
```

### Task 5: Clean up old silver vault assets
Remove dead assets (old design, never referenced in code):
- `gold-vault-0gm.imageset/`
- `gold-vault-0_1g.imageset/`
- `gold-vault-1_5g.imageset/`
- `gold-vault-5_10g.imageset/`
- `gold-vault-10plus.imageset/`

> **CAUTION**: Grep all views before deleting per feedback_asset_dedup_caution.md

### Task 6: Update tests
Update `GoldVaultTier.fromWeight` tests for new 11-tier mapping:
```swift
@Test("0g → empty")
@Test("0.05g → coin01")
@Test("0.3g → coin02")
@Test("0.7g → coin03")
@Test("1.5g → coin04")
@Test("2.5g → biscuit01")
@Test("4g → biscuit02")
@Test("7g → biscuit03")
@Test("15g → biscuit04")
@Test("30g → bar01")
@Test("100g → bar02")
```

### Task 7: Android parity
Same 11-tier mapping in Android `GoldVaultTier` → drawable resources.

## Files to Modify

| File | Change |
|------|--------|
| `Domain/Models/Gold/GoldPortfolio.swift` | Expand `GoldVaultTier` from 5 → 11 tiers |
| `Assets.xcassets/Gold/` | Add 11 new imagesets, remove 5 old silver ones |
| `Styles/Gold/GoldImages.swift` | Add `vaultImage(for:)` function |
| `Lander/Sections/GoldLanderExistingUserHeroSection.swift` | Use dynamic vault image |
| `VanceTests/Tests/Gold/GoldMarketTests.swift` | Update vault tier tests |

## Blockers
1. **ASSETS NOT FINAL**: Designer S said he'll update coin/biscuit scaling. Need confirmation before exporting.
2. **Asset export**: Need to export 11 PNGs from Figma at @3x once finalized.

## Validation
| Weight | Expected |
|--------|----------|
| 0g | Empty purple vault |
| 0.05g | 1 small coin |
| 0.4g | 2 coins |
| 0.8g | 3 coins |
| 1.5g | Many coins |
| 2.5g | 1 biscuit |
| 4g | 2 biscuits |
| 7g | 3 biscuits |
| 15g | Many biscuits |
| 35g | 1+ bars |
| 100g | Multiple bars |
