import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/employee.dart';
import '../../models/attendance_record.dart';
import '../../utils/mock_data.dart';
import '../../services/pdf_service.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _isGeneratingPdf = false;

  Map<String, dynamic> _calculateDailyStats() {
    final employees = MockData.employees;
    final attendanceData = MockData.attendanceData;
    
    int totalMembers = employees.length;
    int present = 0;
    int absent = 0;
    int late = 0;

    for (var employee in employees) {
      final empId = employee.empId;
      final todayRecord = attendanceData[empId]?.firstWhere(
        (r) => r.date == selectedDate,
        orElse: () => AttendanceRecord(
          date: selectedDate,
          status: 'Absent',
          hours: 0,
          location: '',
          method: '',
        ),
      );

      if (todayRecord == null || todayRecord.status == 'Absent' || todayRecord.checkIn == null) {
        absent++;
      } else {
        present++;
        // Check if late (after 9:15 AM)
        final checkInTime = todayRecord.checkIn ?? '';
        if (_isLateCheckIn(checkInTime)) {
          late++;
        }
      }
    }

    return {
      'totalMembers': totalMembers,
      'present': present,
      'absent': absent,
      'late': late,
    };
  }

  bool _isLateCheckIn(String checkInTime) {
    try {
      final parts = checkInTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour > 9 || (hour == 9 && minute > 15);
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
      });
    }
  }

  Future<void> _downloadPDF() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final employees = MockData.employees;
      final attendanceData = MockData.attendanceData;
      await PdfService.generateAttendancePdf(employees, attendanceData, selectedDate);
      
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
            // Date Display
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Date',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(DateTime.parse(selectedDate)),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
            ),
            SizedBox(height: 20),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Members',
                    stats['totalMembers'].toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Present',
                    stats['present'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Absent',
                    stats['absent'].toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Late',
                    stats['late'].toString(),
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
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
}

