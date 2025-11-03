import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Seed initial employee data
  static Future<void> seedInitialData() async {
    try {
      // Check if data already exists
      final existingEmployees = await _firestore.collection('employees').get();
      if (existingEmployees.docs.isNotEmpty) {
        print('Data already seeded. Skipping...');
        return;
      }

      // Create sample employee
      // Note: Password should be set by user during registration, not hardcoded
      final employeeData = {
        'employeeId': 'EMP001',
        'name': 'Sudhi Kumaran',
        'email': 'sudhi.kumaran@fortumars.com',
        // Password removed for security - must be set during user registration
        'role': 'Frontend & Backend Developer',
        'department': 'Software Development',
        'shift': 'Day Shift (9:00 AM - 6:00 PM)',
        'status': 'Active',
        'hourlyRate': 200,
        'sickLeaveBalance': 10,
        'casualLeaveBalance': 15,
        'annualLeaveBalance': 20,
        'emergencyLeaveBalance': 5,
        'maternityLeaveBalance': 0,
        'totalHoursThisMonth': 0,
        'tasksPending': 5,
        'monthlyHours': 160,
        'leaveBalance': 15,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await _firestore.collection('employees').add(employeeData);
      print('Initial data seeded successfully!');
    } catch (e) {
      print('Error seeding data: $e');
    }
  }

  // Seed sample tasks
  static Future<void> seedSampleTasks() async {
    try {
      final existingTasks = await _firestore.collection('tasks').get();
      if (existingTasks.docs.isNotEmpty) {
        print('Tasks already seeded. Skipping...');
        return;
      }

      final tasks = [
        {
          'title': 'Complete HRM App Backend',
          'description': 'Implement Firebase integration and backend logic',
          'assignedTo': 'EMP001',
          'priority': 'High',
          'status': 'In Progress',
          'estimatedHours': 8,
          'deadline': DateTime.now().add(Duration(days: 7)),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'UI/UX Improvements',
          'description': 'Enhance app design and user experience',
          'assignedTo': 'EMP001',
          'priority': 'Medium',
          'status': 'Pending',
          'estimatedHours': 4,
          'deadline': DateTime.now().add(Duration(days: 14)),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Testing and Bug Fixes',
          'description': 'Perform comprehensive testing and fix issues',
          'assignedTo': 'EMP001',
          'priority': 'High',
          'status': 'Pending',
          'estimatedHours': 6,
          'deadline': DateTime.now().add(Duration(days: 5)),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final task in tasks) {
        await _firestore.collection('tasks').add(task);
      }

      print('Sample tasks seeded successfully!');
    } catch (e) {
      print('Error seeding tasks: $e');
    }
  }

  // Seed sample attendance records
  static Future<void> seedSampleAttendance() async {
    try {
      final existingAttendance = await _firestore
          .collection('attendance')
          .get();
      if (existingAttendance.docs.isNotEmpty) {
        print('Tasks already seeded. Skipping...');
        return;
      }

      // Create sample attendance for today
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final attendanceData = {
        'employeeId': 'EMP001',
        'method': 'manual_entry',
        'checkInTime': Timestamp.fromDate(today.subtract(Duration(hours: 8))),
        'date': todayStr,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'checked-in',
        'additionalData': {},
      };

      await _firestore.collection('attendance').add(attendanceData);
      print('Sample attendance seeded successfully!');
    } catch (e) {
      print('Error seeding attendance: $e');
    }
  }

  // Run all seeding operations
  static Future<void> seedAllData() async {
    print('Starting data seeding...');
    await seedInitialData();
    await seedSampleTasks();
    await seedSampleAttendance();
    print('Data seeding completed!');
  }
}
