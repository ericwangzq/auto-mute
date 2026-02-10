#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
PROBE_NAME="AutoMuteProbe"

mkdir -p "$BUILD_DIR"

AUTO_FILES=("$ROOT_DIR"/src/AutoMute/*.swift)
# Exclude app entry point
AUTO_FILES=(${AUTO_FILES:#*main.swift})

xcrun swiftc \
  -O \
  -framework Cocoa \
  -framework ApplicationServices \
  -framework CoreAudio \
  -framework ServiceManagement \
  -o "$BUILD_DIR/$PROBE_NAME" \
  "${AUTO_FILES[@]}" \
  "$ROOT_DIR/src/Probe/main.swift"

echo "Built $BUILD_DIR/$PROBE_NAME"
