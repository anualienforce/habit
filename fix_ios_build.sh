#!/bin/bash

# Fix iOS Build Issues
# This script fixes CocoaPods sync issues and prepares the iOS build

echo "🔧 Fixing iOS build issues..."

# Set UTF-8 encoding for CocoaPods
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Navigate to project root
cd "$(dirname "$0")"

echo "📦 Running flutter clean..."
flutter clean

echo "📦 Running flutter pub get..."
flutter pub get

echo "📦 Installing CocoaPods dependencies..."
cd ios

# Remove Podfile.lock and Pods directory to force fresh install
if [ -f "Podfile.lock" ]; then
    echo "🗑️  Removing old Podfile.lock..."
    rm -f Podfile.lock
fi

if [ -d "Pods" ]; then
    echo "🗑️  Removing old Pods directory..."
    rm -rf Pods
fi

# Run pod install
echo "📦 Running pod install..."
pod install

echo "✅ Done! You can now build the app in Xcode."
echo ""
echo "Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode (NOT Runner.xcodeproj)"
echo "2. Clean build folder: Product → Clean Build Folder (Shift+Cmd+K)"
echo "3. Build: Product → Build (Cmd+B)"
