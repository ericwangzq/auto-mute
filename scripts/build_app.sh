#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_NAME="AutoMute"

mkdir -p "$BUILD_DIR"

SWIFT_FILES=("$ROOT_DIR"/src/AutoMute/*.swift)

xcrun swiftc \
  -O \
  -framework Cocoa \
  -framework ApplicationServices \
  -framework CoreAudio \
  -framework ServiceManagement \
  -o "$BUILD_DIR/$APP_NAME" \
  "${SWIFT_FILES[@]}"

APP_DIR="$BUILD_DIR/$APP_NAME.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/resources/AutoMute.icns" "$APP_DIR/Contents/Resources/AutoMute.icns"
cp "$ROOT_DIR/resources/menubar-icon.png" "$APP_DIR/Contents/Resources/menubar-icon.png"

echo "Built $APP_DIR"
