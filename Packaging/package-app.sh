#!/bin/bash
# Builds, signs, notarizes, and packages Desktop Karaoke for distribution outside the App Store.
#
# One-time prerequisites (see CLAUDE.md / project chat history):
#   - A "Developer ID Application" certificate installed in this machine's login keychain.
#   - Notarization credentials stored via:
#       xcrun notarytool store-credentials "AC_NOTARY" --apple-id "you@example.com" \
#         --team-id "TEAMID" --password "app-specific-password"
#
# Usage:
#   Packaging/package-app.sh [version]
# e.g.
#   Packaging/package-app.sh 1.0.0

set -euo pipefail

VERSION="${1:-1.0.0}"
BUILD_NUMBER="$(date +%Y%m%d%H%M%S)"

APP_NAME="DesktopKaraoke"
DISPLAY_NAME="Desktop Karaoke"
BUNDLE_ID="com.shubhamzanwar.DesktopKaraoke"
TEAM_ID="6F84XC6CQP"
SIGN_IDENTITY="Developer ID Application: Shubham Badrinarayan Zanwar ($TEAM_ID)"
NOTARY_PROFILE="AC_NOTARY"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
ENTITLEMENTS="$ROOT_DIR/Packaging/entitlements.plist"
INFO_PLIST_TEMPLATE="$ROOT_DIR/Packaging/Info.plist.template"

echo "==> Building release binary"
cd "$ROOT_DIR"
swift build -c release

RELEASE_BIN_DIR="$(swift build -c release --show-bin-path)"
EXECUTABLE_PATH="$RELEASE_BIN_DIR/$APP_NAME"
RESOURCE_BUNDLE="$RELEASE_BIN_DIR/${APP_NAME}_${APP_NAME}.bundle"

if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "error: built executable not found at $EXECUTABLE_PATH" >&2
    exit 1
fi
if [ ! -d "$RESOURCE_BUNDLE" ]; then
    echo "error: SPM resource bundle not found at $RESOURCE_BUNDLE" >&2
    exit 1
fi

echo "==> Assembling $APP_NAME.app"
rm -rf "$DIST_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$EXECUTABLE_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# codesign refuses to seal an .app with anything unexpected at its top level (confirmed:
# "unsealed contents present in the bundle root"), so the SPM resource bundle can't live there.
# Resource files are copied directly into Contents/Resources instead; AppResources.swift
# falls back to Bundle.main for them when the SPM resource bundle isn't present.
cp -R "$RESOURCE_BUNDLE"/* "$APP_BUNDLE/Contents/Resources/"

cp "$ROOT_DIR/Design/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

sed -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD_NUMBER/" \
    "$INFO_PLIST_TEMPLATE" > "$APP_BUNDLE/Contents/Info.plist"

echo "==> Code signing"
codesign --force --deep --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SIGN_IDENTITY" \
    "$APP_BUNDLE"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "==> Submitting for notarization"
NOTARIZE_ZIP="$DIST_DIR/$APP_NAME-notarize.zip"
ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARIZE_ZIP"

xcrun notarytool submit "$NOTARIZE_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> Stapling notarization ticket"
xcrun stapler staple "$APP_BUNDLE"
rm -f "$NOTARIZE_ZIP"

echo "==> Verifying Gatekeeper acceptance"
spctl -a -vvv --type execute "$APP_BUNDLE"

echo "==> Building DMG"
DMG_PATH="$DIST_DIR/$DISPLAY_NAME-$VERSION.dmg"
hdiutil create -volname "$DISPLAY_NAME" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_PATH"

codesign --force --sign "$SIGN_IDENTITY" "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"

echo "==> Done: $DMG_PATH"
