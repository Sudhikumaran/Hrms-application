# ✅ Admin Setup for UID: vge8TkWKrEUbHLzWQM1TpaGJ0ul2

## Quick Setup Steps:

### Step 1: Verify User in Firebase Authentication
- URL: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users
- Find user with UID: `vge8TkWKrEUbHLzWQM1TpaGJ0ul2`
- Verify email is verified ✅

### Step 2: Create Admin Document in Firestore

**URL:** https://console.firebase.google.com/project/fortumars-hrms-63078/firestore

1. **Go to Firestore Database**
2. **Click "Start collection"** (or find existing `admins` collection)
3. **Collection ID:** `admins`
4. **Click "Next"**
5. **Document ID:** `vge8TkWKrEUbHLzWQM1TpaGJ0ul2` (paste the UID)
6. **Add Fields:**
   - Field name: `isAdmin`
     - Type: **boolean**
     - Value: `true`
   - Field name: `uid`
     - Type: **string**
     - Value: `vge8TkWKrEUbHLzWQM1TpaGJ0ul2`
   - Field name: `email`
     - Type: **string**
     - Value: `admin@demo.com` (or whatever email you used)
7. **Click "Save"**

### Step 3: Test Login

**Credentials:**
- Email: `admin@demo.com` (or the email you used)
- Password: `admin123` (or the password you set)

---

## Alternative: Use App's Auto-Setup

If you have access to the app:
1. Open Admin Dashboard
2. Go to "Cleanup & Diagnostics"
3. Scroll to "Demo Admin Setup"
4. Click "Setup Demo Admin Document"
5. Paste UID: `vge8TkWKrEUbHLzWQM1TpaGJ0ul2`
6. Click "Setup"

---

## Firestore Document Structure:

```json
{
  "isAdmin": true,
  "uid": "vge8TkWKrEUbHLzWQM1TpaGJ0ul2",
  "email": "admin@demo.com"
}
```

**Document ID must match UID exactly!**


