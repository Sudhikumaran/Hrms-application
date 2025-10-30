import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/employee.dart';
import '../models/attendance_record.dart';
import '../models/leave_request.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth methods
  static Future<bool> saveUser(String userId, String role) async {
    await _prefs?.setString('userId', userId);
    await _prefs?.setString('userRole', role);
    return true;
  }

  static String? getUserId() => _prefs?.getString('userId');
  static String? getUserRole() => _prefs?.getString('userRole');

  static Future<bool> clearUser() async {
    await _prefs?.remove('userId');
    await _prefs?.remove('userRole');
    return true;
  }

  // Employee storage
  static Future<bool> saveEmployees(List<Employee> employees) async {
    final jsonList = employees.map((e) => e.toJson()).toList();
    return await _prefs?.setString('employees', jsonEncode(jsonList)) ?? false;
  }

  static Future<bool> updateEmployee(Employee updated) async {
    final employees = getEmployees();
    final idx = employees.indexWhere((e) => e.empId == updated.empId);
    if (idx >= 0) {
      employees[idx] = updated;
    } else {
      employees.add(updated);
    }
    return await saveEmployees(employees);
  }

  static List<Employee> getEmployees() {
    final jsonString = _prefs?.getString('employees');
    if (jsonString == null) return [];
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((e) => Employee.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Attendance storage
  static Future<bool> saveAttendance(String empId, AttendanceRecord record) async {
    final key = 'attendance_$empId';
    final existing = getAttendance(empId);
    existing.add(record);
    final jsonList = existing.map((e) => e.toJson()).toList();
    return await _prefs?.setString(key, jsonEncode(jsonList)) ?? false;
  }

  // Upsert attendance for a specific date (replace if same date exists)
  static Future<bool> upsertAttendance(String empId, AttendanceRecord record) async {
    final key = 'attendance_$empId';
    final existing = getAttendance(empId);
    final idx = existing.indexWhere((r) => r.date == record.date);
    if (idx >= 0) {
      existing[idx] = record;
    } else {
      existing.add(record);
    }
    final jsonList = existing.map((e) => e.toJson()).toList();
    return await _prefs?.setString(key, jsonEncode(jsonList)) ?? false;
  }

  static List<AttendanceRecord> getAttendance(String empId) {
    final key = 'attendance_$empId';
    final jsonString = _prefs?.getString(key);
    if (jsonString == null) return [];
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((e) => AttendanceRecord.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Leave requests storage
  static Future<bool> saveLeaveRequests(List<LeaveRequest> requests) async {
    final jsonList = requests.map((e) => e.toJson()).toList();
    return await _prefs?.setString('leaveRequests', jsonEncode(jsonList)) ?? false;
  }

  static List<LeaveRequest> getLeaveRequests() {
    final jsonString = _prefs?.getString('leaveRequests');
    if (jsonString == null) return [];
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((e) => LeaveRequest.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addLeaveRequest(LeaveRequest request) async {
    final existing = getLeaveRequests();
    existing.add(request);
    return await saveLeaveRequests(existing);
  }

  // Pending attendance queue (for offline actions)
  static const String _pendingAttendanceKey = 'pending_attendance';

  static Future<bool> addPendingAttendance(Map<String, dynamic> item) async {
    final list = getPendingAttendance();
    list.add(item);
    return await _prefs?.setString(_pendingAttendanceKey, jsonEncode(list)) ?? false;
  }

  static List<Map<String, dynamic>> getPendingAttendance() {
    final str = _prefs?.getString(_pendingAttendanceKey);
    if (str == null) return [];
    try {
      final raw = jsonDecode(str) as List;
      return raw.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> setPendingAttendance(List<Map<String, dynamic>> items) async {
    return await _prefs?.setString(_pendingAttendanceKey, jsonEncode(items)) ?? false;
  }

  // Shift planning storage: empId -> shift name
  static const String _shiftsKey = 'employee_shifts';

  static Future<bool> saveShifts(Map<String, String> empIdToShift) async {
    return await _prefs?.setString(_shiftsKey, jsonEncode(empIdToShift)) ?? false;
  }

  static Map<String, String> getShifts() {
    final str = _prefs?.getString(_shiftsKey);
    if (str == null) return {};
    try {
      final map = (jsonDecode(str) as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      return map;
    } catch (e) {
      return {};
    }
  }

  // Policy settings storage
  static const String _policyKey = 'policy_settings';

  static Future<bool> savePolicySettings({
    required double radiusMeters,
    required String workStart, // HH:mm
    required String workEnd,   // HH:mm
    required int lateGraceMinutes,
  }) async {
    final map = {
      'radius': radiusMeters,
      'workStart': workStart,
      'workEnd': workEnd,
      'lateGrace': lateGraceMinutes,
    };
    return await _prefs?.setString(_policyKey, jsonEncode(map)) ?? false;
  }

  static Map<String, dynamic> getPolicySettings() {
    final str = _prefs?.getString(_policyKey);
    if (str == null) {
      return {
        'radius': 150.0,
        'workStart': '09:00',
        'workEnd': '18:00',
        'lateGrace': 15,
      };
    }
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return map;
    } catch (e) {
      return {
        'radius': 150.0,
        'workStart': '09:00',
        'workEnd': '18:00',
        'lateGrace': 15,
      };
    }
  }

  // Clear all data (logout)
  static Future<bool> clearAll() async {
    return await _prefs?.clear() ?? false;
  }
}

