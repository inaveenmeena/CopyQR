#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h}"
APP_DIR="$ROOT_DIR/dist/CopyQR.app"
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
  -framework CoreImage \
  -framework QuartzCore \
  "$ROOT_DIR/Sources/main.m" \
  -o "$MACOS_DIR/CopyQR"

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
