import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../models/employee.dart';
import '../services/location_service.dart';
import '../services/local_storage_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_record.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool isCheckedIn = false;
  String? checkInTime;
  String attendanceMethod = 'facial';
  bool showCamera = false;

  String? userId;
  String get _todayDate => DateFormat('yyyyMMdd').format(DateTime.now());
  Employee? _employee;
  String? _expectedCheckInLabel; // e.g., "Morning Shift • 09:00 AM"
  double? _distanceMeters; // distance to office
  String? _reminderText; // shift reminder or late warning
  bool _isLate = false;
  // Break tracking
  bool _onBreak = false;
  DateTime? _breakStart;
  int _breakAccumulatedMs = 0;
  DateTime? _checkInRaw;

  @override
  void initState() {
    super.initState();
    _restoreCheckInStatus();
  }

  Future<void> _restoreCheckInStatus() async {
    await LocalStorageService.init();
    userId = LocalStorageService.getUserId();
    if (userId == null) return;
    // Load employee profile for shift info
    final emps = LocalStorageService.getEmployees();
    _employee = emps.firstWhere((e) => e.empId == userId, orElse: () => Employee(
      empId: userId!, name: '', role: '', department: '', shift: 'Morning (9:00 AM - 6:00 PM)', status: '', hourlyRate: 0, location: null, email: null
    ));
    _expectedCheckInLabel = _buildExpectedLabel(_employee?.shift ?? 'Morning (9:00 AM - 6:00 PM)');
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isCheckedIn = prefs.getBool('attendance_checked_in_${userId}_$_todayDate') ?? false;
      checkInTime = prefs.getString('attendance_checkin_time_${userId}_$_todayDate');
      final raw = prefs.getString('attendance_checkin_raw_${userId}_$_todayDate');
      _checkInRaw = raw != null ? DateTime.tryParse(raw) : null;
    });
    // Restore break state
    _breakAccumulatedMs = prefs.getInt('break_acc_${userId}_$_todayDate') ?? 0;
    final startIso = prefs.getString('break_start_${userId}_$_todayDate');
    if (startIso != null && startIso.isNotEmpty) {
      _breakStart = DateTime.tryParse(startIso);
      _onBreak = _breakStart != null;
    }
    // Compute geofence distance
    try {
      final office = await LocationService.getOfficeLocation();
      if (office != null) {
        Position pos;
        try {
          pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        } catch (_) {
          pos = Position(latitude: 0, longitude: 0, accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, timestamp: DateTime.now(), altitudeAccuracy: 0, headingAccuracy: 0);
        }
        final dist = LocationService.calculateDistance(Location(lat: pos.latitude, lng: pos.longitude), office);
        _distanceMeters = dist;
      }
    } catch (_) {}
    _updateReminderBanner();
  }

  String _buildExpectedLabel(String shift) {
    if (shift.toLowerCase().startsWith('night')) {
      return 'Night Shift • 09:00 PM';
    }
    return 'Morning Shift • 09:00 AM';
  }

  void _updateReminderBanner() {
    // Determine shift start based on employee shift
    final shift = (_employee?.shift ?? 'Morning').toLowerCase();
    final DateTime now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day, 9, 0);
    if (shift.startsWith('night')) {
      start = DateTime(now.year, now.month, now.day, 21, 0);
    }
    final diff = start.difference(now).inMinutes;
    String? text;
    bool late = false;
    if (!isCheckedIn) {
      if (diff <= 10 && diff >= -1) {
        text = 'Your shift starts at ${DateFormat('hh:mm a').format(start)}. Time to check in.';
      } else if (diff < -15) {
        late = true;
        text = 'You are ${(-diff)} min late. Please check in.';
      }
    }
    setState(() {
      _reminderText = text;
      _isLate = late;
    });
  }

  Future<void> _persistCheckInStatus(bool checkedIn, [String? time]) async {
    userId ??= LocalStorageService.getUserId();
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('attendance_checked_in_${userId}_$_todayDate', checkedIn);
    if (checkedIn) {
      await prefs.setString('attendance_checkin_time_${userId}_$_todayDate', time ?? '');
      await prefs.setString('attendance_checkin_raw_${userId}_$_todayDate', DateTime.now().toIso8601String());
    } else {
      await prefs.remove('attendance_checkin_time_${userId}_$_todayDate');
      await prefs.remove('attendance_checkin_raw_${userId}_$_todayDate');
    }
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
                  'Attendance',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Card
            AnimatedContainer(
              duration: Duration(milliseconds: 500),
              width: double.infinity,
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCheckedIn
                      ? [Color(0xFF00b09b), Color(0xFF96c93d)]
                      : [Color(0xFFff416c), Color(0xFFff4b2b)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: (isCheckedIn ? Color(0xFF00b09b) : Color(0xFFff416c))
                        .withValues(alpha: 0.4),
                    blurRadius: 25,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_reminderText != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: _isLate ? Colors.red.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(_isLate ? Icons.warning_amber_rounded : Icons.notifications_active, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(child: Text(_reminderText!, style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    ),
                  ],
                  Icon(
                    isCheckedIn ? Icons.check_circle : Icons.access_time,
                    color: Colors.white,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  if (_expectedCheckInLabel != null)
                    Text(
                      _expectedCheckInLabel!,
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  SizedBox(height: 6),
                  Text(
                    isCheckedIn ? 'Checked In' : 'Not Checked In',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (checkInTime != null)
                    Text(
                      'Since $checkInTime',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      child: ElevatedButton(
                        onPressed: isCheckedIn
                            ? _checkOut
                            : _checkInByLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isCheckedIn
                              ? Colors.red
                              : Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 8,
                          shadowColor: (isCheckedIn ? Colors.red : Colors.green)
                              .withValues(alpha: 0.3),
                        ),
                        child: Text(
                          isCheckedIn ? 'Check Out' : 'Check In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isCheckedIn) ...[
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_distanceMeters != null && _distanceMeters!.isFinite)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                            child: Row(children:[Icon(Icons.place, color: Colors.white, size: 16), SizedBox(width: 6), Text('${_distanceMeters!.toStringAsFixed(0)} m away', style: TextStyle(color: Colors.white))]),
                          ),
                        SizedBox(width: 10),
                        TextButton(
                          onPressed: _offlineCheckIn,
                          child: Text('Offline Check-In', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20),

            // Today's Summary
            AnimatedContainer(
              duration: Duration(milliseconds: 400),
              width: double.infinity,
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFf8f9fa)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Summary',
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
                        child: _buildSummaryItem(
                          'Check In',
                          checkInTime ?? '--:--',
                          Icons.login,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Check Out',
                          isCheckedIn ? '--:--' : '18:00',
                          Icons.logout,
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Hours',
                          isCheckedIn ? _calculateHours() : '8.0',
                          Icons.timer,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          _onBreak ? 'Break (Running)' : 'Break',
                          _formatBreakDuration(),
                          Icons.coffee,
                          Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _onBreak ? Colors.amber.shade700 : Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isCheckedIn ? () async {
                            if (_onBreak) {
                              await _endBreak();
                            } else {
                              await _startBreak();
                            }
                          } : null,
                          icon: Icon(_onBreak ? Icons.stop : Icons.coffee),
                          label: Text(_onBreak ? 'End Break' : 'Take Break'),
                        ),
                      ),
                      if (_onBreak) ...[
                        SizedBox(width: 12),
                        Text(_formatBreakDuration(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber.shade900)),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Attendance History
            Text(
              'Attendance History',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 15),
            FutureBuilder<List<AttendanceRecord>>(
              future: _getAllMyAttendance(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return Center(child: Text('No attendance records found', style: TextStyle(color: Colors.grey[600])));
                }
                return Column(
                  children: records.map((r) {
                    if (r == null) return SizedBox.shrink();
                    final date = r.date ?? '--';
                    final checkIn = r.checkIn ?? '--:--';
                    final checkOut = r.checkOut ?? '--:--';
                    final hours = r.hours.toStringAsFixed(2);
                    final status = r.status ?? '--';
                    final color = status == 'Present' ? Colors.green : Colors.red;
                    return _buildHistoryItem(date, '$checkIn - $checkOut', '$hours hrs', status, color);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _checkInByLocation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Location Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching your location...'),
          ],
        ),
      ),
    );
    try {
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        // On web, use dummy
        position = Position(
          latitude: 0.0, longitude: 0.0,
          accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, timestamp: DateTime.now(),
          altitudeAccuracy: 0, headingAccuracy: 0
        );
      }
      final currentLocation = Location(lat: position.latitude, lng: position.longitude);
      final isWithinRange = await LocationService.isWithinOfficeRange(currentLocation);
      Navigator.pop(context);
      if (isWithinRange) {
        _showOtpDialog();
      } else {
        final officeLocation = await LocationService.getOfficeLocation();
        final rawDistance = officeLocation != null
            ? LocationService.calculateDistance(currentLocation, officeLocation)
            : 0.0;
        final distanceStr = (rawDistance.isFinite ? rawDistance : 0.0).toStringAsFixed(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are ${distanceStr}m away. Please be within 150m to check in.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showOtpDialog() {
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('OTP Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the OTP below to Check In.'),
            SizedBox(height: 8),
            Row(children:[
              Text('OTP: ', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(otp, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
            SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(labelText: 'Enter OTP'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (ctrl.text == otp) {
                Navigator.pop(context);
                _performCheckIn('Geo-location + OTP');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP'), backgroundColor: Colors.red));
              }
            },
            child: Text('Check In'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performCheckIn(String method) {
    setState(() {
      isCheckedIn = true;
      checkInTime = TimeOfDay.now().format(context);
    });
    _persistCheckInStatus(true, checkInTime);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checked in (${_expectedCheckInLabel ?? 'Shift'}) via $method'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Offline check-in queue
  void _offlineCheckIn() async {
    await LocalStorageService.init();
    final id = LocalStorageService.getUserId();
    if (id == null) return;
    final item = {
      'empId': id,
      'type': 'checkin',
      'date': _todayDate,
      'time': DateFormat('HH:mm').format(DateTime.now()),
      'method': 'offline',
    };
    await LocalStorageService.addPendingAttendance(item);
    _performCheckIn('Offline');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Offline check-in queued for sync'), backgroundColor: Colors.orange),
    );
  }

  void _checkOut() async {
    // Fetch location and verify before allowing check out
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Location Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching your location...'),
          ],
        ),
      ),
    );
    try {
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        position = Position(
          latitude: 0.0, longitude: 0.0,
          accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, timestamp: DateTime.now(), altitudeAccuracy: 0, headingAccuracy: 0
        );
      }
      final currentLocation = Location(lat: position.latitude, lng: position.longitude);
      final isWithinRange = await LocationService.isWithinOfficeRange(currentLocation);
      Navigator.pop(context);
      if (isWithinRange) {
        _showOtpDialogCheckOut();
      } else {
        final officeLocation = await LocationService.getOfficeLocation();
        final rawDistance = officeLocation != null
            ? LocationService.calculateDistance(currentLocation, officeLocation)
            : 0.0;
        final distanceStr = (rawDistance.isFinite ? rawDistance : 0.0).toStringAsFixed(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are ${distanceStr}m away. Please be within 150m to check out.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showOtpDialogCheckOut() {
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('OTP Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the OTP below to Check Out.'),
            SizedBox(height: 8),
            Row(children:[
              Text('OTP: ', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(otp, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
            SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(labelText: 'Enter OTP'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (ctrl.text == otp) {
                Navigator.pop(context);
                _doCheckOut();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP'), backgroundColor: Colors.red));
              }
            },
            child: Text('Check Out'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _doCheckOut() {
    setState(() {
      isCheckedIn = false;
      checkInTime = null;
    });
    _persistCheckInStatus(false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checked out successfully'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _calculateHours() {
    if (_checkInRaw == null) return '0.0';
    final now = DateTime.now();
    int runningBreak = _breakAccumulatedMs;
    if (_onBreak && _breakStart != null) {
      runningBreak += now.difference(_breakStart!).inMilliseconds;
    }
    final workedMs = now.difference(_checkInRaw!).inMilliseconds - runningBreak;
    final hours = workedMs / (1000 * 60 * 60);
    return hours.toStringAsFixed(1);
  }

  String _formatBreakDuration() {
    int ms = _breakAccumulatedMs;
    if (_onBreak && _breakStart != null) {
      ms += DateTime.now().difference(_breakStart!).inMilliseconds;
    }
    final totalMinutes = (ms / 60000).floor();
    final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _startBreak() async {
    if (_onBreak) return;
    _onBreak = true;
    _breakStart = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('break_start_${userId}_$_todayDate', _breakStart!.toIso8601String());
    setState(() {});
  }

  Future<void> _pauseBreak() async {
    if (!_onBreak || _breakStart == null) return;
    final now = DateTime.now();
    _breakAccumulatedMs += now.difference(_breakStart!).inMilliseconds;
    _onBreak = false;
    _breakStart = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('break_start_${userId}_$_todayDate');
    await prefs.setInt('break_acc_${userId}_$_todayDate', _breakAccumulatedMs);
    setState(() {});
  }

  Future<void> _resumeBreak() async {
    if (_onBreak) return;
    _onBreak = true;
    _breakStart = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('break_start_${userId}_$_todayDate', _breakStart!.toIso8601String());
    setState(() {});
  }

  Future<void> _endBreak() async {
    if (_onBreak && _breakStart != null) {
      _breakAccumulatedMs += DateTime.now().difference(_breakStart!).inMilliseconds;
    }
    _onBreak = false;
    _breakStart = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('break_start_${userId}_$_todayDate');
    await prefs.setInt('break_acc_${userId}_$_todayDate', _breakAccumulatedMs);
    setState(() {});
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHistoryItem(
    String date,
    String time,
    String hours,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hours,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<AttendanceRecord>> _getAllMyAttendance() async {
    final empId = LocalStorageService.getUserId() ?? '';
    await LocalStorageService.init();
    return LocalStorageService.getAttendance(empId);
  }
}
