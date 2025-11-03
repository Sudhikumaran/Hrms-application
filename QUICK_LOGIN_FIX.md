# 🔍 Quick Login Fix Guide

## When Login Fails:

1. **Click "Diagnose" button** in the error message
2. **Check the diagnostic results** - it will show:
   - ✅ What's working
   - ❌ What's failing
   - 📋 Specific recommendations

## Common Issues & Fixes:

### Issue 1: "User not found"
**Fix:** 
- Go to Firebase Authentication console
- Create user with email `ceo@fortumars.com`
- Set password `admin123`

### Issue 2: "Wrong password"
**Fix:**
- Go to Firebase Authentication console
- Click on `ceo@fortumars.com` user
- Click "Reset password" or change password to `admin123`

### Issue 3: "Admin document does not exist"
**Fix:**
- Get User UID from Firebase Authentication (click on user)
- Go to Firestore → `admins` collection
- Create document with Document ID = User UID
- Add field: `isAdmin` = `true`
- Add field: `uid` = User UID (same value)
- Add field: `email` = `ceo@fortumars.com`

### Issue 4: "Firestore not connected"
**Fix:**
- Go to Firebase Console
- Enable Firestore Database (if not enabled)
- Wait 1-2 minutes for database to initialize
- Check security rules allow read/write

## Step-by-Step Setup:

### 1. Create User in Firebase Authentication:
```
URL: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users
- Click "Add user"
- Email: ceo@fortumars.com
- Password: admin123
- ✅ Check "Email verified"
```

### 2. Create Admin Document in Firestore:
```
URL: https://console.firebase.google.com/project/fortumars-hrms-63078/firestore
- Click "Start collection" → Name: admins
- Click "Auto-ID" → Change to the User UID from step 1
- Add field: isAdmin (boolean) = true
- Add field: uid (string) = User UID
- Add field: email (string) = ceo@fortumars.com
- Click "Save"
```

### 3. Test Login:
- Email: `ceo@fortumars.com`
- Password: `admin123`

## Using the Diagnostic Tool:

1. Try to login
2. When error appears, click **"Diagnose"**
3. Wait for diagnostic to complete
4. Read the recommendations
5. Follow the specific fix for your issue

---

**The diagnostic tool will tell you exactly what's wrong and how to fix it!**


