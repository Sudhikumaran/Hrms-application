import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_storage_service.dart';
import 'main_screen.dart';
import 'admin_main_screen.dart';
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
          final employees = LocalStorageService.getEmployees();
          Employee? found;
          for (final e in employees) {
            if (e.empId.toLowerCase() == input.toLowerCase() ||
                (e.email != null && e.email!.toLowerCase() == input.toLowerCase())) {
              found = e;
              break;
            }
          }
          if (found != null) {
            final prefs = await SharedPreferences.getInstance();
            final passEmail = prefs.getString('emp_login_email_${found.email}') ?? '';
            final passId = prefs.getString('emp_login_id_${found.empId}') ?? '';
            if (pwd == passEmail || pwd == passId) {
              await LocalStorageService.saveUser(found.empId, 'Employee');
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => MainScreen()),
              );
              isValid = true;
            }
          }
        } else if (_selectedRole == 'Admin' && input == 'ADMIN' && pwd == 'password') {
          await LocalStorageService.saveUser(input, 'Admin');
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AdminMainScreen()),
          );
          isValid = true;
        }
        if (!isValid && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid credentials'),
              backgroundColor: Colors.red,
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
                    labelText: _selectedRole == 'Employee' ? 'Employee ID' : 'Admin ID',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your ${_selectedRole == 'Employee' ? 'Employee' : 'Admin'} ID';
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
                      Text(
                        'Demo Credentials:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Employee → ID: EMP001 | Password: password'),
                      Text('Admin → ID: ADMIN | Password: password'),
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
    final employees = LocalStorageService.getEmployees();
    final idx = employees.length + 1;
    setState(() {
      _empId = 'EMP${idx.toString().padLeft(3, '0')}';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await LocalStorageService.init();
    final employees = LocalStorageService.getEmployees();
    // Check for unique email
    if (employees.any((e) => (e.email ?? '').toLowerCase() == emailController.text.trim().toLowerCase())) {
      setState(() => _isLoading = false);
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
    await LocalStorageService.saveEmployees(employees);
    // Save login (demo: plain for now)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emp_login_email_${newEmployee.email}', passwordController.text);
    await prefs.setString('emp_login_id_${newEmployee.empId}', passwordController.text);
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
