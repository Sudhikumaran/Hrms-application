# 🔑 Quick SHA-1 Fingerprint Guide

## The Issue:
Your `google-services.json` still has empty `oauth_client: []` because Firebase needs your app's SHA-1 fingerprint first.

## Get SHA-1 Fingerprint - Choose One Method:

### Method 1: Using Android Studio (Easiest)

1. **Open Android Studio**
2. **Open your project:** `D:\FortuMars_HRMS\MobileApp-HRM`
3. **Open Gradle panel:**
   - Look for "Gradle" tab on the right side
   - If not visible, click: `View` → `Tool Windows` → `Gradle`
4. **Run signingReport:**
   - Navigate to: `fortumars_hrm_app` → `Tasks` → `android` → `signingReport`
   - Double-click `signingReport`
5. **Find SHA-1:**
   - Look in the "Run" output panel at the bottom
   - Find line like: `SHA1: XX:XX:XX:XX:XX:...`
   - **Copy the entire SHA-1 string**

### Method 2: Using Command Line

**Windows:**
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Look for:** `SHA1: XX:XX:XX:...`

### Method 3: Using Flutter

If you have `keytool` in your PATH:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Add SHA-1 to Firebase:

1. **Go to:**
   - https://console.firebase.google.com/project/fortumars-hrms-63078/settings/general

2. **Find Android app:**
   - Look for: `com.example.fortumars_hrm_app`

3. **Add fingerprint:**
   - Click on the app
   - Under "SHA certificate fingerprints"
   - Click **"Add fingerprint"**
   - Paste your SHA-1 (the full string with colons)
   - Click **"Save"**

4. **Re-download google-services.json:**
   - Click download icon (⬇️) next to `google-services.json`
   - Replace `android/app/google-services.json`

5. **Verify:**
   - Check new file has `oauth_client` with entries (not empty `[]`)

6. **Rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## After Adding SHA-1:
The `google-services.json` should have OAuth clients like:
```json
"oauth_client": [
  {
    "client_id": "...",
    "client_type": 3
  }
]
```

**This will fix the configuration-not-found error!** ✅


