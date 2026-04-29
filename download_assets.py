#!/usr/bin/env python3
"""
Download Figma Gold Module Assets
Handles downloading from Figma and organizing files for iOS & Android
"""

import requests
import json
import os
import sys
from pathlib import Path

# Asset mapping
ASSETS = {
    "de9dd6d2-3a6a-4447-bdcd-789e21f5390e": "gold_help_circle",
    "60f103cc-e939-4fa4-9231-d9b08e3e1097": "gold_partner_goldwise",
    "ea8532c0-b12d-4b39-a31e-9178f8256d83": "gold_partner_brinks",
    "853ec334-7d9c-47a4-9377-d7d1c11d684a": "gold_user_avatar",
    "f5c8177b-62d7-4223-a351-b89e7b85abc5": "gold_vault_shelf",
    "dd355c17-d814-4072-82f7-e75b10dbc93f": "gold_vault_top_rail",
    "7b0da9ab-9b7e-4114-a0d4-33feac272c10": "gold_vault_mid_rail",
    "56c921db-40e0-482d-9696-85f74cf2f9a4": "gold_coin_stack_1",
    "a525d4d1-627d-4327-9e7d-d33c7f1d5d19": "gold_coin_stack_2",
    "b9b76166-3edf-4e4a-a7e8-7a7d31d4c5cd": "gold_coin_stack_3",
    "bbda6716-ada5-4f95-9043-65ca9d7210cf": "gold_avatar_ring",
    "9d688104-33a9-4cf6-8954-dac8d1861a1f": "gold_pro_tag",
    "50978cc2-c928-4e83-b140-66a566326045": "gold_maximize_icon",
}

# Paths
BASE_DIR = Path(__file__).parent
IOS_ASSETS_DIR = BASE_DIR / "your-ios-app/YourApp/Resources/Assets.xcassets/Gold"
ANDROID_DRAWABLE_DIR = BASE_DIR / "your-android-app/app/src/main/res/drawable"

def download_asset(uuid: str, filename: str) -> bool:
    """Download a single asset from Figma"""
    url = f"https://www.figma.com/api/mcp/asset/{uuid}"

    try:
        print(f"Downloading {filename}...", end=" ", flush=True)
        response = requests.get(url, timeout=30)
        response.raise_for_status()

        if len(response.content) == 0:
            print("ERROR: Empty response")
            return False

        # Save to temporary location
        temp_path = Path("/tmp") / f"{filename}.png"
        with open(temp_path, "wb") as f:
            f.write(response.content)

        file_size = temp_path.stat().st_size
        print(f"OK ({file_size} bytes)")

        # Copy to iOS
        ios_imageset = IOS_ASSETS_DIR / f"{filename}.imageset"
        ios_png = ios_imageset / f"{filename}.png"
        ios_png.write_bytes(response.content)

        # Copy to Android
        android_png = ANDROID_DRAWABLE_DIR / f"{filename}.png"
        android_png.write_bytes(response.content)

        # Cleanup temp
        temp_path.unlink()

        return True

    except requests.exceptions.RequestException as e:
        print(f"ERROR: {e}")
        return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False

def main():
    """Download all assets"""
    print("Figma Gold Module Assets Downloader")
    print("=" * 50)
    print()

    # Verify directories exist
    if not IOS_ASSETS_DIR.exists():
        print(f"ERROR: iOS assets directory not found: {IOS_ASSETS_DIR}")
        return False

    if not ANDROID_DRAWABLE_DIR.exists():
        print(f"ERROR: Android drawable directory not found: {ANDROID_DRAWABLE_DIR}")
        return False

    print(f"iOS Assets Dir: {IOS_ASSETS_DIR}")
    print(f"Android Drawable Dir: {ANDROID_DRAWABLE_DIR}")
    print()

    # Download all assets
    success_count = 0
    total_count = len(ASSETS)

    for uuid, filename in ASSETS.items():
        if download_asset(uuid, filename):
            success_count += 1

    print()
    print("=" * 50)
    print(f"Downloaded: {success_count}/{total_count}")

    if success_count == total_count:
        print("All assets downloaded successfully!")

        # List files
        print()
        print("iOS Assets:")
        for img_file in sorted(IOS_ASSETS_DIR.glob("*/*.png")):
            size = img_file.stat().st_size
            print(f"  {img_file.relative_to(BASE_DIR)} ({size} bytes)")

        print()
        print("Android Assets:")
        for img_file in sorted(ANDROID_DRAWABLE_DIR.glob("gold_*.png")):
            size = img_file.stat().st_size
            print(f"  {img_file.relative_to(BASE_DIR)} ({size} bytes)")

        return True
    else:
        print(f"Some assets failed to download!")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
