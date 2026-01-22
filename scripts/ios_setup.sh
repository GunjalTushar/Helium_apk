#!/usr/bin/env bash
set -euo pipefail

echo "== iOS setup helper for Helium_apk =="

# Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found — installing (you will be prompted for your password)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
  if [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
else
  echo "Homebrew already installed"
fi

# Install CocoaPods
if ! command -v pod >/dev/null 2>&1; then
  echo "Installing CocoaPods via Homebrew..."
  brew install cocoapods
  echo "Running 'pod setup' (this may take a few minutes)..."
  pod setup
else
  echo "CocoaPods already installed"
fi

# Ensure flutter is on PATH (assumes ~/.zshrc was updated by earlier steps)
echo "Sourcing ~/.zshrc to bring flutter into PATH for this session (if present)..."
if [ -f "$HOME/.zshrc" ]; then
  # shellcheck disable=SC1090
  source "$HOME/.zshrc"
fi

echo "Running flutter doctor -v"
flutter doctor -v || true

# Run pod install in ios if Podfile exists, otherwise remind user
if [ -d ios ]; then
  cd ios
  if [ -f Podfile ]; then
    echo "Running pod install in ios/"
    pod install
  else
    echo "No Podfile in ios/ — run 'flutter pub get' and 'flutter build ios' or open Xcode to generate iOS build files."
  fi
  cd - >/dev/null
fi

echo "iOS setup helper finished. Follow README files for remaining manual steps (Xcode signing, device Developer Mode, App Store Connect)."
