import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/admin_setup_helper.dart';

/// One-time admin setup screen
/// Use this screen once to set up admin documents in Firestore
class AdminSetupScreen extends StatefulWidget {
  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _uidController = TextEditingController();
  final _emailController = TextEditingController(
    text: 'ceo@fortumars.com', // Pre-filled with CEO email
  );
  bool _isLoading = false;
  String? _resultMessage;
  bool _resultSuccess = false;

  @override
  void dispose() {
    _uidController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _setupAdmin() async {
    final email = _emailController.text.trim();
    final uid = _uidController.text.trim();

    if (email.isEmpty && uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an email or UID')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    Map<String, dynamic> result;
    if (uid.isNotEmpty) {
      // Use provided UID
      result = await AdminSetupHelper.setupAdminDocument(
        uid,
        email: email.isEmpty ? null : email,
      );
    } else {
      // Use current user if signed in, otherwise error
      result = await AdminSetupHelper.setupCurrentUserAsAdmin();
      if (!result['success'] && email.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please sign in with $email first, then run this setup. Or provide the UID manually.'),
          ),
        );
      }
    }

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
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _setupCurrentUser() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    final result = await AdminSetupHelper.setupCurrentUserAsAdmin();

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
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Setup'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Setup Admin Document',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'This will create the admin document in Firestore.\nRun this once after creating admin user in Firebase Authentication.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
            Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'ceo@fortumars.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            Text(
              'UID (optional - auto-setup will use current user if empty)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _uidController,
              decoration: InputDecoration(
                hintText: 'Enter Firebase UID (leave empty for auto-setup)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _setupAdmin,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Setup Admin Document',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            SizedBox(height: 15),
            Divider(),
            SizedBox(height: 15),
            Text(
              'OR Setup Current User',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'If you\'re already signed in as admin, use this button',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            SizedBox(height: 15),
            OutlinedButton(
              onPressed: _isLoading ? null : _setupCurrentUser,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Setup Current User as Admin'),
            ),
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
          ],
        ),
      ),
    );
  }
}

