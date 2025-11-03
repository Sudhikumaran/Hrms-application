# 🚀 Android & iOS Deployment Guide

## Current Status: ⚠️ NOT Production Ready

**Critical fixes required before deployment.**

---

## 📋 Step-by-Step Preparation

### Phase 1: Critical Fixes (Must Do - 1-2 hours)

#### 1. Initialize Firebase ✅
**Priority: CRITICAL**

Currently Firebase is not initialized. Add this to `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Local Storage
  await LocalStorageService.init();
  print('Local storage initialized successfully');

  runApp(FortuMarsHRMApp());
}
```

#### 2. Remove Demo Credentials ⚠️
**Priority: CRITICAL (Security)**

Remove hardcoded "password" from login screen or make it configurable via environment.

#### 3. Set Up Production Signing Keys
**Priority: CRITICAL**

**For Android:**
- Create a keystore file
- Configure signing in `android/app/build.gradle.kts`

**For iOS:**
- Configure App Store signing in Xcode

---

### Phase 2: Build Configuration (30 minutes)

#### 4. Update Version Number
In `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Format: version+buildNumber
```

#### 5. Update App Metadata
- App name, description
- App icons (Android & iOS)
- Splash screens

---

### Phase 3: Pre-Deployment Testing (2-3 hours)

#### 6. Test All Features
- [ ] Login/Signup
- [ ] Attendance check-in/check-out
- [ ] Leave requests
- [ ] Analytics
- [ ] PDF generation
- [ ] Admin features

#### 7. Test on Real Devices
- [ ] Android (multiple versions)
- [ ] iOS (if available)

---

## 📱 Android Deployment Steps

### Prerequisites
1. Google Play Developer Account ($25 one-time fee)
2. App signing key (keystore file)

### Step-by-Step:

#### 1. Generate Signing Key
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### 2. Configure Signing in `android/app/build.gradle.kts`
```kotlin
android {
    // ... existing code ...
    
    signingConfigs {
        release {
            keyAlias = "upload"
            keyPassword = "YOUR_KEY_PASSWORD"
            storeFile = file("/path/to/upload-keystore.jks")
            storePassword = "YOUR_STORE_PASSWORD"
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.release
            minifyEnabled = true
            shrinkResources = true
        }
    }
}
```

#### 3. Create `key.properties` (add to `.gitignore`)
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=path/to/upload-keystore.jks
```

#### 4. Build Release APK/AAB
```bash
flutter build appbundle  # Recommended for Play Store
# OR
flutter build apk --release
```

#### 5. Upload to Google Play Console
1. Go to [Play Console](https://play.google.com/console)
2. Create new app
3. Fill in app details:
   - App name, description, screenshots
   - Privacy policy URL (required)
   - Content rating
4. Upload AAB file
5. Complete store listing
6. Submit for review

---

## 🍎 iOS Deployment Steps

### Prerequisites
1. Apple Developer Account ($99/year)
2. Mac computer (required for building)
3. Xcode installed

### Step-by-Step:

#### 1. Configure App in Xcode
```bash
cd ios
open Runner.xcworkspace
```

1. Select "Runner" project
2. Go to "Signing & Capabilities"
3. Select your Team
4. Ensure Bundle Identifier is unique

#### 2. Update Bundle Identifier
In `ios/Runner.xcodeproj/project.pbxproj`:
- Change `com.example.fortumars_hrm_app` to something unique like `com.yourcompany.fortumarshrm`

#### 3. Update Version in `pubspec.yaml`
```yaml
version: 1.0.0+1
```

#### 4. Build for Release
```bash
flutter build ios --release
```

#### 5. Archive and Upload via Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Product → Archive
3. Wait for archive to complete
4. Click "Distribute App"
5. Choose "App Store Connect"
6. Follow wizard to upload

#### 6. Submit to App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app
3. Fill in app information
4. Add screenshots (required sizes)
5. Submit for review

---

## 🔧 Quick Fixes Checklist

### Before Building Release:

- [ ] Firebase initialized in `main.dart`
- [ ] Remove demo credentials
- [ ] Update version in `pubspec.yaml`
- [ ] Configure Android signing
- [ ] Configure iOS signing
- [ ] Test on physical devices
- [ ] Update app icons
- [ ] Update splash screens
- [ ] Add privacy policy (required for stores)
- [ ] Test all critical flows

---

## ⚡ Quick Start (Minimum Viable Production)

If you need to deploy ASAP with minimal changes:

1. **Initialize Firebase** (5 min) - Critical
2. **Update version** (1 min) - Easy
3. **Configure signing** (15 min) - Required
4. **Remove demo passwords** (5 min) - Security
5. **Test basic flows** (30 min) - Quality assurance

**Total: ~1 hour for minimal deployment**

---

## 🐛 Known Issues to Address

1. **Data Persistence**: Currently only local storage
   - **Workaround**: Document that data is device-specific
   - **Future**: Implement Firebase sync

2. **Error Handling**: Some operations lack error handling
   - **Workaround**: Test thoroughly before release
   - **Future**: Add comprehensive error handling

3. **No Offline Queue**: No sync mechanism
   - **Workaround**: Document limitations
   - **Future**: Implement sync service

---

## 📝 Store Listing Requirements

### Android (Google Play):
- [x] App name
- [x] Short description (80 chars)
- [x] Full description (4000 chars)
- [x] Screenshots (phone, tablet)
- [x] App icon (512x512)
- [x] Privacy policy URL (REQUIRED)
- [x] Content rating questionnaire
- [x] Feature graphic (1024x500)

### iOS (App Store):
- [x] App name
- [x] Subtitle
- [x] Description (4000 chars)
- [x] Screenshots (all device sizes)
- [x] App icon (1024x1024)
- [x] Privacy policy URL (REQUIRED)
- [x] Support URL
- [x] Marketing URL (optional)

---

## 🚨 Important Notes

1. **Privacy Policy**: Required by both stores
   - Create a page describing data collection
   - Link it in app and store listings

2. **Testing**: Both stores require testing
   - Use TestFlight (iOS) and Internal Testing (Android) first

3. **Review Process**:
   - Android: Usually 1-3 days
   - iOS: Usually 1-7 days

4. **Updates**: After first release, updates are faster

---

## 🆘 Need Help?

If you encounter issues:
1. Check Firebase setup in `FIREBASE_SETUP.md`
2. Review Flutter deployment docs
3. Check store-specific requirements

---

## ✅ Final Checklist Before Submission

- [ ] All critical fixes applied
- [ ] Builds successfully in release mode
- [ ] Tested on real devices
- [ ] App icons and screenshots ready
- [ ] Privacy policy created and linked
- [ ] Store listings filled completely
- [ ] Content ratings completed
- [ ] TestFlight/Internal testing passed

---

**Estimated Timeline**: 
- **Quick deployment**: 1-2 days (with critical fixes)
- **Proper deployment**: 1-2 weeks (with all improvements)





