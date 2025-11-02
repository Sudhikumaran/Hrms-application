import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/local_storage_service.dart';
import 'admin_employees_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_location_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final employees = LocalStorageService.getEmployees();
    final totalMembers = employees.length;
    final activeMembers = employees.where((e) => e.status == 'Active').length;
    
    // Calculate unique departments and shifts
    final departments = employees.map((e) => e.department).toSet().length;
    final shifts = employees.map((e) => e.shift).toSet().length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Dashboard Overview',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Members',
                    totalMembers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active Members',
                    activeMembers.toString(),
                    Icons.person,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Departments',
                    departments.toString(),
                    Icons.business,
                    Colors.purple,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Shifts',
                    shifts.toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 15),
            _buildActionCard(
              'View All Employees',
              'Manage employee details',
              Icons.people_outline,
              Colors.blue,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AdminEmployeesScreen()),
                );
              },
            ),
            SizedBox(height: 12),
            _buildActionCard(
              'View Analytics',
              'Daily attendance insights',
              Icons.analytics_outlined,
              Colors.green,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AdminAnalyticsScreen()),
                );
              },
            ),
            SizedBox(height: 12),
            _buildActionCard(
              'Manage Location',
              'Set office location',
              Icons.location_on,
              Colors.red,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AdminLocationScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
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
        children: [
          Icon(icon, color: color),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
