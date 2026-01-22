# iOS setup and device install (Helium_apk)

Follow these steps on your iMac to prepare and install the app on an iPhone/iPad or upload to TestFlight/App Store.

1) Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)" # or /usr/local/bin/brew for Intel
```

2) Install CocoaPods
```bash
brew install cocoapods
pod setup
```

3) Ensure Flutter is on PATH (this project expects `flutter` in $HOME/flutter/bin)
```bash
source ~/.zshrc
flutter --version
flutter doctor -v
```

4) Update iOS deployment target (optional but recommended)
- Edit `ios/Podfile` and set `platform :ios, '17.0'` (or the minimum you support).
- Then run:
```bash
cd ios
pod install
cd ..
```

5) Xcode & Signing (required for device and App Store)
- Open `ios/Runner.xcworkspace` in Xcode.
- Connect your device (USB or network). In Xcode → Window → Devices and Simulators, pair/trust the device.
- In the Runner target → General:
  - Set **Bundle Identifier** (e.g., `com.yourcompany.app`).
  - Under **Signing & Capabilities**, enable *Automatically manage signing* and choose your Apple ID / Team.
  - Set **Deployment Target** to the iOS version(s) you want to support.

6) Enable Developer Mode on the device
- On iPhone/iPad: Settings → Privacy & Security → Developer Mode → enable (may require reboot).

7) Run on device
```bash
flutter devices
flutter run -d <device-id>
# For release testing
flutter run --release -d <device-id>
```

8) Build an IPA for TestFlight / App Store
```bash
# Development or Ad-Hoc
flutter build ipa --export-method development

# App Store
flutter build ipa --export-method app-store
```

9) Upload to App Store Connect
- Use Xcode Organizer or Apple Transporter to upload the .ipa. Complete metadata on App Store Connect and submit for TestFlight/App Store review.

Notes:
- Publishing to the App Store requires an Apple Developer Program membership.
- Some steps (Xcode install, signing acceptance, GUI interactions) cannot be fully automated in this script and require manual actions in Xcode and on-device.
