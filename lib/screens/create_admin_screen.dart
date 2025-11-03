import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../utils/create_admin_workaround.dart';
import 'admin_main_screen.dart';
import 'login_screen.dart';

/// Simple screen to create admin account with email and password
/// This is the recommended way to set up admin access
class CreateAdminScreen extends StatefulWidget {
  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _statusMessage;
  bool _statusSuccess = false;
  String? _firebaseStatus;

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  Future<void> _checkFirebaseStatus() async {
    try {
      final apps = Firebase.apps;
      if (apps.isEmpty) {
        setState(() {
          _firebaseStatus = '❌ Firebase NOT initialized - No apps found';
        });
        return;
      }
      
      final app = Firebase.app();
      setState(() {
        _firebaseStatus = '✅ Firebase initialized\nProject: ${app.options.projectId}';
      });
    } catch (e) {
      setState(() {
        _firebaseStatus = '❌ Firebase check failed: $e';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _statusMessage = 'Passwords do not match';
        _statusSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('📧 Creating admin account with email: $email');

      // Step 1: Create Firebase Auth account
      print('🔐 Step 1: Creating Firebase Auth account...');
      final authResult = await FirebaseService.createAdminAccount(email, password);
      
      if (authResult['success'] != true) {
        final errorMsg = authResult['message'] ?? 'Failed to create admin account';
        final errorCode = authResult['errorCode'] as String?;
        final fullError = authResult['error'] as String?;
        print('❌ Step 1 Failed: $errorMsg');
        print('❌ Error Code: $errorCode');
        print('❌ Full Error: $fullError');
        print('❌ Full Result: $authResult');
        
        // If configuration-not-found, try direct Firestore creation
        if (errorCode == '400' || (fullError?.contains('CONFIGURATION_NOT_FOUND') ?? false)) {
          print('⚠️ Configuration error detected, trying direct Firestore creation...');
          setState(() {
            _statusMessage = 'Firebase Auth configuration issue. Creating admin directly in Firestore...';
            _statusSuccess = false;
          });
          
          final directResult = await CreateAdminWorkaround.createAdminDirectly(
            email: email,
            password: password,
          );
          
          if (directResult['success'] == true) {
            final uid = directResult['uid'] as String?;
            print('✅ Admin created directly in Firestore with UID: $uid');
            
            // Navigate to admin screen
            await LocalStorageService.init();
            await LocalStorageService.saveUser(uid ?? email, 'Admin');
            
            if (!mounted) return;
            
            setState(() {
              _isLoading = false;
              _statusMessage = 'Admin account created successfully in Firestore!';
              _statusSuccess = true;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Admin account created! Logging you in...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            await Future.delayed(Duration(seconds: 2));
            
            if (!mounted) return;
            
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => AdminMainScreen()),
              (route) => false,
            );
            return;
          } else {
            // Direct creation also failed
            setState(() {
              _isLoading = false;
              _statusMessage = 'Both methods failed. ${directResult['message']}';
              _statusSuccess = false;
            });
            return;
          }
        }
        
        // If email already exists, suggest using login instead
        if (errorCode == 'email-already-in-use' || errorCode == 'EMAIL_EXISTS') {
          setState(() {
            _isLoading = false;
            _statusMessage = errorMsg;
            _statusSuccess = false;
          });
          
          // Show additional dialog with option to go to login
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Email Already Registered'),
                content: Text('This email is already registered. Would you like to go to the login screen?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Stay Here'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text('Go to Login'),
                  ),
                ],
              ),
            );
          }
        } else {
          // Show detailed error message
          String displayMsg = errorMsg;
          if (fullError != null && fullError.isNotEmpty && !fullError.contains(errorMsg)) {
            displayMsg += '\n\nError: $fullError';
          }
          if (errorCode != null && errorCode != 'unknown' && !displayMsg.contains(errorCode)) {
            displayMsg += '\nCode: $errorCode';
          }
          
          setState(() {
            _isLoading = false;
            _statusMessage = displayMsg;
            _statusSuccess = false;
          });
        }
        return;
      }

