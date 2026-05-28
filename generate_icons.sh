#!/bin/bash
set -e

SOURCE_ICON="/Users/napkin/.gemini/antigravity/brain/7e0deeb7-f30e-4e43-9a0e-1c96fbef37dd/aeroloop_appicon_1779883666137.png"
ICONSET_DIR="/Users/napkin/IdeaProjects/Aeroloop/AeroLoop/Resources/Assets.xcassets/AppIcon.appiconset"

# Ensure the source icon exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "Source icon not found!"
    exit 1
fi

# Define sizes
SIZES=(
    "16x16_1x:16"
    "16x16_2x:32"
    "32x32_1x:32"
    "32x32_2x:64"
    "128x128_1x:128"
    "128x128_2x:256"
    "256x256_1x:256"
    "256x256_2x:512"
    "512x512_1x:512"
    "512x512_2x:1024"
)

# Generate images
for entry in "${SIZES[@]}"; do
    NAME="${entry%%:*}"
    SIZE="${entry##*:}"
    FILENAME="icon_${NAME}.png"
    sips -z $SIZE $SIZE "$SOURCE_ICON" --out "$ICONSET_DIR/$FILENAME"
done

# Generate Contents.json
cat << JSON > "$ICONSET_DIR/Contents.json"
{
  "images" : [
    {
      "idiom" : "mac",
      "size" : "16x16",
      "scale" : "1x",
      "filename" : "icon_16x16_1x.png"
    },
    {
      "idiom" : "mac",
      "size" : "16x16",
      "scale" : "2x",
      "filename" : "icon_16x16_2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "32x32",
      "scale" : "1x",
      "filename" : "icon_32x32_1x.png"
    },
    {
      "idiom" : "mac",
      "size" : "32x32",
      "scale" : "2x",
      "filename" : "icon_32x32_2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "128x128",
      "scale" : "1x",
      "filename" : "icon_128x128_1x.png"
    },
    {
      "idiom" : "mac",
      "size" : "128x128",
      "scale" : "2x",
      "filename" : "icon_128x128_2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "256x256",
      "scale" : "1x",
      "filename" : "icon_256x256_1x.png"
    },
    {
      "idiom" : "mac",
      "size" : "256x256",
      "scale" : "2x",
      "filename" : "icon_256x256_2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "512x512",
      "scale" : "1x",
      "filename" : "icon_512x512_1x.png"
    },
    {
      "idiom" : "mac",
      "size" : "512x512",
      "scale" : "2x",
      "filename" : "icon_512x512_2x.png"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

echo "AppIcon generation complete."
