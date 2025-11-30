# 👤 Admin Login Credentials

## CEO Admin Account

**Email**: `ceo@fortumars.com`  
**Password**: `Ceo@Fortumars#1989`

## How to Login

1. Open the app
2. On the login screen, select **"Admin"** role (not "Employee")
3. Enter:
   - **Email**: `ceo@fortumars.com`
   - **Password**: `Ceo@Fortumars#1989`
4. Click **"Login"**

## Important Notes

⚠️ **Password is case-sensitive**: `Ceo@Fortumars#1989`
- Capital C, capital F
- Includes `@` and `#` symbols

## Setup Status

✅ These credentials should work if:
1. User `ceo@fortumars.com` exists in Firebase Authentication
2. Firestore `admins` collection has a document with `isAdmin: true`

If login fails, see `CREATE_CEO_ADMIN_USER.md` for setup instructions.

## Alternative Admin Setup

If you need to set up the admin document manually:
- Go to Firebase Console → Firestore → `admins` collection
- Create document with UID from Firebase Authentication
- Set `isAdmin: true`

---

**Quick Login**:
- Email: `ceo@fortumars.com`
- Password: `Ceo@Fortumars#1989`




