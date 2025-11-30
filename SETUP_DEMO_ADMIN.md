# 🚀 Setup Demo Admin Login

## Quick Setup (5 minutes)

### Step 1: Create Admin User in Firebase Authentication

1. **Go to Firebase Console:**
   - URL: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users

2. **Add User:**
   - Click **"Add user"** button (top of page)
   - **Email:** `admin@demo.com`
   - **Password:** `admin123`
   - ✅ **Check "Email verified"** (important!)
   - Click **"Add user"**

3. **Copy the User UID:**
   - After creating, click on the new user
   - **Copy the UID** (long string like: `abc123xyz456...`)
   - Keep this UID handy for Step 2

### Step 2: Create Admin Document in Firestore

1. **Go to Firestore:**
   - URL: https://console.firebase.google.com/project/fortumars-hrms-63078/firestore

2. **Create Collection (if not exists):**
   - Click **"Start collection"** or find **"admins"** collection
   - Collection name: `admins`

3. **Create Document:**
   - Click **"Add document"** or click on collection name
   - **Document ID:** Paste the User UID from Step 1
   - **Add Fields:**
     - Field name: `isAdmin` → Type: **boolean** → Value: `true`
     - Field name: `uid` → Type: **string** → Value: (paste same UID)
     - Field name: `email` → Type: **string** → Value: `admin@demo.com`
   - Click **"Save"**

### Step 3: Test Login

**Demo Credentials:**
- **Email:** `admin@demo.com`
- **Password:** `admin123`

Try logging in now! 🎉

---

## Alternative: Multiple Demo Admins

You can create multiple admin accounts:
- `admin1@demo.com` / `admin123`
- `admin2@demo.com` / `admin123`
- `ceo@fortumars.com` / `admin123` (for production)

Just repeat Steps 1-2 for each admin account!

---

## Troubleshooting

**If login fails:**
1. Click "Diagnose" button in error message
2. Check if User UID matches Document ID in Firestore
3. Verify `isAdmin` field is set to `true` (boolean, not string!)
4. Check email is verified in Firebase Authentication

---

**Setup takes 2-3 minutes!** ⚡




