import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';

class PdfService {
  static Future<void> generateAttendancePdf(
    List<Employee> employees,
    Map<String, List<AttendanceRecord>> attendanceData,
    String date,
  ) async {
    final pdf = pw.Document();

    // Organize employees by status
    final List<Map<String, dynamic>> presentEmployees = [];
    final List<Map<String, dynamic>> absentEmployees = [];
    final List<Map<String, dynamic>> lateEmployees = [];

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

      if (todayRecord == null || todayRecord.status == 'Absent' || todayRecord.checkIn == null) {
        absentEmployees.add({
          'name': employee.name,
          'checkIn': '--:--',
          'checkOut': '--:--',
        });
      } else {
        final checkInTime = todayRecord.checkIn ?? '--:--';
        // Consider late if check-in is after 9:15 AM
        final isLate = _isLateCheckIn(checkInTime);

        if (isLate) {
          lateEmployees.add({
            'name': employee.name,
            'checkIn': checkInTime,
            'checkOut': todayRecord.checkOut ?? '--:--',
          });
        } else {
          presentEmployees.add({
            'name': employee.name,
            'checkIn': checkInTime,
            'checkOut': todayRecord.checkOut ?? '--:--',
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
                    'Date: $date',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Present Employees Section
            pw.Text(
              'Present Employees (${presentEmployees.length})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildTable(['Employee Name', 'Check-in Time', 'Check-out Time'], presentEmployees),
            pw.SizedBox(height: 20),

            // Late Employees Section
            if (lateEmployees.isNotEmpty) ...[
              pw.Text(
                'Late Employees (${lateEmployees.length})',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700),
              ),
              pw.SizedBox(height: 10),
              _buildTable(['Employee Name', 'Check-in Time', 'Check-out Time'], lateEmployees),
              pw.SizedBox(height: 20),
            ],

            // Absent Employees Section
            pw.Text(
              'Absent Employees (${absentEmployees.length})',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red700),
            ),
            pw.SizedBox(height: 10),
            _buildTable(['Employee Name', 'Check-in Time', 'Check-out Time'], absentEmployees),
            pw.SizedBox(height: 20),

            // Summary
            pw.Divider(),
            pw.Text(
              'Summary: Total: ${employees.length} | Present: ${presentEmployees.length} | Late: ${lateEmployees.length} | Absent: ${absentEmployees.length}',
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
    } on MissingPluginException catch (e) {
      // Fallback: Save PDF to device and share it
      try {
        final bytes = await pdf.save();
        final directory = await getApplicationDocumentsDirectory();
        final file = await File('${directory.path}/attendance_report_$date.pdf').create(recursive: true);
        await file.writeAsBytes(bytes);
        
        // Share the PDF file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Attendance Report - $date',
          text: 'Daily Attendance Report for $date',
        );
      } on MissingPluginException catch (shareError) {
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

  static bool _isLateCheckIn(String checkInTime) {
    try {
      final parts = checkInTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      // Late if after 9:15 AM
      return hour > 9 || (hour == 9 && minute > 15);
    } catch (e) {
      return false;
    }
  }
}
