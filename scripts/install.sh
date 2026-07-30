#!/bin/bash
# Build ClipboardManager (Release), sign with self-signed cert, install to /Applications.
# Run scripts/setup-cert.sh once before this.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="ClipboardManager"
CONFIG="Release"
CERT_NAME="ClipboardManager Self-Signed"
APP_NAME="ClipboardManager.app"
INSTALL_DIR="/Applications"
ENTITLEMENTS="$PROJECT_DIR/ClipboardManager/ClipboardManager.entitlements"

if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "$CERT_NAME"; then
  echo "ERROR: signing identity '$CERT_NAME' not found."
  echo "Run scripts/setup-cert.sh first."
  exit 1
fi

BUILD_DIR=$(mktemp -d -t cm-build)
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "==> Building $SCHEME ($CONFIG)..."
cd "$PROJECT_DIR"
xcodebuild \
  -project ClipboardManager.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$CERT_NAME" \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
  build >/dev/null

BUILT_APP="$BUILD_DIR/Build/Products/$CONFIG/$APP_NAME"
if [ ! -d "$BUILT_APP" ]; then
  echo "ERROR: build did not produce $BUILT_APP"
  exit 1
fi

echo "==> Re-signing with hardened runtime + entitlements..."
codesign --force --deep \
  --sign "$CERT_NAME" \
  --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --timestamp=none \
  "$BUILT_APP"

echo "==> Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$BUILT_APP"

echo "==> Quitting any running instance..."
osascript -e 'tell application "ClipboardManager" to quit' >/dev/null 2>&1 || true
sleep 1
pkill -f "/Applications/$APP_NAME/Contents/MacOS/ClipboardManager" 2>/dev/null || true

echo "==> Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/$APP_NAME"
ditto "$BUILT_APP" "$INSTALL_DIR/$APP_NAME"

echo "==> Removing quarantine attribute..."
xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP_NAME" 2>/dev/null || true

echo "==> Adding Gatekeeper exception..."
spctl --add --label "ClipboardManagerSelfSigned" "$INSTALL_DIR/$APP_NAME" 2>/dev/null || true

echo "==> Launching..."
open "$INSTALL_DIR/$APP_NAME"

echo
echo "Done. Installed signature:"
codesign -dvvv "$INSTALL_DIR/$APP_NAME" 2>&1 | grep -E "Authority|Identifier|TeamIdentifier|Runtime"
