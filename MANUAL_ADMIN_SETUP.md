# 🛠️ Manual Admin Setup - If Auto-Setup Fails

Since auto-setup isn't working, let's manually create the admin document.

## Step 1: Get the User UID

1. Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/authentication/users
2. Find `ceo@fortumars.com` in the list
3. **Copy the User UID** (click the copy icon next to it)
   - It looks like: `qeTVu7wmSFb...` or similar

## Step 2: Create Admin Document in Firestore

1. Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/firestore/databases/-default-/data
2. Click **"Start collection"** (or find `admins` collection if it exists)
3. If creating new collection:
   - Collection ID: `admins`
   - Click **"Next"**
4. Document ID: **Paste the UID** you copied from Step 1
5. Add these fields:
   - Field: `isAdmin`, Type: `boolean`, Value: `true`
   - Field: `uid`, Type: `string`, Value: (paste the UID again)
   - Field: `email`, Type: `string`, Value: `ceo@fortumars.com`
6. Click **"Save"**

## Step 3: Verify Firestore is Enabled

Make sure Firestore Database is enabled:
1. Go to: https://console.firebase.google.com/project/fortumars-hrms-63078/firestore
2. If you see "Create database", click it and enable it

## Step 4: Check Security Rules

1. Firestore → **Rules** tab
2. Should allow read/write:
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

## Step 5: Try Login Again

After creating the admin document manually:
1. Run: `flutter run`
2. Try logging in:
   - Email: `ceo@fortumars.com`
   - Password: `Ceo@Fortumars#1989`

## Troubleshooting

**If still not working**, check console logs:
```bash
flutter run
```

Look for messages starting with:
- `✅` = Success
- `❌` = Error
- `🔍` = Checking
- `🔧` = Attempting

Share the console output and I can help further!




