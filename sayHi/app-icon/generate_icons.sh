#!/bin/bash

# Ensure a master image is provided
if [ -z "$1" ]; then
    echo "Error: Please provide a master image."
    echo "Usage: ./generate_icons.sh <path_to_master_image.png>"
    exit 1
fi

MASTER_IMAGE="$1"

# Check if the file exists
if [ ! -f "$MASTER_IMAGE" ]; then
    echo "Error: File '$MASTER_IMAGE' not found."
    exit 1
fi

# Create standard AppIcon directory structure
OUTPUT_DIR="AppIcon.appiconset"
mkdir -p "$OUTPUT_DIR"

echo "Generating iOS launcher icons from '$MASTER_IMAGE' into '$OUTPUT_DIR'..."

# Helper function to resize using sips
resize_icon() {
    local size=$1
    local filename=$2
    sips -z "$size" "$size" "$MASTER_IMAGE" --out "$OUTPUT_DIR/$filename" > /dev/null 2>&1
}

# Generate all required iOS Icon dimensions
resize_icon 20 "icon-20.png"
resize_icon 40 "icon-20@2x.png"
resize_icon 60 "icon-20@3x.png"
resize_icon 29 "icon-29.png"
resize_icon 58 "icon-29@2x.png"
resize_icon 87 "icon-29@3x.png"
resize_icon 40 "icon-40.png"
resize_icon 80 "icon-40@2x.png"
resize_icon 120 "icon-40@3x.png"
resize_icon 120 "icon-60@2x.png"
resize_icon 152 "icon-76@2x.png"
resize_icon 167 "icon-83.5@2x.png"
resize_icon 180 "icon-60@3x.png"
resize_icon 1024 "icon-1024.png"

# Generate the Contents.json file to map everything automatically in Xcode
cat <<EOT > "$OUTPUT_DIR/Contents.json"
{
  "images" : [
    {
      "idiom" : "iphone",
      "size" : "20x20",
      "scale" : "2x",
      "filename" : "icon-20@2x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "20x20",
      "scale" : "3x",
      "filename" : "icon-20@3x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "29x29",
      "scale" : "2x",
      "filename" : "icon-29@2x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "29x29",
      "scale" : "3x",
      "filename" : "icon-29@3x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "40x40",
      "scale" : "2x",
      "filename" : "icon-40@2x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "40x40",
      "scale" : "3x",
      "filename" : "icon-40@3x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "60x60",
      "scale" : "2x",
      "filename" : "icon-60@2x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "60x60",
      "scale" : "3x",
      "filename" : "icon-60@3x.png"
    },
    {
      "idiom" : "ipad",
      "size" : "20x20",
      "scale" : "1x",
      "filename" : "icon-20.png"
    },
    {
      "idiom" : "ipad",
      "size" : "20x20",
      "scale" : "2x",
      "filename" : "icon-20@2x.png"
    },
    {
      "idiom" : "ipad",
      "size" : "29x29",
      "scale" : "1x",
      "filename" : "icon-29.png"
    },
    {
      "idiom" : "ipad",
      "size" : "29x29",
      "scale" : "2x",
      "filename" : "icon-29@2x.png"
    },
    {
      "idiom" : "ipad",
      "size" : "40x40",
      "scale" : "1x",
      "filename" : "icon-40.png"
    },
    {
      "idiom" : "ipad",
      "size" : "40x40",
      "scale" : "2x",
      "filename" : "icon-40@2x.png"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "icon-76@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "83.5x83.5",
      "idiom" : "ipad",
      "filename" : "icon-83.5@2x.png",
      "scale" : "2x"
    },
    {
      "idiom" : "ios-marketing",
      "size" : "1024x1024",
      "scale" : "1x",
      "filename" : "icon-1024.png"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOT

echo "Success! Asset folder '$OUTPUT_DIR' is ready to use."
echo "Drag the entire '$OUTPUT_DIR' folder straight into Xcode Assets."
