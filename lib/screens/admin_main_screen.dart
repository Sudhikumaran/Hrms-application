import 'package:flutter/material.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_analytics_screen.dart';
import 'admin/admin_employees_screen.dart';
import 'admin/admin_location_screen.dart';
import 'admin/admin_leaves_screen.dart';
import 'admin/admin_shifts_screen.dart';
import '../services/local_storage_service.dart';
import 'login_screen.dart';
// removed logout imports

class AdminMainScreen extends StatefulWidget {
  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    AdminDashboardScreen(),
    AdminAnalyticsScreen(),
    AdminEmployeesScreen(),
    AdminLeavesScreen(),
    AdminShiftsScreen(),
    AdminLocationScreen(),
  ];

  // titles removed with logout AppBar removal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Exit',
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await LocalStorageService.clearUser();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Color(0xFF1976D2),
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Employees',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_turned_in),
              label: 'Leaves',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Shifts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on),
              label: 'Location',
            ),
          ],
        ),
      ),
    );
  }
}
