import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One-time setup helper to create admin document in Firestore
/// 
/// Usage:
/// 1. Sign in with your admin credentials in the app
/// 2. Call this function once:
///    await AdminSetupHelper.setupAdminDocument('UID_HERE');
/// 
/// Or use setupAdminByEmail for CEO account:
///    await AdminSetupHelper.setupAdminByEmail('ceo@fortumars.com');
class AdminSetupHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Setup admin document for a specific UID
  static Future<Map<String, dynamic>> setupAdminDocument(
    String uid, {
    String? email,
  }) async {
    try {
      print('🔧 Setting up admin document for UID: $uid');
      
      // Check if document already exists
      final existingDoc = await _firestore.collection('admins').doc(uid).get();
      if (existingDoc.exists) {
        final data = existingDoc.data();
        if (data != null && data['isAdmin'] == true) {
          print('✅ Admin document already exists');
          return {
            'success': true,
            'message': 'Admin document already exists',
            'alreadyExists': true,
          };
        }
      }

      // Get email from current user if not provided
      String? userEmail = email;
      if (userEmail == null && _auth.currentUser != null) {
        userEmail = _auth.currentUser!.email;
      }

      // Create or update admin document
      await _firestore.collection('admins').doc(uid).set({
        'isAdmin': true,
        'uid': uid,
        if (userEmail != null) 'email': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Admin document created successfully!');
      print('   UID: $uid');
      if (userEmail != null) print('   Email: $userEmail');
      
      return {
        'success': true,
        'message': 'Admin document created successfully',
        'alreadyExists': false,
      };
    } catch (e) {
      print('❌ Setup admin document error: $e');
      return {
        'success': false,
        'message': 'Failed to setup admin document: $e',
      };
    }
  }

  /// Setup admin using current authenticated user
  static Future<Map<String, dynamic>> setupCurrentUserAsAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'success': false,
        'message': 'No user is currently signed in',
      };
    }

    return await setupAdminDocument(user.uid, email: user.email);
  }

  /// Setup multiple admin UIDs at once
  static Future<Map<String, dynamic>> setupMultipleAdmins(
    List<String> uids, {
    Map<String, String>? uidToEmail,
  }) async {
    int successCount = 0;
    int failCount = 0;
    List<String> errors = [];

    for (final uid in uids) {
      final email = uidToEmail?[uid];
      final result = await setupAdminDocument(uid, email: email);
      if (result['success'] == true) {
        successCount++;
      } else {
        failCount++;
        errors.add('UID $uid: ${result['message']}');
      }
    }

    return {
      'success': failCount == 0,
      'message': 'Setup complete: $successCount succeeded, $failCount failed',
      'successCount': successCount,
      'failCount': failCount,
      'errors': errors,
    };
  }

  /// Setup admin by email (requires user to exist in Firebase Auth first)
  /// Useful for CEO account: ceo@fortumars.com
  static Future<Map<String, dynamic>> setupAdminByEmail(String email) async {
    try {
      // Try to find user by email
      final users = await _auth.fetchSignInMethodsForEmail(email);
      if (users.isEmpty) {
        return {
          'success': false,
          'message': 'User with email $email not found in Firebase Authentication. Please create the user first.',
        };
      }

      // Note: fetchSignInMethodsForEmail doesn't return UID
      // We need the user to sign in first or provide UID
      // For now, instruct user to sign in and use setupCurrentUserAsAdmin
      return {
        'success': false,
        'message': 'Please sign in with $email first, then call setupCurrentUserAsAdmin() or provide the UID manually.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking user: $e',
      };
    }
  }

  /// Quick setup for CEO admin account
  /// Call this after creating ceo@fortumars.com in Firebase Authentication
  static Future<Map<String, dynamic>> setupCEOAdmin(String uid) async {
    return await setupAdminDocument(
      uid,
      email: 'ceo@fortumars.com',
    );
  }
}

