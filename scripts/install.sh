#!/bin/bash
# Build from source and install to /Applications on this machine.
# Signs with the self-signed cert when scripts/setup-cert.sh has been run (keeps the
# Accessibility permission across rebuilds); otherwise falls back to ad-hoc signing.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ClipboardManager"
INSTALL_DIR="/Applications"

BUILD_DIR=$(mktemp -d -t cm-install)
trap 'rm -rf "$BUILD_DIR"' EXIT

bash "$PROJECT_DIR/scripts/build-app.sh" "$BUILD_DIR"

echo "==> Quitting any running instance..."
osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
sleep 1
pkill -f "$INSTALL_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true

echo "==> Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/$APP_NAME.app"
ditto "$BUILD_DIR/$APP_NAME.app" "$INSTALL_DIR/$APP_NAME.app"
xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

echo "==> Launching..."
open "$INSTALL_DIR/$APP_NAME.app"

echo
echo "Installed signature:"
codesign -dvvv "$INSTALL_DIR/$APP_NAME.app" 2>&1 | grep -E "Identifier|Authority|Signature|Runtime"
