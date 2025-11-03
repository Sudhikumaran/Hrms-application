# ⚡ Quick Demo Admin Setup (2 minutes)

## Option 1: Automatic Setup (Easiest)

1. **Create user in Firebase Authentication:**
   - Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users
   - Click "Add user"
   - **Email:** `admin@demo.com`
   - **Password:** `admin123`
   - ✅ Check "Email verified"
   - Click "Add user"
   - **Copy the User UID** (click on user to see UID)

2. **Use the app to auto-setup:**
   - Open the app
   - Go to Admin Dashboard → "Cleanup & Diagnostics"
   - Scroll down to "Demo Admin Setup" section
   - Paste the UID in the dialog
   - Click "Setup"
   - Done! ✅

3. **Login:**
   - Email: `admin@demo.com`
   - Password: `admin123`

---

## Option 2: Manual Setup

### Step 1: Firebase Authentication
- URL: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users
- Create user:
  - Email: `admin@demo.com`
  - Password: `admin123`
  - ✅ Email verified: Yes
- **Copy the User UID**

### Step 2: Firestore
- URL: https://console.firebase.google.com/project/fortumars-hrms-63078/firestore
- Collection: `admins`
- Document ID: **Paste the UID from Step 1**
- Fields:
  - `isAdmin` (boolean) = `true`
  - `uid` (string) = UID from Step 1
  - `email` (string) = `admin@demo.com`

### Step 3: Login
- Email: `admin@demo.com`
- Password: `admin123`

---

## Demo Credentials Summary:

```
Email: admin@demo.com
Password: admin123
```

**Setup takes 2 minutes!** 🚀


