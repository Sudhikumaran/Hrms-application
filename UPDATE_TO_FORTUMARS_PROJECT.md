# 🔄 Updating to fortumars-hrms-63078 Project

You're switching from `myproject-f9e45` to `fortumars-hrms-63078`.

## Steps Required:

### 1. Download Correct google-services.json
- Go to Firebase Console → Project: `fortumars-hrms-63078`
- Go to Project Settings (gear icon) → Your apps
- Find your Android app (package: `com.example.fortumars_hrm_app`)
- Download `google-services.json`
- Replace `android/app/google-services.json` with the new file

### 2. Update firebase_options.dart
I'll update the project IDs. You'll need to get the API keys from Firebase Console.

### 3. Verify iOS Configuration
Check if `ios/Runner/GoogleService-Info.plist` needs updating (it already shows `fortumars-hrms-63078`)

## Getting API Keys from Firebase Console:

1. Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/settings/general
2. Scroll to "Your apps" section
3. For each platform (Android, iOS, Web), copy:
   - API Key
   - App ID
   - Messaging Sender ID
   - Project ID (should be `fortumars-hrms-63078`)
   - Storage Bucket
   - Auth Domain (for web)

## After Update:
- Run `flutter clean`
- Run `flutter pub get`
- Restart app