      final uid = authResult['uid'] as String?;
      print('✅ Step 1 Complete: Firebase Auth account created with UID: $uid');

      // Step 2: Create admin document in Firestore
      if (uid != null) {
        print('📝 Step 2: Creating admin document in Firestore...');
        try {
          final setupResult = await FirebaseService.forceSetupAdmin(uid, email);
          
          if (setupResult['success'] != true) {
            print('⚠️ Admin document setup failed, but account created. Trying again...');
            print('⚠️ Error: ${setupResult['message']}');
            // Wait and retry
            await Future.delayed(Duration(seconds: 2));
            final retryResult = await FirebaseService.forceSetupAdmin(uid, email);
            if (retryResult['success'] != true) {
              print('❌ Step 2 Failed after retry: ${retryResult['message']}');
              setState(() {
                _isLoading = false;
                _statusMessage = 'Firebase Auth account created, but admin document setup failed.\n\nPossible issues:\n• Firestore Database not enabled\n• Firestore security rules blocking write access\n• Network connectivity issue\n\nError: ${retryResult['message']}';
                _statusSuccess = false;
              });
              return;
            }
          }
          print('✅ Step 2 Complete: Admin document created in Firestore');
        } catch (e) {
          print('❌ Step 2 Exception: $e');
          setState(() {
            _isLoading = false;
            _statusMessage = 'Error creating admin document: $e';
            _statusSuccess = false;
          });
          return;
        }
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Account created but UID is missing';
          _statusSuccess = false;
        });
        return;
      }

      // Step 3: Store locally and navigate
      await LocalStorageService.init();
      await LocalStorageService.saveUser((uid != null && uid.isNotEmpty) ? uid : email, 'Admin');
      
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _statusMessage = 'Admin account created successfully!';
        _statusSuccess = true;
      });

      // Show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin account created successfully! Logging you in...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to admin screen after short delay
      await Future.delayed(Duration(seconds: 2));
      
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AdminMainScreen()),
        (route) => false,
      );

    } catch (e, stackTrace) {
      print('❌ Error creating admin account: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        String errorMsg = 'An unexpected error occurred: $e';
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMsg = 'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('firestore') || e.toString().contains('Firestore')) {
          errorMsg = 'Firestore connection error. Please ensure:\n• Firestore Database is enabled in Firebase Console\n• Firestore security rules allow writes to "admins" collection';
        }
        _statusMessage = errorMsg;
        _statusSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Admin Account'),
        backgroundColor: Color(0xFF1976D2),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Icon(
                Icons.admin_panel_settings,
                size: 100,
                color: Color(0xFF1976D2),
              ),
              SizedBox(height: 20),
              Text(
                'Create Admin Account',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Enter your email and password to create an admin account.\nThis will set up both Firebase Authentication and admin access.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              
              // Firebase Status Display
              if (_firebaseStatus != null)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _firebaseStatus!.startsWith('✅') 
                        ? Colors.green[50] 
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _firebaseStatus!.startsWith('✅') 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _firebaseStatus!.startsWith('✅') 
                            ? Icons.check_circle 
                            : Icons.warning,
                        color: _firebaseStatus!.startsWith('✅') 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _firebaseStatus!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              
              // Email field
              Text(
                'Admin Email',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'admin@fortumars.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              
              // Password field
              Text(
                'Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Enter password (min 6 characters)',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              
              // Confirm password field
              Text(
                'Confirm Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  hintText: 'Re-enter password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              
              // Status message
              if (_statusMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusSuccess ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _statusSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusSuccess ? Icons.check_circle : Icons.error,
                        color: _statusSuccess ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _statusSuccess ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
              
              // Create button
              ElevatedButton(
                onPressed: _isLoading ? null : _createAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Create Admin Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              SizedBox(height: 20),
              
              // Back to login
              TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  'Back to Login',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

