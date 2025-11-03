import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper for demo/admin development setup
/// This can create demo admin documents automatically
class DemoAdminHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Demo admin credentials (for development/testing only)
  static const String demoEmail = 'admin@demo.com';
  static const String demoPassword = 'admin123';

  /// Create demo admin user and document
  /// NOTE: This requires Firebase Authentication user to be created manually first
  static Future<Map<String, dynamic>> setupDemoAdmin({String? uid, String? email}) async {
    try {
      final targetUid = uid;
      final targetEmail = email ?? demoEmail;

      if (targetUid == null) {
        return {
          'success': false,
          'message': 'UID is required. Please create user in Firebase Authentication first and provide UID.',
          'instructions': [
            '1. Go to Firebase Authentication console',
            '2. Create user with email: $targetEmail, password: $demoPassword',
            '3. Copy the User UID',
            '4. Call this function again with the UID',
          ],
        };
      }

      // Create admin document in Firestore
      await _firestore.collection('admins').doc(targetUid).set({
        'isAdmin': true,
        'uid': targetUid,
        'email': targetEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'isDemo': true, // Mark as demo account
      }, SetOptions(merge: true));

      // Verify creation
      final doc = await _firestore.collection('admins').doc(targetUid).get();
      if (doc.exists && doc.data()?['isAdmin'] == true) {
        return {
          'success': true,
          'message': 'Demo admin document created successfully!',
          'credentials': {
            'email': targetEmail,
            'password': demoPassword,
          },
          'uid': targetUid,
        };
      } else {
        return {
          'success': false,
          'message': 'Document created but verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating demo admin: $e',
      };
    }
  }

  /// Get demo credentials info
  static Map<String, dynamic> getDemoCredentials() {
    return {
      'email': demoEmail,
      'password': demoPassword,
      'note': 'Demo credentials for testing. User must be created in Firebase Authentication first.',
    };
  }

  /// Check if Firestore is accessible for demo setup
  static Future<bool> checkFirestoreAccess() async {
    try {
      await _firestore.collection('admins').limit(1).get().timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timeout'),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

