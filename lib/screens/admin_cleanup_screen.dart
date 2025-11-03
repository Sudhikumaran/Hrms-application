import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/firestore_cleanup.dart';
import '../utils/test_admin_login.dart';
import '../utils/demo_admin_helper.dart';

/// Admin screen for cleaning up Firestore data
class AdminCleanupScreen extends StatefulWidget {
  @override
  State<AdminCleanupScreen> createState() => _AdminCleanupScreenState();
}

class _AdminCleanupScreenState extends State<AdminCleanupScreen> {
  bool _isLoading = false;
  String? _resultMessage;
  bool _resultSuccess = false;
  int _employeeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEmployeeCount();
  }

  Future<void> _loadEmployeeCount() async {
    final count = await FirestoreCleanup.getEmployeeCount();
    setState(() {
      _employeeCount = count;
    });
  }

  Future<void> _deleteAllEmployees() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Delete All Employees?'),
        content: Text(
          'This will PERMANENTLY delete ALL $_employeeCount employee documents from Firestore.\n\n'
          'This action cannot be undone!\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    final result = await FirestoreCleanup.deleteAllEmployees();

    setState(() {
      _isLoading = false;
      _resultSuccess = result['success'] == true;
      _resultMessage = result['message'] ?? 'Unknown result';
      _employeeCount = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_resultMessage!),
          backgroundColor: _resultSuccess ? Colors.green : Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _testAdminLogin() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    final result = await TestAdminLogin.runDiagnostics(
      email: 'ceo@fortumars.com',
      password: 'Ceo@Fortumars#1989',
    );

    String message = 'Diagnostics complete!\n\n';
    
    if (result['authCheck'] == true) {
      message += '✅ Authentication: Working\n';
      message += '   UID: ${result['uid']}\n\n';
    } else {
      message += '❌ Authentication: Failed\n\n';
    }
    
    if (result['firestoreCheck'] == true) {
      message += '✅ Firestore: Accessible\n\n';
    } else {
      message += '❌ Firestore: Not accessible\n\n';
    }
    
    if (result['adminDocCheck'] == true) {
      message += '✅ Admin Document: Exists and valid\n\n';
    } else {
      message += '❌ Admin Document: Missing or invalid\n\n';
    }
    
    if ((result['issues'] as List).isNotEmpty) {
      message += 'Issues found:\n';
      for (var issue in result['issues']) {
        message += '• $issue\n';
      }
    } else {
      message += '✅ All checks passed! Login should work.';
    }

    setState(() {
      _isLoading = false;
      _resultSuccess = result['authCheck'] == true && 
                       result['firestoreCheck'] == true && 
                       result['adminDocCheck'] == true;
      _resultMessage = message;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Diagnostics Results'),
          content: SingleChildScrollView(
            child: Text(_resultMessage!, style: TextStyle(fontFamily: 'monospace')),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _removeDuplicates() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    final result = await FirestoreCleanup.removeDuplicateEmployees();

    setState(() {
      _isLoading = false;
      _resultSuccess = result['success'] == true;
      _resultMessage = result['message'] ?? 'Unknown result';
    });

    // Reload count
    await _loadEmployeeCount();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_resultMessage!),
          backgroundColor: _resultSuccess ? Colors.green : Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firestore Cleanup'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.delete_sweep, size: 80, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Firestore Data Cleanup',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Current employee documents: $_employeeCount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            
            // Test Admin Login
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Admin Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Run diagnostics to find why login is failing',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testAdminLogin,
                      icon: Icon(Icons.bug_report),
                      label: Text('Run Diagnostics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Remove Duplicates Option
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remove Duplicates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Keeps one document per empId and deletes duplicates. Safe to use.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _removeDuplicates,
                      icon: Icon(Icons.filter_alt),
                      label: Text('Remove Duplicates'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Delete All Option
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete All Employees',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '⚠️ WARNING: This will delete ALL employee documents permanently!',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _deleteAllEmployees,
                      icon: Icon(Icons.delete_forever),
                      label: Text('Delete All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_isLoading) ...[
              SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing...'),
                  ],
                ),
              ),
            ],
            
            if (_resultMessage != null) ...[
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _resultSuccess ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _resultSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _resultSuccess ? Icons.check_circle : Icons.error,
                      color: _resultSuccess ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _resultMessage!,
                        style: TextStyle(
                          color: _resultSuccess ? Colors.green[900] : Colors.red[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 30),
            Divider(),
            SizedBox(height: 20),
            
            // Demo Admin Setup Section
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Admin Setup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo Credentials:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text('Email: ${DemoAdminHelper.demoEmail}'),
                          Text('Password: ${DemoAdminHelper.demoPassword}'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚠️ First create user in Firebase Authentication console with these credentials, then click "Setup Demo Admin" below.',
                        style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _setupDemoAdmin,
                      icon: Icon(Icons.admin_panel_settings),
                      label: Text('Setup Demo Admin Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setupDemoAdmin() async {
    // Show dialog to get UID
    final uidController = TextEditingController();
    final emailController = TextEditingController(text: DemoAdminHelper.demoEmail);

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Setup Demo Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'First, create a user in Firebase Authentication:\n'
                '- Email: ${DemoAdminHelper.demoEmail}\n'
                '- Password: ${DemoAdminHelper.demoPassword}\n\n'
                'Then enter the User UID below:',
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: uidController,
                decoration: InputDecoration(
                  labelText: 'User UID (from Firebase Authentication)',
                  border: OutlineInputBorder(),
                  hintText: 'Paste UID here',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Setup'),
          ),
        ],
      ),
    );

    if (shouldProceed != true || uidController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    final result = await DemoAdminHelper.setupDemoAdmin(
      uid: uidController.text.trim(),
      email: emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _resultSuccess = result['success'] == true;
      _resultMessage = result['message'] ?? 'Unknown result';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_resultMessage!),
          backgroundColor: _resultSuccess ? Colors.green : Colors.red,
          duration: Duration(seconds: 5),
        ),
      );

      if (_resultSuccess) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('✅ Demo Admin Ready!'),
            content: Text(
              'Demo admin document created successfully!\n\n'
              'You can now login with:\n'
              'Email: ${result['credentials']?['email'] ?? DemoAdminHelper.demoEmail}\n'
              'Password: ${result['credentials']?['password'] ?? DemoAdminHelper.demoPassword}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

