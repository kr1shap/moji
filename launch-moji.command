#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_PATH="$ROOT_DIR/moji/moji.xcodeproj"
SCHEME="moji"
BUILD_DIR="$ROOT_DIR/.build"
APP_PATH="$BUILD_DIR/Build/Products/Release/moji.app"
MOJI_TEAM_ID="${MOJI_DEVELOPMENT_TEAM:-}"

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "xcodebuild was not found. Install Xcode or the Xcode Command Line Tools first."
    exit 1
fi

echo "Building Moji..."
SIGNING_ARGUMENTS=()
if [[ -n "$MOJI_TEAM_ID" ]]; then
    SIGNING_ARGUMENTS+=(DEVELOPMENT_TEAM="$MOJI_TEAM_ID")
fi

if ! xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    "${SIGNING_ARGUMENTS[@]}" \
    build; then
    echo
    echo "========================================"
    echo "  Build failed"
    echo "========================================"
    echo "Review the xcodebuild error above for the actual cause."
    exit 1
fi

if ! codesign --verify --deep --strict "$APP_PATH"; then
    echo "The built app does not have a valid code signature."
    exit 1
fi

if codesign -dvv "$APP_PATH" 2>&1 | grep -q '^Signature=adhoc$'; then
    echo
    echo "========================================"
    echo "  Build failed: signing is not stable"
    echo "========================================"
    echo "Xcode produced a Sign to Run Locally build."
    echo "Select an Apple Development team in Xcode so macOS can retain Moji's permissions."
    exit 1
fi

APP_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_PATH/Contents/Info.plist")"
if pgrep -x "$APP_EXECUTABLE" >/dev/null 2>&1; then
    echo "Stopping the existing $APP_EXECUTABLE process..."
    pkill -x "$APP_EXECUTABLE"
    for _ in {1..20}; do
        pgrep -x "$APP_EXECUTABLE" >/dev/null 2>&1 || break
        sleep 0.1
    done
    if pgrep -x "$APP_EXECUTABLE" >/dev/null 2>&1; then
        echo "Could not stop the existing $APP_EXECUTABLE process."
        exit 1
    fi
    echo "Existing process stopped."
else
    echo "No existing $APP_EXECUTABLE process found."
fi

echo
echo "========================================"
echo "  Build complete — launching Moji"
echo "========================================"
open "$APP_PATH"
echo "Moji is running. Use its Accessibility button to request the required macOS permission."
