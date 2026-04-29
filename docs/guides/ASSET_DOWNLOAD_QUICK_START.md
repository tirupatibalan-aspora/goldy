# Figma Assets Download - Quick Start

## Current Status

- [x] All 13 iOS imageset directories created
- [x] All Contents.json files generated
- [x] Android drawable directory ready
- [ ] Asset PNG files downloaded from Figma

## One-Command Download

Choose one method below:

### Method 1: Bash Script (Recommended)
```bash
cd /sessions/laughing-inspiring-pasteur/mnt/Aspora
bash download_figma_assets.sh
```

### Method 2: Python Script
```bash
cd /sessions/laughing-inspiring-pasteur/mnt/Aspora
python3 download_assets.py
```

### Method 3: Manual curl (if scripts fail)
```bash
cd /sessions/laughing-inspiring-pasteur/mnt/Aspora

# Download help circle icon
curl -L -o /tmp/gold_help_circle.png \
  "https://www.figma.com/api/mcp/asset/de9dd6d2-3a6a-4447-bdcd-789e21f5390e"
cp /tmp/gold_help_circle.png \
  "vance-ios/Aspora/Resources/Assets.xcassets/Gold/gold_help_circle.imageset/"
cp /tmp/gold_help_circle.png \
  "vance-android/app/src/main/res/drawable/"

# ... repeat for each of the 13 assets (see full list in FIGMA_ASSETS_SETUP.md)
```

## Asset UUIDs (for manual download)

| Name | UUID |
|------|------|
| help_circle | de9dd6d2-3a6a-4447-bdcd-789e21f5390e |
| partner_goldwise | 60f103cc-e939-4fa4-9231-d9b08e3e1097 |
| partner_brinks | ea8532c0-b12d-4b39-a31e-9178f8256d83 |
| user_avatar | 853ec334-7d9c-47a4-9377-d7d1c11d684a |
| vault_shelf | f5c8177b-62d7-4223-a351-b89e7b85abc5 |
| vault_top_rail | dd355c17-d814-4072-82f7-e75b10dbc93f |
| vault_mid_rail | 7b0da9ab-9b7e-4114-a0d4-33feac272c10 |
| coin_stack_1 | 56c921db-40e0-482d-9696-85f74cf2f9a4 |
| coin_stack_2 | a525d4d1-627d-4327-9e7d-d33c7f1d5d19 |
| coin_stack_3 | b9b76166-3edf-4e4a-a7e8-7a7d31d4c5cd |
| avatar_ring | bbda6716-ada5-4f95-9043-65ca9d7210cf |
| pro_tag | 9d688104-33a9-4cf6-8954-dac8d1861a1f |
| maximize_icon | 50978cc2-c928-4e83-b140-66a566326045 |

## Verify Download Success

```bash
# Check iOS
find /sessions/laughing-inspiring-pasteur/mnt/Aspora/vance-ios/Aspora/Resources/Assets.xcassets/Gold -name "gold_*.png" | wc -l
# Should output: 13

# Check Android
ls /sessions/laughing-inspiring-pasteur/mnt/Aspora/vance-android/app/src/main/res/drawable/gold_*.png | wc -l
# Should output: 13
```

## Files Provided

- `download_figma_assets.sh` - Bash script to download all assets
- `download_assets.py` - Python script as alternative
- `FIGMA_ASSETS_SETUP.md` - Complete documentation
- `ASSET_DOWNLOAD_QUICK_START.md` - This file

## Documentation

See `FIGMA_ASSETS_SETUP.md` for:
- Complete directory structure
- Asset mapping details
- iOS/Android configuration options
- Code usage examples
