import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_analytics_screen.dart';
import 'admin/admin_employees_screen.dart';
import 'admin/admin_location_screen.dart';
import 'admin/admin_leaves_screen.dart';
import 'admin/admin_shifts_screen.dart';
import 'admin/admin_profile_screen.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AdminMainScreen extends StatefulWidget {
  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  bool _checkingRole = true;

  @override
  void initState() {
    super.initState();
    _verifyAdminAccess();
  }

  Future<void> _verifyAdminAccess() async {
    await LocalStorageService.init();
    
    // CRITICAL: Verify user is actually an Admin, not an Employee
    final userRole = LocalStorageService.getUserRole();
    print('🔍 AdminMainScreen: Checking user role - $userRole');
    
    if (userRole == 'Employee') {
      print('⚠️ Employee user trying to access Admin screen - redirecting...');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
        return;
      }
    }
    
    // Check admin status - handle both Firebase Auth and direct Firestore admins
    final firebaseUser = FirebaseService.getCurrentUser();
    final userId = LocalStorageService.getUserId();
    bool isAdmin = false;
    
    if (firebaseUser != null) {
      // User authenticated via Firebase Auth - check by UID
      try {
        isAdmin = await FirebaseService.checkIfAdmin(firebaseUser.uid);
        print('🔍 Admin check via Firebase Auth UID: $isAdmin');
      } catch (e) {
        print('Error checking admin status: $e');
      }
    } else if (userId != null) {
      // No Firebase Auth user - might be direct Firestore admin
      print('⚠️ No Firebase Auth user, checking direct admin with UID: $userId');
      try {
        // Check if this UID exists in admins collection (direct admin)
        isAdmin = await FirebaseService.checkIfAdmin(userId);
        print('🔍 Admin check via stored UID: $isAdmin');
        
        // Also check by email if we have it stored
        if (!isAdmin) {
          final prefs = await SharedPreferences.getInstance();
          final userEmail = prefs.getString('userEmail');
          if (userEmail != null && userEmail.isNotEmpty) {
            print('🔍 Checking admin by email: $userEmail');
            isAdmin = await FirebaseService.checkIfAdminByEmail(userEmail);
            print('🔍 Admin check via email: $isAdmin');
          }
        }
      } catch (e) {
        print('Error checking direct admin status: $e');
      }
    }
    
    if (!isAdmin) {
      print('⚠️ User is not an admin - redirecting to login');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return;
      }
    } else {
      print('✅ Admin access verified');
      setState(() {
        _checkingRole = false;
      });
    }
  }

  final List<Widget> _screens = [
    AdminDashboardScreen(),
    AdminAnalyticsScreen(),
    AdminEmployeesScreen(),
    AdminLeavesScreen(),
    AdminShiftsScreen(),
    AdminLocationScreen(),
    AdminProfileScreen(),
  ];

  // titles removed with logout AppBar removal

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
              Text('Verifying admin access...'),
            ],
          ),
        ),
      );
    }
    
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
              // Sign out from Firebase Auth
              await FirebaseService.signOut();
              // Clear local storage
              await LocalStorageService.clearUser();
              if (!mounted) return;
              if (!context.mounted) return;
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
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
