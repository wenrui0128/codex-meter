#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CodexQuotaIsland"
DISPLAY_NAME="CodexMeter"
VERSION="0.1.0"
ICON_SOURCE="${ICON_SOURCE:-$ROOT_DIR/Packaging/AppIconSource.png}"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$DIST_DIR/dmg-stage"
APP_DIR="$STAGE_DIR/$DISPLAY_NAME.app"
ICONSET_DIR="$DIST_DIR/AppIcon.iconset"
DMG_PATH="$DIST_DIR/${DISPLAY_NAME}-${VERSION}-unsigned.dmg"

cd "$ROOT_DIR"

swift build -c release

rm -rf "$STAGE_DIR" "$ICONSET_DIR" "$DMG_PATH"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$DIST_DIR"

cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
cp -R "$ROOT_DIR/Packaging/en.lproj" "$APP_DIR/Contents/Resources/en.lproj"
cp -R "$ROOT_DIR/Packaging/zh-Hans.lproj" "$APP_DIR/Contents/Resources/zh-Hans.lproj"
cp "$ROOT_DIR/Packaging/Read Me.txt" "$STAGE_DIR/Read Me.txt"
cp "$ROOT_DIR/Packaging/DMG-使用说明.txt" "$STAGE_DIR/使用说明.txt"

if [[ -f "$ICON_SOURCE" ]]; then
  mkdir -p "$ICONSET_DIR"
  sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
else
  echo "Warning: icon source not found: $ICON_SOURCE" >&2
fi

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
  -volname "$DISPLAY_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "$DMG_PATH"
