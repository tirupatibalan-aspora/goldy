# Figma Gold Module Assets Setup

## Status: Directory Structure Ready ✓

All necessary directories and configuration files have been created. The asset PNG files need to be downloaded from Figma URLs and placed in the designated directories.

## Directory Structure Created

### iOS
```
vance-ios/Aspora/Resources/Assets.xcassets/Gold/
├── gold_help_circle.imageset/
│   └── Contents.json ✓
├── gold_partner_goldwise.imageset/
│   └── Contents.json ✓
├── gold_partner_brinks.imageset/
│   └── Contents.json ✓
├── gold_user_avatar.imageset/
│   └── Contents.json ✓
├── gold_vault_shelf.imageset/
│   └── Contents.json ✓
├── gold_vault_top_rail.imageset/
│   └── Contents.json ✓
├── gold_vault_mid_rail.imageset/
│   └── Contents.json ✓
├── gold_coin_stack_1.imageset/
│   └── Contents.json ✓
├── gold_coin_stack_2.imageset/
│   └── Contents.json ✓
├── gold_coin_stack_3.imageset/
│   └── Contents.json ✓
├── gold_avatar_ring.imageset/
│   └── Contents.json ✓
├── gold_pro_tag.imageset/
│   └── Contents.json ✓
└── gold_maximize_icon.imageset/
    └── Contents.json ✓
```

### Android
```
vance-android/app/src/main/res/drawable/
└── (Ready to receive gold_*.png files)
```

## Asset Mapping

| Asset Name | Figma UUID | iOS Path | Android Path |
|---|---|---|---|
| Help Circle Icon | de9dd6d2-3a6a-4447-bdcd-789e21f5390e | `gold_help_circle.imageset/` | `gold_help_circle.png` |
| Goldwise Logo | 60f103cc-e939-4fa4-9231-d9b08e3e1097 | `gold_partner_goldwise.imageset/` | `gold_partner_goldwise.png` |
| Brinks Logo | ea8532c0-b12d-4b39-a31e-9178f8256d83 | `gold_partner_brinks.imageset/` | `gold_partner_brinks.png` |
| User Avatar | 853ec334-7d9c-47a4-9377-d7d1c11d684a | `gold_user_avatar.imageset/` | `gold_user_avatar.png` |
| Vault Shelf | f5c8177b-62d7-4223-a351-b89e7b85abc5 | `gold_vault_shelf.imageset/` | `gold_vault_shelf.png` |
| Vault Top Rail | dd355c17-d814-4072-82f7-e75b10dbc93f | `gold_vault_top_rail.imageset/` | `gold_vault_top_rail.png` |
| Vault Mid Rail | 7b0da9ab-9b7e-4114-a0d4-33feac272c10 | `gold_vault_mid_rail.imageset/` | `gold_vault_mid_rail.png` |
| Coin Stack 1 | 56c921db-40e0-482d-9696-85f74cf2f9a4 | `gold_coin_stack_1.imageset/` | `gold_coin_stack_1.png` |
| Coin Stack 2 | a525d4d1-627d-4327-9e7d-d33c7f1d5d19 | `gold_coin_stack_2.imageset/` | `gold_coin_stack_2.png` |
| Coin Stack 3 | b9b76166-3edf-4e4a-a7e8-7a7d31d4c5cd | `gold_coin_stack_3.imageset/` | `gold_coin_stack_3.png` |
| Avatar Ring | bbda6716-ada5-4f95-9043-65ca9d7210cf | `gold_avatar_ring.imageset/` | `gold_avatar_ring.png` |
| Pro Tag Badge | 9d688104-33a9-4cf6-8954-dac8d1861a1f | `gold_pro_tag.imageset/` | `gold_pro_tag.png` |
| Maximize Icon | 50978cc2-c928-4e83-b140-66a566326045 | `gold_maximize_icon.imageset/` | `gold_maximize_icon.png` |

## Next Steps: Download Assets

### Option 1: Run the Automated Script
A script has been created at: `/sessions/laughing-inspiring-pasteur/mnt/Aspora/download_figma_assets.sh`

```bash
cd /sessions/laughing-inspiring-pasteur/mnt/Aspora
bash download_figma_assets.sh
```

This script will:
1. Download all 13 PNG files from Figma
2. Copy each PNG to the correct iOS imageset directory
3. Copy each PNG to the Android drawable directory
4. Verify all downloads succeeded

### Option 2: Manual Download (if script fails due to network restrictions)

For each asset, download the PNG file and place it:

```bash
# Example for help_circle icon:
curl -L -o /tmp/gold_help_circle.png "https://www.figma.com/api/mcp/asset/de9dd6d2-3a6a-4447-bdcd-789e21f5390e"

# Copy to iOS
cp /tmp/gold_help_circle.png vance-ios/Aspora/Resources/Assets.xcassets/Gold/gold_help_circle.imageset/gold_help_circle.png

# Copy to Android
cp /tmp/gold_help_circle.png vance-android/app/src/main/res/drawable/gold_help_circle.png
```

Repeat for all 13 assets using the UUID-to-filename mapping above.

## iOS Asset Configuration

Each imageset directory contains a `Contents.json` file that tells Xcode:
- Which PNG file to use (1x scale)
- That 2x and 3x scales are not provided (Xcode will auto-scale if needed)

Example `Contents.json`:
```json
{
  "images": [
    {
      "filename": "gold_help_circle.png",
      "idiom": "universal",
      "scale": "1x"
    },
    {
      "idiom": "universal",
      "scale": "2x"
    },
    {
      "idiom": "universal",
      "scale": "3x"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

## Android Asset Configuration

Android PNGs are placed directly in `res/drawable/` without additional configuration.

To reference in code:
```kotlin
ImageVector(painter = painterResource(R.drawable.gold_help_circle))
// or in Compose
Image(painter = painterResource(R.drawable.gold_help_circle))
```

## Usage in Code

### iOS (SwiftUI)
```swift
Image("gold_help_circle")
Image("gold_partner_goldwise")
Image("gold_vault_shelf")
// etc.
```

### Android (Jetpack Compose)
```kotlin
Image(
    painter = painterResource(id = R.drawable.gold_help_circle),
    contentDescription = "Help icon"
)
```

### Android (XML)
```xml
<ImageView
    android:src="@drawable/gold_help_circle"
    android:contentDescription="Help icon" />
```

## Verification

After downloading, verify all assets are in place:

### iOS
```bash
find vance-ios/Aspora/Resources/Assets.xcassets/Gold -name "gold_*.png" | wc -l
# Should output: 13
```

### Android
```bash
ls vance-android/app/src/main/res/drawable/gold_*.png | wc -l
# Should output: 13
```

## Notes

- Figma asset URLs are valid for 7 days from generation
- All PNG files are downloaded at 1x scale
- iOS will automatically scale to 2x and 3x if needed
- For better practice, consider providing 1x, 2x, and 3x versions if available from Figma
- The Contents.json files are already configured for universal idiom (iPhone, iPad)
