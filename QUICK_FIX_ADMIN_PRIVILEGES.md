# 🔧 Quick Fix: "Admin Privileges Required" Error

## The Problem:
Login works but shows "Admin privileges required" - this means the admin document in Firestore is missing or not accessible.

## Quick Solution:

### Option 1: Check Firestore Admin Document (Easiest)

1. **Get your User UID:**
   - When you created the admin account, the app showed a UID
   - OR go to Firebase Authentication → Find your user → Copy the UID

2. **Check Firestore:**
   - URL: https://console.firebase.google.com/project/fortumars-hrms-63078/firestore
   - Go to `admins` collection
   - Look for document with your UID as Document ID

3. **If document exists:**
   - Check if `isAdmin` field = `true` (boolean, not string!)
   - If not true, edit it and set to `true`

4. **If document doesn't exist:**
   - Create it:
     - Document ID: Your UID
     - `isAdmin` = `true` (boolean)
     - `uid` = Your UID (string)
     - `email` = Your email

### Option 2: Rebuild and Let Auto-Setup Work

The code now has enhanced auto-setup that should create the admin document automatically:

```bash
flutter clean
flutter pub get
flutter run
```

Then try login again - it should auto-create the admin document if missing.

---

## What the Fix Does:

1. ✅ Works with REST API authentication (no currentUser needed)
2. ✅ Checks Firestore directly for admin document
3. ✅ Auto-creates admin document if missing
4. ✅ Retries admin check after auto-setup
5. ✅ Better error messages

**Try rebuilding and logging in again - it should work now!** 🚀


