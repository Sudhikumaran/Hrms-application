import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_rest_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ==================== AUTHENTICATION ====================

  // Employee Login with Firebase Authentication
  static Future<Map<String, dynamic>> signInEmployee(
    String emailOrEmpId,
    String password,
  ) async {
    try {
      print('🔐 Attempting employee login for: $emailOrEmpId');
      
      String? employeeEmail;
      String? empId = '';
      QueryDocumentSnapshot? employeeDoc;
      
      // Strategy 1: If input looks like an email, try Firebase Auth directly first
      final isEmailFormat = emailOrEmpId.contains('@');
      
      if (isEmailFormat) {
        // Try Firebase Auth directly with email
        try {
          print('📧 Input looks like email, trying Firebase Auth directly...');
          final credential = await _auth.signInWithEmailAndPassword(
            email: emailOrEmpId.trim(),
            password: password,
          );
          
          if (credential.user != null) {
            final uid = credential.user!.uid;
            final authEmail = credential.user!.email;
            print('✅ Firebase Auth successful for email: $authEmail');
            
            // Verify user is NOT an admin
            final isAdmin = await _checkIfAdmin(uid);
            if (isAdmin) {
              await _auth.signOut();
              return {
                'success': false,
                'message': 'This account has admin privileges. Please use Admin login instead.',
              };
            }
            
            // Now find employee data in Firestore
            employeeEmail = authEmail;
            try {
              final emailQuery = await _firestore.collection('employees')
                  .where('email', isEqualTo: employeeEmail)
                  .limit(1)
                  .get();
              
              if (emailQuery.docs.isNotEmpty) {
                employeeDoc = emailQuery.docs.first;
                final data = employeeDoc.data() as Map<String, dynamic>?;
                if (data != null) {
                  empId = (data['empId'] as String?) ?? (data['employeeId'] as String?) ?? '';
                  print('✅ Found employee data in Firestore: $empId');
                } else {
                  empId = emailOrEmpId.split('@')[0].toUpperCase();
                }
              } else {
                print('⚠️ Employee not found in Firestore, but Firebase Auth worked');
                // Still allow login, employee might not be synced yet
                empId = emailOrEmpId.split('@')[0].toUpperCase(); // Use email prefix as temp ID
              }
            } catch (e) {
              print('⚠️ Error querying Firestore: $e');
              // Still allow login
              empId = emailOrEmpId.split('@')[0].toUpperCase();
            }
            
            // Ensure empId is not empty (empId is already set above, so this is just for safety)
            final finalEmpId = (empId.isNotEmpty) ? empId : emailOrEmpId.split('@')[0].toUpperCase();
            
            // Store employee data locally
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userId', finalEmpId);
            await prefs.setString('userEmail', employeeEmail!); // employeeEmail is guaranteed to be non-null here
            await prefs.setString('userRole', 'Employee');
            await prefs.setString('firebaseUserId', uid);
            
            // Update employee document with Firebase UID if doc exists
            if (employeeDoc != null) {
              try {
                await employeeDoc.reference.update({
                  'firebaseUserId': uid,
                  'lastLogin': FieldValue.serverTimestamp(),
                });
                print('✅ Updated employee document with Firebase UID');
              } catch (e) {
                print('⚠️ Could not update employee document: $e');
              }
            }
            
            return {
              'success': true,
              'userId': finalEmpId,
              'email': employeeEmail,
              'firebaseUid': uid,
              'message': 'Employee login successful',
            };
          }
        } catch (e) {
          if (e is FirebaseAuthException) {
            // Auth failed, continue to Firestore lookup strategy
            print('⚠️ Firebase Auth failed: ${e.code} - ${e.message}');
            // If user-not-found, they might not have Firebase Auth account yet
            // Continue to fallback method
          } else {
            print('⚠️ Firebase Auth error: $e');
          }
        }
      }
      
      // Also try with Employee ID format (EMP001, etc.) by looking up email first
      // This handles cases where user enters Employee ID but we need email for Firebase Auth
      
      // Strategy 2: Find employee in Firestore first (for empId or if email auth failed)
      print('🔍 Searching Firestore for employee...');
      final employeesRef = _firestore.collection('employees');
      
      QuerySnapshot? emailQuery;
      QuerySnapshot? empIdQuery;
      
      // Try email query
      try {
        emailQuery = await employeesRef
            .where('email', isEqualTo: emailOrEmpId)
            .limit(1)
            .get();
      } catch (e) {
        print('Email query failed: $e');
      }
      
      // Try empId query
      if (emailQuery?.docs.isEmpty ?? true) {
        try {
          empIdQuery = await employeesRef
              .where('empId', isEqualTo: emailOrEmpId.toUpperCase())
              .limit(1)
              .get();
          
          if (empIdQuery.docs.isEmpty) {
            empIdQuery = await employeesRef
                .where('employeeId', isEqualTo: emailOrEmpId.toUpperCase())
                .limit(1)
                .get();
          }
        } catch (e) {
          print('EmpId query failed: $e');
        }
      }
      
      // Get employee data
      if (emailQuery?.docs.isNotEmpty ?? false) {
        employeeDoc = emailQuery!.docs.first;
        final data = employeeDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          employeeEmail = data['email'] as String?;
          empId = (data['empId'] as String?) ?? (data['employeeId'] as String?) ?? '';
          print('✅ Found employee by email: $employeeEmail');
        }
      } else if (empIdQuery?.docs.isNotEmpty ?? false) {
        employeeDoc = empIdQuery!.docs.first;
        final data = employeeDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          employeeEmail = data['email'] as String?;
          empId = (data['empId'] as String?) ?? (data['employeeId'] as String?) ?? emailOrEmpId.toUpperCase();
          print('✅ Found employee by empId: $empId');
        }
      }
      
      if (employeeEmail == null || employeeEmail.isEmpty) {
        return {
          'success': false,
          'message': 'Employee account does not have an email. Please contact admin.',
        };
      }
      
      // Verify user is NOT an admin
      String? uidFromEmployee;
      if (employeeDoc != null) {
        final docData = employeeDoc.data() as Map<String, dynamic>?;
        if (docData != null) {
          uidFromEmployee = docData['firebaseUserId'] as String?;
        }
      }
      if (uidFromEmployee != null) {
        final isAdmin = await _checkIfAdmin(uidFromEmployee);
        if (isAdmin) {
          return {
            'success': false,
            'message': 'This account has admin privileges. Please use Admin login instead.',
          };
        }
      }
      
      print('🔐 Attempting Firebase Auth with email: $employeeEmail');
      
      // Sign in with Firebase Auth using the employee's email
      final credential = await _auth.signInWithEmailAndPassword(
        email: employeeEmail.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        final uid = credential.user!.uid;
        final finalEmpId = empId ?? emailOrEmpId.toUpperCase();
        
        print('✅ Employee Firebase Authentication successful for UID: $uid');
        
        // CRITICAL: Double-check user is NOT an admin after authentication
        final isAdmin = await _checkIfAdmin(uid);
        if (isAdmin) {
          // Sign out immediately if they're an admin
          await _auth.signOut();
          return {
            'success': false,
            'message': 'This account has admin privileges. Please use Admin login instead.',
          };
        }
        
        // Store employee data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', finalEmpId);
        await prefs.setString('userEmail', employeeEmail.trim());
        await prefs.setString('userRole', 'Employee'); // Explicitly set as Employee
        await prefs.setString('firebaseUserId', uid);
        
        // Link Firebase UID to employee document if not already linked
        if (employeeDoc != null) {
          try {
            await employeeDoc.reference.update({
              'firebaseUserId': uid,
              'lastLogin': FieldValue.serverTimestamp(),
            });
            print('✅ Updated employee document with Firebase UID');
          } catch (e) {
            print('⚠️ Could not update employee document: $e');
          }
        }
        
        return {
          'success': true,
          'userId': finalEmpId,
          'email': employeeEmail.trim(),
          'firebaseUid': uid,
          'message': 'Employee login successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Authentication failed',
        };
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      bool useFallback = false;
      
      if (e.code == 'user-not-found') {
        // Employee might not have Firebase Auth account yet - use fallback
        message = 'No Firebase account found. Trying local password...';
        useFallback = true;
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        message = 'Employee account has been disabled';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed attempts. Please try again later.';
      }
      return {
        'success': false,
        'message': message,
        'useFallback': useFallback,
      };
    } catch (e) {
      print('Employee sign in error: $e');
      // If Firestore/network error, try fallback
      final errorStr = e.toString().toLowerCase();
      final isNetworkError = errorStr.contains('firestore') || 
                           errorStr.contains('network') || 
                           errorStr.contains('timeout') ||
                           errorStr.contains('connection');
      
      return {
        'success': false,
        'message': 'Login failed: $e',
        'useFallback': isNetworkError,
      };
    }
  }

  // Create Employee Account in Firebase Auth
  static Future<Map<String, dynamic>> createEmployeeAccount(
    String email,
    String password,
    String empId,
  ) async {
    try {
      print('🔐 Creating Firebase Auth account for employee: $empId, email: $email');
      
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        print('✅ Firebase Auth account created for UID: $uid');
        
        // Update employee document in Firestore with Firebase UID
        try {
          final employeesRef = _firestore.collection('employees');
          final query = await employeesRef
              .where('empId', isEqualTo: empId)
              .limit(1)
              .get();
          
          if (query.docs.isEmpty) {
            // Try with employeeId field
            final query2 = await employeesRef
                .where('employeeId', isEqualTo: empId)
                .limit(1)
                .get();
            
            if (query2.docs.isNotEmpty) {
              await query2.docs.first.reference.update({
                'firebaseUserId': uid,
                'email': email.trim(),
              });
            }
          } else {
            await query.docs.first.reference.update({
              'firebaseUserId': uid,
              'email': email.trim(),
            });
          }
          print('✅ Updated employee document with Firebase UID');
        } catch (e) {
          print('⚠️ Could not update employee document: $e');
        }
        
        // Sign out after account creation (user will sign in normally)
        await _auth.signOut();
        
        return {
          'success': true,
          'uid': uid,
          'email': email.trim(),
          'message': 'Employee Firebase Auth account created successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create Firebase Auth account',
        };
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException when creating employee account: ${e.code} - ${e.message}');
      String message = 'Account creation failed';
      String? errorCode;
      
      if (e.code == 'email-already-in-use') {
        message = 'Email is already in use';
        errorCode = e.code;
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
        errorCode = e.code;
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak. Use at least 6 characters';
        errorCode = e.code;
      } else if (e.code == 'configuration-not-found' || e.code == 'unknown' || e.message?.contains('configuration') == true) {
        message = 'Firebase Auth configuration issue. Account creation skipped (login via local password will continue to work)';
        errorCode = e.code;
        print('⚠️ Firebase Auth configuration error - employee can still login via local password');
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password authentication is not enabled in Firebase Console';
        errorCode = e.code;
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Account creation skipped (login via local password will continue to work)';
        errorCode = e.code;
      } else {
        message = 'Account creation failed: ${e.code}';
        errorCode = e.code;
      }
      
      return {
        'success': false,
        'message': message,
        'errorCode': errorCode,
      };
    } catch (e, stackTrace) {
      print('❌ Error creating employee account: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error creating account: $e',
      };
    }
  }

  // Create Admin Account with Firebase Authentication
  static Future<Map<String, dynamic>> createAdminAccount(
    String email,
    String password,
  ) async {
    try {
      print('🔐 Creating Firebase Auth account for admin: $email');
      
      // Check if Firebase is initialized
      try {
        final apps = Firebase.apps;
        print('📋 Found ${apps.length} Firebase app(s)');
        if (apps.isEmpty) {
          throw Exception('No Firebase apps initialized. Check main.dart Firebase.initializeApp()');
        }
        
        final app = Firebase.app();
        print('✅ Firebase app initialized: ${app.name}');
        print('📋 Project ID: ${app.options.projectId}');
        print('📋 Storage Bucket: ${app.options.storageBucket}');
        final apiKey = app.options.apiKey;
        if (apiKey.isNotEmpty && apiKey.length > 20) {
          print('📋 API Key: ${apiKey.substring(0, 20)}...');
        } else {
          print('📋 API Key: $apiKey');
        }
      } catch (e, stackTrace) {
        print('❌ Firebase not initialized: $e');
        print('❌ Full error: ${e.toString()}');
        print('❌ Stack trace: $stackTrace');
        
        // Try to get more details about the error
        String detailedError = 'Firebase is not properly configured.\n\n';
        detailedError += 'Error Details: ${e.toString()}\n\n';
        
        if (e.toString().contains('No Firebase App')) {
          detailedError += 'Firebase was not initialized.\n';
          detailedError += 'Check main.dart - Firebase.initializeApp() may have failed.\n\n';
        } else if (e.toString().contains('configuration')) {
          detailedError += 'Configuration mismatch detected.\n';
          detailedError += 'Verify firebase_options.dart matches your platform.\n\n';
        }
        
        detailedError += 'Please:\n';
        detailedError += '1. Check console logs for Firebase initialization errors\n';
        detailedError += '2. Verify you\'re running on Android (not Windows/Web)\n';
        detailedError += '3. Ensure firebase_options.dart matches google-services.json\n';
        detailedError += '4. Run: flutter clean && flutter pub get && flutter run\n';
        
        return {
          'success': false,
          'message': detailedError,
        };
      }
      
      // Additional check: Try to access Firebase Auth
      bool authAccessible = false;
      try {
        final currentUser = _auth.currentUser;
        print('✅ Firebase Auth accessible. Current user: ${currentUser?.uid ?? "none"}');
        authAccessible = true;
      } catch (e) {
        print('⚠️ Firebase Auth SDK not accessible: $e');
        print('🔄 Will try REST API as fallback...');
        authAccessible = false;
      }
      
      // Try SDK first, fallback to REST API if configuration-not-found
      Map<String, dynamic>? authResult;
      
      if (authAccessible) {
        try {
          // Create user in Firebase Auth SDK
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          
          if (userCredential.user != null) {
            final uid = userCredential.user!.uid;
            print('✅ Firebase Auth SDK account created for admin UID: $uid');
            authResult = {
              'success': true,
              'uid': uid,
              'email': email.trim(),
              'message': 'Admin Firebase Auth account created successfully',
            };
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'configuration-not-found' || e.code == 'unknown' || e.message?.contains('configuration') == true) {
            print('⚠️ SDK failed with configuration error, trying REST API fallback...');
            authResult = null; // Will use REST API below
          } else {
            rethrow; // Re-throw other auth exceptions to be handled below
          }
        }
      }
      
      // Use REST API fallback if SDK failed or not accessible
      if (authResult == null) {
        print('🌐 Creating account using REST API...');
        print('📧 Email: ${email.trim()}');
        print('🔑 Password length: ${password.length}');
        try {
          authResult = await FirebaseRestAuth.signUpWithEmailPassword(
            email: email.trim(),
            password: password,
          );
          
          if (authResult['success'] == true) {
            print('✅ REST API account creation successful');
            print('📋 UID: ${authResult['uid']}');
          } else {
            print('❌ REST API account creation failed');
            print('❌ Error: ${authResult['message']}');
            print('❌ Error code: ${authResult['errorCode'] ?? 'N/A'}');
            print('❌ Full error: ${authResult['error'] ?? 'N/A'}');
          }
        } catch (e, stackTrace) {
          print('❌ REST API exception: $e');
          print('❌ Stack trace: $stackTrace');
          authResult = {
            'success': false,
            'message': 'REST API error: $e',
          };
        }
      }
      
      // Use the result from SDK or REST API
      if (authResult['success'] == true) {
        return authResult;
      } else {
        // REST API or SDK failed, return its error
        return authResult;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      String message = 'Account creation failed';
      
      if (e.code == 'email-already-in-use') {
        message = 'Email "$email" is already registered.\n\nPlease use the login screen instead.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address format.\n\nPlease enter a valid email (e.g., admin@fortumars.com)';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.\n\nPassword must be at least 6 characters long.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password authentication is not enabled.\n\nPlease enable it in Firebase Console:\nAuthentication → Sign-in method → Email/Password';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error.\n\nPlease check your internet connection and try again.';
      } else if (e.code == 'configuration-not-found' || e.message?.contains('configuration') == true) {
        message = 'Firebase configuration error.\n\nPlease:\n1. Stop the app completely\n2. Run: flutter clean && flutter pub get\n3. Restart the app (full restart, not hot reload)\n\nOr run: flutterfire configure';
      } else if (e.code == 'invalid-api-key') {
        message = 'Invalid Firebase API key.\n\nPlease update firebase_options.dart with the correct API key from google-services.json.';
      } else if (e.code == 'invalid-app-credential' || e.code == 'app-not-authorized') {
        message = 'Firebase app not authorized.\n\nPlease verify:\n• Project ID matches in firebase_options.dart and google-services.json\n• App ID is correct\n• Firebase project is active';
      } else {
        message = 'Account creation failed: ${e.code}\n${e.message ?? "Unknown error"}';
      }
      
      return {
        'success': false,
        'message': message,
        'errorCode': e.code,
      };
    } catch (e, stackTrace) {
      print('❌ Error creating admin account: $e');
      print('❌ Stack trace: $stackTrace');
      String message = 'Error creating account: $e';
      
      // Check for common error patterns
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        message = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('firestore') || e.toString().contains('Firestore')) {
        message = 'Firestore connection error. Please ensure Firestore Database is enabled in Firebase Console.';
      }
      
      return {
        'success': false,
        'message': message,
      };
    }
  }

  // Admin Login with Firebase Authentication
  static Future<Map<String, dynamic>> signInAdmin(
    String email,
    String password,
  ) async {
    try {
      // First, check if admin exists in Firestore with direct auth method
      // (created via workaround when Firebase Auth had config issues)
      try {
        print('🔍 Checking for direct Firestore admin (email-based)...');
        final directAdminQuery = await _firestore.collection('admins')
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get();
        
        if (directAdminQuery.docs.isNotEmpty) {
          final adminDoc = directAdminQuery.docs.first;
          final adminData = adminDoc.data();
          final authMethod = adminData['authMethod'] as String?;
          
          if (authMethod == 'direct') {
            print('✅ Found direct Firestore admin');
            final storedPassword = adminData['passwordHash'] as String?;
            final uid = adminDoc.id;
            
            // Verify password
            if (storedPassword == password) {
              print('✅ Password verified for direct admin');
              
              // Store admin data locally
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userId', uid);
              await prefs.setString('userEmail', email.trim());
              await prefs.setString('userRole', 'Admin');
              await prefs.setString('adminPassword', password); // Store for future use
              
              return {
                'success': true,
                'userId': uid,
                'email': email.trim(),
                'message': 'Admin login successful (direct Firestore)',
              };
            } else {
              print('❌ Password mismatch for direct admin');
              return {
                'success': false,
                'message': 'Incorrect password',
              };
            }
          }
        }
      } catch (e) {
        print('⚠️ Error checking direct admin: $e');
        // Continue to Firebase Auth methods
      }
      
      // Try REST API first (workaround for configuration-not-found)
      try {
        final restAuth = await _tryRestApiAuth(email, password);
        if (restAuth['success'] == true) {
          // REST API worked - use it for authentication
          final uid = restAuth['userId'] as String;
          print('✅ REST API Authentication successful for UID: $uid');
          
          // Continue with admin check...
          // Store admin data locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', uid);
          await prefs.setString('userEmail', email.trim());
          await prefs.setString('userRole', 'Admin');
          
          // Auto-setup admin document
          final setupSuccess = await autoSetupAdminIfNeeded(uid, email.trim());
          if (setupSuccess) {
            await Future.delayed(Duration(milliseconds: 1000));
          }
          
          // Check admin status - but first ensure Firestore connection
          print('🔍 Checking admin status for UID: $uid');
          
          // Wait a moment for Firestore to be ready
          await Future.delayed(Duration(milliseconds: 500));
          
          final isAdmin = await _checkIfAdmin(uid);
          print('🔍 Admin check result: $isAdmin');
          
          if (!isAdmin) {
            print('⚠️ Admin check failed, but trying to auto-setup...');
            // Try to setup admin document if it doesn't exist
            final setupResult = await autoSetupAdminIfNeeded(uid, email.trim());
            print('🔧 Auto-setup result: $setupResult');
            
            if (setupResult) {
              // Wait for sync
              await Future.delayed(Duration(milliseconds: 1000));
              // Check again
              final isAdminRetry = await _checkIfAdmin(uid);
              if (!isAdminRetry) {
                await FirebaseRestAuth.signOut();
                return {
                  'success': false,
                  'message': 'Access denied. Admin privileges required. Please verify admin document exists in Firestore.',
                };
              }
            } else {
              await FirebaseRestAuth.signOut();
              return {
                'success': false,
                'message': 'Access denied. Admin privileges required. Could not create admin document. Please check Firestore connection.',
              };
            }
          }
          
          print('✅ Admin verified - login successful');
          return {
            'success': true,
            'userId': uid,
            'email': email.trim(),
            'message': 'Admin login successful (via REST API)',
          };
        }
      } catch (e) {
        print('REST API auth attempt failed, trying SDK: $e');
      }
      
      // Fallback to SDK authentication
      // Sign in with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        print('✅ Firebase Authentication successful for UID: $uid');
        
        // Special handling for known admin UID
        const knownAdminUID = '0PiQBMhHcDUJXnX3T49B8CKZKNl1';
        if (uid == knownAdminUID) {
          print('🔧 Detected known admin UID, ensuring admin document exists...');
          // Force create admin document for this specific UID
          final forceResult = await forceSetupAdmin(uid, email.trim());
          if (forceResult['success'] == true) {
            print('✅ Admin document force-created for known UID');
          }
        }
        
        // Auto-setup admin document if it doesn't exist (convenience feature)
        // This allows first-time admin login to work automatically
        print('🔧 Attempting auto-setup for UID: $uid, Email: ${email.trim()}');
        final setupSuccess = await autoSetupAdminIfNeeded(uid, email.trim());
        print('🔧 Auto-setup result: $setupSuccess');
        
        // Give Firestore a moment to sync if document was just created
        if (setupSuccess) {
          print('⏳ Waiting for Firestore to sync...');
          await Future.delayed(Duration(milliseconds: 1000)); // Increased delay
        }
        
        // Check if user is admin (check custom claims or Firestore)
        print('🔍 Checking admin status for UID: $uid');
        var isAdmin = await _checkIfAdmin(uid);
        print('🔍 Admin check result: $isAdmin');
        
        // If admin check fails but setup succeeded, wait longer and retry
        if (!isAdmin && setupSuccess) {
          print('⚠️ Admin check failed after setup, waiting longer and retrying...');
          await Future.delayed(Duration(seconds: 2));
          isAdmin = await _checkIfAdmin(uid);
          print('🔍 Admin check retry result: $isAdmin');
        }
        
        // If still not admin, try one more time to setup
        if (!isAdmin) {
          print('⚠️ Admin check still failed, trying manual setup...');
          final manualSetup = await setupAdminDocument(uid, email: email.trim());
          if (manualSetup['success'] == true) {
            await Future.delayed(Duration(seconds: 1));
            isAdmin = await _checkIfAdmin(uid);
            print('🔍 Admin check after manual setup: $isAdmin');
          }
        }
        
        if (!isAdmin) {
          print('❌ Admin check failed after all attempts');
          
          // Get detailed error info
          String errorDetails = 'Access denied. Admin privileges required.\n\n';
          errorDetails += 'Debugging info:\n';
          errorDetails += '- User authenticated: ✅ Yes\n';
          errorDetails += '- Auto-setup attempted: ${setupSuccess ? "✅ Yes" : "❌ Failed"}\n';
          errorDetails += '- Admin check result: ❌ Failed\n\n';
          errorDetails += 'Possible issues:\n';
          errorDetails += '1. Firestore not enabled (check console logs)\n';
          errorDetails += '2. Firestore security rules blocking\n';
          errorDetails += '3. Admin document creation failed\n\n';
          errorDetails += 'Trying to create admin document manually...\n';
          errorDetails += 'Check console logs for detailed error messages.';
          
          // Try one final manual setup with more verbose logging
          try {
            print('🔧 Final attempt: Creating admin document manually...');
            final forceResult = await forceSetupAdmin(uid, email.trim());
            if (forceResult['success'] == true) {
              await Future.delayed(Duration(seconds: 2));
              final finalCheck = await _checkIfAdmin(uid);
              if (finalCheck) {
                print('✅ Admin document created successfully on final attempt');
                isAdmin = true;
              } else {
                print('⚠️ Document created but check still fails - may need Firestore rules update');
              }
            } else {
              print('❌ Force setup failed: ${forceResult['message']}');
            }
          } catch (e) {
            print('❌ Final setup attempt failed: $e');
          }
          
          if (!isAdmin) {
            // Only sign out if we've exhausted all options
            await _auth.signOut();
            return {
              'success': false,
              'message': errorDetails,
            };
          }
        }
        
        print('✅ Admin verified - login successful');

        // Store admin data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', credential.user!.uid);
        await prefs.setString('userEmail', email.trim());
        await prefs.setString('userRole', 'Admin');

        return {
          'success': true,
          'userId': credential.user!.uid,
          'email': email.trim(),
          'message': 'Admin login successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Authentication failed',
        };
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        // Check if this is a direct Firestore admin
        print('⚠️ Firebase Auth: user-not-found, checking Firestore for direct admin...');
        try {
          final directAdminQuery = await _firestore.collection('admins')
              .where('email', isEqualTo: email.trim())
              .limit(1)
              .get();
          
          if (directAdminQuery.docs.isNotEmpty) {
            final adminDoc = directAdminQuery.docs.first;
            final adminData = adminDoc.data();
            final authMethod = adminData['authMethod'] as String?;
            
            if (authMethod == 'direct') {
              final storedPassword = adminData['passwordHash'] as String?;
              final uid = adminDoc.id;
              
              if (storedPassword == password) {
                print('✅ Found direct admin in Firestore with matching password');
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('userId', uid);
                await prefs.setString('userEmail', email.trim());
                await prefs.setString('userRole', 'Admin');
                await prefs.setString('adminPassword', password);
                
                return {
                  'success': true,
                  'userId': uid,
                  'email': email.trim(),
                  'message': 'Admin login successful (direct Firestore)',
                };
              } else {
                message = 'Incorrect password';
              }
            } else {
              message = 'No admin account found with this email in Firebase Auth';
            }
          } else {
            message = 'No admin account found with this email';
          }
        } catch (firestoreError) {
          print('⚠️ Error checking Firestore for direct admin: $firestoreError');
          message = 'No admin account found with this email';
        }
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        message = 'Admin account has been disabled';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print('Admin sign in error: $e');
      
      // Last resort: Check Firestore for direct admin
      try {
        print('⚠️ Final attempt: Checking Firestore for direct admin...');
        final directAdminQuery = await _firestore.collection('admins')
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get();
        
        if (directAdminQuery.docs.isNotEmpty) {
          final adminDoc = directAdminQuery.docs.first;
          final adminData = adminDoc.data();
          final authMethod = adminData['authMethod'] as String?;
          
          if (authMethod == 'direct') {
            final storedPassword = adminData['passwordHash'] as String?;
            final uid = adminDoc.id;
            
            if (storedPassword == password) {
              print('✅ Found direct admin in Firestore');
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userId', uid);
              await prefs.setString('userEmail', email.trim());
              await prefs.setString('userRole', 'Admin');
              await prefs.setString('adminPassword', password);
              
              return {
                'success': true,
                'userId': uid,
                'email': email.trim(),
                'message': 'Admin login successful (direct Firestore)',
              };
            }
          }
        }
      } catch (firestoreError) {
        print('⚠️ Firestore check failed: $firestoreError');
      }
      
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  // Get current Firebase Auth user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is admin (public method)
  static Future<bool> checkIfAdmin(String uid) async {
    return await _checkIfAdmin(uid);
  }

  // Check if user is admin by email (for direct Firestore admins)
  static Future<bool> checkIfAdminByEmail(String email) async {
    try {
      print('🔍 Checking admin by email: $email');
      final adminQuery = await _firestore.collection('admins')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      
      if (adminQuery.docs.isNotEmpty) {
        final adminDoc = adminQuery.docs.first;
        final adminData = adminDoc.data();
        if (adminData['isAdmin'] == true) {
          print('✅ Found admin by email');
          return true;
        }
      }
      print('❌ No admin found by email');
      return false;
    } catch (e) {
      print('❌ Error checking admin by email: $e');
      return false;
    }
  }

  // Check if user is admin (private method)
  static Future<bool> _checkIfAdmin(String uid) async {
    try {
      // For REST API auth, we might not have currentUser, so check Firestore directly
      final user = _auth.currentUser;
      String? userEmail;
      
      if (user != null) {
        userEmail = user.email;
        print('Admin check: Checking for UID: $uid, Email: ${user.email ?? "not available"}');
        
        // Option 1: Check custom claims (set via Firebase Admin SDK)
        // Only check if we have a current user (SDK auth)
        try {
          final tokenResult = await user.getIdTokenResult(true); // Refresh token to get latest claims
          final claims = tokenResult.claims;
          if (claims != null && claims['admin'] == true) {
            print('Admin check: Found admin custom claim');
            return true;
          }
          print('Admin check: No admin custom claim found');
        } catch (e) {
          print('Admin check: Error checking custom claims: $e');
        }
      } else {
        // REST API auth - no currentUser, check Firestore directly
        print('Admin check: No current user (REST API auth), checking Firestore directly for UID: $uid');
      }

      // Option 2: Check Firestore for admin collection
      try {
        print('Admin check: Attempting to read admins collection...');
        final adminDoc = await _firestore.collection('admins').doc(uid).get();
        print('Admin check: Document read - exists=${adminDoc.exists}');
        
        if (adminDoc.exists) {
          final data = adminDoc.data();
          print('Admin check: Document data: $data');
          if (data != null && data['isAdmin'] == true) {
            print('✅ Admin check: Found admin in Firestore admins collection');
            return true;
          } else {
            print('❌ Admin check: Document exists but isAdmin is not true. Data: $data');
          }
        } else {
          print('❌ Admin check: No admin document found in admins collection for UID: $uid');
          print('   This means the auto-setup failed or Firestore is not accessible');
        }
      } catch (e) {
        print('❌ Admin check: Error checking admins collection: $e');
        print('   This might indicate Firestore is not accessible or rules are blocking');
      }

      // Option 3: Check if email is in admin list (simple approach)
      if (userEmail != null) {
        try {
          final adminListDoc = await _firestore.collection('config').doc('admins').get();
          if (adminListDoc.exists) {
            final data = adminListDoc.data();
            final adminEmails = data?['emails'] as List<dynamic>? ?? [];
            final emailList = adminEmails.map((e) => e.toString().toLowerCase()).toList();
            if (emailList.contains(userEmail.toLowerCase())) {
              print('Admin check: Email found in admin list');
              return true;
            }
            print('Admin check: Email $userEmail not in admin list: $emailList');
          } else {
            print('Admin check: No config/admins document found');
          }
        } catch (e) {
          print('Admin check: Error checking admin list: $e');
        }
      } else {
        print('Admin check: Skipping email list check (no email available for REST API auth)');
      }

      // Option 4: If user exists in Firebase Auth and is explicitly an admin user
      // Check if there's an 'admin' field or role in the user metadata
      // For now, if user can authenticate, we'll require explicit admin verification
      print('Admin check: User authenticated but no admin verification found. Access denied.');
      return false;
    } catch (e) {
      print('Admin check error: $e');
      // Return false on error - require explicit admin setup
      return false;
    }
  }

  // NOTE: Old signInEmployee and createEmployeeAccount methods removed
  // New Firebase Auth-based methods are defined at the top of the file (lines 18-247)

  // Get current employee data
  static Future<Map<String, dynamic>?> getCurrentEmployee() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString('employeeId');

      if (employeeId != null) {
        final doc = await _firestore
            .collection('employees')
            .doc(employeeId)
            .get();
        if (doc.exists) {
          return doc.data();
        }
      }
      return null;
    } catch (e) {
      print('Get current employee error: $e');
      return null;
    }
  }

  // Update employee profile
  static Future<bool> updateEmployeeProfile(
    String employeeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('employees').doc(employeeId).update(updates);
      return true;
    } catch (e) {
      print('Update employee error: $e');
      return false;
    }
  }

  // ==================== ATTENDANCE MANAGEMENT ====================

  // Check-in with method
  static Future<Map<String, dynamic>> checkIn(
    String employeeId,
    String method,
    Map<String, dynamic>? additionalData,
  ) async {
    try {
      final now = DateTime.now();
      final checkInData = {
        'employeeId': employeeId,
        'method': method,
        'checkInTime': FieldValue.serverTimestamp(),
        'date':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'checked-in',
        'additionalData': additionalData ?? {},
      };

      // Check if already checked in today
      final existingAttendance = await _firestore
          .collection('attendance')
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isEqualTo: checkInData['date'])
          .where('status', isEqualTo: 'checked-in')
          .get();

      if (existingAttendance.docs.isNotEmpty) {
        return {'success': false, 'message': 'Already checked in today'};
      }

      // Create attendance record
      final docRef = await _firestore.collection('attendance').add(checkInData);

      // Update employee's last check-in
      await _firestore.collection('employees').doc(employeeId).update({
        'lastCheckIn': FieldValue.serverTimestamp(),
        'lastCheckInMethod': method,
      });

      return {
        'success': true,
        'attendanceId': docRef.id,
        'message': 'Check-in successful via $method',
        'data': checkInData,
      };
    } catch (e) {
      print('Check-in error: $e');
      return {'success': false, 'message': 'Check-in failed: $e'};
    }
  }

  // Check-out
  static Future<Map<String, dynamic>> checkOut(String employeeId) async {
    try {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Find today's check-in record
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isEqualTo: today)
          .where('status', isEqualTo: 'checked-in')
          .get();

      if (attendanceQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No check-in record found for today',
        };
      }

      final attendanceDoc = attendanceQuery.docs.first;
      final checkInTime = attendanceDoc.data()['checkInTime'] as Timestamp;

      // Calculate hours worked
      final checkOutTime = now;
      final hoursWorked =
          checkOutTime.difference(checkInTime.toDate()).inMinutes / 60.0;

      // Update attendance record
      await _firestore.collection('attendance').doc(attendanceDoc.id).update({
        'checkOutTime': FieldValue.serverTimestamp(),
        'status': 'checked-out',
        'hoursWorked': hoursWorked,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update employee's last check-out
      await _firestore.collection('employees').doc(employeeId).update({
        'lastCheckOut': FieldValue.serverTimestamp(),
        'totalHoursThisMonth': FieldValue.increment(hoursWorked),
      });

      return {
        'success': true,
        'message': 'Check-out successful',
        'hoursWorked': hoursWorked,
        'checkOutTime': now,
      };
    } catch (e) {
      print('Check-out error: $e');
      return {'success': false, 'message': 'Check-out failed: $e'};
    }
  }

  // Get attendance history
  static Future<List<Map<String, dynamic>>> getAttendanceHistory(
    String employeeId, {
    int limit = 30,
  }) async {
    try {
      final query = await _firestore
          .collection('attendance')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Get attendance history error: $e');
      return [];
    }
  }

  // Get today's attendance status
  static Future<Map<String, dynamic>?> getTodayAttendance(
    String employeeId,
  ) async {
    try {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final query = await _firestore
          .collection('attendance')
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isEqualTo: today)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        data['id'] = query.docs.first.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Get today attendance error: $e');
      return null;
    }
  }

  // ==================== TASK MANAGEMENT ====================

  // Create new task
  static Future<Map<String, dynamic>> createTask(
    Map<String, dynamic> taskData,
  ) async {
    try {
      taskData['createdAt'] = FieldValue.serverTimestamp();
      taskData['updatedAt'] = FieldValue.serverTimestamp();
      taskData['status'] = 'pending';

      final docRef = await _firestore.collection('tasks').add(taskData);

      return {
        'success': true,
        'taskId': docRef.id,
        'message': 'Task created successfully',
      };
    } catch (e) {
      print('Create task error: $e');
      return {'success': false, 'message': 'Failed to create task: $e'};
    }
  }

  // Get tasks for employee
  static Future<List<Map<String, dynamic>>> getEmployeeTasks(
    String employeeId, {
    String? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: employeeId)
          .orderBy('createdAt', descending: true);

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Get employee tasks error: $e');
      return [];
    }
  }

  // Update task status
  static Future<bool> updateTaskStatus(
    String taskId,
    String newStatus,
    String? notes,
  ) async {
    try {
      final updates = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _firestore.collection('tasks').doc(taskId).update(updates);
      return true;
    } catch (e) {
      print('Update task status error: $e');
      return false;
    }
  }

  // ==================== LEAVE MANAGEMENT ====================

  // Apply for leave
  static Future<Map<String, dynamic>> applyForLeave(
    Map<String, dynamic> leaveData,
  ) async {
    try {
      leaveData['createdAt'] = FieldValue.serverTimestamp();
      leaveData['status'] = 'pending';
      leaveData['approvedBy'] = null;
      leaveData['approvedAt'] = null;

      final docRef = await _firestore
          .collection('leave_requests')
          .add(leaveData);

      return {
        'success': true,
        'leaveId': docRef.id,
        'message': 'Leave request submitted successfully',
      };
    } catch (e) {
      print('Apply for leave error: $e');
      return {
        'success': false,
        'message': 'Failed to submit leave request: $e',
      };
    }
  }

  // Get leave requests for employee
  static Future<List<Map<String, dynamic>>> getEmployeeLeaveRequests(
    String employeeId,
  ) async {
    try {
      final query = await _firestore
          .collection('leave_requests')
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Get leave requests error: $e');
      return [];
    }
  }

  // Get leave balance
  static Future<Map<String, dynamic>> getLeaveBalance(String employeeId) async {
    try {
      final employeeDoc = await _firestore
          .collection('employees')
          .doc(employeeId)
          .get();
      if (employeeDoc.exists) {
        final data = employeeDoc.data()!;
        return {
          'sick': data['sickLeaveBalance'] ?? 0,
          'casual': data['casualLeaveBalance'] ?? 0,
          'annual': data['annualLeaveBalance'] ?? 0,
          'emergency': data['emergencyLeaveBalance'] ?? 0,
          'maternity': data['maternityLeaveBalance'] ?? 0,
        };
      }
      return {};
    } catch (e) {
      print('Get leave balance error: $e');
      return {};
    }
  }

  // ==================== FILE STORAGE ====================

  // Upload profile picture
  static Future<String?> uploadProfilePicture(
    String employeeId,
    Uint8List imageBytes,
  ) async {
    try {
      final ref = _storage.ref('profile_pictures/$employeeId.jpg');
      final uploadTask = ref.putData(imageBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update employee profile with new picture URL
      await _firestore.collection('employees').doc(employeeId).update({
        'profilePictureUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      print('Upload profile picture error: $e');
      return null;
    }
  }

  // Upload document
  static Future<String?> uploadDocument(
    String employeeId,
    String documentType,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final ref = _storage.ref('documents/$employeeId/$documentType/$fileName');
      final uploadTask = ref.putData(fileBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Upload document error: $e');
      return null;
    }
  }

  // ==================== NOTIFICATIONS ====================

  // Subscribe to notifications
  static Future<void> subscribeToNotifications(String employeeId) async {
    try {
      await _messaging.subscribeToTopic('all_employees');
      await _messaging.subscribeToTopic('employee_$employeeId');

      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('employees').doc(employeeId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Subscribe to notifications error: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  // Store employee data locally

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== PASSWORD MANAGEMENT ====================

  /// Change password for current user
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userEmail = prefs.getString('userEmail');
      
      // Check if this is a direct Firestore admin (no Firebase Auth user)
      if (user == null && userId != null && userEmail != null) {
        print('🔍 No Firebase Auth user - checking for direct Firestore admin...');
        
        // Check if admin exists in Firestore with direct auth method
        try {
          final adminQuery = await _firestore.collection('admins')
              .where('email', isEqualTo: userEmail.trim())
              .limit(1)
              .get();
          
          if (adminQuery.docs.isNotEmpty) {
            final adminDoc = adminQuery.docs.first;
            final adminData = adminDoc.data();
            final authMethod = adminData['authMethod'] as String?;
            
            if (authMethod == 'direct') {
              print('✅ Found direct Firestore admin - updating password in Firestore');
              
              // Verify current password
              final storedPassword = adminData['passwordHash'] as String?;
              if (storedPassword != currentPassword) {
                return {
                  'success': false,
                  'message': 'Current password is incorrect',
                };
              }
              
              // Update password in Firestore
              await adminDoc.reference.update({
                'passwordHash': newPassword,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              
              // Also update local storage
              await prefs.setString('adminPassword', newPassword);
              
              print('✅ Password updated successfully in Firestore');
              return {
                'success': true,
                'message': 'Password changed successfully',
              };
            }
          }
        } catch (e) {
          print('❌ Error updating password for direct admin: $e');
          return {
            'success': false,
            'message': 'Error updating password: $e',
          };
        }
        
        // If we get here, admin not found or not a direct admin
        return {
          'success': false,
          'message': 'No admin account found. Please try logging in again.',
        };
      }
      
      // Firebase Auth user path
      if (user == null) {
        return {
          'success': false,
          'message': 'No user is currently signed in',
        };
      }

      // Re-authenticate user with current password
      final authUserEmail = user.email;
      if (authUserEmail == null) {
        return {
          'success': false,
          'message': 'User email not available',
        };
      }
      
      final credential = EmailAuthProvider.credential(
        email: authUserEmail,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      
      // Refresh token
      await user.reload();

      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Password change failed';
      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        message = 'New password is too weak. Use at least 6 characters';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please log out and log in again, then try changing password';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print('Change password error: $e');
      return {
        'success': false,
        'message': 'Password change failed: $e',
      };
    }
  }

  /// Update user email
  static Future<Map<String, dynamic>> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user is currently signed in',
        };
      }

      await user.verifyBeforeUpdateEmail(newEmail); // Use verifyBeforeUpdateEmail instead of deprecated updateEmail
      await user.reload();

      return {
        'success': true,
        'message': 'Email updated. Please verify your new email.',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Email update failed';
      if (e.code == 'email-already-in-use') {
        message = 'Email is already in use by another account';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please log out and log in again, then try updating email';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Email update failed: $e',
      };
    }
  }

  // ==================== REST API AUTH HELPER ====================
  
  /// Try authentication using REST API (workaround for configuration-not-found)
  static Future<Map<String, dynamic>> _tryRestApiAuth(String email, String password) async {
    try {
      return await FirebaseRestAuth.signInWithEmailPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'REST API auth failed: $e',
      };
    }
  }

  // ==================== ADMIN SETUP HELPER ====================
  
  /// Manually create admin document for a specific UID (for fixing admin access)
  static Future<Map<String, dynamic>> forceSetupAdmin(String uid, String email) async {
    try {
      print('🔧 Force setting up admin document for UID: $uid');
      print('📧 Email: $email');
      
      // Check Firestore accessibility first
      try {
        await _firestore.collection('admins').limit(1).get().timeout(Duration(seconds: 10));
        print('✅ Firestore is accessible');
      } catch (e) {
        print('❌ Firestore not accessible: $e');
        String errorMsg = 'Firestore is not accessible';
        if (e.toString().contains('permission-denied')) {
          errorMsg = 'Permission denied. Check Firestore security rules to allow writes to "admins" collection.';
        } else if (e.toString().contains('unavailable') || e.toString().contains('network')) {
          errorMsg = 'Firestore is unavailable. Please check:\n• Firestore Database is enabled in Firebase Console\n• Your internet connection is working';
        }
        return {
          'success': false,
          'message': errorMsg,
        };
      }
      
      // Directly create/update admin document
      try {
        await _firestore.collection('admins').doc(uid).set({
          'isAdmin': true,
          'uid': uid,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✅ Admin document write completed');
      } catch (e) {
        print('❌ Error writing admin document: $e');
        String errorMsg = 'Failed to write admin document: $e';
        if (e.toString().contains('permission-denied')) {
          errorMsg = 'Permission denied. Firestore security rules are blocking write access to "admins" collection.\n\nPlease update your Firestore rules to allow writes:\n\nmatch /admins/{document=**} {\n  allow write: if true; // Or your custom rule\n}';
        }
        return {
          'success': false,
          'message': errorMsg,
        };
      }
      
      // Wait and verify
      await Future.delayed(Duration(seconds: 2));
      final verifyDoc = await _firestore.collection('admins').doc(uid).get();
      
      if (verifyDoc.exists && verifyDoc.data()?['isAdmin'] == true) {
        print('✅ Admin document force-created successfully for UID: $uid');
        return {
          'success': true,
          'message': 'Admin document created successfully',
        };
      } else {
        print('⚠️ Document exists but isAdmin field is not true or document missing');
        return {
          'success': false,
          'message': 'Document was created but verification failed. Please check Firestore manually.',
        };
      }
    } catch (e) {
      print('❌ Force setup admin error: $e');
      String errorMsg = 'Failed to setup admin: $e';
      if (e.toString().contains('permission-denied')) {
        errorMsg = 'Permission denied by Firestore security rules. Please update rules to allow writes to "admins" collection.';
      } else if (e.toString().contains('unavailable') || e.toString().contains('network')) {
        errorMsg = 'Network or Firestore unavailable. Please check your connection and ensure Firestore is enabled.';
      }
      return {
        'success': false,
        'message': errorMsg,
      };
    }
  }

  /// Helper function to set up admin document in Firestore
  /// Call this once after admin user is created in Firebase Authentication
  /// Usage: Call this method with the admin user's UID after they sign in
  static Future<Map<String, dynamic>> setupAdminDocument(String uid, {String? email}) async {
    try {
      print('🔧 Setting up admin document for UID: $uid, Email: ${email ?? "not provided"}');
      
      // Check if Firestore is accessible
      try {
        await _firestore.collection('admins').limit(1).get().timeout(Duration(seconds: 5));
        print('✅ Firestore is accessible');
      } catch (e) {
        print('❌ Firestore not accessible: $e');
        return {
          'success': false,
          'message': 'Firestore is not accessible. Please enable Firestore Database in Firebase Console.',
        };
      }
      
      // Check if document already exists
      try {
        final existingDoc = await _firestore.collection('admins').doc(uid).get();
        print('📄 Existing document check: exists=${existingDoc.exists}');
        
        if (existingDoc.exists) {
          final data = existingDoc.data();
          print('📄 Document data: $data');
          if (data != null && data['isAdmin'] == true) {
            print('✅ Admin document already exists and is valid');
            return {
              'success': true,
              'message': 'Admin document already exists',
              'alreadyExists': true,
            };
          } else {
            print('⚠️ Document exists but isAdmin is not true, updating...');
          }
        }

        // Create or update admin document
        print('📝 Creating/updating admin document...');
        await _firestore.collection('admins').doc(uid).set({
          'isAdmin': true,
          'uid': uid,
          if (email != null) 'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ Admin document created/updated successfully for UID: $uid');
        
        // Verify it was created
        final verifyDoc = await _firestore.collection('admins').doc(uid).get();
        if (verifyDoc.exists && verifyDoc.data()?['isAdmin'] == true) {
          print('✅ Verified: Admin document exists and is valid');
          return {
            'success': true,
            'message': 'Admin document created successfully',
            'alreadyExists': false,
          };
        } else {
          print('❌ Verification failed: Document may not have been created properly');
          return {
            'success': false,
            'message': 'Document creation may have failed. Please check Firestore.',
          };
        }
      } catch (e) {
        print('❌ Error during document creation: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        return {
          'success': false,
          'message': 'Failed to setup admin document: $e',
        };
      }
    } catch (e) {
      print('❌ Setup admin document error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': 'Failed to setup admin document: $e',
      };
    }
  }

  /// Auto-setup admin document after successful admin login
  /// This will automatically create the admin document if it doesn't exist
  static Future<bool> autoSetupAdminIfNeeded(String uid, String email) async {
    try {
      print('🔍 Checking if admin document exists for UID: $uid');
      
      // Check if Firestore is accessible
      try {
        await _firestore.collection('admins').limit(1).get().timeout(Duration(seconds: 5));
        print('✅ Firestore is accessible');
      } catch (e) {
        print('❌ Firestore not accessible: $e');
        print('⚠️ Please enable Firestore Database in Firebase Console');
        return false;
      }
      
      // Check if admin document exists
      try {
        final adminDoc = await _firestore.collection('admins').doc(uid).get();
        print('📄 Admin document check: exists=${adminDoc.exists}');
        
        if (!adminDoc.exists || adminDoc.data()?['isAdmin'] != true) {
          // Auto-create admin document
          print('✨ Auto-creating admin document for UID: $uid, Email: $email');
          final result = await setupAdminDocument(uid, email: email);
          if (result['success'] == true) {
            print('✅ Admin document created successfully!');
            return true;
          } else {
            print('❌ Failed to create admin document: ${result['message']}');
            return false;
          }
        } else {
          print('✅ Admin document already exists');
        }
        return true;
      } catch (e) {
        print('❌ Error checking/creating admin document: $e');
        return false;
      }
    } catch (e) {
      print('❌ Auto-setup admin error: $e');
      print('⚠️ Stack trace: ${StackTrace.current}');
      // Return false to indicate setup failed
      return false;
    }
  }
}

