import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/employee.dart';
import '../services/local_storage_service.dart';
import '../services/hybrid_storage_service.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Employee? _currentUser;
  double _totalHoursThisMonth = 0;
  double _averageDailyHours = 0;
  double _attendanceRate = 0;
  int _wfhDays = 0;
  bool _isLoading = true;

  Employee get _fallbackUser => Employee(
        empId: 'DEMO',
        name: 'Guest User',
        role: 'Employee',
        department: 'General',
        shift: 'Morning (9:00 AM - 6:00 PM)',
        status: 'Active',
        hourlyRate: 0,
        location: null,
        email: null,
      );

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await LocalStorageService.init();
    final userId = LocalStorageService.getUserId();
    Employee? user;
    if (userId != null) {
      final employees = HybridStorageService.getEmployees();
      if (employees.isNotEmpty) {
        user = employees.firstWhere(
          (e) => e.empId == userId,
          orElse: () => employees.first,
        );
      }
    }
    user ??= _fallbackUser;

    final records = HybridStorageService.getAttendance(userId ?? user.empId);
    final now = DateTime.now();
    final monthKey = DateFormat('yyyyMM').format(now);
    final monthRecords = records.where((r) => r.date.startsWith(monthKey)).toList();
    double totalHours = monthRecords.fold(0, (sum, r) => sum + r.hours);
    double averageDailyHours = monthRecords.isNotEmpty ? totalHours / monthRecords.length : 0;
    final presentStatuses = {'PRESENT', 'WFH', 'LATE'};
    final presentDays = monthRecords.where((r) => presentStatuses.contains(r.status.toUpperCase())).length;
    final wfhDays = monthRecords.where((r) => r.status.toUpperCase() == 'WFH').length;
    final firstDay = DateTime(now.year, now.month, 1);
    final daysElapsed = now.difference(firstDay).inDays + 1;
    final attendanceRate = daysElapsed > 0 ? ((presentDays / daysElapsed) * 100).clamp(0, 100).toDouble() : 0.0;

    setState(() {
      _currentUser = user;
      _totalHoursThisMonth = totalHours;
      _averageDailyHours = averageDailyHours;
      _attendanceRate = attendanceRate;
      _wfhDays = wfhDays;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser ?? _fallbackUser;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Text(
                            user.name.isNotEmpty ? user.name.substring(0, 1) : user.empId.substring(0, 1),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          user.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.role,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            user.empId,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoSection('Personal Information', [
                          _buildInfoItem('Department', user.department, Icons.business),
                          _buildInfoItem('Shift', user.shift, Icons.schedule),
                          _buildInfoItem('Status', user.status, Icons.verified_user),
                          if (user.email != null)
                            _buildInfoItem('Email', user.email!, Icons.email),
                        ]),
                        SizedBox(height: 20),
                        _buildInfoSection('Work Statistics', [
                          _buildInfoItem('Total Hours This Month', '${_totalHoursThisMonth.toStringAsFixed(1)} hrs', Icons.timer),
                          _buildInfoItem('Average Daily Hours', '${_averageDailyHours.toStringAsFixed(1)} hrs', Icons.schedule),
                          _buildInfoItem('WFH Days', '$_wfhDays', Icons.home_work),
                          _buildInfoItem('Attendance Rate', '${_attendanceRate.toStringAsFixed(0)}%', Icons.trending_up),
                        ]),
                        SizedBox(height: 20),
                        _buildInfoSection('Settings', [
                          _buildActionItem('Change Password', Icons.lock, () => _showChangePasswordDialog(user)),
                          _buildActionItem('Logout', Icons.logout, () => _showLogoutDialog(context)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(Employee user) async {
    final email = user.email;
    final empId = user.empId;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email not available for this user.')));
      return;
    }
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Current Password'),
                enabled: !isLoading,
              ),
              SizedBox(height: 16),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'New Password'),
                enabled: !isLoading,
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm New Password'),
                enabled: !isLoading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: isLoading ? null : () async {
                final currentPass = currentController.text.trim();
                final newPass = newController.text.trim();
                final confirm = confirmController.text.trim();
                
                if (currentPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter current password.')),
                  );
                  return;
                }
                
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('New password must be at least 6 characters.')),
                  );
                  return;
                }
                
                if (newPass != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('New passwords do not match.')),
                  );
                  return;
                }
                
                setState(() => isLoading = true);
                
                // Use FirebaseService.changePassword for proper password update
                final result = await FirebaseService.changePassword(
                  currentPassword: currentPass,
                  newPassword: newPass,
                );
                
                setState(() => isLoading = false);
                
                if (!ctx.mounted) return;
                
                if (result['success'] == true) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Password updated successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Password update failed.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: isLoading 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
