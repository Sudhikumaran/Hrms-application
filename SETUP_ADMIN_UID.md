# Quick Admin Setup for UID: MVsrV4s4PEWTbF1gxsdjib8jIO22

## Method 1: Firestore Admin Document (Recommended)

### Steps:
1. Open Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to **Firestore Database**
4. Click **Start collection** (if no collections exist) or click **Add collection**
5. Collection ID: `admins`
6. Click **Next**
7. Document ID: `MVsrV4s4PEWTbF1gxsdjib8jIO22` (paste the UID exactly)
8. Add first field:
   - Field: `isAdmin`
   - Type: **boolean**
   - Value: `true`
9. Click **Save**

### Visual Guide:
```
Firestore Database
└── Collection: admins
    └── Document ID: MVsrV4s4PEWTbF1gxsdjib8jIO22
        └── Field: isAdmin = true (boolean)
```

## Method 2: Using Firebase Console Directly

1. Firebase Console → Firestore Database
2. Click **"Start collection"** or the **"+"** button
3. Collection ID: `admins`
4. Document ID: `MVsrV4s4PEWTbF1gxsdjib8jIO22`
5. Click **"Add field"**:
   - Field name: `isAdmin`
   - Type: Select **boolean**
   - Value: `true`
6. Click **Save**

## Verification

After setup, the app will check:
- ✅ Firebase Authentication (already done - user can sign in)
- ✅ Firestore `admins/{UID}` document with `isAdmin: true`

## Testing

1. Run the app
2. Select "Admin" role
3. Enter the admin email and password
4. Check console logs for:
   ```
   Admin check: Checking for UID: MVsrV4s4PEWTbF1gxsdjib8jIO22
   Admin check: Found admin in Firestore admins collection ✅
   ```

## Troubleshooting

If login still fails after setup:
1. Verify the UID matches exactly (case-sensitive)
2. Check that `isAdmin` is a boolean `true`, not a string
3. Wait a few seconds after creating the document (Firestore sync time)
4. Check console logs for specific error messages




