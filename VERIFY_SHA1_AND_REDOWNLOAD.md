# ✅ Verify SHA-1 Added and Re-download

## Current Status:
Your `google-services.json` still has empty OAuth clients. This means:

**Either:**
1. SHA-1 fingerprint hasn't been added to Firebase Console yet, OR
2. You downloaded google-services.json before Firebase generated OAuth clients

## Step-by-Step Fix:

### Step 1: Verify SHA-1 is Added

1. **Go to Firebase Console:**
   - https://console.firebase.google.com/project/fortumars-hrms-63078/settings/general

2. **Check Your Android App:**
   - Find app: `com.example.fortumars_hrm_app`
   - Click on it
   - Scroll to "SHA certificate fingerprints"
   - **Verify you see:** `FA:17:F2:86:C8:88:0C:3B:01:1C:12:A7:8F:FC:40:40:72:BC:5E:3A`
   
   **If NOT there:**
   - Click "Add fingerprint"
   - Paste: `FA:17:F2:86:C8:88:0C:3B:01:1C:12:A7:8F:FC:40:40:72:BC:5E:3A`
   - Click "Save"
   - **Wait 30-60 seconds** for Firebase to process

### Step 2: Wait and Re-download

**Important:** After adding SHA-1, Firebase needs time (30-60 seconds) to generate OAuth clients.

1. **Wait 1 minute** after adding SHA-1
2. **Refresh the Firebase Console page** (F5)
3. **Re-download google-services.json:**
   - Still in Project Settings
   - Find your Android app
   - Click **download icon (⬇️)** next to `google-services.json`
   - Download the file

### Step 3: Verify New File Has OAuth Clients

**Before replacing**, check if the downloaded file has:

```json
"oauth_client": [
  {
    "client_id": "...",
    "client_type": 3,
    ...
  }
]
```

**NOT:** `"oauth_client": []`

### Step 4: Replace and Rebuild

1. **Replace the file:**
   - `android/app/google-services.json` ← replace with new file

2. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## If Still Empty After Adding SHA-1:

Sometimes Firebase needs the SHA-1 to be added **BEFORE** enabling Email/Password authentication.

**Try this order:**

1. Add SHA-1 fingerprint first
2. Wait 1-2 minutes
3. Enable Email/Password authentication
4. Wait 1-2 minutes
5. Re-download google-services.json
6. Should now have OAuth clients!

---

## Quick Checklist:

- [ ] SHA-1 added to Firebase Console
- [ ] Waited 1-2 minutes after adding
- [ ] Re-downloaded google-services.json
- [ ] Verified new file has OAuth clients (not empty)
- [ ] Replaced android/app/google-services.json
- [ ] Cleaned and rebuilt app

**Once OAuth clients are present, login will work!** ✅




