# TEMPORARY LOGIN BYPASS - Instructions

## Current Status
✅ Login bypass is **ACTIVE**
- The app will skip the login screen
- You will automatically enter as a **Temporary Admin**
- All admin features are accessible

## Steps to Set Up Proper Authentication

### 1. Run the App
```powershell
flutter run
```

The app will automatically:
- Skip the splash screen
- Bypass the login page
- Take you directly to the **Admin Dashboard**

### 2. Add Users Through the Admin Panel

Once you're in the Admin Dashboard:

1. Click the **People icon** (👥) in the left sidebar
   - OR look for "User Management" option
   
2. Click the **+ (Add)** button in the top right

3. Add your users:
   - **First user**: Create your permanent admin account
     - Email: your-admin@novotel.com
     - Password: (choose a secure password)
     - Role: System Admin
     - Department: IT
   
   - **Other users**: Add managers and staff as needed

4. **Important**: All users added through this screen will be:
   - Created in Firebase Authentication
   - Stored in Firestore with proper roles
   - Able to log in normally

### 3. Restore Normal Login

Once you've added users, restore normal authentication:

**Option A: Via Code**
1. Open `lib/config/routes.dart`
2. Find line 20: `static const bool _bypassLogin = true;`
3. Change to: `static const bool _bypassLogin = false;`
4. Save and restart the app

**Option B: Remove Bypass Code (Recommended)**
Delete or comment out these sections:

**In `lib/config/routes.dart`:**
- Remove lines 19-20 (the `_bypassLogin` flag)
- Change line 27 from:
  ```dart
  nextScreen: _bypassLogin ? _BypassAdminWrapper() : const SignInPage(),
  ```
  to:
  ```dart
  nextScreen: const SignInPage(),
  ```
- Remove the entire `_BypassAdminWrapper` class (lines 37-46)

**In `lib/services/auth_service.dart`:**
- Remove lines 26-45 (the `bypassLoginAsAdmin()` method and bypass flag)

### 4. Test Normal Login

After restoring normal authentication:
1. Restart the app
2. You should see the login screen
3. Log in with the admin account you created in step 2
4. Verify everything works correctly

## Troubleshooting

### "Firebase not configured" error
- Make sure Firebase is properly initialized in your project
- Check that `firebase_options.dart` exists
- Verify Firebase configuration files are in place

### Can't add users / User Management not working
- Ensure you have internet connection
- Check Firebase Console to see if users are being created
- Look at the app logs for error messages

### Need to re-enable bypass?
Just set `_bypassLogin = true` again in `lib/config/routes.dart`

---

**IMPORTANT**: Once you have working user accounts, delete this file and remove all bypass code to ensure security.
