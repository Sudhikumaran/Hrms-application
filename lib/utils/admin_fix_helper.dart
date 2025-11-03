import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

/// Helper utility to fix admin access for a specific UID
class AdminFixHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Force create admin document for a specific UID
  /// Use this if admin login is failing due to missing admin document
  static Future<Map<String, dynamic>> fixAdminAccess(String uid, String email) async {
    try {
      print('🔧 Fixing admin access for UID: $uid');
      print('📧 Email: $email');
      
      // Try using FirebaseService method first
      final result = await FirebaseService.forceSetupAdmin(uid, email);
      
      if (result['success'] == true) {
        print('✅ Admin document created successfully');
        
        // Verify it exists
        await Future.delayed(Duration(seconds: 1));
        final verify = await _firestore.collection('admins').doc(uid).get();
        
        if (verify.exists) {
          final data = verify.data();
          print('✅ Verification: Admin document exists');
          print('   Data: $data');
          return {
            'success': true,
            'message': 'Admin document created and verified successfully',
            'uid': uid,
            'email': email,
          };
        } else {
          return {
            'success': false,
            'message': 'Document creation reported success but verification failed',
          };
        }
      } else {
        // If FirebaseService method failed, try direct approach
        print('⚠️ FirebaseService method failed, trying direct Firestore write...');
        try {
          await _firestore.collection('admins').doc(uid).set({
            'isAdmin': true,
            'uid': uid,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          await Future.delayed(Duration(seconds: 2));
          final verify = await _firestore.collection('admins').doc(uid).get();
          
          if (verify.exists && verify.data()?['isAdmin'] == true) {
            return {
              'success': true,
              'message': 'Admin document created directly in Firestore',
              'uid': uid,
              'email': email,
            };
          }
        } catch (e) {
          print('❌ Direct Firestore write failed: $e');
          return {
            'success': false,
            'message': 'Failed to create admin document: $e',
          };
        }
      }
      
      return result;
    } catch (e) {
      print('❌ Fix admin access error: $e');
      return {
        'success': false,
        'message': 'Error fixing admin access: $e',
      };
    }
  }

  /// Check if admin document exists
  static Future<bool> checkAdminExists(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking admin: $e');
      return false;
    }
  }
}

