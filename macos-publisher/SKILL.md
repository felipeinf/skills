---
name: macos-publisher
description: Use when distributing a macOS app outside the App Store and need to notarize it with Apple, create a drag-installable DMG, and package for distribution.
---

# macOS Publisher

Sign, notarize, and package a macOS app for distribution outside the App Store. Build DMG first, then notarize (not vice versa).

## Inputs

- **APP_PATH** — compiled `.app` bundle
- **APP_NAME** — used for DMG volume and filename
- **ZIP_NAME** — distribution filename (e.g., `MyApp-v1.0.0.zip`)
- **PROFILE** — keychain profile name for notarytool
- **OUTPUT_DIR** — where DMG and ZIP go

## Preflight

Verify signing identity is "Developer ID Application" (not "Apple Development"):
```bash
codesign -dvv APP_PATH 2>&1 | grep Authority
```
If wrong cert, re-sign: `codesign --force --deep --sign "Developer ID Application: Name (TEAMID)" --options runtime --timestamp APP_PATH`

Verify keychain profile works: `xcrun notarytool history --keychain-profile PROFILE 2>&1 | head -1`

If no profile, create once:
```bash
xcrun notarytool store-credentials PROFILE \
  --apple-id APPLE_ID --app-password APP_PWD --team-id TEAM_ID
```
Team ID: developer.apple.com/account → Membership. App password: appleid.apple.com → App-Specific Passwords.

## Build & Notarize

```bash
# 1. Validate signing
codesign -v --deep --strict APP_PATH

# 2. Create DMG contents
mkdir -p /tmp/APP_NAME-dmg-build
cp -Rp APP_PATH /tmp/APP_NAME-dmg-build/
ln -s /Applications /tmp/APP_NAME-dmg-build/Applications

# 3. Create DMG
hdiutil create -volname "APP_NAME" -srcfolder /tmp/APP_NAME-dmg-build \
  -ov -format UDZO OUTPUT_DIR/APP_NAME.dmg

# 4. Notarize (expect: status: Accepted)
xcrun notarytool submit OUTPUT_DIR/APP_NAME.dmg --keychain-profile PROFILE --wait

# 5. Staple ticket
xcrun stapler staple OUTPUT_DIR/APP_NAME.dmg

# 6. Package ZIP
ditto -c -k --sequesterRsrc OUTPUT_DIR/APP_NAME.dmg OUTPUT_DIR/ZIP_NAME
```

## Verify Before Shipping

```bash
hdiutil attach OUTPUT_DIR/APP_NAME.dmg -mountpoint /tmp/test && ls -la /tmp/test && hdiutil detach /tmp/test
# → app bundle + Applications symlink

xattr -l OUTPUT_DIR/APP_NAME.dmg | grep com.apple.provenance
# → must be present

unzip -t OUTPUT_DIR/ZIP_NAME
# → No errors detected
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Notarization rejected | `xcrun notarytool log SUBMISSION_ID --keychain-profile PROFILE` — common: debug cert, missing `--options runtime`, unsigned embedded frameworks |
| DMG missing Applications | Symlink failed — check `ls -la /tmp/APP_NAME-dmg-build/` |
| Gatekeeper still warns | Staple missing — re-run `xcrun stapler staple` on the DMG |
