#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

swift build -c release

APP="$ROOT/dist/Blink.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$(swift build -c release --show-bin-path)/Blink" "$APP/Contents/MacOS/Blink"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.allen.blink</string>
    <key>CFBundleName</key>
    <string>Blink</string>
    <key>CFBundleExecutable</key>
    <string>Blink</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP"

echo "Built $APP"
echo "Move it to /Applications, then launch it, before enabling \"Launch at Login\"."

if [[ "${1:-}" == "--dmg" ]]; then
    DMG="$ROOT/dist/Blink.dmg"
    rm -f "$DMG"
    hdiutil create -volname Blink -srcfolder "$APP" -ov -format UDZO "$DMG"
    echo "Built $DMG"
fi
