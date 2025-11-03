import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/setup_all_auth.dart';

/// Screen to set up Firebase Authentication for all employees and admin
class SetupAuthScreen extends StatefulWidget {
  @override
  State<SetupAuthScreen> createState() => _SetupAuthScreenState();
}

class _SetupAuthScreenState extends State<SetupAuthScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  bool _statusSuccess = false;
  Map<String, dynamic>? _results;

  Future<void> _setupAllAuth() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up Firebase Authentication for all users...';
      _statusSuccess = false;
      _results = null;
    });

    try {
      final result = await SetupAllAuth.setupAllAuth();
      
      setState(() {
        _isLoading = false;
        _statusMessage = result['message'] as String?;
        _statusSuccess = result['success'] == true;
        _results = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _statusMessage ?? 'Setup completed',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: _statusSuccess ? Colors.green : Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
        _statusSuccess = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setupEmployeesOnly() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up Firebase Authentication for all employees...';
      _statusSuccess = false;
      _results = null;
    });

    try {
      final result = await SetupAllAuth.setupEmployeesAuth();
      
      setState(() {
        _isLoading = false;
        _statusMessage = result['message'] as String?;
        _statusSuccess = result['success'] == true;
        _results = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _statusMessage ?? 'Setup completed',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: _statusSuccess ? Colors.green : Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
        _statusSuccess = false;
      });
    }
  }

  Future<void> _setupAdminOnly() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up Firebase Authentication for admin...';
      _statusSuccess = false;
      _results = null;
    });

    try {
      final result = await SetupAllAuth.setupAdminAuth();
      
      setState(() {
        _isLoading = false;
        _statusMessage = result['message'] as String?;
        _statusSuccess = result['success'] == true;
        _results = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _statusMessage ?? 'Setup completed',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: _statusSuccess ? Colors.green : Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
        _statusSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Authentication'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.vpn_key, size: 80, color: Color(0xFF1976D2)),
            SizedBox(height: 20),
            Text(
              'Firebase Authentication Setup',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Create Firebase Auth accounts for all employees and admin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            
            if (_statusMessage != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusSuccess ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusSuccess ? Colors.green : Colors.orange,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _statusSuccess ? Icons.check_circle : Icons.info,
                          color: _statusSuccess ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              color: _statusSuccess ? Colors.green[900] : Colors.orange[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_results != null && _results!['employees'] != null) ...[
                      SizedBox(height: 12),
                      _buildResultSection('Employees', _results!['employees']),
                    ],
                    if (_results != null && _results!['admin'] != null) ...[
                      SizedBox(height: 12),
                      _buildResultSection('Admin', _results!['admin']),
                    ],
                  ],
                ),
              ),
            
            if (_statusMessage != null) SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _setupAllAuth,
              icon: Icon(Icons.supervised_user_circle),
              label: Text('Setup All (Employees + Admin)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            
            SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _setupEmployeesOnly,
              icon: Icon(Icons.people),
              label: Text('Setup Employees Only'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _setupAdminOnly,
              icon: Icon(Icons.admin_panel_settings),
              label: Text('Setup Admin Only'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            if (_isLoading) ...[
              SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Setting up authentication...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This may take a few minutes',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 30),
            Divider(),
            SizedBox(height: 20),
            
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Important Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('• Employees must have email addresses and passwords stored locally'),
                  Text('• If Firebase Auth is not configured, accounts will be skipped'),
                  Text('• Existing accounts will be skipped (not an error)'),
                  Text('• Employees can still login via local password if Firebase Auth fails'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String title, Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          if (data['created'] != null)
            Text('✓ Created: ${data['created']}'),
          if (data['skipped'] != null)
            Text('○ Skipped: ${data['skipped']}'),
          if (data['failed'] != null && (data['failed'] as int) > 0)
            Text('✗ Failed: ${data['failed']}', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

