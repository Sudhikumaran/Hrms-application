# 🔧 Troubleshoot: "Invalid credentials" on Admin Login

## Current Issue
You're seeing "Invalid credentials" when trying to log in with:
- Email: `ceo@fortumars.com`
- Password: `Ceo@Fortumars#1989`

## Possible Causes & Solutions

### ✅ Solution 1: Create User in Firebase Authentication (Most Common)

The user might not exist in Firebase Authentication yet.

**Steps:**
1. Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users
2. Check if `ceo@fortumars.com` exists in the users list
3. If **NOT** there:
   - Click **"Add user"**
   - Email: `ceo@fortumars.com`
   - Password: `Ceo@Fortumars#1989`
   - ✅ Check **"Set email as verified"**
   - Click **"Add user"**
4. Try logging in again

### ✅ Solution 2: Verify Password

Double-check the password:
- Must be exactly: `Ceo@Fortumars#1989`
- Case-sensitive (capital C, capital F)
- Includes `@` and `#` symbols

### ✅ Solution 3: Check Firestore Connection

If Firestore isn't connected, admin check might fail:
1. Ensure Firestore is enabled in Firebase Console
2. Check security rules allow access
3. Look for connection messages in app console

### ✅ Solution 4: Admin Document Auto-Creation

The app automatically creates admin document on first login. If login fails with "Invalid credentials", it might be:
- Wrong password
- User doesn't exist in Firebase Authentication
- Network/connection issue

## Quick Diagnostic Steps

1. **Verify User Exists:**
   - Go to Firebase Console → Authentication → Users
   - Look for `ceo@fortumars.com`
   - If missing, create it

2. **Test Password:**
   - Try resetting password in Firebase Console
   - Or create user fresh with correct password

3. **Check Console Logs:**
   - Run app with `flutter run`
   - Look for error messages in console
   - Should see messages like "Admin check: ..."

4. **Check Firestore:**
   - Ensure Firestore Database is enabled
   - Check security rules allow access

## Expected Behavior

After creating user in Firebase Authentication:
1. First login attempt → App creates admin document automatically
2. Login succeeds → Redirects to Admin Dashboard
3. Admin document appears in Firestore `admins` collection

## Still Not Working?

If user exists and password is correct:
1. Check Firebase project matches: `fortumars-hrms-63078`
2. Verify `firebase_options.dart` has correct project ID
3. Check internet connection
4. Try logging out and back in

---

**Most likely fix**: Create the user in Firebase Authentication first!


