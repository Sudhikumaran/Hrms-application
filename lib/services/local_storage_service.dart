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

  // Clear all data (logout)
  static Future<bool> clearAll() async {
    return await _prefs?.clear() ?? false;
  }
}

