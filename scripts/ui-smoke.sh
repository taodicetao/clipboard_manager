#!/bin/bash
# UI smoke test against the installed app, driven through System Events.
# Needs: ClipboardManager installed in /Applications, and Accessibility access for the
# terminal running this script (System Settings → Privacy & Security → Accessibility).
# Do not touch the keyboard or mouse while it runs (~20 s).
set -uo pipefail

if [ ! -d /Applications/ClipboardManager.app ]; then
  echo "ClipboardManager.app is not installed in /Applications (run scripts/install.sh)" >&2
  exit 2
fi

OUTPUT=$(osascript "$(dirname "$0")/ui-smoke.applescript" 2>&1)
echo "$OUTPUT"
if echo "$OUTPUT" | grep -q "^FAIL"; then
  exit 1
fi
if ! echo "$OUTPUT" | grep -q "^PASS"; then
  echo "no checks ran — is Accessibility access granted to this terminal?" >&2
  exit 2
fi
