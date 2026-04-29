---
name: Gold Error State Hero Plan
description: iOS error state for existing user hero — info tooltip, stale price pill, scroll-to-hide, question mark icon
type: project
---

# Gold Error State — Existing User Hero (iOS first)

## Figma Reference
- Node: 2-39914 (error state frame)
- Question mark icon: 2:39855

## What to Build

### 1. Info (ⓘ) Button Next to Portfolio Value
- Small circled-i icon inline with "AED 1,343.23"
- Only visible when price data is stale (`isPriceStale == true`)
- Tap toggles tooltip

### 2. Tooltip Popup
- Text: "Latest price data is temporarily unavailable. But your Gold weight is accurate."
- Background: warm cream/beige (#FFF5E0 approx)
- Rounded corners, appears below AED value
- Auto-hides on scroll

### 3. Stale Price Pill (replaces Live Price Banner)
- When price is stale, show: clock icon + "Last Updated X mins ago" (orange) + "AED Y/g" (black)
- Replaces the red dot live price banner
- Capsule shape, light background

### 4. Scroll-to-Hide Tooltip
- Use PreferenceKey to track scroll offset in GoldLanderView
- When scroll offset changes → dismiss tooltip

### 5. Question Mark Icon
- Replace SF Symbol `questionmark.circle` with Figma asset from node 2:39855
- Bold circled question mark

## Files to Modify
| File | Change |
|------|--------|
| `GoldLanderViewModel.swift` | Add `isPriceStale`, `lastPriceUpdate`, `showPriceTooltip`, `formattedLastUpdated`, `formattedStalePrice` |
| `GoldLanderExistingUserHeroSection.swift` | Add info button, tooltip, stale price pill |
| `GoldLanderView.swift` | Scroll tracking to hide tooltip, pass new bindings, update ? icon |
| `GoldColors.swift` | Tooltip background color |
| `GoldImages.swift` | Question mark icon asset reference |
| `Localizable.strings` | New strings for tooltip, last updated |
| `GoldLivePriceBanner.swift` | No change — replaced by stale pill when stale |

## Strings
- `gold_price_unavailable_tooltip` = "Latest price data is temporarily unavailable.\nBut your Gold weight is accurate."
- `gold_last_updated_format` = "Last Updated %@ ago"
- `gold_stale_price_format` = "%@ %@/g" (currency + price)
