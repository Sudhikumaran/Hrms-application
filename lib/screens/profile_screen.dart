import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../utils/mock_data.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  Employee get currentUser {
    try {
      if (MockData.employees.isNotEmpty) {
        return MockData.employees.first;
      } else {
        return Employee(
          empId: 'EMP001',
          name: 'Sudhi Kumaran',
          role: 'Frontend & Backend Developer',
          department: 'Development',
          shift: 'Morning',
          status: 'Active',
          hourlyRate: 200,
          location: Location(lat: 11.1085, lng: 77.3411),
        );
      }
    } catch (e) {
      return Employee(
        empId: 'EMP001',
        name: 'Sudhi Kumaran',
        role: 'Frontend & Backend Developer',
        department: 'Development',
        shift: 'Morning',
        status: 'Active',
        hourlyRate: 200,
        location: Location(lat: 11.1085, lng: 77.3411),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: Icon(Icons.edit), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
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
                      currentUser.name.substring(0, 2),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    currentUser.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentUser.role,
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
                      currentUser.empId,
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

            // Profile Information
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoSection('Personal Information', [
                    _buildInfoItem(
                      'Department',
                      currentUser.department,
                      Icons.business,
                    ),
                    _buildInfoItem('Shift', currentUser.shift, Icons.schedule),
                    _buildInfoItem(
                      'Status',
                      currentUser.status,
                      Icons.verified_user,
                    ),
                    _buildInfoItem(
                      'Hourly Rate',
                      '₹${currentUser.hourlyRate}',
                      Icons.attach_money,
                    ),
                  ]),
                  SizedBox(height: 20),
                  _buildInfoSection('Work Statistics', [
                    _buildInfoItem(
                      'Total Hours This Month',
                      '160 hrs',
                      Icons.timer,
                    ),
                    _buildInfoItem(
                      'Average Daily Hours',
                      '8.0 hrs',
                      Icons.schedule,
                    ),
                    _buildInfoItem('Tasks Completed', '15', Icons.task_alt),
                    _buildInfoItem('Attendance Rate', '95%', Icons.trending_up),
                  ]),
                  SizedBox(height: 20),
                  _buildInfoSection('Settings', [
                    _buildActionItem('Change Password', Icons.lock, () {}),
                    _buildActionItem(
                      'Notification Settings',
                      Icons.notifications,
                      () {},
                    ),
                    _buildActionItem(
                      'Privacy Settings',
                      Icons.privacy_tip,
                      () {},
                    ),
                    _buildActionItem('Help & Support', Icons.help, () {}),
                    _buildActionItem(
                      'Logout',
                      Icons.logout,
                      () => _showLogoutDialog(context),
                    ),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
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
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
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
