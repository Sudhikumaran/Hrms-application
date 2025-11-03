# 🔧 Fix "configuration-not-found" - Authentication Not Enabled

## The Problem:
Error: `Firebase error code: configuration-not-found`

This means **Firebase Authentication is not enabled** for your Android app.

## Quick Fix (5 minutes):

### Step 1: Enable Email/Password Authentication

1. **Go to Firebase Authentication:**
   - URL: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/providers

2. **Enable Email/Password:**
   - Click on **"Email/Password"**
   - Toggle **"Enable"** to **ON**
   - Make sure both checkboxes are enabled:
     - ✅ Email/Password (first sign-in method)
     - ✅ Email link (passwordless sign-in) - optional
   - Click **"Save"**

### Step 2: Verify Android App is Registered

1. **Go to Project Settings:**
   - URL: https://console.firebase.google.com/project/fortumars-hrms-63078/settings/general

2. **Check "Your apps" section:**
   - Should see Android app with package: `com.example.fortumars_hrm_app`
   - If missing, click "Add app" → Android
   - Package name: `com.example.fortumars_hrm_app`
   - Download `google-services.json` and replace the existing file

### Step 3: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

### Step 4: Try Login Again

After enabling Authentication, try logging in:
- Email: `admin@demo.com`
- Password: `admin123`

---

## Why This Happens:

The `configuration-not-found` error occurs when:
- Authentication provider is not enabled in Firebase Console
- Android app is not properly registered
- `google-services.json` is missing OAuth configuration

**The most common cause: Email/Password authentication is not enabled!**

---

## Verification:

After enabling, you should see:
- ✅ Authentication shows "Email/Password" as enabled
- ✅ Login works without "configuration-not-found" error

**Enable Authentication first - this fixes 90% of configuration-not-found errors!**


