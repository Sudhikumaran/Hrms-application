import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_storage_service.dart';
import '../models/attendance_record.dart';

class EmployeeAnalyticsScreen extends StatefulWidget {
  @override
  State<EmployeeAnalyticsScreen> createState() => _EmployeeAnalyticsScreenState();
}

class _EmployeeAnalyticsScreenState extends State<EmployeeAnalyticsScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _userId;
  List<AttendanceRecord> _records = [];

  // Config: mark late if check-in after 09:15
  static final DateFormat _dateKey = DateFormat('yyyyMMdd');
  static final DateFormat _timeFmt = DateFormat('HH:mm');
  static const String _lateThreshold = '09:15';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await LocalStorageService.init();
    final id = LocalStorageService.getUserId();
    if (id == null) return;
    final all = LocalStorageService.getAttendance(id);
    setState(() {
      _userId = id;
      _records = all;
    });
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
          .where((t) => t != null && t!.trim().isNotEmpty)
          .cast<String>()
          .toList()
        ..sort();
      if (firstCheckIn.isEmpty) {
        dayToStatus[day] = 'present';
      } else {
        try {
          final threshold = _timeFmt.parse(_lateThreshold);
          final actual = _timeFmt.parse(firstCheckIn.first);
          dayToStatus[day] = actual.isAfter(threshold) ? 'late' : 'present';
        } catch (_) {
          dayToStatus[day] = 'present';
        }
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
        title: Text('My Analytics'),
        backgroundColor: Color(0xFF1976D2),
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

    Color _colorFor(String s) {
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
          color: _colorFor(status),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
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

