import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_storage_service.dart';
import '../services/hybrid_storage_service.dart';
import '../models/attendance_record.dart';
import '../models/employee.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeAnalyticsScreen extends StatefulWidget {
  @override
  State<EmployeeAnalyticsScreen> createState() => _EmployeeAnalyticsScreenState();
}

class _EmployeeAnalyticsScreenState extends State<EmployeeAnalyticsScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _userId;
  List<AttendanceRecord> _records = [];
  Employee? _currentEmployee;

  // Config: mark late thresholds based on shift
  static final DateFormat _dateKey = DateFormat('yyyyMMdd');
  static final DateFormat _timeFmt = DateFormat('HH:mm');
  static const String _morningLateThreshold = '09:15'; // 9:15 AM
  static const String _nightLateThreshold = '21:15'; // 9:15 PM

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await LocalStorageService.init();
    final id = LocalStorageService.getUserId();
    if (id == null) return;
    
    // Get employee details to determine shift
    final employees = HybridStorageService.getEmployees();
    final employee = employees.where((e) => e.empId == id).firstOrNull;
    
    final all = HybridStorageService.getAttendance(id);
    setState(() {
      _userId = id;
      _records = all;
      _currentEmployee = employee;
    });
  }
  
  /// Get late threshold based on employee's shift
  String _getLateThresholdForShift() {
    if (_currentEmployee == null) {
      return _morningLateThreshold; // Default to morning
    }
    
    final shiftLower = _currentEmployee!.shift.toLowerCase();
    if (shiftLower.contains('night') || shiftLower.contains('9:00 pm') || shiftLower.contains('9:00 PM')) {
      return _nightLateThreshold; // Night shift: 9:15 PM
    } else {
      return _morningLateThreshold; // Morning shift: 9:15 AM
    }
  }
  
  /// Check if check-in time is late based on employee's shift
  bool _isLateCheckIn(String checkInTime, String? shift) {
    try {
      // Parse check-in time - it's in 24-hour format (HH:mm)
      final parts = checkInTime.split(':');
      if (parts.length < 2) {
        print('⚠️ Invalid check-in time format: $checkInTime');
        return false;
      }
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      // Determine shift type
      final shiftLower = (shift ?? '').toLowerCase();
      final isNightShift = shiftLower.contains('night') || 
                          shiftLower.contains('9:00 pm') || 
                          shiftLower.contains('9:00 PM') ||
                          shiftLower.contains('21:00');
      
      if (isNightShift) {
        // Night shift logic: late if check-in is AFTER 9:15 PM (21:15)
        // Example: 8:25 PM (20:25) = NOT late (early/on-time) ✅
        // Example: 9:00 PM (21:00) = NOT late (on-time) ✅
        // Example: 9:15 PM (21:15) = NOT late (exactly on threshold) ✅
        // Example: 9:16 PM (21:16) = LATE ❌
        // Example: 9:20 PM (21:20) = LATE ❌
        final isLate = hour > 21 || (hour == 21 && minute > 15);
        print('🌙 Night shift - Check-in: $checkInTime (${hour}:${minute.toString().padLeft(2, '0')}), Late: $isLate');
        return isLate;
      } else {
        // Morning shift logic: late if check-in is AFTER 9:15 AM
        // Example: 8:45 AM = NOT late ✅
        // Example: 9:00 AM = NOT late ✅
        // Example: 9:15 AM = NOT late (exactly on threshold) ✅
        // Example: 9:16 AM = LATE ❌
        final isLate = hour > 9 || (hour == 9 && minute > 15);
        print('🌅 Morning shift - Check-in: $checkInTime (${hour}:${minute.toString().padLeft(2, '0')}), Late: $isLate');
        return isLate;
      }
    } catch (e) {
      print('⚠️ Error parsing check-in time: $checkInTime - $e');
      return false; // Default to not late if parsing fails
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    });
  }

  // Map of day -> status
  Map<int, String> _statusForMonth(DateTime month) {
    final Map<int, String> dayToStatus = {};
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final key = _dateKey.format(date);
      final dayRecords = _records.where((r) => r.date == key).toList();
      if (dayRecords.isEmpty) {
        // Weekend optional rule: still show as absent; can be enhanced later
        dayToStatus[day] = 'absent';
        continue;
      }
      // If any record exists, compute late vs present by check-in
      final firstCheckIn = dayRecords
          .map((r) => r.checkIn)
          .where((t) => t != null && t.trim().isNotEmpty)
          .cast<String>()
          .toList()
        ..sort();
      if (firstCheckIn.isEmpty) {
        dayToStatus[day] = 'present';
      } else {
        // Use shift-aware late check
        final isLate = _isLateCheckIn(firstCheckIn.first, _currentEmployee?.shift);
        dayToStatus[day] = isLate ? 'late' : 'present';
      }
    }
    return dayToStatus;
  }

  Map<String, num> _kpisForMonth(DateTime month) {
    final statuses = _statusForMonth(month);
    final totalDays = statuses.length;
    final present = statuses.values.where((s) => s == 'present').length;
    final late = statuses.values.where((s) => s == 'late').length;
    final absent = statuses.values.where((s) => s == 'absent').length;
    // Sum hours from records in this month
    final startKey = _dateKey.format(DateTime(month.year, month.month, 1));
    final endKey = _dateKey.format(DateTime(month.year, month.month + 1, 0));
    double hours = 0;
    for (final r in _records) {
      if (r.date.compareTo(startKey) >= 0 && r.date.compareTo(endKey) <= 0) {
        hours += r.hours;
      }
    }
    final attendancePct = totalDays == 0 ? 0 : ((present + late) / totalDays) * 100;
    return {
      'present': present,
      'late': late,
      'absent': absent,
      'attendancePct': attendancePct,
      'hours': hours,
    };
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(_focusedMonth);
    final statuses = _statusForMonth(_focusedMonth);
    final kpis = _kpisForMonth(_focusedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/fortumars_logo.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
            ),
            Expanded(
              child: Center(
                child: Text(
                  'My Analytics',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            SizedBox(width: 90), // Balance logo
          ],
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFF5F5F5),
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => _changeMonth(-1), icon: Icon(Icons.chevron_left)),
                Text(monthName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => _changeMonth(1), icon: Icon(Icons.chevron_right)),
              ],
            ),
            SizedBox(height: 10),
            _buildLegend(),
            SizedBox(height: 12),
            _buildCalendar(statuses),
            SizedBox(height: 16),
            _buildKpis(kpis),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(Color color, String label) {
      return Row(children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        SizedBox(width: 6),
        Text(label),
      ]);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        item(Colors.green.shade400, 'Present'),
        SizedBox(width: 16),
        item(Colors.amber.shade600, 'Late'),
        SizedBox(width: 16),
        item(Colors.red.shade400, 'Absent'),
      ],
    );
  }

  Widget _buildCalendar(Map<int, String> statuses) {
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday; // 1=Mon..7=Sun
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    final List<Widget> tiles = [];
    // Weekday headers
    const labels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    tiles.addAll(labels.map((l) => Center(child: Text(l, style: TextStyle(fontWeight: FontWeight.bold)))));

    // Leading blanks
    final leading = firstWeekday - 1; // number of blanks before day 1
    for (int i = 0; i < leading; i++) {
      tiles.add(Container());
    }

    Color colorFor(String s) {
      switch (s) {
        case 'present':
          return Colors.green.shade400;
        case 'late':
          return Colors.amber.shade600;
        case 'absent':
        default:
          return Colors.red.shade400;
      }
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final status = statuses[day] ?? 'absent';
      tiles.add(Container(
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorFor(status),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text('$day', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ));
    }

    // Calculate total grid cells: 7 headers + blanks + days, then wrap in GridView
    return Expanded(
      child: GridView.count(
        crossAxisCount: 7,
        childAspectRatio: 1.1,
        physics: BouncingScrollPhysics(),
        children: tiles,
      ),
    );
  }

  Widget _buildKpis(Map<String, num> kpis) {
    Widget chip(String label, String value, Color color) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.black54)),
            SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This Month', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: chip('Attendance %', '${kpis['attendancePct']!.toStringAsFixed(1)}%', Colors.blue)),
            SizedBox(width: 8),
            Expanded(child: chip('Present', '${kpis['present']}', Colors.green)),
            SizedBox(width: 8),
            Expanded(child: chip('Late', '${kpis['late']}', Colors.amber.shade800)),
            SizedBox(width: 8),
            Expanded(child: chip('Absent', '${kpis['absent']}', Colors.red)),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: chip('Hours', '${kpis['hours']!.toStringAsFixed(1)} h', Colors.purple)),
          ],
        ),
      ],
    );
  }
}

