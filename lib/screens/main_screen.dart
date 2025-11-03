import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/hybrid_storage_service.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import 'dashboard_screen.dart';
import 'attendance_screen.dart';
import 'leave_screen.dart';
import 'profile_screen.dart';
import 'employee_analytics_screen.dart';
import 'admin_main_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Employee? currentUser;
  bool _checkingRole = true;

  @override
  void initState() {
    super.initState();
    _verifyRoleAndInitialize();
  }

  Future<void> _verifyRoleAndInitialize() async {
    await LocalStorageService.init();
    
    // CRITICAL: Verify user is actually an Employee, not an Admin
    final userRole = LocalStorageService.getUserRole();
    print('🔍 MainScreen: Checking user role - $userRole');
    
    if (userRole == 'Admin') {
      print('⚠️ Admin user trying to access Employee screen - redirecting...');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AdminMainScreen()),
        );
        return;
      }
    }
    
    // Verify user is authenticated and is an Employee via Firebase Auth
    final firebaseUser = FirebaseService.getCurrentUser();
    if (firebaseUser != null) {
      // Check if this user is actually an admin in Firestore
      try {
        final isAdmin = await FirebaseService.checkIfAdmin(firebaseUser.uid);
        if (isAdmin) {
          print('⚠️ Firebase Auth user is an admin - redirecting to admin screen');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => AdminMainScreen()),
            );
            return;
          }
        }
      } catch (e) {
        print('Error checking admin status: $e');
      }
    }
    
    // User is verified as Employee - proceed
    _initializeUser();
  }

  void _initializeUser() {
    try {
      final employees = HybridStorageService.getEmployees();
      final userId = LocalStorageService.getUserId();
      
      if (userId != null && employees.isNotEmpty) {
        // Find the current logged-in employee
        final employee = employees.firstWhere(
          (e) => e.empId == userId,
          orElse: () => employees.first,
        );
        setState(() {
          currentUser = employee;
          _checkingRole = false;
        });
      } else {
        setState(() {
          _checkingRole = false;
        });
      }
    } catch (e) {
      print('Error loading user: $e');
      setState(() {
        _checkingRole = false;
      });
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
    if (_checkingRole) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying access...'),
            ],
          ),
        ),
      );
    }
    
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Unable to load employee data'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
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
