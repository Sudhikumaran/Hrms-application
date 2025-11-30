# 🔧 Fix "configuration-not-found" Error

## Error:
```
Firebase error code: configuration-not-found
```

## What This Means:
Firebase Authentication is not properly configured for your Android app.

## Fix Steps:

### Step 1: Verify Android App in Firebase Console

1. **Go to Firebase Console:**
   - https://console.firebase.google.com/project/fortumars-hrms-63078/settings/general

2. **Check Android App Registration:**
   - Go to "Your apps" section
   - Look for Android app with package name: `com.example.fortumars_hrm_app`
   - If missing, add Android app:
     - Click "Add app" → Android icon
     - Package name: `com.example.fortumars_hrm_app`
     - App nickname: `FortuMars HRM Android`
     - Download `google-services.json`
     - Replace `android/app/google-services.json` with new file

### Step 2: Verify Authentication is Enabled

1. **Go to Authentication:**
   - https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/providers

2. **Enable Email/Password:**
   - Find "Email/Password" provider
   - Click it
   - Toggle "Enable" ON
   - Click "Save"

### Step 3: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

### Step 4: Verify Package Name Matches

**Check `android/app/build.gradle.kts`:**
- Should have: `namespace = "com.example.fortumars_hrm_app"`

**This MUST match the package name in Firebase Console!**

### Step 5: If Still Failing

**Option A: Re-register Android App**
1. Delete existing Android app from Firebase Console
2. Re-add Android app with same package name
3. Download new `google-services.json`
4. Replace old file
5. Clean and rebuild

**Option B: Check App ID**
- Verify `appId` in `firebase_options.dart` matches Firebase Console
- Verify `google-services.json` has correct `mobilesdk_app_id`

---

## Quick Check:

1. ✅ Android app registered in Firebase Console
2. ✅ Email/Password auth enabled
3. ✅ `google-services.json` in correct location
4. ✅ Package name matches everywhere
5. ✅ Clean rebuild done

If all checked, try login again!




