# Fix "configuration-not-found" Error

## The Problem
The error "Account creation failed: configuration-not-found Error" means Firebase is not properly configured for your platform.

## Quick Fix Steps

### Option 1: Reconfigure Firebase (Recommended)

1. **Install FlutterFire CLI** (if not already installed):
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Navigate to your project directory**:
   ```bash
   cd D:\FortuMars_HRMS\MobileApp-HRM
   ```

3. **Run FlutterFire configure**:
   ```bash
   flutterfire configure
   ```
   
4. **Follow the prompts**:
   - Select your Firebase project: `fortumars-hrms-63078`
   - Select platforms: Android, iOS, Web (as needed)
   
5. **Restart your app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Option 2: Manual Configuration

If FlutterFire CLI doesn't work, manually update `lib/firebase_options.dart`:

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: fortumars-hrms-63078
3. **Get configuration values**:
   - Click the gear icon → Project settings
   - Scroll down to "Your apps"
   - Click on Android/iOS/Web app
   - Copy the configuration values

4. **Update firebase_options.dart** with the correct values

### For Android (Current Platform)

Your Android config in `firebase_options.dart` looks correct, but verify:
- `google-services.json` exists at `android/app/google-services.json`
- The `appId` matches the one in `google-services.json`

### Check google-services.json

1. Open `android/app/google-services.json`
2. Find the `appId` (should be like: `1:148043153053:android:xxxxx`)
3. Compare with `firebase_options.dart` - they should match

## Verify Fix

After reconfiguring, try creating admin account again. The error should be resolved.

## Still Having Issues?

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

2. **Check Firebase initialization** in `lib/main.dart` - should have:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

3. **Ensure Authentication is enabled**:
   - Firebase Console → Authentication → Sign-in method
   - Enable "Email/Password"

4. **Check Firestore is enabled**:
   - Firebase Console → Firestore Database
   - Should show "Active" status

