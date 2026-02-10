#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_NAME="AutoMute"
DMG_NAME="AutoMute"
STAGE_DIR="$BUILD_DIR/dmg"

"$ROOT_DIR/scripts/build_app.sh"

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
cp -R "$BUILD_DIR/$APP_NAME.app" "$STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create -volname "$DMG_NAME" -srcfolder "$STAGE_DIR" -ov -format UDZO "$BUILD_DIR/$DMG_NAME.dmg"

echo "Built $BUILD_DIR/$DMG_NAME.dmg"
