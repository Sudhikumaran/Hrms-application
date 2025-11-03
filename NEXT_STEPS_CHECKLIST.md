# ✅ Next Steps Checklist

## Right Now - Do These Steps:

### ☐ Step 1: Verify SHA-1 in Firebase
- [ ] Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/settings/general
- [ ] Click on Android app: `com.example.fortumars_hrm_app`
- [ ] Check "SHA certificate fingerprints" section
- [ ] Verify SHA-1 exists: `FA:17:F2:86:C8:88:0C:3B:01:1C:12:A7:8F:FC:40:40:72:BC:5E:3A`
- [ ] If NOT there → Click "Add fingerprint" → Paste SHA-1 → Save

### ☐ Step 2: Wait and Re-download
- [ ] If you just added SHA-1, **wait 1-2 minutes**
- [ ] Refresh Firebase Console page (F5)
- [ ] Click **download icon (⬇️)** next to `google-services.json`
- [ ] Save the file (don't replace yet!)

### ☐ Step 3: Verify File Has OAuth Clients
- [ ] Open the downloaded `google-services.json` file
- [ ] Search for `"oauth_client"`
- [ ] Check if it has entries like:
  ```json
  "oauth_client": [
    {
      "client_id": "...",
      "client_type": 3
    }
  ]
  ```
- [ ] ✅ If it HAS entries → Continue to Step 4
- [ ] ❌ If it's STILL empty `[]` → Wait another minute and re-download

### ☐ Step 4: Replace File and Rebuild
- [ ] Replace `android/app/google-services.json` with new file
- [ ] Run commands:
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

### ☐ Step 5: Test Login
- [ ] Try login with:
  - Email: `admin@demo.com`
  - Password: `admin123`
- [ ] Should work now! ✅

---

## Quick Command to Run After Step 4:

```bash
flutter clean && flutter pub get && flutter run
```

---

## If OAuth Clients Still Empty After 5 Minutes:

1. Try adding SHA-1 again (maybe typo?)
2. Double-check Email/Password is enabled
3. Try deleting and re-adding Android app in Firebase Console
4. Contact Firebase support if still not working

**Most likely: You need to wait a bit longer for Firebase to process SHA-1!** ⏳


