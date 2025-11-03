# FortuMars HRMS - Build Guide

## ✅ App Configuration Complete

### App Name
- **Android**: "FortuMars HRMS" ✅
- **iOS**: "FortuMars HRMS" ✅
- **Web**: "FortuMars HRMS" ✅

### App Icon
- **Source**: `assets/images/fortumars_logo.png`
- **Generated for**: Android & iOS ✅
- **Adaptive Icon**: Enabled with white background ✅

---

## 📱 Building for Android

### Prerequisites
- Android Studio installed
- Android SDK installed
- Flutter SDK installed

### Build Commands

#### 1. **Debug APK** (For Testing)
```bash
flutter build apk --debug
```
**Output**: `build/app/outputs/flutter-apk/app-debug.apk`

#### 2. **Release APK** (For Distribution)
```bash
flutter build apk --release
```
**Output**: `build/app/outputs/flutter-apk/app-release.apk`

#### 3. **App Bundle** (For Google Play Store)
```bash
flutter build appbundle --release
```
**Output**: `build/app/outputs/bundle/release/app-release.aab`

### Installation
1. Enable "Install from Unknown Sources" on your Android device
2. Transfer the APK to your device
3. Open and install the APK file

---

## 🍎 Building for iOS

### Prerequisites
- **macOS** (Required - iOS builds only work on Mac)
- Xcode installed (latest version)
- Apple Developer Account (for signing)
- CocoaPods installed

### Build Commands (Run on macOS)

#### 1. **Get Dependencies**
```bash
cd ios
pod install
cd ..
```

#### 2. **Debug Build** (For Testing)
```bash
flutter build ios --debug
```
**Note**: Open in Xcode and run on simulator/device

#### 3. **Release Build** (For Distribution)
```bash
flutter build ios --release
```

#### 4. **Archive for App Store** (Using Xcode)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" or your device
3. Product → Archive
4. Distribute to App Store or export IPA

---

## 📦 Build Output Locations

### Android
- **APK**: `build/app/outputs/flutter-apk/`
- **AAB**: `build/app/outputs/bundle/`

### iOS
- **IPA**: `build/ios/ipa/`
- **Archive**: Created in Xcode Organizer

---

## 🚀 Quick Start Commands

### For Android (Windows/Mac/Linux)
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

### For iOS (macOS Only)
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get
cd ios && pod install && cd ..

# Build release iOS
flutter build ios --release

# Then open Xcode to archive
open ios/Runner.xcworkspace
```

---

## 📝 Version Information

- **Current Version**: 1.0.0+1
- **App Name**: FortuMars HRMS
- **Package ID**: com.example.fortumars_hrm_app

**Note**: Update `applicationId` in `android/app/build.gradle.kts` and Bundle ID in Xcode before publishing to stores.

---

## ✅ What's Configured

1. ✅ App name set to "FortuMars HRMS" for all platforms
2. ✅ App icon generated from `fortumars_logo.png`
3. ✅ Adaptive icons configured for Android
4. ✅ iOS icons generated (alpha channel removed for App Store)
5. ✅ Web manifest updated

---

## 🎯 Next Steps for Production

1. **Update Package ID** (Android)
   - Edit `android/app/build.gradle.kts`
   - Change `applicationId` to your unique ID (e.g., `com.fortumars.hrms`)

2. **Update Bundle ID** (iOS)
   - Open `ios/Runner.xcworkspace` in Xcode
   - Update Bundle Identifier in Signing & Capabilities

3. **Create Signing Keys** (Android)
   - Create release keystore
   - Add `key.properties` file

4. **Configure App Store Signing** (iOS)
   - Set up in Xcode with your Apple Developer account

5. **Test Builds**
   - Test on real devices
   - Verify all features work correctly

---

## 📞 Support

For build issues:
1. Check Flutter doctor: `flutter doctor`
2. Clean and rebuild: `flutter clean && flutter pub get`
3. Verify Firebase configuration for both platforms

