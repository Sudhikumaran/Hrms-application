# 🔒 Firestore Security Rules Setup Guide

## ⚠️ CRITICAL: Set Security Rules Before Production

Your Firestore database needs security rules to prevent unauthorized access. Currently, it's likely in "test mode" which allows anyone to read/write.

---

## 📋 Step-by-Step Instructions

### Step 1: Access Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `myproject-f9e45` (or your project name)
3. Click on **"Firestore Database"** in the left menu
4. Click on the **"Rules"** tab

### Step 2: Copy Security Rules

The security rules file (`firestore.rules`) has been created in your project root. Copy its contents or use the rules below:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is admin
    function isAdmin() {
      return request.auth != null && 
             exists(/databases/$(database)/documents/admins/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Employees collection
    match /employees/{employeeId} {
      allow read: if request.auth != null;
      allow create, update, delete: if isAdmin();
    }
    
    // Attendance collection
    match /attendance/{attendanceId} {
      allow read: if request.auth != null && 
                     (resource.data.employeeId == request.auth.uid || isAdmin());
      allow create: if request.auth != null && 
                       request.resource.data.employeeId == request.auth.uid;
      allow update: if request.auth != null && 
                       (resource.data.employeeId == request.auth.uid || isAdmin());
      allow delete: if isAdmin();
    }
    
    // Leave requests
    match /leaveRequests/{leaveId} {
      allow read: if request.auth != null && 
                     (resource.data.empId == request.auth.uid || isAdmin());
      allow create: if request.auth != null && 
                       request.resource.data.empId == request.auth.uid;
      allow update: if request.auth != null && 
                       (resource.data.empId == request.auth.uid || isAdmin());
      allow delete: if isAdmin();
    }
    
    // Tasks (if used)
    match /tasks/{taskId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       (resource.data.assignedTo == request.auth.uid || isAdmin());
      allow delete: if isAdmin();
    }
    
    // Admins collection
    match /admins/{adminId} {
      allow read: if request.auth != null && request.auth.uid == adminId;
      allow write: if false; // Only set via Admin SDK
    }
    
    // Config collection
    match /config/{document=**} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
  }
}
```

### Step 3: Paste and Publish

1. **Paste** the rules into the Firebase Console Rules editor
2. Click **"Publish"** button
3. Wait for confirmation (should be instant)

---

## ✅ What These Rules Do

### Employees Collection
- ✅ Anyone authenticated can **read** employees (to find their own data)
- ✅ Only **admins** can create/update/delete employees

### Attendance Collection
- ✅ Users can **read** their own attendance records
- ✅ Admins can **read** all attendance
- ✅ Users can **create** their own attendance (check-in)
- ✅ Users can **update** their own attendance (check-out)
- ✅ Admins can **update/delete** any attendance

### Leave Requests
- ✅ Users can **read** their own leave requests
- ✅ Users can **create** leave requests
- ✅ Users can **update** their own requests (status changes)
- ✅ Admins can **read/update** all requests

### Admins Collection
- ✅ Only admins can **read** their own admin record
- ✅ **Write** is disabled (must be set via Firebase Admin SDK)

---

## 🧪 Testing the Rules

After publishing:

1. **Test Mode Check**: The console should show a warning if still in test mode - you've fixed it!
2. **Test Access**: Try accessing Firestore from your app - should work for authenticated users
3. **Test Unauthorized**: Without authentication, operations should fail

---

## ⚠️ Important Notes

1. **Admin Setup**: To set a user as admin, you need to:
   - Use Firebase Admin SDK (server-side)
   - Or manually create in Firestore Console:
     - Collection: `admins`
     - Document ID: `{firebase_auth_uid}`
     - Fields: `{ isAdmin: true }`

2. **Custom Claims Alternative**: You can also use Firebase Custom Claims instead of the `admins` collection:
   ```javascript
   // In Firebase Admin SDK (Node.js)
   admin.auth().setCustomUserClaims(uid, { admin: true });
   ```
   Then update rules to check custom claims instead.

3. **Storage Rules**: Don't forget to set Firebase Storage rules too if you use Storage!

---

## 🔍 Troubleshooting

### "Permission denied" errors

1. **Check authentication**: User must be signed in
2. **Check admin status**: Verify admin document exists in Firestore
3. **Check rule syntax**: Make sure rules are valid (Firebase Console will show errors)

### Rules not applying

1. **Wait a few seconds**: Rules can take 1-2 minutes to propagate
2. **Clear app cache**: Sometimes cached rules persist
3. **Check rule version**: Should be `rules_version = '2'`

---

## ✅ Verification Checklist

- [ ] Rules pasted in Firebase Console
- [ ] Rules published successfully
- [ ] No syntax errors shown
- [ ] Test mode warning removed
- [ ] Admin document created in Firestore
- [ ] Test app access - works for authenticated users
- [ ] Test unauthorized access - properly denied

---

**Once these rules are set, your Firestore database is production-ready! 🔒**





