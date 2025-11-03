import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';

/// Workaround to create admin account when Firebase Auth has configuration issues
/// Creates admin document directly in Firestore
class CreateAdminWorkaround {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create admin account directly in Firestore (without Firebase Auth)
  /// Use this if Firebase Auth REST API is giving configuration-not-found errors
  static Future<Map<String, dynamic>> createAdminDirectly({
    required String email,
    required String password,
  }) async {
    try {
      print('🔧 Creating admin directly in Firestore (workaround)...');
      
      // Generate a temporary UID (we'll use email hash or timestamp)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uid = 'admin_${email.replaceAll('@', '_').replaceAll('.', '_')}_$timestamp';
      
      // Check if admin with this email already exists
      final existingQuery = await _firestore.collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (existingQuery.docs.isNotEmpty) {
        final existingDoc = existingQuery.docs.first;
        final existingUid = existingDoc.id;
        print('⚠️ Admin with email $email already exists with UID: $existingUid');
        return {
          'success': false,
          'message': 'Admin with this email already exists. Please use login instead.',
          'uid': existingUid,
        };
      }
      
      // Create admin document
      await _firestore.collection('admins').doc(uid).set({
        'isAdmin': true,
        'uid': uid,
        'email': email,
        'passwordHash': password, // Store password (in production, hash this)
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'authMethod': 'direct', // Mark as direct creation (no Firebase Auth)
      });
      
      // Verify creation
      await Future.delayed(Duration(seconds: 1));
      final verifyDoc = await _firestore.collection('admins').doc(uid).get();
      
      if (verifyDoc.exists) {
        print('✅ Admin document created successfully in Firestore');
        print('📋 UID: $uid');
        print('📧 Email: $email');
        
        // Store locally for login
        await LocalStorageService.init();
        await LocalStorageService.saveUser(uid, 'Admin');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);
        await prefs.setString('adminPassword', password); // Store for login verification
        
        return {
          'success': true,
          'uid': uid,
          'email': email,
          'message': 'Admin account created in Firestore. You can now login.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to verify admin document creation',
        };
      }
    } catch (e, stackTrace) {
      print('❌ Direct admin creation error: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error creating admin: $e',
      };
    }
  }
}

