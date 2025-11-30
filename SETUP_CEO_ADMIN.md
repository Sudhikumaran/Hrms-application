# 👤 Setup CEO Admin Account

## Admin Credentials:
- **Email**: `ceo@fortumars.com`
- **Password**: `Ceo@Fortumars#1989`

## Step 1: Create User in Firebase Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users)
2. Click **"Add user"** (or "Users" tab → "Add user")
3. Enter:
   - **Email**: `ceo@fortumars.com`
   - **Password**: `Ceo@Fortumars#1989`
   - **Email verified**: ✅ (check the box)
4. Click **"Add user"**
5. **Copy the UID** that's generated (you'll need it for Step 2)

## Step 2: Create Admin Document in Firestore

After creating the user, you have 3 options:

### Option A: Use the Admin Setup Screen (Easiest)
1. Run the app: `flutter run`
2. Log in with: `ceo@fortumars.com` / `Ceo@Fortumars#1989`
3. The app will automatically create the admin document on first login
4. You should be able to log in successfully!

### Option B: Use Firebase Console (Manual)
1. Go to [Firestore Database](https://console.firebase.google.com/project/fortumars-hrms-63078/firestore/databases/-default-/data)
2. Click **"Start collection"** (or "+")
3. Collection ID: `admins`
4. Document ID: Paste the **UID** from Step 1
5. Add these fields:
   - Field: `isAdmin`, Type: `boolean`, Value: `true`
   - Field: `uid`, Type: `string`, Value: (same UID)
   - Field: `email`, Type: `string`, Value: `ceo@fortumars.com`
6. Click **"Save"**

### Option C: Use the Helper Script
1. After creating the user, note the UID
2. The app has auto-setup that will create the document on first login
3. If you prefer manual setup, use Option B

## Step 3: Test Login

1. Run the app: `flutter run`
2. On login screen:
   - Select role: **"Admin"**
   - Email: `ceo@fortumars.com`
   - Password: `Ceo@Fortumars#1989`
3. Click **"Login"**
4. Should successfully log in and redirect to Admin Dashboard

## Troubleshooting

### "Access denied" error
- Make sure the admin document exists in Firestore (`admins` collection with UID as document ID)
- Check that `isAdmin: true` field is set

### "User not found" error
- Verify user was created in Firebase Authentication
- Check email spelling: `ceo@fortumars.com`

### "Wrong password" error
- Password is case-sensitive: `Ceo@Fortumars#1989`
- Check for any extra spaces

## After Setup

Once logged in:
- ✅ Admin document is automatically created if it doesn't exist
- ✅ Admin login works with these credentials
- ✅ All admin features are accessible

---

**Note**: The app has auto-setup functionality, so if you create the user in Firebase Authentication and log in, it will automatically create the admin document for you!




