#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h}"
APP_DIR="$ROOT_DIR/dist/CopyQR.app"
ZIP_PATH="$ROOT_DIR/dist/CopyQR-macOS.zip"
SIGNING_IDENTITY="${COPYQR_SIGNING_IDENTITY:-CopyQR Local Release}"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

mkdir -p "$MACOS_DIR"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

clang \
  -O \
  -fobjc-arc \
  -fblocks \
  -mmacosx-version-min=13.0 \
  -framework AppKit \
  -framework ApplicationServices \
  -framework Carbon \
  -framework CoreImage \
  -framework QuartzCore \
  -framework ServiceManagement \
  -lz \
  "$ROOT_DIR/Sources/main.m" \
  -o "$MACOS_DIR/CopyQR"

codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_DIR"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"
echo "$APP_DIR"
echo "$ZIP_PATH"
