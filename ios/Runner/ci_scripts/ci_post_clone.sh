#!/bin/sh

# The CI_WORKSPACE is the root of your repository
cd $CI_WORKSPACE

# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Precache iOS artifacts
flutter precache --ios

# Install dependencies
flutter pub get

# Navigate to iOS directory
cd ios

# Install CocoaPods dependencies
# Xcode Cloud has CocoaPods installed, but we need to run it
pod install
