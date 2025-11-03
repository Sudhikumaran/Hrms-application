# ⚠️ Critical: UID Mismatch Check

## Issue
The admin document might have a different UID than the actual Firebase Auth user.

## How to Verify UID Match

### Step 1: Get Actual User UID from Firebase Auth

1. Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users
2. Click on `ceo@fortumars.com`
3. **Copy the User UID** shown (should be in the user details page)
4. Note this UID - let's call it **"Actual UID"**

### Step 2: Check Admin Document UID

1. Go to Firestore: https://console.firebase.google.com/project/fortumars-hrms-63078/firestore
2. Open `admins` collection
3. Find the document (probably `1i4pkgSXLFQruAhWlpPQnzGgdbn2`)
4. Check:
   - **Document ID** should match **Actual UID**
   - **uid field** should also match **Actual UID**

### Step 3: Fix if Mismatched

If the Document ID or `uid` field doesn't match the Actual UID from Firebase Auth:

1. **Delete the current admin document** (wrong UID)
2. **Create new document** with:
   - Document ID: **Actual UID** (from Firebase Auth)
   - `isAdmin`: `true`
   - `uid`: **Actual UID** (same value)
   - `email`: `ceo@fortumars.com`

## Common Issue

The UID you see in the admin document (`1i4pkgSXLFQruAhWlpPQnzGgdbn2`) might not be the actual UID of `ceo@fortumars.com` in Firebase Auth.

**The Document ID MUST match the User UID from Firebase Authentication!**

## Quick Fix

1. Get the actual UID from Firebase Auth (for ceo@fortumars.com)
2. Delete the admin document if it has wrong UID
3. Create new document with correct UID as Document ID
4. Try login again

---

**This is likely the issue!** The UID mismatch would cause the admin check to fail.


