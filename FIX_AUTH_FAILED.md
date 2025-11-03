# 🔧 Fix "Authentication failed" Error

## Current Status:
- ✅ Firebase Auth: Working
- ✅ User Exists: Yes
- ❌ Sign In: FAILED
- ✅ Firestore: Working

## The Issue:
Authentication failed means the password is incorrect OR the user account has an issue.

## Fix Steps:

### Step 1: Verify Password in Firebase Console

1. **Go to Firebase Authentication:**
   - URL: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users

2. **Find the user:**
   - Look for `admin@demo.com`

3. **Reset/Verify Password:**
   - Click on the user
   - Click **"Reset password"** OR
   - Use three dots (⋮) menu → **"Reset password"**
   - Set password to: `admin123`
   - Make sure **"Email verified"** is checked ✅

### Step 2: Common Password Issues

**Check these:**
- No extra spaces before/after password
- Password is exactly: `admin123` (lowercase, no quotes)
- If you changed password, use the NEW password

### Step 3: If Password Reset Doesn't Work

**Try deleting and recreating the user:**

1. **Delete existing user:**
   - Firebase Authentication → Users
   - Find `admin@demo.com`
   - Click user → Three dots (⋮) → "Delete user"

2. **Create new user:**
   - Click "Add user"
   - Email: `admin@demo.com`
   - Password: `admin123`
   - ✅ Check "Email verified"
   - Click "Add user"
   - **Copy the NEW UID**

3. **Update Firestore document:**
   - Go to Firestore → `admins` collection
   - Delete old document (UID: `vge8TkWKrEUbHLzWQM1TpaGJ0ul2`)
   - Create new document with NEW UID as Document ID
   - Fields:
     - `isAdmin` = `true`
     - `uid` = NEW UID
     - `email` = `admin@demo.com`

### Step 4: Try Login Again

**Credentials:**
- Email: `admin@demo.com`
- Password: `admin123`

---

## Quick Fix (Most Common):

The password in Firebase Authentication probably doesn't match `admin123`.

**Solution:** Reset the password in Firebase Authentication console to `admin123`.


