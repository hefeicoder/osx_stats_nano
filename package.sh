#!/bin/bash
set -e

APP_NAME="OSXStatsNano"
BUNDLE_ID="com.hefeicoder.osx-stats-nano"
VERSION="1.0.1"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR=".build/release"
STAGING="/tmp/osx-stats-nano-staging"

echo "==> Building release binary..."
swift build -c release

echo "==> Creating .app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>OSX Stats Nano</string>
    <key>CFBundleDisplayName</key>
    <string>OSX Stats Nano</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 hefeicoder. MIT License.</string>
</dict>
</plist>
EOF

echo "==> Ad-hoc signing..."
codesign --deep --force --sign - "${APP_BUNDLE}"

echo "==> Creating DMG..."
rm -rf "${STAGING}" "${DMG_NAME}"
mkdir -p "${STAGING}"
cp -r "${APP_BUNDLE}" "${STAGING}/"
ln -s /Applications "${STAGING}/Applications"

hdiutil create \
    -volname "OSX Stats Nano" \
    -srcfolder "${STAGING}" \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

rm -rf "${STAGING}"

echo ""
echo "Done! Created:"
echo "  ${APP_BUNDLE}   — run locally"
echo "  ${DMG_NAME}  — distribute via GitHub Releases"
