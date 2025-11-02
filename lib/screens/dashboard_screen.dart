import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'attendance_screen.dart';
import 'leave_screen.dart';
import '../services/local_storage_service.dart';
import '../models/employee.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? checkInTimestamp;
  bool isCheckedIn = false;
  String? userId;
  String? _employeeName;
  int _breakMsToday = 0;
  double _monthlyHours = 0.0;
  Timer? _uiTicker;
  @override
  void initState() {
    super.initState();
    _getCheckInInfo();
    _loadBreakAndMonthlyData();
    _startUiTicker();
  }

  void _getCheckInInfo() async {
    await LocalStorageService.init();
    userId = LocalStorageService.getUserId();
    if (userId == null) return;
    
    // Load employee name
    final employees = LocalStorageService.getEmployees();
    if (employees.isNotEmpty) {
      final employee = employees.firstWhere((e) => e.empId == userId, orElse: () => employees.first);
      _employeeName = employee.name;
    }
    final dateKey = DateFormat('yyyyMMdd').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final checked = prefs.getBool('attendance_checked_in_${userId}_$dateKey') ?? false;
    final checkInIso = prefs.getString('attendance_checkin_raw_${userId}_$dateKey');
    setState(() {
      isCheckedIn = checked;
      checkInTimestamp = checkInIso != null && checked ? DateTime.tryParse(checkInIso) : null;
    });
    _loadBreakAndMonthlyData();
    _handleUiTicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                  'Dashboard',
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
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black87),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: double.infinity,
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667eea).withValues(alpha: 0.4),
                    blurRadius: 25,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    _employeeName ?? 'Employee',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isCheckedIn && checkInTimestamp != null) ...[
              SizedBox(height: 20),
              Card(
                color: Color(0xFF1565c0),
                margin: EdgeInsets.zero,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.timelapse, color: Colors.white, size: 28),
                        SizedBox(width: 14),
                        Text('Time Worked:', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(width: 14),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _LiveWorkTimerBig(checkIn: checkInTimestamp!, userId: userId ?? ''),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 20),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Hours Today', _liveHoursTodayString(), Icons.timer, Colors.green),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard('Breaks Today', _liveBreaksTodayString(), Icons.coffee, Colors.brown),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Attendance Status', _attendanceStatusString(), Icons.person, Colors.purple),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard('Monthly Worked Hours', _liveMonthlyWorkedHoursString(), Icons.calendar_month, Colors.blue),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Check In',
                    Icons.login,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AttendanceScreen()),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildActionCard(
                    'Apply Leave',
                    Icons.calendar_today,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LeaveScreen()),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Recent Activity
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildActivityItem(
                    'Checked in at 9:00 AM',
                    'Today',
                    Icons.login,
                    Colors.green,
                  ),
                  Divider(height: 1),
                  _buildActivityItem(
                    'Leave request submitted',
                    'Yesterday',
                    Icons.calendar_today,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _liveHoursTodayString() {
    if (!isCheckedIn || checkInTimestamp == null) return '--:--:--';
    final d = DateTime.now().difference(checkInTimestamp!);
    String two(int n) => n.toString().padLeft(2, '0');
    final safeBreak = _breakMsToday.isFinite ? _breakMsToday : 0;
    final workedMs = d.inMilliseconds - safeBreak;
    final clampedMs = workedMs.isFinite ? workedMs : 0;
    final worked = Duration(milliseconds: clampedMs < 0 ? 0 : clampedMs.round());
    final h = two(worked.inHours);
    final m = two(worked.inMinutes.remainder(60));
    final s = two(worked.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  Future<void> _loadBreakAndMonthlyData() async {
    if (userId == null) return;
    final dateKey = DateFormat('yyyyMMdd').format(DateTime.now());
    final monthKey = DateFormat('yyyyMM').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    
    // Load break data (using same keys as attendance_screen)
    final breakAcc = prefs.getInt('break_acc_${userId}_$dateKey') ?? 0;
    final breakStartIso = prefs.getString('break_start_${userId}_$dateKey');
    int currentBreak = 0;
    if (breakStartIso != null && breakStartIso.isNotEmpty) {
      final start = DateTime.tryParse(breakStartIso);
      if (start != null) currentBreak = DateTime.now().difference(start).inMilliseconds;
    }
    
    // Load monthly hours from attendance records
    await LocalStorageService.init();
    final records = LocalStorageService.getAttendance(userId!);
    double totalHours = 0;
    for (final r in records) {
      if (r.date.startsWith(monthKey)) {
        totalHours += r.hours;
      }
    }
    
    final combinedBreak = breakAcc + currentBreak;
    final safeBreak = combinedBreak.isFinite ? combinedBreak : 0;
    final safeHours = totalHours.isFinite ? totalHours : 0.0;

    setState(() {
      _breakMsToday = safeBreak < 0 ? 0 : safeBreak.round();
      _monthlyHours = safeHours;
    });
  }
  
  String _liveBreaksTodayString() {
    final safeMs = _breakMsToday.isFinite ? _breakMsToday : 0;
    final totalSeconds = (safeMs / 1000).floor();
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _attendanceStatusString() {
    if (isCheckedIn && checkInTimestamp != null) {
      return 'Checked In';
    } else {
      return 'Not Checked In';
    }
  }

  String _liveMonthlyWorkedHoursString() {
    return '${_monthlyHours.toStringAsFixed(1)}h';
  }

  void _handleUiTicker() {
    if (isCheckedIn && checkInTimestamp != null) {
      _startUiTicker();
    } else {
      _uiTicker?.cancel();
    }
  }

  void _startUiTicker() {
    _uiTicker?.cancel();
    _uiTicker = Timer.periodic(Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (!isCheckedIn || checkInTimestamp == null) {
        _uiTicker?.cancel();
        return;
      }
      await _loadBreakAndMonthlyData();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    super.dispose();
  }
}

class _LiveWorkTimer extends StatefulWidget {
  final DateTime checkIn;
  final String userId;
  const _LiveWorkTimer({required this.checkIn, required this.userId});
  @override
  State<_LiveWorkTimer> createState() => _LiveWorkTimerState();
}

class _LiveWorkTimerState extends State<_LiveWorkTimer> {
  late Duration duration;
  int _breakMs = 0;
  late DateTime _now;
  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    duration = _now.difference(widget.checkIn);
    _startTimer();
  }
  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (!mounted) return false;
      await _loadBreakMs();
      setState(() {
        _now = DateTime.now();
        final raw = _now.difference(widget.checkIn);
        final worked = raw.inMilliseconds - _breakMs;
        duration = Duration(milliseconds: worked < 0 ? 0 : worked);
      });
      return mounted;
    });
  }
  Future<void> _loadBreakMs() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyyMMdd').format(DateTime.now());
    final acc = prefs.getInt('break_acc_${widget.userId}_$dateKey') ?? 0;
    final startIso = prefs.getString('break_start_${widget.userId}_$dateKey');
    int running = 0;
    if (startIso != null && startIso.isNotEmpty) {
      final start = DateTime.tryParse(startIso);
      if (start != null) running = DateTime.now().difference(start).inMilliseconds;
    }
    _breakMs = acc + running;
  }
  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(duration.inHours);
    final m = two(duration.inMinutes.remainder(60));
    final s = two(duration.inSeconds.remainder(60));
    return Row(
      children: [
        Icon(Icons.timelapse, color: Colors.white, size: 18),
        SizedBox(width: 6),
        Text('Time Worked: ', style: TextStyle(color: Colors.white70)),
        Text('$h:$m:$s', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
      ],
    );
  }
}

