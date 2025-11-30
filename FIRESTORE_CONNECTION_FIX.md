# 🔧 Firestore Connection Timeout - Fix Guide

## Problem
Your app is showing:
```
HybridStorageService.isOnline: false
Firestore connection failed: TimeoutException after 0:00:05.000000
```

This means data is **NOT** syncing to Firestore - only stored locally.

## Root Causes & Solutions

### ✅ Solution 1: Enable Firestore Database (Most Common)

**Problem**: Firestore Database may not be created in your Firebase project.

**Fix**:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `myproject-f9e45`
3. Click **"Firestore Database"** in the left sidebar
4. If you see "Create database" button:
   - Click it
   - Choose **"Start in test mode"** (for development)
   - Select your preferred location (e.g., `us-central1`)
   - Click **"Enable"**
5. Wait 1-2 minutes for the database to initialize

**Verify**: You should see an empty database with collections view.

---

### ✅ Solution 2: Check Firestore Security Rules

**Problem**: Security rules might be blocking all access.

**Fix**:
1. In Firebase Console → Firestore Database → **Rules** tab
2. Replace with these **test mode** rules (for development only):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all documents
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

3. Click **"Publish"**
4. Wait 30 seconds for rules to update

⚠️ **Warning**: These rules allow anyone to read/write. Use proper rules for production!

---

### ✅ Solution 3: Check Internet Connection

**Problem**: Device/emulator has no internet.

**Fix**:
- Ensure device has internet connection
- If using emulator, check network settings
- Try restarting the app after connecting to internet

---

### ✅ Solution 4: Verify Firebase Project Configuration

**Problem**: Firebase config might be incorrect.

**Fix**:
1. Verify `lib/firebase_options.dart` has correct project ID: `myproject-f9e45`
2. Check `android/app/google-services.json` exists and is valid
3. Run:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

### ✅ Solution 5: Increase Timeout (Already Done)

I've increased the timeout from 5 to 10 seconds. If it still times out, the database likely isn't enabled.

---

## Quick Diagnostic Steps

1. **Check Firestore exists**: 
   - Firebase Console → Firestore Database
   - Should see collections view (even if empty)

2. **Check Security Rules**:
   - Rules tab should allow reads/writes

3. **Test Connection**:
   - Restart app
   - Check console for: `HybridStorage: Firestore connected ✅`
   - Use Admin Dashboard → "Firestore Sync Status" button

4. **Check Network**:
   - Ensure device has internet
   - Firewall/VPN might be blocking Firebase

---

## After Fixing

Once Firestore is enabled:
1. Restart the app
2. You should see: `HybridStorage: Firestore connected ✅`
3. Data will automatically sync:
   - On save operations
   - Every 30 seconds automatically
   - On app startup

---

## Verify It's Working

1. **In App**: Go to Admin Dashboard → "Firestore Sync Status"
   - Should show "✅ Connected"
   - Should show data counts

2. **In Firebase Console**: 
   - Go to Firestore Database
   - You should see collections: `employees`, `attendance`, `leaveRequests`, `admins`

3. **Test Save**:
   - Create/update an employee
   - Check Firebase Console → Firestore → `employees` collection
   - Should see the data appear within seconds

---

## Still Not Working?

If connection still fails after all steps:
1. Check Firebase Console → Project Settings → General
2. Ensure Firestore is listed as "Enabled"
3. Try creating a test collection manually in Firebase Console
4. Check if you're using the correct Firebase project

---

## Summary

**Most likely issue**: Firestore Database is not created in Firebase Console.

**Quick fix**: 
1. Go to Firebase Console
2. Create Firestore Database
3. Set rules to test mode
4. Restart app

Data will then sync automatically! 🎉




