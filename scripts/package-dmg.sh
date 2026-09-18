#!/bin/bash
# Package ClipboardManager.app into a distributable DMG (drag-to-install).
# Usage: scripts/package-dmg.sh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PBXPROJ="$PROJECT_DIR/ClipboardManager.xcodeproj/project.pbxproj"
APP_NAME="ClipboardManager"
DIST="$PROJECT_DIR/dist"

VERSION=$(sed -n 's/.*[[:space:]]MARKETING_VERSION = \([^;]*\);.*/\1/p' "$PBXPROJ" | head -1 | tr -d '"')
DMG="$DIST/$APP_NAME-$VERSION.dmg"

SIGN_IDENTITY="-" bash "$PROJECT_DIR/scripts/build-app.sh" "$DIST"

STAGE=$(mktemp -d -t cm-dmg)
trap 'rm -rf "$STAGE"' EXIT

ditto "$DIST/$APP_NAME.app" "$STAGE/$APP_NAME.app"
ln -s /Applications "$STAGE/Applications"

cat > "$STAGE/อ่านก่อนติดตั้ง.txt" <<'README'
ClipboardManager — วิธีติดตั้ง (macOS 15.5 ขึ้นไป)

1. ลาก ClipboardManager.app ไปวางที่โฟลเดอร์ Applications (ไอคอนในหน้าต่างนี้)
2. เปิดแอปจาก Applications
   ครั้งแรกจะขึ้นเตือนว่า "ไม่สามารถตรวจสอบผู้พัฒนา" เพราะแอปไม่ได้ notarize กับ Apple
   ให้ไปที่ System Settings > Privacy & Security แล้วกด "Open Anyway"

   ถ้ายังเปิดไม่ได้ เปิด Terminal แล้ววางคำสั่งนี้:
       xattr -dr com.apple.quarantine /Applications/ClipboardManager.app

3. อนุญาต Accessibility (จำเป็น — ใช้สำหรับสั่ง paste)
   System Settings > Privacy & Security > Accessibility > เปิดสวิตช์ ClipboardManager
4. แอปทำงานอยู่บน menu bar (ไอคอน clipboard) — กด Cmd+; เพื่อเรียกหน้าต่างประวัติ
   เปลี่ยน shortcut, จำนวนรายการ, และแอปที่ไม่ต้องบันทึก ได้ที่เมนู > Settings…

เริ่มพร้อมเครื่อง (ถ้าต้องการ): เมนู > Settings… > General > Launch at login
README

rm -f "$DMG"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DMG" >/dev/null

echo "==> Packaged: $DMG"
ls -lh "$DMG" | awk '{print "    size: "$5}'
echo "    sha256: $(shasum -a 256 "$DMG" | cut -d' ' -f1)"
