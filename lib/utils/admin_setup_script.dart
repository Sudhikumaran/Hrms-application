import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Quick utility script to set up admin document for a specific UID
/// Run this once to fix admin access issues
class AdminSetupScript {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Set up admin document for the specific UID provided by user
  /// UID: 0PiQBMhHcDUJXnX3T49B8CKZKNl1
  static Future<void> setupAdminForUID() async {
    const adminUID = '0PiQBMhHcDUJXnX3T49B8CKZKNl1';
    
    try {
      print('🔧 Setting up admin document for UID: $adminUID');
      
      // Get the user's email from Firebase Auth if they're signed in
      String? email;
      try {
        final user = _auth.currentUser;
        if (user != null && user.uid == adminUID) {
          email = user.email;
          print('✅ Found email from current user: $email');
        } else {
          // Try to get user by UID (this might not work if not signed in)
          print('⚠️ User not signed in or UID mismatch, will use placeholder email');
        }
      } catch (e) {
        print('⚠️ Could not get email from auth: $e');
      }
      
      // Create or update admin document
      await _firestore.collection('admins').doc(adminUID).set({
        'isAdmin': true,
        'uid': adminUID,
        'email': email ?? 'admin@fortumars.com', // Use provided email or placeholder
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Verify it was created
      await Future.delayed(Duration(seconds: 2));
      final verifyDoc = await _firestore.collection('admins').doc(adminUID).get();
      
      if (verifyDoc.exists) {
        final data = verifyDoc.data();
        print('✅ Admin document created successfully!');
        print('   UID: $adminUID');
        print('   Email: ${data?['email'] ?? 'N/A'}');
        print('   isAdmin: ${data?['isAdmin'] ?? false}');
      } else {
        print('❌ Admin document verification failed');
      }
    } catch (e) {
      print('❌ Error setting up admin: $e');
      rethrow;
    }
  }

  /// Alternative: Set up admin document with explicit email
  static Future<void> setupAdminForUIDWithEmail(String email) async {
    const adminUID = '0PiQBMhHcDUJXnX3T49B8CKZKNl1';
    
    try {
      print('🔧 Setting up admin document for UID: $adminUID');
      print('📧 Email: $email');
      
      // Create or update admin document
      await _firestore.collection('admins').doc(adminUID).set({
        'isAdmin': true,
        'uid': adminUID,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Verify it was created
      await Future.delayed(Duration(seconds: 2));
      final verifyDoc = await _firestore.collection('admins').doc(adminUID).get();
      
      if (verifyDoc.exists && verifyDoc.data()?['isAdmin'] == true) {
        print('✅ Admin document created and verified successfully!');
        print('   UID: $adminUID');
        print('   Email: $email');
      } else {
        print('❌ Admin document verification failed');
      }
    } catch (e) {
      print('❌ Error setting up admin: $e');
      rethrow;
    }
  }
}

