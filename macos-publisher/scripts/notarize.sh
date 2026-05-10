#!/bin/bash
set -e

# macOS Publisher Script
# Usage: bash notarize.sh /path/to/MyApp.app MyApp /output/dir

APP_PATH="$1"
APP_NAME="$2"
OUTPUT_DIR="$3"

if [ -z "$APP_PATH" ] || [ -z "$APP_NAME" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Usage: $0 <app_path> <app_name> <output_dir>"
  echo "Example: $0 /path/to/MyApp.app MyApp /releases/"
  exit 1
fi

echo "=========================================="
echo "macOS Publisher"
echo "=========================================="
echo "App: $APP_NAME"
echo "Source: $APP_PATH"
echo "Output: $OUTPUT_DIR"
echo ""

# Phase 1: Validate code signing
echo "=== Phase 1: Validating code signing ==="
if ! codesign -v --deep --strict "$APP_PATH" 2>/dev/null; then
  echo "❌ App is not code-signed."
  echo "Sign with: codesign --force --deep --sign \"Developer ID Application: YourName (TEAMID)\" \"$APP_PATH\""
  exit 1
fi
echo "✅ App is properly signed"
echo ""

# Phase 2: Prepare DMG contents
echo "=== Phase 2: Preparing DMG contents ==="
DMG_BUILD="/tmp/${APP_NAME}-dmg-build"
mkdir -p "$DMG_BUILD"
cp -Rp "$APP_PATH" "$DMG_BUILD/"
cd "$DMG_BUILD"
ln -s /Applications Applications
echo "✅ DMG structure ready at $DMG_BUILD"
ls -la "$DMG_BUILD"
echo ""

# Phase 3: Create DMG
echo "=== Phase 3: Creating DMG ==="
mkdir -p "$OUTPUT_DIR"
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$DMG_BUILD" \
  -ov -format UDZO \
  "$OUTPUT_DIR/${APP_NAME}.dmg" 2>&1 | grep -E "(created|error)" || true
echo "✅ DMG created"
ls -lh "$OUTPUT_DIR/${APP_NAME}.dmg"
echo ""

# Phase 4: Notarize with Apple
echo "=== Phase 4: Notarizing with Apple ==="
echo "Submitting to Apple Notary Service..."
if ! xcrun notarytool submit "$OUTPUT_DIR/${APP_NAME}.dmg" \
  --keychain-profile apple-notary \
  --wait 2>&1 | tee /tmp/notary-submit.log; then
  echo "❌ Notarization failed. Check /tmp/notary-submit.log"
  exit 1
fi

if grep -q "status: Accepted" /tmp/notary-submit.log; then
  echo "✅ Notarization accepted"
else
  echo "❌ Notarization not accepted. Review the log above."
  exit 1
fi
echo ""

# Phase 5: Staple ticket
echo "=== Phase 5: Stapling notarization ticket ==="
xcrun stapler staple "$OUTPUT_DIR/${APP_NAME}.dmg"
echo "Validating staple..."
if xcrun stapler validate "$OUTPUT_DIR/${APP_NAME}.dmg" 2>&1 | grep -q "validate action worked"; then
  echo "✅ Staple validated"
else
  echo "⚠️  Staple validation had issues. Continuing..."
fi
echo ""

# Phase 6: Package for distribution
echo "=== Phase 6: Packaging for distribution ==="
ditto -c -k --sequesterRsrc "$OUTPUT_DIR/${APP_NAME}.dmg" \
  "$OUTPUT_DIR/${APP_NAME}-notarized.zip"
echo "✅ ZIP created"
ls -lh "$OUTPUT_DIR/${APP_NAME}-notarized.zip"
echo ""

# Verification
echo "=== Verification ==="
echo "Checking ZIP integrity..."
if unzip -t "$OUTPUT_DIR/${APP_NAME}-notarized.zip" 2>&1 | grep -q "No errors detected"; then
  echo "✅ ZIP integrity verified"
else
  echo "⚠️  ZIP integrity check had issues"
fi

echo ""
echo "=========================================="
echo "✅ Done!"
echo "=========================================="
echo "📦 Distribution package ready:"
echo "   $OUTPUT_DIR/${APP_NAME}-notarized.zip"
echo ""
echo "Users can now download and install your app."
