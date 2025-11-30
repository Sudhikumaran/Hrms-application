# 🔐 Add SHA-1 Fingerprint to Fix OAuth Configuration

## Why This is Needed:
Firebase needs your app's SHA-1 certificate fingerprint to generate OAuth clients for Email/Password authentication.

## Step 1: Get SHA-1 Fingerprint

### Option A: Using Gradle (Recommended)

1. **Open terminal in project root**
2. **Run:**
   ```bash
   cd android
   ./gradlew signingReport
   ```
   
   **OR on Windows:**
   ```bash
   cd android
   .\gradlew.bat signingReport
   ```

3. **Look for output like:**
   ```
   Variant: debug
   Config: debug
   Store: ~/.android/debug.keystore
   Alias: AndroidDebugKey
   SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   ```

4. **Copy the SHA1 value** (the long string after "SHA1:")

### Option B: Using Keytool (If Gradle doesn't work)

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

On Windows, the path is usually:
```
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Step 2: Add SHA-1 to Firebase Console

1. **Go to Project Settings:**
   - URL: https://console.firebase.google.com/project/fortumars-hrms-63078/settings/general

2. **Find Your Android App:**
   - Look for app with package: `com.example.fortumars_hrm_app`
   - Scroll down to "Your apps" section

3. **Add SHA Certificate Fingerprint:**
   - Click on your Android app
   - Under "SHA certificate fingerprints", click **"Add fingerprint"**
   - Paste your SHA-1 fingerprint
   - Click **"Save"**

## Step 3: Re-download google-services.json

1. **Still in Project Settings:**
   - After adding SHA-1, click the **download icon (⬇️)** next to `google-services.json`
   - Download the updated file

2. **Replace the file:**
   - Replace `android/app/google-services.json` with the newly downloaded file

3. **Verify it has OAuth clients:**
   - The new file should have `oauth_client` array with entries, not empty `[]`

## Step 4: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

## Step 5: Test Login

- Email: `admin@demo.com`
- Password: `admin123`

The `configuration-not-found` error should now be **GONE**! ✅

---

## Quick Summary:
1. Get SHA-1 fingerprint (use gradlew signingReport)
2. Add SHA-1 to Firebase Console → Your Android app
3. Re-download google-services.json
4. Replace the file
5. Clean and rebuild
6. Test login

**This will fix the empty OAuth clients issue!** 🎯




