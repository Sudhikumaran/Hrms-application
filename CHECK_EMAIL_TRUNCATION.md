# 📧 Email Truncation Check

## Issue Description
The email in Firestore appears as `"sudhikumaran2005@gma"` (incomplete).

## Possible Causes

### 1. **Firestore Console Display Issue** (Most Likely)
- Firestore Console sometimes truncates long field values in the UI
- The actual data might be complete
- **Check**: Click on the email field to see full value, or view in JSON format

### 2. **Data Entry Issue**
- Email was entered incomplete during employee signup
- **Check**: Verify the employee record in the app

### 3. **Code Issue** (Unlikely but possible)
- Check if email field has character limits

## How to Verify

### Option 1: Check in Firestore Console
1. Click on the email field in the document
2. The full value should appear in the edit view
3. Or export data to see actual values

### Option 2: Check in App
1. Go to Admin → Employees
2. Find EMP001
3. View/edit the employee details
4. Check if email is complete there

### Option 3: Check Actual Data
The email field in `Employee` model stores as-is, no truncation:
```dart
'email': email,  // Stored as provided
```

## Fix if Truncated

If email is actually incomplete:

1. **In App**: Edit employee EMP001 → Update email → Save
2. **In Firestore**: Edit document → Update email field → Save

## About the View

You're viewing the **`employees`** collection, which is correct for employee data.

To see admin account:
- Go to **`admins`** collection
- Look for document with `email: "ceo@fortumars.com"`

---

**Most likely**: It's just a display truncation in Firestore Console. Click on the field to see the full value!


