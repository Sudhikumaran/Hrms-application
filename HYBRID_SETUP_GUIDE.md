# 🔄 Hybrid Storage Setup Guide

## ✅ What I've Done:

1. ✅ Created `HybridStorageService` - Combines local storage + Firestore
2. ✅ Updated `main.dart` to use HybridStorageService
3. ✅ Automatic sync between local and cloud

---

## 📋 How It Works:

### Architecture:

```
App → HybridStorageService
         ↓
    ┌────┴────┐
    ↓         ↓
Local Storage  Firestore
(Always works)  (When online)
    ↓         ↓
    └────┬────┘
    Automatic Sync
```

### Features:

1. **Local First**: Always saves to local storage immediately
2. **Cloud Sync**: Automatically syncs to Firestore when online
3. **Offline Support**: Works completely offline (uses local data)
4. **Auto Sync**: Syncs every 30 seconds when online
5. **Conflict Resolution**: Latest write wins

---

## 🔧 Setup Steps:

### Step 1: Enable Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `fortumars-hrms-63078`
3. Click **"Firestore Database"** in left menu
4. Click **"Create database"**
5. Choose **"Start in test mode"** (for development)
6. Select region (closest to your users)
7. Click **"Done"**

### Step 2: Test the Connection

Run the app and check logs:
- Should see: `Firebase initialized successfully`
- Should see: `Hybrid storage initialized successfully`
- Should see: `Synced X employees from Firestore` (if data exists)

### Step 3: Update Screens (Optional - Gradually Migrate)

**Option A: Quick Test (One Screen)**
Update `attendance_screen.dart` to use `HybridStorageService` instead of `LocalStorageService`

**Option B: Full Migration**
Replace `LocalStorageService` with `HybridStorageService` in all screens

---

## 📝 Migration Example:

### Before (LocalStorageService):
```dart
import 'services/local_storage_service.dart';

// Save
await LocalStorageService.upsertAttendance(empId, record);

// Get
final records = LocalStorageService.getAttendance(empId);
```

### After (HybridStorageService):
```dart
import 'services/hybrid_storage_service.dart';

// Save (automatically syncs to Firestore if online)
await HybridStorageService.saveAttendance(empId, record);

// Get (reads from local, syncs from cloud in background)
final records = HybridStorageService.getAttendance(empId);
```

---

## 🎯 What Gets Synced:

| Data Type | Local Storage | Firestore | Auto Sync |
|-----------|--------------|-----------|-----------|
| Employees | ✅ | ✅ | ✅ Every 30s |
| Attendance | ✅ | ✅ | ✅ Every 30s |
| Leave Requests | ✅ | ✅ | ✅ Every 30s |
| User Auth | ✅ | ❌ | N/A |

---

## 🔍 Verify It's Working:

### Check 1: Firebase Console
1. Go to Firestore Database
2. You should see collections:
   - `employees`
   - `attendance`
   - `leaveRequests`

### Check 2: App Logs
Look for these messages:
```
Firebase initialized successfully
Hybrid storage initialized successfully
Synced X employees from Firestore
Synced attendance for EMP001 from Firestore
```

### Check 3: Test Offline
1. Turn off internet
2. Use the app - should still work (uses local data)
3. Turn internet back on
4. Wait 30 seconds - should sync to Firestore

---

## ⚙️ Configuration:

### Sync Interval
Currently set to 30 seconds. To change:

In `hybrid_storage_service.dart`, line ~47:
```dart
_syncTimer = Timer.periodic(Duration(seconds: 30), (_) {
  // Change 30 to your desired seconds
});
```

### Manual Sync
Trigger sync manually:
```dart
await HybridStorageService.syncNow();
```

---

## 🐛 Troubleshooting:

### Issue: "Firestore not connected"
**Solution**: 
1. Check Firebase Console - is Firestore enabled?
2. Check internet connection
3. Verify `google-services.json` / `GoogleService-Info.plist` are correct

### Issue: "Data not syncing"
**Solution**:
1. Check if `_isOnline` is true (check logs)
2. Manually trigger: `await HybridStorageService.syncNow()`
3. Check Firebase Console for data

### Issue: "Duplicate data in Firestore"
**Solution**:
- This is expected during initial sync
- The service handles duplicates (latest wins)
- After first sync, duplicates should stop

---

## 📊 Current Status:

| Component | Status |
|-----------|--------|
| HybridStorageService Created | ✅ |
| Main.dart Updated | ✅ |
| Firestore Database | ⏳ Need to enable |
| Screen Migration | ⏳ Optional |

---

## ✅ Next Steps:

1. **Enable Firestore** in Firebase Console (5 minutes)
2. **Test connection** - Run app and check logs
3. **Verify sync** - Check Firebase Console for data
4. **Gradually migrate screens** (optional - can keep using LocalStorageService, HybridStorageService will sync in background)

---

## 💡 Benefits:

1. ✅ **Offline First**: App works without internet
2. ✅ **Cloud Sync**: Data syncs automatically when online
3. ✅ **No Breaking Changes**: Existing code still works
4. ✅ **Gradual Migration**: Update screens one at a time
5. ✅ **Best of Both Worlds**: Local speed + Cloud backup

---

**The hybrid system is ready! Just enable Firestore in Firebase Console and you're good to go! 🚀**





