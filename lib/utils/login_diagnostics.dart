import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

/// Comprehensive login diagnostics
class LoginDiagnostics {
  static Future<Map<String, dynamic>> runFullDiagnostics({
    required String email,
    required String password,
  }) async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'email': email,
      'steps': <String, dynamic>{},
    };

    try {
      // Step 1: Check Firebase Auth connection
      results['steps']['1_firebase_auth'] = await _checkFirebaseAuth();

      // Step 2: Check if user exists
      results['steps']['2_user_exists'] = await _checkUserExists(email);

      // Step 3: Try to sign in
      results['steps']['3_sign_in'] = await _trySignIn(email, password);

      // Step 4: Check Firestore connection
      results['steps']['4_firestore'] = await _checkFirestore();

      // Step 5: Check admin document
      if (results['steps']['3_sign_in']['success'] == true) {
        final uid = results['steps']['3_sign_in']['uid'] as String?;
        if (uid != null) {
          results['steps']['5_admin_doc'] = await _checkAdminDocument(uid);
        }
      }

      // Step 6: Check custom claims
      if (results['steps']['3_sign_in']['success'] == true) {
        results['steps']['6_custom_claims'] = await _checkCustomClaims();
      }

      // Overall result
      final signInSuccess = results['steps']['3_sign_in']?['success'] == true;
      final adminDocSuccess = results['steps']['5_admin_doc']?['isAdmin'] == true;
      final customClaimsSuccess = results['steps']['6_custom_claims']?['isAdmin'] == true;

      results['overall'] = {
        'canSignIn': signInSuccess,
        'hasAdminAccess': adminDocSuccess || customClaimsSuccess,
        'blockingIssue': _getBlockingIssue(results),
        'recommendation': _getRecommendation(results),
      };
    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }

  static Future<Map<String, dynamic>> _checkFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      return {
        'success': true,
        'connected': true,
        'currentUser': user?.email ?? 'none',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _checkUserExists(String email) async {
    try {
      // We can't directly check if user exists without attempting sign in
      // But we can provide info
      return {
        'success': true,
        'message': 'User existence will be verified during sign in',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _trySignIn(String email, String password) async {
    try {
      final auth = FirebaseAuth.instance;
      
      // Try to sign in
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        return {
          'success': true,
          'uid': credential.user!.uid,
          'email': credential.user!.email,
          'emailVerified': credential.user!.emailVerified,
        };
      } else {
        return {
          'success': false,
          'error': 'Sign in returned null user',
        };
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication failed';
      String detailedMessage = '';
      
      if (e.code == 'user-not-found') {
        message = 'User not found';
        detailedMessage = 'User does not exist in Firebase Authentication. Please create the user first.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
        detailedMessage = 'The password is incorrect. Please check the password in Firebase Authentication console and reset it to "admin123" if needed.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
        detailedMessage = 'The email format is invalid. Please check the email address.';
      } else if (e.code == 'user-disabled') {
        message = 'User account is disabled';
        detailedMessage = 'This user account has been disabled. Please enable it in Firebase Authentication console.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed attempts';
        detailedMessage = 'Too many failed login attempts. Please wait a few minutes and try again.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error';
        detailedMessage = 'Network connection failed. Please check your internet connection.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials';
        detailedMessage = 'The email or password is incorrect. Please verify credentials in Firebase Authentication console.';
      } else {
        detailedMessage = 'Firebase error code: ${e.code}. Message: ${e.message ?? "No details"}';
      }
      
      return {
        'success': false,
        'error': message,
        'detailedError': detailedMessage,
        'code': e.code,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Unexpected error: $e',
        'detailedError': 'An unexpected error occurred during authentication. Please check console logs for details.',
      };
    }
  }

  static Future<Map<String, dynamic>> _checkFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').limit(1).get().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Firestore connection timeout');
        },
      );
      return {
        'success': true,
        'connected': true,
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'connected': false,
        'error': 'Firestore connection timeout. Database may not be enabled.',
      };
    } catch (e) {
      return {
        'success': false,
        'connected': false,
        'error': 'Firestore error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> _checkAdminDocument(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Check admins collection
      final adminDoc = await firestore.collection('admins').doc(uid).get();
      
      if (adminDoc.exists) {
        final data = adminDoc.data();
        return {
          'success': true,
          'exists': true,
          'isAdmin': data?['isAdmin'] == true,
          'data': data,
        };
      } else {
        return {
          'success': true,
          'exists': false,
          'isAdmin': false,
          'message': 'Admin document does not exist. Document ID should match User UID: $uid',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error checking admin document: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> _checkCustomClaims() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'No user signed in',
        };
      }

      final tokenResult = await user.getIdTokenResult(true);
      final claims = tokenResult.claims;
      
      return {
        'success': true,
        'isAdmin': claims?['admin'] == true,
        'claims': claims,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error checking custom claims: $e',
      };
    }
  }

  static String _getBlockingIssue(Map<String, dynamic> results) {
    if (results['steps']['3_sign_in']?['success'] != true) {
      return results['steps']['3_sign_in']?['error'] ?? 'Sign in failed';
    }
    if (results['steps']['4_firestore']?['connected'] != true) {
      return 'Firestore is not connected';
    }
    if (results['steps']['5_admin_doc']?['isAdmin'] != true) {
      return 'Admin document does not exist or isAdmin is not true';
    }
    return 'No blocking issues found';
  }

  static String _getRecommendation(Map<String, dynamic> results) {
    final signIn = results['steps']['3_sign_in'];
    final firestore = results['steps']['4_firestore'];
    final adminDoc = results['steps']['5_admin_doc'];

    if (signIn?['success'] != true) {
      final error = signIn?['error'] ?? '';
      if (error.contains('not found')) {
        return 'Create user in Firebase Authentication console';
      } else if (error.contains('password')) {
        return 'Check password in Firebase Authentication console';
      }
      return 'Fix authentication issue first';
    }

    if (firestore?['connected'] != true) {
      return 'Enable Firestore Database in Firebase Console';
    }

    if (adminDoc?['isAdmin'] != true) {
      final uid = signIn?['uid'] as String?;
      if (uid != null) {
        return 'Create admin document in Firestore:\nCollection: admins\nDocument ID: $uid\nField: isAdmin = true';
      }
      return 'Create admin document in Firestore';
    }

    return 'Everything looks good!';
  }
}

