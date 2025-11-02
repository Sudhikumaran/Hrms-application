import '../models/employee.dart';
import '../models/attendance_record.dart';
import '../models/leave_request.dart';

// Mock Data - Deprecated: App now uses LocalStorageService for all data
// This file is kept for backward compatibility but should not be used
class MockData {
  static List<Employee> get employees => [];

  static Map<String, List<AttendanceRecord>> get attendanceData => {};

  static List<dynamic> get tasks => [];

  static List<LeaveRequest> get leaveRequests => [];
}
