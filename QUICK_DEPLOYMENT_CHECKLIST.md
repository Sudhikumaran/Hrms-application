# ⚡ Quick Deployment Checklist

## ✅ Already Fixed:
- ✅ Firebase initialization added to `main.dart`
- ✅ Version updated to `1.0.0+1`

---

## 🔴 CRITICAL - Do These NOW (Before Building):

### 1. Remove Demo Credentials (Security)
**File**: `lib/screens/login_screen.dart`

Find and remove/comment out:
- Line ~56: Admin login with hardcoded password
- Lines ~285-286: Demo credentials display

### 2. Android Signing (Required for Release)
**File**: `android/app/build.gradle.kts`

Create `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

Update `build.gradle.kts` to use it (see DEPLOYMENT_GUIDE.md)

### 3. iOS Bundle ID
**Action**: Update Bundle Identifier in Xcode
- Current: `com.example.fortumars_hrm_app`
- Should be: `com.yourcompany.fortumarshrm` (unique)

---

## 📱 Android Build Commands:

```bash
# 1. Clean and get dependencies
flutter clean
flutter pub get

# 2. Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab

# OR Build APK (for direct installation)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🍎 iOS Build Commands:

```bash
# 1. Clean and get dependencies
flutter clean
flutter pub get

# 2. Build for iOS
flutter build ios --release

# 3. Then open Xcode and archive:
# - Open ios/Runner.xcworkspace in Xcode
# - Product → Archive
# - Distribute to App Store
```

---

## 📋 Pre-Submission Checklist:

### Required:
- [ ] Remove demo credentials from login screen
- [ ] Test app on real Android device
- [ ] Test app on real iOS device (if available)
- [ ] Create privacy policy (both stores require this)
- [ ] Prepare app screenshots
- [ ] Prepare app icon (1024x1024 for iOS, 512x512 for Android)
- [ ] Configure Android signing
- [ ] Configure iOS signing in Xcode

### Recommended:
- [ ] Test all major features
- [ ] Test on multiple Android versions
- [ ] Add app description
- [ ] Prepare feature graphic (Android)

---

## 🚀 Deployment Timeline:

**Minimum (Critical fixes only)**: 2-4 hours
1. Remove credentials (10 min)
2. Configure signing (30 min)
3. Build and test (1 hour)
4. Prepare store assets (1 hour)
5. Submit to stores (30 min)

**Proper (All improvements)**: 1-2 weeks
- Includes testing, error handling, documentation

---

## 📞 Store Accounts Needed:

1. **Google Play Console**: https://play.google.com/console
   - $25 one-time registration fee
   
2. **Apple App Store Connect**: https://appstoreconnect.apple.com
   - $99/year developer program

---

## ⚠️ Important Notes:

1. **Privacy Policy**: Create a page describing what data you collect
   - Both stores require this URL
   - Can be a simple GitHub Pages site or website

2. **Testing**: Test the release build before submitting:
   ```bash
   flutter install --release  # Install on connected device
   ```

3. **First Review**: Can take 1-7 days
   - iOS typically longer (1-7 days)
   - Android typically faster (1-3 days)

---

## 🐛 If Build Fails:

1. **Android**:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   flutter build appbundle
   ```

2. **iOS**:
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   flutter clean
   flutter pub get
   flutter build ios
   ```

---

## 📝 Next Steps:

1. ✅ Read `DEPLOYMENT_GUIDE.md` for detailed instructions
2. ✅ Complete critical fixes (credentials, signing)
3. ✅ Build release version
4. ✅ Test on real devices
5. ✅ Create store listings
6. ✅ Submit to stores

---

**Need help?** Check:
- `DEPLOYMENT_GUIDE.md` - Detailed guide
- `PRODUCTION_READINESS.md` - What's missing
- `FIREBASE_SETUP.md` - Firebase configuration







