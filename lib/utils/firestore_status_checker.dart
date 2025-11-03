import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/hybrid_storage_service.dart';

/// Utility to check Firestore connection and data sync status
class FirestoreStatusChecker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if Firestore is connected and working
  static Future<Map<String, dynamic>> checkConnection() async {
    try {
      // Try a simple query
      await _firestore.collection('employees').limit(1).get().timeout(
        Duration(seconds: 5),
      );
      return {
        'connected': true,
        'message': '✅ Firestore is connected and accessible',
      };
    } catch (e) {
      return {
        'connected': false,
        'message': '❌ Firestore connection failed: $e',
      };
    }
  }

  /// Get data counts from Firestore
  static Future<Map<String, dynamic>> getDataCounts() async {
    try {
      final employeesCount = (await _firestore.collection('employees').get()).docs.length;
      final attendanceCount = (await _firestore.collection('attendance').get()).docs.length;
      final leaveRequestsCount = (await _firestore.collection('leaveRequests').get()).docs.length;
      final adminsCount = (await _firestore.collection('admins').get()).docs.length;

      return {
        'success': true,
        'employees': employeesCount,
        'attendance': attendanceCount,
        'leaveRequests': leaveRequestsCount,
        'admins': adminsCount,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get full sync status report
  static Future<Map<String, dynamic>> getFullStatus() async {
    final connection = await checkConnection();
    final isOnline = HybridStorageService.isOnline;
    
    Map<String, dynamic> status = {
      'firestoreConnected': connection['connected'],
      'hybridServiceOnline': isOnline,
      'connectionMessage': connection['message'],
    };

    if (connection['connected'] == true) {
      final counts = await getDataCounts();
      status['dataCounts'] = counts;
    }

    return status;
  }

  /// Print status to console
  static Future<void> printStatus() async {
    print('\n========== FIRESTORE STATUS CHECK ==========');
    
    final isOnline = HybridStorageService.isOnline;
    print('HybridStorageService.isOnline: $isOnline');
    
    final connection = await checkConnection();
    print(connection['message']);
    
    if (connection['connected'] == true) {
      final counts = await getDataCounts();
      if (counts['success'] == true) {
        print('\n📊 Data in Firestore:');
        print('  👥 Employees: ${counts['employees']}');
        print('  📅 Attendance Records: ${counts['attendance']}');
        print('  📝 Leave Requests: ${counts['leaveRequests']}');
        print('  👤 Admin Users: ${counts['admins']}');
      } else {
        print('❌ Error getting data counts: ${counts['error']}');
      }
    }
    
    print('==========================================\n');
  }
}


