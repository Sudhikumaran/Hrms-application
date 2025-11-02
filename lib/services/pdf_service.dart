import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';

class PdfService {
  static Future<void> generateAttendancePdf(
    List<Employee> employees,
    Map<String, List<AttendanceRecord>> attendanceData,
    String date,
  ) async {
    final pdf = pw.Document();
    // Convert internal date key (yyyyMMdd) to display format (yyyy-MM-dd) if needed
    String displayDate = date;
    if (date.length == 8 && int.tryParse(date) != null) {
      try {
        final parsed = DateTime.parse('${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)}');
        displayDate = DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {}
    }

    // Organize employees by status and shift
    final List<Map<String, dynamic>> morningPresent = [];
    final List<Map<String, dynamic>> morningLate = [];
    final List<Map<String, dynamic>> nightPresent = [];
    final List<Map<String, dynamic>> nightLate = [];
    final List<Map<String, dynamic>> wfhEmployees = [];
    final List<Map<String, dynamic>> absentEmployees = [];

    for (var employee in employees) {
      final empId = employee.empId;
      final todayRecord = attendanceData[empId]
          ?.firstWhere((r) => r.date == date, orElse: () => AttendanceRecord(
                date: date,
                status: 'Absent',
                hours: 0,
                location: '',
                method: '',
              ));

      // If employee checked in, they are present/WFH/Late (not absent)
      if (todayRecord != null && todayRecord.checkIn != null && todayRecord.checkIn!.isNotEmpty) {
        final checkInTime = todayRecord.checkIn!;
        // WFH handling
        if ((todayRecord.status ?? '').toString().toUpperCase() == 'WFH') {
          wfhEmployees.add({
            'name': employee.name,
            'checkIn': checkInTime,
            'checkOut': todayRecord.checkOut ?? '--:--',
          });
          continue;
        }
        // Consider late based on shift
        final isLate = _isLateCheckIn(checkInTime, employee.shift);
        final shiftLower = employee.shift.toLowerCase();
        final isNightShift = shiftLower.startsWith('night');

        if (isNightShift) {
          if (isLate) {
            nightLate.add({
              'name': employee.name,
              'checkIn': checkInTime,
              'checkOut': todayRecord.checkOut ?? '--:--',
            });
          } else {
            nightPresent.add({
              'name': employee.name,
              'checkIn': checkInTime,
              'checkOut': todayRecord.checkOut ?? '--:--',
            });
          }
        } else {
          // Morning shift
          if (isLate) {
            morningLate.add({
              'name': employee.name,
              'checkIn': checkInTime,
              'checkOut': todayRecord.checkOut ?? '--:--',
            });
          } else {
            morningPresent.add({
              'name': employee.name,
              'checkIn': checkInTime,
              'checkOut': todayRecord.checkOut ?? '--:--',
            });
          }
        }
      } else {
        // No check-in means absent (only show for non-night shifts during day)
        final shiftLower = employee.shift.toLowerCase();
        final isNightShift = shiftLower.startsWith('night');
        if (!isNightShift) {
          absentEmployees.add({
            'name': employee.name,
            'checkIn': '--:--',
            'checkOut': '--:--',
          });
        }
      }
    }

    // Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Daily Attendance Report',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Date: $displayDate',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Morning Shift Section
            pw.Text(
              '🌅 Morning Shift',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
            ),
            pw.SizedBox(height: 10),
            // Morning Present
            if (morningPresent.isNotEmpty) ...[
              pw.Text(
                'Present (${morningPresent.length})',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
              ),
              pw.SizedBox(height: 8),
              _buildTable(['Employee Name', 'Check-in Time', 'Check-out Time'], morningPresent),
              pw.SizedBox(height: 15),
            ],
            // Morning Late
            if (morningLate.isNotEmpty) ...[
              pw.Text(
                'Late (${morningLate.length})',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700),
              ),
              pw.SizedBox(height: 8),
              _buildTable(['Employee Name', 'Check-in Time', 'Check-out Time'], morningLate),
              pw.SizedBox(height: 15),
            ],
            if (morningPresent.isEmpty && morningLate.isEmpty)
              pw.Text('No Morning Shift attendance data', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 20),

            // Night Shift Section
            pw.Text(
              '🌙 Night Shift',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700),
            ),
            pw.SizedBox(height: 10),
            // Night Present
            if (nightPresent.isNotEmpty) ...[
              pw.Text(
                'Present (${nightPresent.length})',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
              ),
              pw.SizedBox(height: 8),
              _buildTable(['Employee Name', 'Check-in Time', 'Check-out Time'], nightPresent),
              pw.SizedBox(height: 15),
            ],
            // Night Late
            if (nightLate.isNotEmpty) ...[
              pw.Text(
                'Late (${nightLate.length})',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700),
              ),
              pw.SizedBox(height: 8),
              _buildTable(['Employee Name', 'Check-in Time', 'Check-out Time'], nightLate),
              pw.SizedBox(height: 15),
            ],
            if (nightPresent.isEmpty && nightLate.isEmpty)
              pw.Text('No Night Shift attendance data', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 20),

            // WFH Employees Section
            if (wfhEmployees.isNotEmpty) ...[
              pw.Text(
                '🏠 Working From Home (${wfhEmployees.length})',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 10),
              _buildTable(['Employee Name', 'Check-in Time', 'Check-out Time'], wfhEmployees),
              pw.SizedBox(height: 20),
            ],

            // Absent Employees Section (Morning shift only)
            if (absentEmployees.isNotEmpty) ...[
              pw.Text(
                '❌ Absent Employees (${absentEmployees.length})',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
              ),
              pw.SizedBox(height: 10),
              _buildTable(['Employee Name', 'Check-in Time', 'Check-out Time'], absentEmployees),
              pw.SizedBox(height: 20),
            ],

            // Summary
            pw.Divider(),
            pw.Text(
              'Summary: Total: ${employees.length} | Morning: Present ${morningPresent.length}, Late ${morningLate.length} | Night: Present ${nightPresent.length}, Late ${nightLate.length} | WFH: ${wfhEmployees.length} | Absent: ${absentEmployees.length}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    // Try to use Printing package first, fallback to share if it fails
    try {
      final bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    } on MissingPluginException catch (_) {
      // Fallback: Save PDF to device and share it
      try {
        final bytes = await pdf.save();
        final directory = await getApplicationDocumentsDirectory();
        final file = await File('${directory.path}/attendance_report_$displayDate.pdf').create(recursive: true);
        await file.writeAsBytes(bytes);
        
        // Share the PDF file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Attendance Report - $displayDate',
          text: 'Daily Attendance Report for $displayDate',
        );
      } on MissingPluginException catch (_) {
        // Both plugins failed - provide detailed error message with bytes length
        final pdfBytes = await pdf.save();
        throw Exception(
          'Native plugins not initialized. Please rebuild the app:\n\n'
          '1. Stop the app completely\n'
          '2. Run: flutter clean\n'
          '3. Run: flutter pub get\n'
          '4. Run: flutter run\n\n'
          'PDF generated successfully (${pdfBytes.length} bytes) but needs native plugins to save.'
        );
      } catch (shareError) {
        throw Exception('Failed to share PDF: $shareError');
      }
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  static pw.Widget _buildTable(List<String> headers, List<Map<String, dynamic>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers.map((h) => pw.Padding(
            padding: pw.EdgeInsets.all(8),
            child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          )).toList(),
        ),
        // Data rows
        ...data.map((row) => pw.TableRow(
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text(row['name']),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text(row['checkIn']),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text(row['checkOut']),
            ),
          ],
        )).toList(),
        // Empty row if no data
        if (data.isEmpty)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: pw.Text('No records', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              ),
              pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('')),
              pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('')),
            ],
          ),
      ],
    );
  }

  static bool _isLateCheckIn(String checkInTime, String shift) {
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
}
