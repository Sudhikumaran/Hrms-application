import '../models/employee.dart';
import '../models/attendance_record.dart';
import '../models/leave_request.dart';

// Mock Data
class MockData {
  static List<Employee> get employees {
    try {
      return [
        Employee(
          empId: 'EMP001',
          name: 'Sudhi Kumaran',
          role: 'Frontend & Backend Developer',
          department: 'Development',
          shift: 'Morning',
          status: 'Active',
          hourlyRate: 200,
          location: Location(lat: 11.1085, lng: 77.3411),
        ),
        Employee(
          empId: 'EMP002',
          name: 'Akash Kumar',
          role: 'Frontend & Backend Developer',
          department: 'Development',
          shift: 'Morning',
          status: 'Active',
          hourlyRate: 180,
          location: Location(lat: 11.1085, lng: 77.3411),
        ),
        Employee(
          empId: 'EMP003',
          name: 'BalaMurugan',
          role: 'Frontend Developer',
          department: 'Development',
          shift: 'Evening',
          status: 'Active',
          hourlyRate: 150,
          location: Location(lat: 11.1085, lng: 77.3411),
        ),
      ];
    } catch (e) {
      return [
        Employee(
          empId: 'EMP001',
          name: 'Sudhi Kumaran',
          role: 'Frontend & Backend Developer',
          department: 'Development',
          shift: 'Morning',
          status: 'Active',
          hourlyRate: 200,
          location: Location(lat: 11.1085, lng: 77.3411),
        ),
      ];
    }
  }

  static Map<String, List<AttendanceRecord>> get attendanceData {
    try {
      return {
        'EMP001': [
          AttendanceRecord(
            date: '2024-08-22',
            checkIn: '09:00',
            checkOut: '18:00',
            status: 'Present',
            hours: 8.0,
            location: 'Office',
            method: 'facial',
          ),
          AttendanceRecord(
            date: '2024-08-21',
            checkIn: '09:15',
            checkOut: '18:30',
            status: 'Present',
            hours: 8.25,
            location: 'Office',
            method: 'geo',
          ),
        ],
      };
    } catch (e) {
      return {};
    }
  }

  static List<dynamic> get tasks {
    try {
      return [];
    } catch (e) {
      return [];
    }
  }

  static List<LeaveRequest> get leaveRequests {
    try {
      return [
        LeaveRequest(
          id: 'LVE001',
          empId: 'EMP002',
          type: 'Sick Leave',
          startDate: '2024-08-25',
          endDate: '2024-08-26',
          reason: 'Medical appointment',
          status: 'Pending',
        ),
      ];
    } catch (e) {
      return [];
    }
  }
}
