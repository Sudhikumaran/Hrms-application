# 🔐 Android Release Signing Setup Guide

## ⚠️ CRITICAL: Required for Production Builds

To publish your app to Google Play Store, you need to sign your release builds with a release keystore (not debug keys).

---

## 📋 Step-by-Step Instructions

### Step 1: Generate Release Keystore

Run this command in your terminal:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**You'll be prompted for:**
- Keystore password (remember this!)
- Key password (can be same as keystore password)
- Your name and organization details

**Important**: Save these passwords securely - you'll need them to publish updates!

---

### Step 2: Create key.properties File

1. Copy the template file:
   ```bash
   cp android/key.properties.template android/key.properties
   ```

2. Edit `android/key.properties` and fill in your actual values:

   ```properties
   storePassword=YOUR_ACTUAL_STORE_PASSWORD
   keyPassword=YOUR_ACTUAL_KEY_PASSWORD
   keyAlias=upload
   storeFile=/full/path/to/upload-keystore.jks
   ```

   **Note**: Use absolute path for `storeFile` (e.g., `/Users/yourname/upload-keystore.jks`)

---

### Step 3: Verify Build Configuration

The `build.gradle.kts` has been updated to automatically use your release keystore when `key.properties` exists.

**To test:**
```bash
cd android
./gradlew clean
cd ..
flutter build appbundle --release
```

If `key.properties` exists, it will use release signing. Otherwise, it falls back to debug signing (for testing only).

---

## ✅ What's Already Configured

- ✅ `build.gradle.kts` updated to support release signing
- ✅ Automatic detection of `key.properties`
- ✅ Fallback to debug signing if keystore not configured
- ✅ `key.properties` added to `.gitignore` (won't be committed)

---

## 🚨 Important Security Notes

1. **NEVER commit `key.properties` or `.jks` files to Git**
   - Already added to `.gitignore` ✅
   - Keep backups in secure location
   - Share with team securely (password manager, etc.)

2. **Backup Your Keystore**
   - If you lose the keystore, you CANNOT update your app on Play Store
   - Store backup in multiple secure locations
   - Keep passwords in password manager

3. **Use Different Keystores for Different Apps**
   - Each app should have its own keystore
   - Don't reuse keystores across projects

---

## 🧪 Testing

### Test Release Build (with signing)
```bash
flutter build appbundle --release
```

### Test Debug Build
```bash
flutter build apk --debug
```

---

## 📱 For Google Play Store

Once you have the signed release build:

1. Upload `app-release.aab` to Google Play Console
2. Google Play will re-sign it with their own key (App Signing by Google Play)
3. But you still need your upload keystore to sign updates

---

## 🆘 Troubleshooting

### "Keystore file not found"
- Check `storeFile` path in `key.properties` is absolute and correct
- Verify the `.jks` file exists at that path

### "Password incorrect"
- Double-check `storePassword` and `keyPassword` in `key.properties`
- Make sure no extra spaces or special characters

### "Key alias not found"
- Default alias is `upload` - make sure you used this when creating keystore
- Or update `keyAlias` in `key.properties` to match your keystore

---

## ✅ Verification Checklist

- [ ] Keystore generated successfully
- [ ] `key.properties` created with correct values
- [ ] Release build completes without errors
- [ ] `key.properties` is in `.gitignore` (won't be committed)
- [ ] Keystore backed up securely
- [ ] Passwords saved in password manager

---

**Once configured, your Android builds are production-ready! 🎉**





