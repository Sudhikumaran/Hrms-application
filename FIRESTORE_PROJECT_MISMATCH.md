# ⚠️ CRITICAL: Firebase Project ID Mismatch Found!

## Problem

Your `google-services.json` file points to project: **`fortumars-hrms-63078`**
But your `firebase_options.dart` uses project: **`myproject-f9e45`**

This mismatch is causing the Firestore connection timeout!

## Solution Options

### Option 1: Use the Correct Project (fortumars-hrms-63078) - RECOMMENDED

Update `lib/firebase_options.dart` to match your `google-services.json`:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **fortumars-hrms-63078**
3. Go to Project Settings (gear icon) → General tab
4. Scroll to "Your apps" section
5. Find your Android/iOS/Web apps
6. Copy the correct configuration values
7. Update `lib/firebase_options.dart` with the matching values

### Option 2: Regenerate firebase_options.dart (EASIEST)

Run FlutterFire CLI to regenerate with correct project:

```bash
flutterfire configure
```

This will:
- Detect your `google-services.json` project
- Automatically update `firebase_options.dart`
- Match all platform configs

### Option 3: Ensure Firestore is Enabled

**IMPORTANT**: Before anything else, make sure Firestore is enabled in your Firebase project!

1. Go to Firebase Console → Project: **fortumars-hrms-63078**
2. Click **"Firestore Database"** in sidebar
3. If you see "Create database":
   - Click it
   - Choose **"Start in test mode"**
   - Select location
   - Click **"Enable"**
4. Wait 1-2 minutes

## Quick Fix Steps

1. **Enable Firestore** in Firebase project `fortumars-hrms-63078`
2. **Run**: `flutterfire configure` (or manually update `firebase_options.dart`)
3. **Restart** the app
4. **Check** connection status in Admin Dashboard

## After Fixing

You should see:
```
HybridStorage: Firestore connected ✅
```

And data will sync to Firestore automatically!

---

## Verify Project Match

Check these match:
- ✅ `android/app/google-services.json` → `project_id: "fortumars-hrms-63078"`
- ✅ `lib/firebase_options.dart` → `projectId: 'fortumars-hrms-63078'`
- ✅ Firestore enabled in Firebase Console for `fortumars-hrms-63078`




