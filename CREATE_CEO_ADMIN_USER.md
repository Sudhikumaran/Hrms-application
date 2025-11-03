# 👤 Create CEO Admin User - Quick Guide

## CEO Admin Credentials
- **Email**: `ceo@fortumars.com`
- **Password**: `Ceo@Fortumars#1989`

## Quick Setup Steps

### Step 1: Create User in Firebase Authentication

1. Open: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users
2. Click **"Add user"** button
3. Fill in:
   - **Email**: `ceo@fortumars.com`
   - **Password**: `Ceo@Fortumars#1989`
   - ✅ Check **"Set email as verified"**
4. Click **"Add user"**
5. ✅ User created! Note the UID if shown (not required - auto-setup will handle it)

### Step 2: Enable Firestore (if not already done)

1. Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/firestore
2. If you see "Create database":
   - Click **"Create database"**
   - Choose **"Start in test mode"**
   - Select location
   - Click **"Enable"**

### Step 3: Set Firestore Security Rules

1. In Firestore → **Rules** tab
2. Paste:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```
3. Click **"Publish"**

### Step 4: Test Login (Auto-Setup)

The app has **automatic admin document creation**! Just:

1. Run: `flutter run`
2. On login screen:
   - Select **"Admin"** role
   - Email: `ceo@fortumars.com`
   - Password: `Ceo@Fortumars#1989`
3. Click **"Login"**
4. ✅ On first login, the app automatically:
   - Creates admin document in Firestore
   - Grants admin access
   - Logs you into Admin Dashboard

## That's It! 🎉

The admin document will be automatically created on first login. No manual Firestore setup needed!

## Verify It Worked

After logging in:
1. Go to Firebase Console → Firestore → Data
2. Check `admins` collection
3. You should see a document with the UID containing:
   - `isAdmin: true`
   - `email: ceo@fortumars.com`
   - `uid: <your-uid>`

## Troubleshooting

**"Access denied" on first login?**
- Wait 1-2 seconds and try logging in again
- The auto-setup might need a moment

**"User not found"?**
- Verify user was created in Firebase Authentication
- Check email spelling: `ceo@fortumars.com`

**"Wrong password"?**
- Password is: `Ceo@Fortumars#1989` (case-sensitive, includes @ and #)

---

**Note**: The app's auto-setup feature creates the admin document automatically, so you don't need to manually create it in Firestore!


