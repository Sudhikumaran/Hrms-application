import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../services/hybrid_storage_service.dart';

/// Utility to set up Firebase Authentication for all employees and admin
class SetupAllAuth {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  /// Create Firebase Auth accounts for all employees
  static Future<Map<String, dynamic>> setupEmployeesAuth() async {
    try {
      print('🚀 Starting Firebase Auth setup for all employees...');
      
      // Get all employees
      final employees = HybridStorageService.getEmployees();
      if (employees.isEmpty) {
        return {
          'success': false,
          'message': 'No employees found',
          'created': 0,
          'failed': 0,
          'skipped': 0,
        };
      }
      
      print('📋 Found ${employees.length} employees to process');
      
      int created = 0;
      int failed = 0;
      int skipped = 0;
      List<String> errors = [];
      
      for (var employee in employees) {
        try {
          // Skip if no email
          if (employee.email == null || employee.email!.isEmpty) {
            print('⚠️ Skipping ${employee.empId}: No email address');
            skipped++;
            continue;
          }
          
          // Check if Firebase Auth account already exists
          // We'll try to create it and handle email-already-in-use error
          print('ℹ️ ${employee.empId} (${employee.email}): Processing...');
          
          // Get the employee's password from SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          String? password;
          
          // Try to find password by employee ID
          password = prefs.getString('emp_login_id_${employee.empId}');
          
          // If not found, try by email
          if (password == null || password.isEmpty) {
            password = prefs.getString('emp_login_email_${employee.email}');
          }
          
          if (password == null || password.isEmpty) {
            print('⚠️ Skipping ${employee.empId} (${employee.email}): No password found in local storage');
            skipped++;
            continue;
          }
          
          // Save password to Firestore first (like admin) - ensures login works even without Firebase Auth
          try {
            print('💾 Saving password to Firestore for ${employee.empId}...');
            final employeesRef = _firestore.collection('employees');
            final query = await employeesRef
                .where('empId', isEqualTo: employee.empId)
                .limit(1)
                .get();
            
            if (query.docs.isNotEmpty) {
              await query.docs.first.reference.update({
                'passwordHash': password,
                'authMethod': 'direct', // Will be upgraded to 'firebase' if Auth succeeds
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('✅ Password saved to Firestore for ${employee.empId}');
            } else {
              print('⚠️ Employee ${employee.empId} not found in Firestore, cannot save password');
            }
          } catch (e) {
            print('⚠️ Error saving password to Firestore for ${employee.empId}: $e');
          }
          
          print('🔐 Creating Firebase Auth account for ${employee.empId} (${employee.email})...');
          
          final result = await FirebaseService.createEmployeeAccount(
            employee.email!,
            password,
            employee.empId,
          );
          
          if (result['success'] == true) {
            print('✅ Created Firebase Auth account for ${employee.empId}');
            
            // Upgrade auth method to 'firebase' in Firestore
            try {
              final employeesRef = _firestore.collection('employees');
              final query = await employeesRef
                  .where('empId', isEqualTo: employee.empId)
                  .limit(1)
                  .get();
              
              if (query.docs.isNotEmpty) {
                await query.docs.first.reference.update({
                  'authMethod': 'firebase',
                  'firebaseUserId': result['uid'],
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                print('✅ Updated auth method to firebase for ${employee.empId}');
              }
            } catch (e) {
              print('⚠️ Could not update auth method: $e');
            }
            
            created++;
            
            // Small delay to avoid rate limiting
            await Future.delayed(Duration(milliseconds: 500));
          } else {
            final errorCode = result['errorCode'] as String?;
            final errorMsg = result['message'] as String?;
            
            if (errorCode == 'email-already-in-use') {
              print('ℹ️ ${employee.empId} (${employee.email}): Account already exists');
              skipped++; // Don't count as failure if account already exists
            } else if (errorCode == 'configuration-not-found' || errorCode == 'unknown') {
              print('⚠️ ${employee.empId} (${employee.email}): Firebase Auth configuration issue - skipping');
              errors.add('${employee.empId}: Firebase Auth not configured');
              skipped++;
            } else {
              print('❌ Failed to create account for ${employee.empId}: $errorMsg');
              errors.add('${employee.empId}: $errorMsg');
              failed++;
            }
          }
        } catch (e) {
          print('❌ Error processing ${employee.empId}: $e');
          errors.add('${employee.empId}: $e');
          failed++;
        }
      }
      
      print('✅ Employee auth setup complete:');
      print('   Created: $created');
      print('   Skipped: $skipped');
      print('   Failed: $failed');
      
      return {
        'success': failed == 0 || created > 0,
        'message': 'Created $created, skipped $skipped, failed $failed employee accounts',
        'created': created,
        'skipped': skipped,
        'failed': failed,
        'errors': errors,
      };
    } catch (e, stackTrace) {
      print('❌ Error setting up employee auth: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error: $e',
        'created': 0,
        'failed': 0,
        'skipped': 0,
      };
    }
  }
  
  /// Create Firebase Auth account for admin
  static Future<Map<String, dynamic>> setupAdminAuth({
    String? email,
    String? password,
  }) async {
    try {
      print('🚀 Starting Firebase Auth setup for admin...');
      
      // Get admin email and password from SharedPreferences if not provided
      final prefs = await SharedPreferences.getInstance();
      final adminEmail = email ?? prefs.getString('userEmail') ?? 'ceo@fortumars.com';
      final adminPassword = password ?? prefs.getString('adminPassword');
      
      if (adminPassword == null || adminPassword.isEmpty) {
        return {
          'success': false,
          'message': 'Admin password not found. Please provide password.',
        };
      }
      
      print('🔐 Creating Firebase Auth account for admin: $adminEmail');
      
      final result = await FirebaseService.createAdminAccount(adminEmail, adminPassword);
      
      if (result['success'] == true) {
        print('✅ Admin Firebase Auth account created successfully');
        return {
          'success': true,
          'message': 'Admin Firebase Auth account created successfully',
          'uid': result['uid'],
          'email': adminEmail,
        };
      } else {
        final errorCode = result['errorCode'] as String?;
        final errorMsg = result['message'] as String?;
        
        if (errorCode == 'email-already-in-use') {
          return {
            'success': true,
            'message': 'Admin Firebase Auth account already exists',
            'email': adminEmail,
          };
        } else {
          return {
            'success': false,
            'message': errorMsg ?? 'Failed to create admin account',
            'errorCode': errorCode,
          };
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error setting up admin auth: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  /// Setup authentication for all employees and admin
  static Future<Map<String, dynamic>> setupAllAuth({
    String? adminEmail,
    String? adminPassword,
  }) async {
    try {
      print('🚀 Starting Firebase Auth setup for all users...');
      
      // Setup employees
      print('\n📋 Step 1: Setting up employee authentication...');
      final employeesResult = await setupEmployeesAuth();
      
      // Setup admin
      print('\n📋 Step 2: Setting up admin authentication...');
      final adminResult = await setupAdminAuth(
        email: adminEmail,
        password: adminPassword,
      );
      
      return {
        'success': employeesResult['success'] == true && adminResult['success'] == true,
        'message': 'Setup complete: ${employeesResult['message']}; Admin: ${adminResult['message']}',
        'employees': employeesResult,
        'admin': adminResult,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}

