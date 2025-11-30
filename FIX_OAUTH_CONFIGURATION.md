# 🔧 Fix "configuration-not-found" - Missing OAuth Client

## The Issue:
Even though Email/Password is enabled, `google-services.json` still has empty OAuth clients:
```json
"oauth_client": []
```

## Solution: Re-download google-services.json

After enabling Email/Password authentication, you need to **re-download** the `google-services.json` file to get the OAuth client configuration.

### Step 1: Re-download google-services.json

1. **Go to Project Settings:**
   - URL: https://console.firebase.google.com/project/fortumars-hrms-63078/settings/general

2. **Find your Android app:**
   - Look for app with package: `com.example.fortumars_hrm_app`
   - Click the **download icon** (⬇️) next to `google-services.json`

3. **Replace the file:**
   - Replace `android/app/google-services.json` with the newly downloaded file

### Step 2: Add SHA-1 Certificate (If Required)

Sometimes Firebase needs your app's SHA-1 fingerprint:

1. **Get SHA-1 Fingerprint:**
   ```bash
   # For debug build:
   cd android
   ./gradlew signingReport
   ```
   
   Look for: `SHA1: XX:XX:XX:...` under `Variant: debug`

2. **Add to Firebase Console:**
   - Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/settings/general
   - Find your Android app
   - Click "Add fingerprint"
   - Paste the SHA-1 value
   - Save

3. **Re-download google-services.json again** (after adding SHA-1)

### Step 3: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

### Step 4: Alternative - Check Firebase Console

Sometimes you need to wait a few minutes after enabling authentication for the OAuth clients to be generated automatically. Try:

1. Wait 2-3 minutes after enabling Email/Password
2. Refresh Firebase Console
3. Re-download google-services.json
4. Rebuild

---

## Quick Check:

The new `google-services.json` should have `oauth_client` array with at least one entry, not empty!

After re-downloading, the configuration should work! ✅




