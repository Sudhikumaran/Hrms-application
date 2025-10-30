import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'attendance_screen.dart';
import 'leave_screen.dart';
import '../services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? checkInTimestamp;
  bool isCheckedIn = false;
  String? userId;
  @override
  void initState() {
    super.initState();
    _getCheckInInfo();
  }

  void _getCheckInInfo() async {
    await LocalStorageService.init();
    userId = LocalStorageService.getUserId();
    if (userId == null) return;
    final dateKey = DateFormat('yyyyMMdd').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final checked = prefs.getBool('attendance_checked_in_${userId}_$dateKey') ?? false;
    final checkInIso = prefs.getString('attendance_checkin_raw_${userId}_$dateKey');
    setState(() {
      isCheckedIn = checked;
      checkInTimestamp = checkInIso != null && checked ? DateTime.tryParse(checkInIso) : null;
    });
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
            onPressed: () {},
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
                    'Sudhi Kumaran',
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
                        'Friday, August 22, 2024',
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
                          child: _LiveWorkTimerBig(checkIn: checkInTimestamp!),
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
                  child: _buildStatCard('Tasks Pending', '0', Icons.assignment, Colors.orange),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('This Month', '160h', Icons.calendar_month, Colors.blue),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard('Leave Balance', '12', Icons.beach_access, Colors.purple),
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
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }
}

class _LiveWorkTimer extends StatefulWidget {
  final DateTime checkIn;
  const _LiveWorkTimer({required this.checkIn});
  @override
  State<_LiveWorkTimer> createState() => _LiveWorkTimerState();
}

class _LiveWorkTimerState extends State<_LiveWorkTimer> {
  late Duration duration;
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
      setState(() {
        _now = DateTime.now();
        duration = _now.difference(widget.checkIn);
      });
      return mounted;
    });
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
  const _LiveWorkTimerText({required this.checkIn});
  @override
  State<_LiveWorkTimerText> createState() => _LiveWorkTimerTextState();
}
class _LiveWorkTimerTextState extends State<_LiveWorkTimerText> {
  late Duration duration;
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
      setState(() {
        _now = DateTime.now();
        duration = _now.difference(widget.checkIn);
      });
      return mounted;
    });
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
  const _LiveWorkTimerBig({required this.checkIn});
  @override
  State<_LiveWorkTimerBig> createState() => _LiveWorkTimerBigState();
}
class _LiveWorkTimerBigState extends State<_LiveWorkTimerBig> {
  late Duration duration;
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
      setState(() {
        _now = DateTime.now();
        duration = _now.difference(widget.checkIn);
      });
      return mounted;
    });
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
