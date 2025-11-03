import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import '../services/hybrid_storage_service.dart';
import '../utils/login_diagnostics.dart';
import 'main_screen.dart';
import 'admin_main_screen.dart';
import 'create_admin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _empIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'Employee';

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        final input = _empIdController.text.trim();
        final pwd = _passwordController.text;
        bool isValid = false;
        if (_selectedRole == 'Employee') {
          await LocalStorageService.init();
          // Ensure HybridStorageService is initialized
          await HybridStorageService.init();
          
          // CRITICAL: Force sync employees from Firestore first (important after restart)
          if (HybridStorageService.isOnline) {
            print('🔄 Force syncing employees from Firestore before login...');
            await HybridStorageService.refreshEmployeesFromFirestore();
          }
          
          // Use Firebase Authentication for employee login (same as admin)
          try {
            print('🔐 Attempting employee login for: ${input.trim()}');
            final result = await FirebaseService.signInEmployee(input, pwd);
            print('📋 Employee login result: $result');
            
            if (result['success'] == true) {
              print('✅ Login successful, navigating to main screen');
              await LocalStorageService.saveUser(result['userId'] ?? input, 'Employee');
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => MainScreen()),
              );
              isValid = true;
            } else {
              print('❌ Login failed: ${result['message']}');
              
              // If result says to use fallback, don't show error yet
              final useFallback = result['useFallback'] == true;
              if (!useFallback) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Invalid credentials'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              }
            }
          } catch (e, stackTrace) {
            print('❌ Employee login exception: $e');
            print('❌ Stack trace: $stackTrace');
            // Continue to fallback
          }
          
          // Fallback to old method if Firebase Auth fails (backward compatibility)
          // Also use if result indicates useFallback
          if (!isValid) {
            print('⚠️ Firebase Auth failed, trying fallback method (local passwords)...');
            
            // Get employees - try Firestore first, then local
            List<Employee> employees = [];
            
            // Try to get from Firestore if online
            if (HybridStorageService.isOnline) {
              try {
                print('🌐 Online - refreshing employees from Firestore...');
                employees = await HybridStorageService.refreshEmployeesFromFirestore();
                print('✅ Refreshed: ${employees.length} employees from Firestore');
              } catch (e) {
                print('⚠️ Firestore refresh failed: $e, using local employees');
                employees = HybridStorageService.getEmployees();
              }
            } else {
              employees = HybridStorageService.getEmployees();
              print('📱 Offline - using local employees: ${employees.length}');
            }
            
            // If still no employees, try just local storage directly
            if (employees.isEmpty) {
              print('⚠️ No employees from Firestore, checking local storage...');
              await LocalStorageService.init();
              employees = LocalStorageService.getEmployees();
              print('📱 Local storage has ${employees.length} employees');
            }
            
            print('🔍 Login attempt - Total employees found: ${employees.length}');
            print('🔍 Login attempt - Input: $input');
          
          Employee? found;
          for (final e in employees) {
            final empIdMatch = e.empId.toLowerCase() == input.toLowerCase();
            final emailMatch = e.email != null && e.email!.toLowerCase() == input.toLowerCase();
            print('🔍 Checking employee: ${e.empId}, email: ${e.email}, empIdMatch: $empIdMatch, emailMatch: $emailMatch');
            
            if (empIdMatch || emailMatch) {
              found = e;
              print('✅ Found employee: ${found.empId}, email: ${found.email}');
              break;
            }
          }
          
          if (found != null) {
            final prefs = await SharedPreferences.getInstance();
            
            // Collect ALL possible password keys for this employee
            final allKeys = prefs.getKeys();
            final List<String> passwordKeys = [];
            final List<String> storedPasswords = [];
            
            // Standard keys
            final emailKey = found.email != null ? 'emp_login_email_${found.email}' : '';
            final idKey = 'emp_login_id_${found.empId}';
            
            passwordKeys.add(idKey);
            if (emailKey.isNotEmpty) passwordKeys.add(emailKey);
            
            // Find ALL password keys that might match this employee
            for (var key in allKeys) {
              // Check emp_login_id keys
              if (key.startsWith('emp_login_id_')) {
                final keyEmpId = key.replaceFirst('emp_login_id_', '');
                if (keyEmpId.toUpperCase() == found.empId.toUpperCase()) {
                  if (!passwordKeys.contains(key)) {
                    passwordKeys.add(key);
                    print('🔍 Found additional ID key: $key');
                  }
                }
              }
              // Check emp_login_email keys
              if (key.startsWith('emp_login_email_')) {
                final keyEmail = key.replaceFirst('emp_login_email_', '');
                // Case-insensitive match
                if (found.email != null && keyEmail.toLowerCase().trim() == found.email!.toLowerCase().trim()) {
                  if (!passwordKeys.contains(key)) {
                    passwordKeys.add(key);
                    print('🔍 Found additional email key: $key');
                  }
                }
                // Also check if email in key matches any email format
                if (found.email != null && keyEmail.contains(found.email!.split('@')[0])) {
                  if (!passwordKeys.contains(key)) {
                    passwordKeys.add(key);
                    print('🔍 Found potential email key: $key');
                  }
                }
              }
            }
            
            print('🔐 Checking ${passwordKeys.length} password keys for employee ${found.empId}');
            print('🔐 Keys: $passwordKeys');
            
            // Try all password keys
            bool passwordMatch = false;
            String? matchedKey;
            
            for (var key in passwordKeys) {
              final storedPassword = prefs.getString(key);
              if (storedPassword != null && storedPassword.isNotEmpty) {
                storedPasswords.add(storedPassword);
                print('🔐 Key "$key" has password: "${storedPassword.length > 0 ? "***${storedPassword.length} chars" : "(empty)"}"');
                if (pwd == storedPassword) {
                  passwordMatch = true;
                  matchedKey = key;
                  print('✅ Password match found on key: $key');
                  break;
                }
              }
            }
            
            print('🔐 Input password: "${pwd.length} chars"');
            print('🔐 Total stored passwords checked: ${storedPasswords.length}');
            
            if (passwordMatch && matchedKey != null) {
              print('✅ Password match on key "$matchedKey"! Logging in...');
              
              // Try to create Firebase Auth account for this employee if they don't have one
              // This migrates old accounts to Firebase Auth automatically
              if (found.email != null && found.email!.isNotEmpty) {
                try {
                  print('🔐 Attempting to create Firebase Auth account for ${found.email}...');
                  final authResult = await FirebaseService.createEmployeeAccount(
                    found.email!,
                    pwd, // Use the password they just entered
                    found.empId,
                  );
                  if (authResult['success'] == true) {
                    print('✅ Firebase Auth account created for future logins');
                  } else {
                    final errorCode = authResult['errorCode'] as String?;
                    final errorMsg = authResult['message'] as String?;
                    
                    // Don't log as error if it's a configuration issue - this is expected
                    if (errorCode == 'configuration-not-found' || errorCode == 'unknown' || (errorMsg?.contains('configuration') ?? false)) {
                      print('ℹ️ Firebase Auth not configured - employee will continue using local password login');
                    } else if (errorCode == 'email-already-in-use') {
                      print('ℹ️ Email already has Firebase Auth account - future logins will use Firebase Auth');
                    } else {
                      print('⚠️ Could not create Firebase Auth account: $errorMsg');
                      print('   Error code: ${errorCode ?? "unknown"}');
                    }
                    // Continue anyway - local password works
                  }
                } catch (e) {
                  print('⚠️ Error creating Firebase Auth account: $e');
                  // Continue anyway - local password works
                }
              }
              
              await LocalStorageService.saveUser(found.empId, 'Employee');
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => MainScreen()),
              );
              isValid = true;
            } else {
              print('❌ Password mismatch - Checked ${passwordKeys.length} keys, ${storedPasswords.length} had passwords');
              print('❌ Input password does not match any stored password');
              
              // Debug: Show all password keys in system
              final allPasswordKeys = allKeys.where((k) => 
                k.startsWith('emp_login_id_') || k.startsWith('emp_login_email_')
              ).toList();
              print('📋 All password keys in system: $allPasswordKeys');
              
              // Debug: Show password values for debugging (BE CAREFUL - only for debugging!)
              for (var key in allPasswordKeys) {
                final passValue = prefs.getString(key);
                print('  Key "$key": ${passValue != null ? "${passValue.length} chars" : "null"}');
              }
              
              // Show a helpful error with all relevant info
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password mismatch. Check console logs for details. Employee: ${found.empId}, Email: ${found.email ?? "N/A"}'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 8),
                  ),
                );
              }
            }
          } else {
            print('❌ Employee not found');
          }
          }
        } else if (_selectedRole == 'Admin') {
          // Ensure HybridStorageService is initialized for Firestore access
          await LocalStorageService.init();
          await HybridStorageService.init();
          
          // Use Firebase Authentication for admin login
          try {
            print('🔐 Attempting admin login for: ${input.trim()}');
            print('📧 Email: ${input.trim()}, Password length: ${pwd.length}');
            
            final result = await FirebaseService.signInAdmin(input.trim(), pwd);
            print('📋 Admin login result: $result');
            
            if (result['success'] == true) {
              print('✅ Login successful, navigating to admin screen');
              await LocalStorageService.saveUser(result['userId'] ?? input, 'Admin');
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => AdminMainScreen()),
              );
              isValid = true;
            } else {
              print('❌ Login failed: ${result['message']}');
              if (mounted) {
                // Show more detailed error message with diagnostic button
                final errorMsg = result['message'] ?? 'Invalid admin credentials';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      errorMsg,
                      style: TextStyle(fontSize: 14),
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 10), // Longer duration to read
                    action: SnackBarAction(
                      label: 'Diagnose',
                      textColor: Colors.white,
                      onPressed: () async {
                        // Run diagnostics
                        await _runDiagnostics(context, input.trim(), pwd);
                      },
                    ),
                  ),
                );
              }
            }
          } catch (e, stackTrace) {
            print('❌ Admin login exception: $e');
            print('❌ Stack trace: $stackTrace');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Admin login failed: $e'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 8),
                  action: SnackBarAction(
                    label: 'Diagnose',
                    textColor: Colors.white,
                    onPressed: () async {
                      await _runDiagnostics(context, input.trim(), pwd);
                    },
                  ),
                ),
              );
            }
          }
        }
        if (!isValid && mounted) {
          // Show more helpful error message
          String errorMsg = 'Invalid credentials';
          if (_selectedRole == 'Employee') {
            final employees = HybridStorageService.getEmployees();
            if (employees.isEmpty) {
              errorMsg = 'No employees found. Please sign up first.';
            } else {
              errorMsg = 'Invalid Employee ID/Email or Password.\n\nFound ${employees.length} employee(s) in system.\nPlease check your credentials and try again.';
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _runDiagnostics(BuildContext context, String email, String password) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: FutureBuilder<Map<String, dynamic>>(
            future: LoginDiagnostics.runFullDiagnostics(email: email, password: password),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Running diagnostics...'),
                  ],
                );
              }

              final results = snapshot.data!;
              final overall = results['overall'] as Map<String, dynamic>?;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login Diagnostics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    if (overall != null) ...[
                      _buildStatusRow('Can Sign In', overall['canSignIn'] ?? false),
                      _buildStatusRow('Has Admin Access', overall['hasAdminAccess'] ?? false),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blocking Issue:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              overall['blockingIssue'] ?? 'Unknown',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recommendation:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              overall['recommendation'] ?? 'No recommendation',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    Text(
                      'Detailed Steps:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    ..._buildDetailedSteps(results['steps'] as Map<String, dynamic>?),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailedSteps(Map<String, dynamic>? steps) {
    if (steps == null) return [Text('No steps available')];

    return steps.entries.map((entry) {
      final stepName = entry.key.replaceAll('_', ' ').toUpperCase();
      final stepData = entry.value as Map<String, dynamic>?;
      final success = stepData?['success'] == true || stepData?['connected'] == true;

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 16,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stepName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  if (stepData?['error'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stepData!['error'],
                          style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        if (stepData['detailedError'] != null) ...[
                          SizedBox(height: 4),
                          Text(
                            stepData['detailedError'],
                            style: TextStyle(fontSize: 9, color: Colors.red[700]),
                          ),
                        ],
                        if (stepData['code'] != null)
                          Text(
                            'Error code: ${stepData['code']}',
                            style: TextStyle(fontSize: 8, color: Colors.grey[600], fontFamily: 'monospace'),
                          ),
                      ],
                    )
                  else if (stepData?['message'] != null)
                    Text(
                      stepData!['message'],
                      style: TextStyle(fontSize: 10),
                    )
                  else if (stepData?['uid'] != null)
                    Text(
                      'UID: ${stepData!['uid']}',
                      style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/images/fortumars_logo.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Sign In',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text('Sign in to your account', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                SizedBox(height: 20),

                // Role Selector
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Login as', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                ),
                SizedBox(height: 8),
                // Custom Segmented Control
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentedButton(
                          'Employee',
                          _selectedRole == 'Employee',
                          true, // isFirst
                          () {
                            setState(() {
                              _selectedRole = 'Employee';
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentedButton(
                          'Admin',
                          _selectedRole == 'Admin',
                          false, // isLast
                          () {
                            setState(() {
                              _selectedRole = 'Admin';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // ID Field
                TextFormField(
                  controller: _empIdController,
                  decoration: InputDecoration(
                    labelText: _selectedRole == 'Employee' ? 'Employee ID' : 'Admin Email',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your ${_selectedRole == 'Employee' ? 'Employee' : 'Admin'} ${_selectedRole == 'Admin' ? 'Email' : 'ID'}';
                    }
                    if (_selectedRole == 'Admin') {
                      // Validate email format for admin
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 15),
                if (_selectedRole == 'Employee')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => EmployeeSignUpScreen()),
                          );
                        },
                        child: Text('New employee? Sign up', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2), decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                if (_selectedRole == 'Admin')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CreateAdminScreen()),
                          );
                        },
                        child: Text('Create Admin Account', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2), decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                SizedBox(height: 20),

                // Demo Credentials
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Removed demo credentials for security
                      // Text(
                      //   'Demo Credentials:',
                      //   style: TextStyle(fontWeight: FontWeight.bold),
                      // ),
                      // Text('Employee → ID: EMP001 | Password: password'),
                      // Text('Admin → ID: ADMIN | Password: password'),
                      Text(
                        'Please sign up or contact admin for credentials',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedButton(
    String label,
    bool isSelected,
    bool isFirst,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1976D2) : Colors.transparent,
          borderRadius: isFirst
              ? BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                )
              : BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class EmployeeSignUpScreen extends StatefulWidget {
  @override
  State<EmployeeSignUpScreen> createState() => _EmployeeSignUpScreenState();
}

class _EmployeeSignUpScreenState extends State<EmployeeSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final roleController = TextEditingController();
  String? _selectedDesignation;
  String? _selectedShift;
  String? _empId; // displayed
  bool _isLoading = false;
  final List<String> _designations = [
    'Software Development',
    'Web Development',
    'Digital Marketing',
    'Business Lead',
  ];
  final List<String> _shifts = [
    'Morning (9:00 AM - 6:00 PM)',
    'Night (9:00 PM - 6:00 AM)',
  ];

  @override
  void initState() {
    super.initState();
    _setEmpId();
  }
  Future<void> _setEmpId() async {
    await LocalStorageService.init();
    final employees = HybridStorageService.getEmployees();
    final idx = employees.length + 1;
    setState(() {
      _empId = 'EMP${idx.toString().padLeft(3, '0')}';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await LocalStorageService.init();
    final employees = HybridStorageService.getEmployees();
    // Check for unique email
    if (employees.any((e) => (e.email ?? '').toLowerCase() == emailController.text.trim().toLowerCase())) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email already registered.'), backgroundColor: Colors.red),
      );
      return;
    }
    // Create new employee
    final newEmployee = Employee(
      empId: _empId!,
      name: nameController.text.trim(),
      role: roleController.text.trim(),
      department: _selectedDesignation ?? '',
      shift: _selectedShift ?? 'Morning (9:00 AM - 6:00 PM)',
      status: 'Active',
      hourlyRate: 0,
      location: null,
      email: emailController.text.trim(),
    );
    employees.add(newEmployee);
    // Save via HybridStorageService (syncs to Firestore)
    await HybridStorageService.saveEmployee(newEmployee);
    
    // Create Firebase Authentication account for employee
    final password = passwordController.text.trim();
    if (newEmployee.email != null && newEmployee.email!.isNotEmpty) {
      print('🔐 Creating Firebase Auth account for employee ${newEmployee.empId}...');
      final authResult = await FirebaseService.createEmployeeAccount(
        newEmployee.email!,
        password,
        newEmployee.empId,
      );
      
      if (authResult['success'] == true) {
        print('✅ Firebase Auth account created successfully');
      } else {
        print('⚠️ Firebase Auth account creation failed: ${authResult['message']}');
        // Still allow signup but user will need to use fallback login
        // Save password locally as backup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('emp_login_id_${newEmployee.empId}', password);
        await prefs.setString('emp_login_email_${newEmployee.email}', password);
      }
    } else {
      print('⚠️ No email provided, saving password locally only');
      // Fallback: save password locally if no email
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emp_login_id_${newEmployee.empId}', password);
    }
    
    print('✅ Employee registration successful: ${newEmployee.empId}');
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful! Employee ID: $_empId'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Employee Sign Up'), backgroundColor: Color(0xFF1976D2)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 25),
              Text('Create Your Account', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold)),
              SizedBox(height: 30),
              // Emp ID preview
              if (_empId != null) ...[
                Text('Your Employee ID:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                SizedBox(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(_empId!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 2, color: Color(0xFF1976D2))),
                ),
                SizedBox(height: 18),
              ],
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (v) => v==null||v.trim().isEmpty ? 'Please enter name' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedDesignation,
                decoration: InputDecoration(labelText: 'Designation'),
                items: _designations.map((d)=>DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v)=>setState(()=>_selectedDesignation=v),
                validator: (v) => v==null ? 'Please select your designation' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedShift,
                decoration: InputDecoration(labelText: 'Shift'),
                items: _shifts.map((s)=>DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v)=>setState(()=>_selectedShift=v),
                validator: (v) => v==null ? 'Please select your shift' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: roleController,
                decoration: InputDecoration(labelText: 'Role'),
                validator: (v) => v==null||v.trim().isEmpty ? 'Please enter your role' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v==null || v.trim().isEmpty) return 'Please enter email';
                  if (!RegExp(r'^.+@.+\..+').hasMatch(v.trim())) return 'Enter a valid email';
                  return null;
                }
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v==null||v.length<6 ? 'Enter min 6 char password' : null,
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ),
              ),
              SizedBox(height: 18),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back to Login', style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
