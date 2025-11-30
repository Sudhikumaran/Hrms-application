# ✅ Updated to fortumars-hrms-63078 Project

## What I've Updated:

### ✅ Android Configuration
- `android/app/google-services.json` → Updated to `fortumars-hrms-63078`
- `lib/firebase_options.dart` → Android config updated with correct project ID

### ✅ iOS Configuration  
- `lib/firebase_options.dart` → iOS config updated (already had correct values in GoogleService-Info.plist)

### ⚠️ Web Configuration (TODO)
- Web and Windows configs need API keys from Firebase Console
- If you don't use web/windows, you can ignore this

## Important: Enable Firestore Database

Since you're using the `fortumars-hrms-63078` project, make sure Firestore is enabled:

1. Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/firestore
2. If you see "Create database":
   - Click **"Create database"**
   - Choose **"Start in test mode"**
   - Select location (e.g., `us-central1`)
   - Click **"Enable"**

3. Set Security Rules (in Firestore → Rules tab):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```
   Click **"Publish"**

## Test Connection

After enabling Firestore:

```bash
flutter run
```

You should see:
```
HybridStorage: Firestore connected ✅
```

## Status

- ✅ Project ID: `fortumars-hrms-63078`
- ✅ Android: Configured
- ✅ iOS: Configured  
- ⚠️ Web: Needs API key from Firebase Console (if needed)
- ⚠️ Windows: Needs API key from Firebase Console (if needed)

---

**Next Step**: Enable Firestore Database in Firebase Console and test the connection!




