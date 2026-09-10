#!/bin/bash
# Build ClipboardManager.app from source. Requires only Xcode Command Line Tools.
# Usage: scripts/build-app.sh [OUTPUT_DIR]
# Env:   SIGN_IDENTITY  signing identity ("-" = ad-hoc). Default: self-signed cert if
#                       present in the keychain, otherwise ad-hoc.
#        ARCHS          space separated arch list. Default: "arm64 x86_64".
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$PROJECT_DIR/ClipboardManager"
PBXPROJ="$PROJECT_DIR/ClipboardManager.xcodeproj/project.pbxproj"
ENTITLEMENTS="$SRC_DIR/ClipboardManager.entitlements"
ICON_DIR="$SRC_DIR/Assets.xcassets/AppIcon.appiconset"
APP_NAME="ClipboardManager"
CERT_NAME="ClipboardManager Self-Signed"

OUT_DIR="${1:-$PROJECT_DIR/dist}"
ARCHS="${ARCHS:-arm64 x86_64}"

build_setting() {
  sed -n "s/.*[[:space:]]$1 = \\([^;]*\\);.*/\\1/p" "$PBXPROJ" | head -1 | tr -d '"'
}

BUNDLE_ID=$(build_setting PRODUCT_BUNDLE_IDENTIFIER)
VERSION=$(build_setting MARKETING_VERSION)
BUILD_NUMBER=$(build_setting CURRENT_PROJECT_VERSION)
DEPLOY_TARGET=$(build_setting MACOSX_DEPLOYMENT_TARGET)
SDK=$(xcrun --show-sdk-path --sdk macosx)

if [ -z "${SIGN_IDENTITY:-}" ]; then
  if security find-identity -v -p codesigning 2>/dev/null | grep -q "$CERT_NAME"; then
    SIGN_IDENTITY="$CERT_NAME"
  else
    SIGN_IDENTITY="-"
  fi
fi

WORK=$(mktemp -d -t cm-build)
trap 'rm -rf "$WORK"' EXIT

APP="$WORK/$APP_NAME.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "==> Compiling $APP_NAME $VERSION ($BUILD_NUMBER) for: $ARCHS"
SLICES=()
for arch in $ARCHS; do
  swiftc \
    -O -swift-version 5 \
    -sdk "$SDK" \
    -target "$arch-apple-macos$DEPLOY_TARGET" \
    -o "$WORK/$APP_NAME-$arch" \
    "$SRC_DIR"/*.swift
  SLICES+=("$WORK/$APP_NAME-$arch")
done
lipo -create "${SLICES[@]}" -output "$APP/Contents/MacOS/$APP_NAME"

echo "==> Building app icon"
ICON_SRC=$(ls -S "$ICON_DIR"/*.png | head -1)
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
while read -r px name; do
  sips -z "$px" "$px" "$ICON_SRC" --out "$ICONSET/$name.png" >/dev/null
done <<'SIZES'
16 icon_16x16
32 icon_16x16@2x
32 icon_32x32
64 icon_32x32@2x
128 icon_128x128
256 icon_128x128@2x
256 icon_256x256
512 icon_256x256@2x
512 icon_512x512
1024 icon_512x512@2x
SIZES
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

echo "==> Writing bundle metadata"
printf 'APPL????' > "$APP/Contents/PkgInfo"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>$APP_NAME</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>$BUNDLE_ID</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$APP_NAME</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$VERSION</string>
	<key>CFBundleVersion</key>
	<string>$BUILD_NUMBER</string>
	<key>LSMinimumSystemVersion</key>
	<string>$DEPLOY_TARGET</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null

echo "==> Signing with: $SIGN_IDENTITY"
codesign --force \
  --sign "$SIGN_IDENTITY" \
  --identifier "$BUNDLE_ID" \
  --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --timestamp=none \
  "$APP"
codesign --verify --strict --verbose=1 "$APP"

mkdir -p "$OUT_DIR"
rm -rf "$OUT_DIR/$APP_NAME.app"
ditto "$APP" "$OUT_DIR/$APP_NAME.app"
echo "==> Built: $OUT_DIR/$APP_NAME.app"
