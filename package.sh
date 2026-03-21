#!/bin/bash
set -e

APP_NAME="OSXStatsNano"
BUNDLE_ID="com.hefeicoder.osx-stats-nano"
VERSION="1.0.2"
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

echo "==> Generating icon..."
ICONSET="/tmp/AppIcon.iconset"
rm -rf "${ICONSET}" && mkdir "${ICONSET}"
sips -z 16 16     icon.png --out "${ICONSET}/icon_16x16.png"     > /dev/null
sips -z 32 32     icon.png --out "${ICONSET}/icon_16x16@2x.png"  > /dev/null
sips -z 32 32     icon.png --out "${ICONSET}/icon_32x32.png"     > /dev/null
sips -z 64 64     icon.png --out "${ICONSET}/icon_32x32@2x.png"  > /dev/null
sips -z 128 128   icon.png --out "${ICONSET}/icon_128x128.png"   > /dev/null
sips -z 256 256   icon.png --out "${ICONSET}/icon_128x128@2x.png"> /dev/null
sips -z 256 256   icon.png --out "${ICONSET}/icon_256x256.png"   > /dev/null
sips -z 512 512   icon.png --out "${ICONSET}/icon_256x256@2x.png"> /dev/null
sips -z 512 512   icon.png --out "${ICONSET}/icon_512x512.png"   > /dev/null
cp icon.png "${ICONSET}/icon_512x512@2x.png"
iconutil -c icns "${ICONSET}" -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
rm -rf "${ICONSET}"

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
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
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
