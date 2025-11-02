import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/local_storage_service.dart';
import 'dashboard_screen.dart';
import 'attendance_screen.dart';
import 'leave_screen.dart';
import 'profile_screen.dart';
import 'employee_analytics_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Employee? currentUser;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    try {
      final employees = LocalStorageService.getEmployees();
      if (employees.isNotEmpty) {
        setState(() {
          currentUser = employees.first;
        });
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  final List<Widget> _screens = [
    DashboardScreen(),
    AttendanceScreen(),
    EmployeeAnalyticsScreen(),
    LeaveScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Defensive clamp
    final numTabs = _screens.length;
    if (_currentIndex < 0 || _currentIndex >= numTabs) _currentIndex = 0;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Color(0xFF1976D2),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Leave'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