class _LiveWorkTimerText extends StatefulWidget {
  final DateTime checkIn;
  final String userId;
  const _LiveWorkTimerText({required this.checkIn, required this.userId});
  @override
  State<_LiveWorkTimerText> createState() => _LiveWorkTimerTextState();
}
class _LiveWorkTimerTextState extends State<_LiveWorkTimerText> {
  late Duration duration;
  int _breakMs = 0;
  late DateTime _now;
  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    duration = _now.difference(widget.checkIn);
    _startTimer();
  }
  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (!mounted) return false;
      await _loadBreakMs();
      setState(() {
        _now = DateTime.now();
        final raw = _now.difference(widget.checkIn);
        final worked = raw.inMilliseconds - _breakMs;
        duration = Duration(milliseconds: worked < 0 ? 0 : worked);
      });
      return mounted;
    });
  }
  Future<void> _loadBreakMs() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyyMMdd').format(DateTime.now());
    final acc = prefs.getInt('break_acc_${widget.userId}_$dateKey') ?? 0;
    final startIso = prefs.getString('break_start_${widget.userId}_$dateKey');
    int running = 0;
    if (startIso != null && startIso.isNotEmpty) {
      final start = DateTime.tryParse(startIso);
      if (start != null) running = DateTime.now().difference(start).inMilliseconds;
    }
    _breakMs = acc + running;
  }
  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(duration.inHours);
    final m = two(duration.inMinutes.remainder(60));
    final s = two(duration.inSeconds.remainder(60));
    return Text('$h:$m:$s', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 28));
  }
}

class _LiveWorkTimerBig extends StatefulWidget {
  final DateTime checkIn;
  final String userId;
  const _LiveWorkTimerBig({required this.checkIn, required this.userId});
  @override
  State<_LiveWorkTimerBig> createState() => _LiveWorkTimerBigState();
}
class _LiveWorkTimerBigState extends State<_LiveWorkTimerBig> {
  late Duration duration;
  int _breakMs = 0;
  late DateTime _now;
  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    duration = _now.difference(widget.checkIn);
    _startTimer();
  }
  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (!mounted) return false;
      await _loadBreakMs();
      setState(() {
        _now = DateTime.now();
        final raw = _now.difference(widget.checkIn);
        final worked = raw.inMilliseconds - _breakMs;
        duration = Duration(milliseconds: worked < 0 ? 0 : worked);
      });
      return mounted;
    });
  }
  Future<void> _loadBreakMs() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyyMMdd').format(DateTime.now());
    final acc = prefs.getInt('break_acc_${widget.userId}_$dateKey') ?? 0;
    final startIso = prefs.getString('break_start_${widget.userId}_$dateKey');
    int running = 0;
    if (startIso != null && startIso.isNotEmpty) {
      final start = DateTime.tryParse(startIso);
      if (start != null) running = DateTime.now().difference(start).inMilliseconds;
    }
    _breakMs = acc + running;
  }
  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(duration.inHours);
    final m = two(duration.inMinutes.remainder(60));
    final s = two(duration.inSeconds.remainder(60));
    return Text('$h:$m:$s', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 28, letterSpacing: 1));
  }
}
