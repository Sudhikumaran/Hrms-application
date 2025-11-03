import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to clean up duplicate employee documents in Firestore
class FirestoreCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Delete all employee documents from Firestore
  /// WARNING: This will delete ALL employees. Use with caution!
  static Future<Map<String, dynamic>> deleteAllEmployees() async {
    try {
      print('🗑️ Starting deletion of all employees...');
      
      final snapshot = await _firestore.collection('employees').get();
      final int totalCount = snapshot.docs.length;
      
      if (totalCount == 0) {
        return {
          'success': true,
          'message': 'No employees found to delete',
          'deletedCount': 0,
        };
      }

      print('Found $totalCount employee documents');
      
      int deletedCount = 0;
      int errorCount = 0;
      
      // Delete each document
      for (var doc in snapshot.docs) {
        try {
          await doc.reference.delete();
          deletedCount++;
          print('✅ Deleted: ${doc.id}');
        } catch (e) {
          errorCount++;
          print('❌ Error deleting ${doc.id}: $e');
        }
      }

      print('✅ Cleanup complete! Deleted: $deletedCount, Errors: $errorCount');
      
      return {
        'success': errorCount == 0,
        'message': 'Deleted $deletedCount out of $totalCount employees',
        'deletedCount': deletedCount,
        'errorCount': errorCount,
        'totalCount': totalCount,
      };
    } catch (e) {
      print('❌ Cleanup error: $e');
      return {
        'success': false,
        'message': 'Error during cleanup: $e',
      };
    }
  }

  /// Remove duplicates, keeping only the most recent document for each empId
  static Future<Map<String, dynamic>> removeDuplicateEmployees() async {
    try {
      print('🔍 Starting duplicate removal...');
      
      final snapshot = await _firestore.collection('employees').get();
      final Map<String, List<DocumentSnapshot>> groupedByEmpId = {};
      
      // Group documents by empId (handle both 'empId' and 'employeeId' fields)
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final empId = data['empId'] ?? data['employeeId'];
        
        if (empId != null) {
          if (!groupedByEmpId.containsKey(empId)) {
            groupedByEmpId[empId] = [];
          }
          groupedByEmpId[empId]!.add(doc);
        }
      }

      int keptCount = 0;
      int deletedCount = 0;
      int errorCount = 0;

      // For each empId group, keep the most recent and delete others
      for (var entry in groupedByEmpId.entries) {
        final empId = entry.key;
        final docs = entry.value;
        
        if (docs.length > 1) {
          // Sort by document ID (newer documents have later IDs) or timestamp
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTime = aData?['createdAt'] as Timestamp?;
            final bTime = bData?['createdAt'] as Timestamp?;
            
            if (aTime != null && bTime != null) {
              return bTime.compareTo(aTime); // Most recent first
            }
            return b.id.compareTo(a.id); // Fallback to document ID
          });

          // Keep the first (most recent), delete the rest
          keptCount++;
          print('📌 Keeping most recent document for $empId: ${docs.first.id}');
          
          for (int i = 1; i < docs.length; i++) {
            try {
              await docs[i].reference.delete();
              deletedCount++;
              print('🗑️ Deleted duplicate: ${docs[i].id} (empId: $empId)');
            } catch (e) {
              errorCount++;
              print('❌ Error deleting ${docs[i].id}: $e');
            }
          }
        } else {
          // Only one document for this empId, keep it
          keptCount++;
          print('✅ Keeping unique document for $empId: ${docs.first.id}');
        }
      }

      print('✅ Duplicate removal complete!');
      print('   Kept: $keptCount, Deleted: $deletedCount, Errors: $errorCount');
      
      return {
        'success': errorCount == 0,
        'message': 'Removed duplicates. Kept $keptCount, deleted $deletedCount',
        'keptCount': keptCount,
        'deletedCount': deletedCount,
        'errorCount': errorCount,
      };
    } catch (e) {
      print('❌ Duplicate removal error: $e');
      return {
        'success': false,
        'message': 'Error removing duplicates: $e',
      };
    }
  }

  /// Delete employees with specific empId
  static Future<Map<String, dynamic>> deleteEmployeesByEmpId(String empId) async {
    try {
      print('🗑️ Deleting employees with empId: $empId');
      
      // Query by both field names
      final query1 = await _firestore
          .collection('employees')
          .where('empId', isEqualTo: empId)
          .get();
      
      final query2 = await _firestore
          .collection('employees')
          .where('employeeId', isEqualTo: empId)
          .get();

      final allDocs = <DocumentSnapshot>[];
      allDocs.addAll(query1.docs);
      
      // Add docs from query2 that aren't already in query1
      for (var doc in query2.docs) {
        if (!query1.docs.any((d) => d.id == doc.id)) {
          allDocs.add(doc);
        }
      }

      if (allDocs.isEmpty) {
        return {
          'success': true,
          'message': 'No employees found with empId: $empId',
          'deletedCount': 0,
        };
      }

      int deletedCount = 0;
      for (var doc in allDocs) {
        try {
          await doc.reference.delete();
          deletedCount++;
          print('✅ Deleted: ${doc.id}');
        } catch (e) {
          print('❌ Error deleting ${doc.id}: $e');
        }
      }

      return {
        'success': true,
        'message': 'Deleted $deletedCount documents for empId: $empId',
        'deletedCount': deletedCount,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting employees: $e',
      };
    }
  }

  /// Get count of employees
  static Future<int> getEmployeeCount() async {
    try {
      final snapshot = await _firestore.collection('employees').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting employee count: $e');
      return 0;
    }
  }
}

