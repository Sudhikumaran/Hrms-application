# 🔐 Admin Authentication Setup Guide

## Problem
Admin login is not working after adding admin credentials to Firebase Authentication.

## Solution

You need to verify the admin user in one of these ways:

### **Option 1: Set Custom Claims (Recommended - Most Secure)**

This requires Firebase Admin SDK. If you have a backend server:

```javascript
// Using Firebase Admin SDK (Node.js)
const admin = require('firebase-admin');
admin.initializeApp();

// Set admin custom claim for a user
const uid = 'USER_UID_HERE'; // Get from Firebase Console > Authentication
admin.auth().setCustomUserClaims(uid, { admin: true });
```

**OR** use Firebase Console Functions:
1. Go to Firebase Console > Functions
2. Create a function to set custom claims
3. Call it with the user's UID

### **Option 2: Create Firestore Admin Document (Easiest)**

1. Go to Firebase Console > Firestore Database
2. Create a collection called `admins`
3. Create a document with the **User UID** (not email) as the document ID
4. Add a field: `isAdmin` = `true`

**Example:**
```
Collection: admins
Document ID: [USER_UID_FROM_AUTHENTICATION]
Fields:
  - isAdmin: true
  - email: "admin@example.com"
  - createdAt: [timestamp]
```

**To find the UID:**
- Go to Firebase Console > Authentication > Users
- Find your admin user
- Copy the UID (not the email)

### **Option 3: Add Email to Admin List (Simple)**

1. Go to Firebase Console > Firestore Database
2. Create a collection called `config`
3. Create a document with ID `admins`
4. Add a field: `emails` = `["admin@example.com"]` (array of strings)

**Example:**
```
Collection: config
Document ID: admins
Fields:
  - emails: ["admin@example.com", "admin2@example.com"]
```

### **Option 4: Temporary Workaround (Less Secure)**

If you need immediate access, you can temporarily modify the code to accept any authenticated Firebase user as admin. However, this is **NOT RECOMMENDED** for production.

---

## Verification Steps

1. ✅ Add admin user to Firebase Authentication
2. ✅ Set up one of the verification methods above (Option 2 is easiest)
3. ✅ Try logging in with admin email and password
4. ✅ Check console logs for "Admin check: ..." messages

## Troubleshooting

### Error: "Access denied. Admin privileges required."
- The user authenticated successfully but failed admin verification
- Check that you've set up one of the verification methods above
- Check console logs for which verification method failed

### Error: "No admin account found with this email"
- The email doesn't exist in Firebase Authentication
- Go to Firebase Console > Authentication > Users and verify the email

### Error: "Incorrect password"
- The password is wrong
- Reset password in Firebase Console or use the forgot password flow

### Error: "Authentication failed"
- General authentication error
- Check Firebase project configuration
- Verify `google-services.json` is in `android/app/`
- Check internet connection

## Quick Setup (Recommended: Option 2)

1. Open Firebase Console
2. Go to Authentication > Users
3. Find your admin user and **copy the UID**
4. Go to Firestore Database
5. Create collection: `admins`
6. Create document with ID = the UID you copied
7. Add field: `isAdmin` = `true` (boolean)
8. Save
9. Try logging in again!

---

## Testing

After setup, the console should show:
```
Admin check: Checking for UID: [uid], Email: [email]
Admin check: Found admin in Firestore admins collection
```

If you see "Access denied" errors, check which verification method failed in the logs.


