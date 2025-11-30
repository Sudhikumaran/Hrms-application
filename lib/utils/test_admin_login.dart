import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Test utility to diagnose admin login issues
class TestAdminLogin {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Run comprehensive diagnostics
  static Future<Map<String, dynamic>> runDiagnostics({
    required String email,
    required String password,
  }) async {
    print('\n========== ADMIN LOGIN DIAGNOSTICS ==========');
    
    Map<String, dynamic> results = {
      'authCheck': false,
      'firestoreCheck': false,
      'adminDocCheck': false,
      'issues': [],
    };

    // Test 1: Firebase Auth
    print('\n1. Testing Firebase Authentication...');
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        final uid = credential.user!.uid;
        print('✅ Auth successful! UID: $uid');
        results['authCheck'] = true;
        results['uid'] = uid;
        
        // Test 2: Firestore Access
        print('\n2. Testing Firestore access...');
        try {
          await _firestore.collection('admins').limit(1).get().timeout(Duration(seconds: 5));
          print('✅ Firestore is accessible');
          results['firestoreCheck'] = true;
          
          // Test 3: Admin Document
          print('\n3. Checking admin document...');
          try {
            final adminDoc = await _firestore.collection('admins').doc(uid).get();
            if (adminDoc.exists) {
              final data = adminDoc.data();
              print('✅ Admin document exists');
              print('   Data: $data');
              if (data != null && data['isAdmin'] == true) {
                print('✅ isAdmin field is true');
                results['adminDocCheck'] = true;
              } else {
                print('❌ isAdmin field is false or missing');
                results['issues'].add('Admin document exists but isAdmin is not true');
              }
            } else {
              print('❌ Admin document does NOT exist');
              results['issues'].add('Admin document missing. Need to create in Firestore.');
            }
          } catch (e) {
            print('❌ Error checking admin document: $e');
            results['issues'].add('Cannot read admin document: $e');
          }
        } catch (e) {
          print('❌ Firestore not accessible: $e');
          results['issues'].add('Firestore not accessible: $e');
        }
        
        // Sign out
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Auth failed: ${e.code} - ${e.message}');
      results['issues'].add('Authentication failed: ${e.code}');
      if (e.code == 'user-not-found') {
        results['issues'].add('User does not exist. Create in Firebase Console.');
      } else if (e.code == 'wrong-password') {
        results['issues'].add('Wrong password. Verify password is correct.');
      }
    } catch (e) {
      print('❌ Error: $e');
      results['issues'].add('Unexpected error: $e');
    }

    print('\n========== DIAGNOSTICS COMPLETE ==========\n');
    
    return results;
  }
}




