#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "⚡️ Loopin (Apple Silicon M Serisi Uyumlu Mouse Macro & Auto-Clicker) Derleniyor..."

APP_NAME="Loopin"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"
MODULE_CACHE="$SCRIPT_DIR/../.build/mc"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$MODULE_CACHE"

# Info.plist kopyala
cp "$SCRIPT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# AppIcon kopyala
if [ -f "$SCRIPT_DIR/Resources/AppIcon.icns" ]; then
    cp "$SCRIPT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi
if [ -f "$SCRIPT_DIR/Resources/AppIcon_1024.png" ]; then
    cp "$SCRIPT_DIR/Resources/AppIcon_1024.png" "$RESOURCES_DIR/AppIcon_1024.png"
fi

SWIFT_SOURCES=(
    Sources/Models/MacroModels.swift
    Sources/Services/AccessibilityManager.swift
    Sources/Services/SoundManager.swift
    Sources/Services/HotKeyManager.swift
    Sources/Services/MouseRecorder.swift
    Sources/Services/MacroPlayer.swift
    Sources/Services/AutoClicker.swift
    Sources/Services/UpdateManager.swift
    Sources/ViewModels/AppViewModel.swift
    Sources/Views/IconBadge.swift
    Sources/Views/AutoClickerView.swift
    Sources/Views/MacroRecorderView.swift
    Sources/Views/CoordinateInspectorView.swift
    Sources/Views/SettingsView.swift
    Sources/Views/MenuBarView.swift
    Sources/Views/MainWindow.swift
    Sources/App/LoopinApp.swift
)

echo "📦 Kaynak dosyalar derleniyor:"
for src in "${SWIFT_SOURCES[@]}"; do
    echo "  - $src"
done

swiftc \
    -module-cache-path "$MODULE_CACHE" \
    -O \
    -target arm64-apple-macosx14.0 \
    -parse-as-library \
    "${SWIFT_SOURCES[@]}" \
    -o "$MACOS_DIR/$APP_NAME"

echo "🔐 Sabit Tanımlayıcılı Kod İmzası Uygulanıyor (macOS TCC İzinlerinin Korunması İçin)..."
codesign --force --deep -s - -r='designated => identifier "com.blackowl.Loopin"' "$APP_BUNDLE"

echo "✅ Derleme başarılı: $APP_BUNDLE"
echo "🚀 Loopin'i çalıştırmak için: open \"$APP_BUNDLE\""
