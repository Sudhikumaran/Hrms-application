import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/attendance_record.dart';
import '../../services/pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/local_storage_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _internalDateKey = DateFormat('yyyyMMdd').format(DateTime.now()); // For matching with attendance records
  bool _isGeneratingPdf = false;

  // Filters
  String? _selectedDepartment;
  String? _selectedShift;
  String? _selectedRole;
  static const _presetKey = 'admin_analytics_filter_preset';

  List<Employee> get employees => LocalStorageService.getEmployees();
  Map<String, List<AttendanceRecord>> get attendanceData => _getSavedAttendance();

  Map<String, List<AttendanceRecord>> _getSavedAttendance() {
    final Map<String, List<AttendanceRecord>> result = {};
    for (final emp in employees) {
      result[emp.empId] = LocalStorageService.getAttendance(emp.empId);
    }
    return result;
  }

  List<String> get _departments =>
      employees.map((e) => e.department).toSet().toList()..sort();
  List<String> get _shifts =>
      employees.map((e) => e.shift).toSet().toList()..sort();
  List<String> get _roles =>
      employees.map((e) => e.role).toSet().toList()..sort();

  List<Employee> _filteredEmployees() {
    return employees.where((e) {
      final depOk = _selectedDepartment == null || e.department == _selectedDepartment;
      final shiftOk = _selectedShift == null || e.shift == _selectedShift;
      final roleOk = _selectedRole == null || e.role == _selectedRole;
      return depOk && shiftOk && roleOk;
    }).toList();
  }

  Map<String, dynamic> _calculateDailyStats() {
    final filtered = _filteredEmployees();
    final realAttendance = attendanceData;
    int totalMembers = filtered.length;
    int present = 0;
    int absent = 0;
    int late = 0;
    for (var employee in filtered) {
      final empId = employee.empId;
      final records = realAttendance[empId] ?? [];
      AttendanceRecord? todayRecord;
      try {
        todayRecord = records.firstWhere((r) => r.date == _internalDateKey);
      } catch(_) {
        todayRecord = null;
      }
      // If employee checked in, they are present/WFH/Late (not absent)
      if (todayRecord != null && todayRecord.checkIn != null && todayRecord.checkIn!.isNotEmpty) {
        present++;
        // Check if late based on shift
        if (_isLateCheckIn(todayRecord.checkIn!, employee.shift)) {
          late++;
        }
      } else {
        absent++;
      }
    }
    return {
      'totalMembers': totalMembers,
      'present': present,
      'absent': absent,
      'late': late,
    };
  }

  bool _isLateCheckIn(String checkInTime, String shift) {
    try {
      final parts = checkInTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      // Determine late threshold based on shift: late if check-in after 9:10 AM/PM
      final shiftLower = shift.toLowerCase();
      if (shiftLower.startsWith('night')) {
        // Night shift: late if after 9:10 PM
        return hour >= 21 && minute > 10;
      } else {
        // Morning shift: late if after 9:10 AM
        return hour > 9 || (hour == 9 && minute > 10);
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(selectedDate),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(picked);
        _internalDateKey = DateFormat('yyyyMMdd').format(picked); // Update internal key for matching
      });
    }
  }

  Future<void> _savePreset() async {
    final prefs = await SharedPreferences.getInstance();
    final preset = {
      'department': _selectedDepartment,
      'shift': _selectedShift,
      'role': _selectedRole,
      'date': selectedDate,
    };
    await prefs.setString(_presetKey, preset.toString());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preset saved')),
      );
    }
  }

  Future<void> _loadPreset() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_presetKey);
    if (str == null) return;
    // Very small parser for the simple map string we saved
    String? getValue(String key) {
      final regex = RegExp('$key: (.*?)[,}]');
      final m = regex.firstMatch(str);
      if (m == null) return null;
      final v = m.group(1);
      if (v == 'null') return null;
      return v;
    }
    setState(() {
      _selectedDepartment = getValue('department');
      _selectedShift = getValue('shift');
      _selectedRole = getValue('role');
      selectedDate = getValue('date') ?? selectedDate;
    });
  }

  Future<void> _downloadPDF() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final employees = _filteredEmployees();
      final attendanceData = this.attendanceData;
      // Pass internal date key for matching with attendance records
      await PdfService.generateAttendancePdf(employees, attendanceData, _internalDateKey);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateDailyStats();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Analytics'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters + Date
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selected Date', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(DateTime.parse(selectedDate)),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: Icon(Icons.edit),
                        label: Text('Change'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDropdown('Department', _departments, _selectedDepartment, (v){ setState(()=>_selectedDepartment=v); })),
                      SizedBox(width: 8),
                      Expanded(child: _buildDropdown('Shift', _shifts, _selectedShift, (v){ setState(()=>_selectedShift=v); })),
                      SizedBox(width: 8),
                      Expanded(child: _buildDropdown('Role', _roles, _selectedRole, (v){ setState(()=>_selectedRole=v); })),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(onPressed: _savePreset, icon: Icon(Icons.save), label: Text('Save preset')),
                      SizedBox(width: 8),
                      OutlinedButton.icon(onPressed: _loadPreset, icon: Icon(Icons.download), label: Text('Load preset')),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Stats Cards
            Row(
              children: [
                Expanded(child: _buildDrillCard('Total Members', stats['totalMembers'].toString(), Icons.people, Colors.blue, _drillTotal)),
                SizedBox(width: 12),
                Expanded(child: _buildDrillCard('Present', stats['present'].toString(), Icons.check_circle, Colors.green, _drillPresent)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDrillCard('Absent', stats['absent'].toString(), Icons.cancel, Colors.red, _drillAbsent)),
                SizedBox(width: 12),
                Expanded(child: _buildDrillCard('Late', stats['late'].toString(), Icons.access_time, Colors.orange, _drillLate)),
              ],
            ),
            SizedBox(height: 30),

            // PDF Download Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _downloadPDF,
                icon: _isGeneratingPdf
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.download),
                label: Text(_isGeneratingPdf ? 'Generating PDF...' : 'Download PDF Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          Icon(icon, color: color, size: 32),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDrillCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: _buildStatCard(title, value, icon, color),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options,
    String? current,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('All')),
        ...options.map((o) => DropdownMenuItem<String>(value: o, child: Text(o))).toList(),
      ],
      onChanged: onChanged,
    );
  }

  // Drill-down handlers
  void _drillTotal() => _showDrill('All Employees', _filteredEmployees());
  void _drillPresent() => _showDrill('Present', _filteredEmployees().where((e){
    final rec = attendanceData[e.empId]?.firstWhere(
      (r)=> r.date==_internalDateKey,
      orElse: ()=> AttendanceRecord(date:_internalDateKey,status:'Absent',hours:0,location:'',method:''),
    );
    return rec!=null && rec.checkIn!=null && rec.checkIn!.isNotEmpty;
  }).toList());
  void _drillAbsent() => _showDrill('Absent', _filteredEmployees().where((e){
    final rec = attendanceData[e.empId]?.firstWhere(
      (r)=> r.date==_internalDateKey,
      orElse: ()=> AttendanceRecord(date:_internalDateKey,status:'Absent',hours:0,location:'',method:''),
    );
    return rec==null || rec.checkIn==null || rec.checkIn!.isEmpty;
  }).toList());
  void _drillLate() => _showDrill('Late', _filteredEmployees().where((e){
    final rec = attendanceData[e.empId]?.firstWhere(
      (r)=> r.date==_internalDateKey,
      orElse: ()=> AttendanceRecord(date:_internalDateKey,status:'Absent',hours:0,location:'',method:''),
    );
    if(rec==null || rec.checkIn==null || rec.checkIn!.isEmpty) return false;
    return _isLateCheckIn(rec.checkIn!, e.shift);
  }).toList());

  void _showDrill(String title, List<Employee> list) {
    showModalBottomSheet(
      context: context,
      builder: (context){
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Count: ${list.length}')
                  ],
                ),
              ),
              Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, i){
                    final e = list[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(e.name.substring(0,2).toUpperCase())),
                      title: Text(e.name),
                      subtitle: Text('${e.empId} • ${e.department} • ${e.shift}'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

