#!/bin/bash
# Download Figma Gold Module Assets and organize for iOS & Android
# This script downloads all 13 assets from the Portfolio Screen (29168:5694)
# Compatible with macOS bash 3.x (no associative arrays)

set -e

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory (where this script lives)
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Paths (relative to BASE_DIR)
IOS_ASSETS_DIR="$BASE_DIR/your-ios-app/YourApp/Resources/Assets.xcassets/Gold"
ANDROID_DRAWABLE_DIR="$BASE_DIR/your-android-app/app/src/main/res/drawable"
TEMP_DIR="/tmp/figma_assets_$$"

# Asset list: "uuid|filename" pairs
ASSET_LIST=(
    "de9dd6d2-3a6a-4447-bdcd-789e21f5390e|gold_help_circle"
    "60f103cc-e939-4fa4-9231-d9b08e3e1097|gold_partner_goldwise"
    "ea8532c0-b12d-4b39-a31e-9178f8256d83|gold_partner_brinks"
    "853ec334-7d9c-47a4-9377-d7d1c11d684a|gold_user_avatar"
    "f5c8177b-62d7-4223-a351-b89e7b85abc5|gold_vault_shelf"
    "dd355c17-d814-4072-82f7-e75b10dbc93f|gold_vault_top_rail"
    "7b0da9ab-9b7e-4114-a0d4-33feac272c10|gold_vault_mid_rail"
    "56c921db-40e0-482d-9696-85f74cf2f9a4|gold_coin_stack_1"
    "a525d4d1-627d-4327-9e7d-d33c7f1d5d19|gold_coin_stack_2"
    "b9b76166-3edf-4e4a-a7e8-7a7d31d4c5cd|gold_coin_stack_3"
    "bbda6716-ada5-4f95-9043-65ca9d7210cf|gold_avatar_ring"
    "9d688104-33a9-4cf6-8954-dac8d1861a1f|gold_pro_tag"
    "50978cc2-c928-4e83-b140-66a566326045|gold_maximize_icon"
)

TOTAL=${#ASSET_LIST[@]}

# Create temp directory
mkdir -p "$TEMP_DIR"

echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "$IOS_ASSETS_DIR"
mkdir -p "$ANDROID_DRAWABLE_DIR"

echo -e "${BLUE}Downloading $TOTAL assets from Figma...${NC}"

download_count=0
success_count=0

for entry in "${ASSET_LIST[@]}"; do
    uuid="${entry%%|*}"
    filename="${entry##*|}"
    url="https://www.figma.com/api/mcp/asset/$uuid"

    download_count=$((download_count + 1))
    echo -n "[$download_count/$TOTAL] Downloading $filename... "

    if curl -sL -o "$TEMP_DIR/${filename}.png" "$url" 2>/dev/null; then
        file_size=$(stat -f%z "$TEMP_DIR/${filename}.png" 2>/dev/null || stat -c%s "$TEMP_DIR/${filename}.png" 2>/dev/null)

        if [ "$file_size" -gt 0 ]; then
            echo -e "${GREEN}✓ (${file_size} bytes)${NC}"
            success_count=$((success_count + 1))

            # Copy to iOS xcassets
            ios_imageset="$IOS_ASSETS_DIR/${filename}.imageset"
            mkdir -p "$ios_imageset"
            cp "$TEMP_DIR/${filename}.png" "$ios_imageset/${filename}.png"

            # Create Contents.json for iOS
            cat > "$ios_imageset/Contents.json" << EOF
{
  "images": [
    {
      "filename": "${filename}.png",
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
EOF

            # Copy to Android drawable
            cp "$TEMP_DIR/${filename}.png" "$ANDROID_DRAWABLE_DIR/${filename}.png"
        else
            echo -e "${RED}✗ (empty file)${NC}"
        fi
    else
        echo -e "${RED}✗ (download failed)${NC}"
    fi
done

# Cleanup temp
rm -rf "$TEMP_DIR"

echo ""
echo -e "${BLUE}Summary:${NC}"
echo -e "Downloaded: $success_count / $download_count"

if [ "$success_count" -eq "$TOTAL" ]; then
    echo -e "${GREEN}All assets downloaded successfully!${NC}"

    echo -e "\n${BLUE}iOS Assets:${NC}"
    find "$IOS_ASSETS_DIR" -name "*.png" | sort

    echo -e "\n${BLUE}Android Assets:${NC}"
    find "$ANDROID_DRAWABLE_DIR" -name "gold_*.png" | sort

    exit 0
else
    echo -e "${RED}Some assets failed to download ($success_count/$TOTAL). Check the URLs and try again.${NC}"
    exit 1
fi
