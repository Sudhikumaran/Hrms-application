import 'dart:async' show TimeoutException, Timer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';
import '../models/leave_request.dart';
import 'local_storage_service.dart';

/// Hybrid Storage Service
/// Combines local storage (offline support) with Firestore (cloud sync)
class HybridStorageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static SharedPreferences? _prefs;
  static bool _isOnline = false;
  static Timer? _syncTimer;
  static bool _isInitialized = false;
  
  // Get employees collection reference (for external use)
  static CollectionReference? getEmployeesRef() {
    return _isOnline ? _firestore.collection('employees') : null;
  }

  // Initialize the hybrid service
  static Future<void> init() async {
    // Prevent multiple initializations
    if (_isInitialized && _prefs != null) {
      print('HybridStorage: Already initialized, skipping...');
      return;
    }
    
    await LocalStorageService.init();
    _prefs = await SharedPreferences.getInstance();
    
    // Check Firebase connection (Firebase should already be initialized in main.dart)
    try {
      print('HybridStorage: Checking Firestore connection...');
      
      // First verify Firebase is initialized
      try {
        _firestore.settings;
        print('HybridStorage: Firestore instance initialized');
      } catch (e) {
        print('HybridStorage: Firestore instance error: $e');
        rethrow;
      }
      
      // Try a simple query to verify Firestore is accessible
      // Increased timeout and better error handling
      final queryResult = await _firestore
          .collection('employees')
          .limit(1)
          .get()
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Firestore connection timeout after 10 seconds');
      });
      
      print('HybridStorage: Firestore query successful - ${queryResult.docs.length} docs');
      _isOnline = true;
      _prefs?.setBool('firebase_connected', true);
      print('HybridStorage: Firestore connected ✅');
      
      // Start periodic sync
      _startSyncTimer();
      
      // Sync Firestore data to local on startup (download cloud data)
      // This is critical - ensure employees are loaded from Firestore
      print('📥 Syncing Firestore to local storage...');
      await _syncFirestoreToLocal();
      
      // Verify employees were loaded
      final employeesAfterSync = LocalStorageService.getEmployees();
      print('✅ After sync: ${employeesAfterSync.length} employees in local storage');
      
      // Then sync local changes to Firestore
      await _syncLocalToFirestore();
    } on TimeoutException catch (e) {
      // Timeout specifically - likely Firestore not enabled or network issue
      _isOnline = false;
      _prefs?.setBool('firebase_connected', false);
      print('HybridStorage: ❌ Connection timeout - $e');
      print('HybridStorage: Please check:');
      print('  1. Firestore Database is created in Firebase Console');
      print('  2. Internet connection is active');
      print('  3. Firestore security rules allow access');
      print('HybridStorage: Running in offline mode (local storage only)');
    } catch (e) {
      // Other Firestore errors
      _isOnline = false;
      _prefs?.setBool('firebase_connected', false);
      print('HybridStorage: ❌ Firestore connection failed - $e');
      print('HybridStorage: Error type: ${e.runtimeType}');
      print('HybridStorage: Running in offline mode (local storage only) - App will still work!');
      print('HybridStorage: Enable Firestore in Firebase Console to enable cloud sync');
    }
    
    _isInitialized = true;
    print('HybridStorage: Initialization complete');
  }

  // Start periodic sync every 30 seconds
  static void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_isOnline) {
        _syncLocalToFirestore();
        _syncFirestoreToLocal();
      }
    });
  }

  // Check if online
  static bool get isOnline => _isOnline;

  // ==================== EMPLOYEE MANAGEMENT ====================

  /// Save employee (local first, then sync to Firestore)
  static Future<bool> saveEmployee(Employee employee) async {
    try {
      // Save locally first (always works)
      await LocalStorageService.updateEmployee(employee);
      
      // Sync to Firestore if online
      if (_isOnline) {
        try {
          final employeesRef = _firestore.collection('employees');
          // Query by both 'empId' and 'employeeId' to handle field name variations
          final query1 = await employeesRef
              .where('empId', isEqualTo: employee.empId)
              .limit(1)
              .get();
          
          final query2 = query1.docs.isEmpty
              ? await employeesRef
                  .where('employeeId', isEqualTo: employee.empId)
                  .limit(1)
                  .get()
              : query1;
          
          if (query2.docs.isNotEmpty) {
            // Update existing document
            await query2.docs.first.reference.update(employee.toJson());
            print('Updated existing employee ${employee.empId} in Firestore');
          } else {
            // Create new document only if truly doesn't exist
            await employeesRef.add(employee.toJson());
            print('Created new employee ${employee.empId} in Firestore');
          }
          return true;
        } catch (e) {
          print('Firestore save error: $e');
          // Mark for sync later
          await _markForSync('employee', employee.empId);
        }
      }
      return true;
    } catch (e) {
      print('Save employee error: $e');
      return false;
    }
  }

  // Delete all employees from Firestore and local storage
  static Future<Map<String, dynamic>> deleteAllEmployees() async {
    try {
      print('🗑️ Starting delete all employees operation...');
      int deletedCount = 0;
      List<String> errors = [];

      // Step 1: Delete from Firestore
      if (_isOnline) {
        try {
          print('🗑️ Deleting all employees from Firestore...');
          final snapshot = await _firestore.collection('employees').get();
          
          // Delete in batches (Firestore limit is 500 operations per batch)
          final batchSize = 500;
          final docs = snapshot.docs;
          print('🗑️ Found ${docs.length} employees in Firestore to delete');

          for (int i = 0; i < docs.length; i += batchSize) {
            final batch = _firestore.batch();
            final end = (i + batchSize < docs.length) ? i + batchSize : docs.length;
            
            for (int j = i; j < end; j++) {
              batch.delete(docs[j].reference);
            }
            
            await batch.commit();
            deletedCount += (end - i);
            print('✅ Deleted batch: ${end - i} employees (Total: $deletedCount)');
          }

          print('✅ Successfully deleted $deletedCount employees from Firestore');
        } catch (e) {
          print('❌ Error deleting from Firestore: $e');
          errors.add('Firestore: $e');
        }
      } else {
        print('⚠️ Not online - skipping Firestore deletion');
      }

      // Step 2: Clear local storage
      try {
        print('🗑️ Clearing local employee storage...');
        await LocalStorageService.saveEmployees([]);
        print('✅ Local employee storage cleared');
      } catch (e) {
        print('❌ Error clearing local storage: $e');
        errors.add('Local storage: $e');
      }

      // Step 3: Clear all employee-related SharedPreferences
      try {
        print('🗑️ Clearing employee-related preferences...');
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        
        // Remove all employee login password keys
        for (var key in allKeys) {
          if (key.startsWith('emp_login_id_') || key.startsWith('emp_login_email_')) {
            await prefs.remove(key);
          }
        }
        print('✅ Employee preferences cleared');
      } catch (e) {
        print('⚠️ Error clearing preferences: $e');
        errors.add('Preferences: $e');
      }

      if (errors.isNotEmpty) {
        return {
          'success': false,
          'message': 'Deleted $deletedCount employees, but some errors occurred:\n${errors.join('\n')}',
          'deletedCount': deletedCount,
          'errors': errors,
        };
      }

      return {
        'success': true,
        'message': 'Successfully deleted all $deletedCount employees',
        'deletedCount': deletedCount,
      };
    } catch (e, stackTrace) {
      print('❌ Error deleting all employees: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error deleting employees: $e',
        'deletedCount': 0,
      };
    }
  }

  /// Get employees (local first, sync from Firestore if online)
  static List<Employee> getEmployees() {
    final localEmployees = LocalStorageService.getEmployees();
    // If local is empty and we're online, try to fetch from Firestore synchronously
    // This ensures we have data even if initial sync failed
    if (localEmployees.isEmpty && _isOnline) {
      print('⚠️ No local employees found, but online - attempting Firestore fetch...');
      // Trigger async sync (non-blocking)
      syncEmployeesFromFirestore().catchError((e) {
        print('Error fetching employees from Firestore: $e');
      });
    }
    return localEmployees;
  }
  
  /// Force refresh employees from Firestore (useful for login retry)
  static Future<List<Employee>> refreshEmployeesFromFirestore() async {
    print('🔄 Force refreshing employees from Firestore...');
    await syncEmployeesFromFirestore();
    return LocalStorageService.getEmployees();
  }

  /// Sync employees from Firestore to local
  static Future<void> syncEmployeesFromFirestore({int retryCount = 0, int maxRetries = 2}) async {
    // Try to reconnect if offline
    if (!_isOnline) {
      print('⚠️ Not online, attempting to reconnect to Firestore...');
      try {
        // Quick connectivity check
        await _firestore.collection('employees').limit(1).get().timeout(
          Duration(seconds: 5),
          onTimeout: () {
            print('❌ Firestore connection timeout');
            throw TimeoutException('Connection timeout');
          },
        );
        _isOnline = true;
        print('✅ Reconnected to Firestore');
      } catch (e) {
        print('❌ Could not reconnect to Firestore: $e');
        return;
      }
    }
    
    try {
      print('📥 Fetching employees from Firestore...');
      final snapshot = await _firestore.collection('employees')
          .get()
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Firestore query timeout');
      });
      
      final List<Employee> firestoreEmployees = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          // Handle both 'empId' and 'employeeId' field names
          if (data.containsKey('employeeId') && !data.containsKey('empId')) {
            data['empId'] = data['employeeId'];
          }
          firestoreEmployees.add(Employee.fromJson(data));
          print('  ✓ Loaded employee: ${data['empId']} - ${data['name']}');
        } catch (e) {
          print('❌ Error parsing employee ${doc.id}: $e');
          print('  Document data: ${doc.data()}');
        }
      }
      
      // Always merge to preserve local employees even if Firestore is empty
      final localEmployees = LocalStorageService.getEmployees();
      final Map<String, Employee> mergedEmployeesMap = {};
      
      // Add local employees first (preserve local data)
      for (var emp in localEmployees) {
        mergedEmployeesMap[emp.empId] = emp;
      }
      
      // Merge Firestore employees (Firestore data takes precedence for conflicts)
      for (var emp in firestoreEmployees) {
        mergedEmployeesMap[emp.empId] = emp;
      }
      
      // Save merged list
      final mergedEmployees = mergedEmployeesMap.values.toList();
      await LocalStorageService.saveEmployees(mergedEmployees);
      print('✅ Synced ${firestoreEmployees.length} employees from Firestore, merged with ${localEmployees.length} local employees. Total: ${mergedEmployees.length}');
    } on TimeoutException catch (e) {
      print('❌ Sync timeout: $e');
      if (retryCount < maxRetries) {
        print('🔄 Retrying sync (attempt ${retryCount + 1}/$maxRetries)...');
        await Future.delayed(Duration(seconds: 2));
        return await syncEmployeesFromFirestore(retryCount: retryCount + 1, maxRetries: maxRetries);
      }
    } catch (e) {
      print('❌ Sync employees error: $e');
      if (retryCount < maxRetries) {
        print('🔄 Retrying sync (attempt ${retryCount + 1}/$maxRetries)...');
        await Future.delayed(Duration(seconds: 2));
        return await syncEmployeesFromFirestore(retryCount: retryCount + 1, maxRetries: maxRetries);
      }
    }
  }

  // ==================== ATTENDANCE MANAGEMENT ====================

  /// Save attendance (local first, then sync to Firestore)
  static Future<bool> saveAttendance(String empId, AttendanceRecord record) async {
    try {
      // Save locally first
      await LocalStorageService.upsertAttendance(empId, record);
      
      // Sync to Firestore if online
      if (_isOnline) {
        try {
          final attendanceRef = _firestore.collection('attendance');
          final query = await attendanceRef
              .where('employeeId', isEqualTo: empId)
              .where('date', isEqualTo: record.date)
              .limit(1)
              .get();
          
          final data = {
            'employeeId': empId,
            'date': record.date,
            'checkIn': record.checkIn,
            'checkOut': record.checkOut,
            'status': record.status,
            'hours': record.hours,
            'location': record.location,
            'method': record.method,
            'wfh': record.status.toUpperCase() == 'WFH',
            'updatedAt': FieldValue.serverTimestamp(),
          };
          
          if (query.docs.isNotEmpty) {
            await query.docs.first.reference.update(data);
          } else {
            await attendanceRef.add({
              ...data,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
          return true;
        } catch (e) {
          print('Firestore attendance save error: $e');
          await _markForSync('attendance', '${empId}_${record.date}');
        }
      }
      return true;
    } catch (e) {
      print('Save attendance error: $e');
      return false;
    }
  }

  /// Get attendance records (local first)
  static List<AttendanceRecord> getAttendance(String empId) {
    return LocalStorageService.getAttendance(empId);
  }

  /// Sync attendance from Firestore to local
  static Future<void> syncAttendanceFromFirestore(String empId) async {
    if (!_isOnline) return;
    
    try {
      final snapshot = await _firestore.collection('attendance')
          .where('employeeId', isEqualTo: empId)
          .get();
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final record = AttendanceRecord(
            date: data['date'] ?? '',
            checkIn: data['checkIn'],
            checkOut: data['checkOut'],
            status: data['status'],
            hours: (data['hours'] as num?)?.toDouble() ?? 0.0,
            location: data['location'] ?? '',
            method: data['method'] ?? '',
          );
          
          await LocalStorageService.upsertAttendance(empId, record);
        } catch (e) {
          print('Error parsing attendance ${doc.id}: $e');
        }
      }
      
      print('Synced attendance for $empId from Firestore');
    } catch (e) {
      print('Sync attendance error: $e');
    }
  }

  // ==================== LEAVE REQUESTS ====================

  /// Save leave request (local first, then sync to Firestore)
  static Future<bool> saveLeaveRequest(LeaveRequest request) async {
    try {
      // Check for duplicates before saving (same empId, startDate, endDate, type, and status)
      final current = LocalStorageService.getLeaveRequests();
      
      // Check if exact duplicate already exists
      final isDuplicate = current.any((existing) =>
        existing.empId == request.empId &&
        existing.startDate == request.startDate &&
        existing.endDate == request.endDate &&
        existing.type == request.type &&
        existing.status == request.status);
      
      if (isDuplicate) {
        print('⚠️ Duplicate leave request detected - skipping save');
        print('   Request: ${request.type} from ${request.startDate} to ${request.endDate}');
        return false;
      }
      
      // Save locally first
      final updated = [...current, request];
      await LocalStorageService.saveLeaveRequests(updated);
      print('✅ Leave request saved locally: ${request.type} (${request.startDate} to ${request.endDate})');
      
      // Sync to Firestore if online
      if (_isOnline) {
        try {
          // Check Firestore for duplicates before adding
          final duplicateQuery = await _firestore.collection('leaveRequests')
              .where('empId', isEqualTo: request.empId)
              .where('startDate', isEqualTo: request.startDate)
              .where('endDate', isEqualTo: request.endDate)
              .where('type', isEqualTo: request.type)
              .where('status', isEqualTo: request.status)
              .limit(1)
              .get();
          
          if (duplicateQuery.docs.isNotEmpty) {
            print('⚠️ Duplicate leave request already exists in Firestore - skipping');
            return true; // Already exists, so consider it successful
          }
          
          await _firestore.collection('leaveRequests').add({
            'empId': request.empId,
            'type': request.type,
            'startDate': request.startDate,
            'endDate': request.endDate,
            'reason': request.reason,
            'status': request.status,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Leave request saved to Firestore');
          return true;
        } catch (e) {
          print('Firestore leave save error: $e');
          await _markForSync('leave', request.id);
        }
      }
      return true;
    } catch (e) {
      print('Save leave request error: $e');
      return false;
    }
  }

  /// Get leave requests (local first)
  static List<LeaveRequest> getLeaveRequests() {
    return LocalStorageService.getLeaveRequests();
  }

  /// Update leave request status
  static Future<bool> updateLeaveRequest(String requestId, String status, {String? note}) async {
    try {
      // Update locally first
      final requests = LocalStorageService.getLeaveRequests();
      final index = requests.indexWhere((r) => r.id == requestId);
      if (index >= 0) {
        final updated = requests[index];
        final newRequest = LeaveRequest(
          id: updated.id,
          empId: updated.empId,
          type: updated.type,
          startDate: updated.startDate,
          endDate: updated.endDate,
          reason: note != null ? '${updated.reason} | Note: $note' : updated.reason,
          status: status,
        );
        requests[index] = newRequest;
        await LocalStorageService.saveLeaveRequests(requests);
      }
      
      // Sync to Firestore if online
      if (_isOnline) {
        try {
          final query = await _firestore.collection('leaveRequests')
              .where('empId', isEqualTo: requests[index].empId)
              .where('startDate', isEqualTo: requests[index].startDate)
              .limit(1)
              .get();
          
          if (query.docs.isNotEmpty) {
            await query.docs.first.reference.update({
              'status': status,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          print('Firestore leave update error: $e');
        }
      }
      return true;
    } catch (e) {
      print('Update leave request error: $e');
      return false;
    }
  }

  /// Clean up duplicate leave requests from Firestore (keep only the newest one per unique key)
  static Future<void> _cleanupDuplicateLeaveRequestsInFirestore() async {
    if (!_isOnline) return;
    
    try {
      print('🧹 Starting cleanup of duplicate leave requests in Firestore...');
      final snapshot = await _firestore.collection('leaveRequests').get();
      
      // Group documents by unique key
      final Map<String, List<QueryDocumentSnapshot>> duplicatesByKey = {};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final empId = data['empId'] ?? '';
          final type = data['type'] ?? '';
          final startDate = data['startDate'] ?? '';
          final endDate = data['endDate'] ?? '';
          final status = data['status'] ?? 'Pending';
          
          // Create unique key for deduplication
          final uniqueKey = '${empId}_${startDate}_${endDate}_${type}_${status}';
          
          if (!duplicatesByKey.containsKey(uniqueKey)) {
            duplicatesByKey[uniqueKey] = [];
          }
          duplicatesByKey[uniqueKey]!.add(doc);
        } catch (e) {
          print('⚠️ Error processing document ${doc.id} for cleanup: $e');
        }
      }
      
      // Find and delete duplicates (keep the one with latest createdAt or newest document ID)
      int deletedCount = 0;
      final batch = _firestore.batch();
      int batchOperations = 0;
      const maxBatchSize = 500;
      
      for (var entry in duplicatesByKey.entries) {
        final docs = entry.value;
        if (docs.length > 1) {
          // Sort by createdAt (newest first) or document ID
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aCreated = aData?['createdAt'] as Timestamp?;
            final bCreated = bData?['createdAt'] as Timestamp?;
            
            if (aCreated != null && bCreated != null) {
              return bCreated.compareTo(aCreated); // Newest first
            }
            // If no createdAt, compare document IDs (newer IDs are typically larger)
            return b.id.compareTo(a.id);
          });
          
          // Keep the first one (newest), delete the rest
          for (int i = 1; i < docs.length; i++) {
            batch.delete(docs[i].reference);
            batchOperations++;
            deletedCount++;
            
            if (batchOperations >= maxBatchSize) {
              await batch.commit();
              batchOperations = 0;
              print('✅ Deleted batch of duplicate leave requests');
            }
          }
          
          if (docs.length > 1) {
            print('🗑️ Will delete ${docs.length - 1} duplicates for key: ${entry.key}');
          }
        }
      }
      
      // Commit remaining batch
      if (batchOperations > 0) {
        await batch.commit();
      }
      
      if (deletedCount > 0) {
        print('✅ Cleanup complete: Deleted $deletedCount duplicate leave requests from Firestore');
      } else {
        print('✅ No duplicates found in Firestore');
      }
    } catch (e) {
      print('❌ Error cleaning up duplicate leave requests: $e');
    }
  }

  /// Sync leave requests from Firestore to local
  static Future<void> syncLeaveRequestsFromFirestore() async {
    if (!_isOnline) return;
    
    try {
      // First, cleanup duplicates in Firestore (one-time operation, but safe to run multiple times)
      await _cleanupDuplicateLeaveRequestsInFirestore();
      
      final snapshot = await _firestore.collection('leaveRequests').get();
      final List<LeaveRequest> requests = [];
      final Map<String, LeaveRequest> uniqueRequests = {}; // Deduplicate by key
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final request = LeaveRequest(
            id: doc.id,
            empId: data['empId'] ?? '',
            type: data['type'] ?? '',
            startDate: data['startDate'] ?? '',
            endDate: data['endDate'] ?? '',
            reason: data['reason'] ?? '',
            status: data['status'] ?? 'Pending',
          );
          
          // Create unique key for deduplication: empId_startDate_endDate_type_status
          final uniqueKey = '${request.empId}_${request.startDate}_${request.endDate}_${request.type}_${request.status}';
          
          // Only add if not already in map (deduplicate)
          if (!uniqueRequests.containsKey(uniqueKey)) {
            uniqueRequests[uniqueKey] = request;
            requests.add(request);
          } else {
            // This should not happen after cleanup, but keep as safeguard
            print('⚠️ Skipping duplicate leave request from Firestore: $uniqueKey (after cleanup)');
          }
        } catch (e) {
          print('Error parsing leave request ${doc.id}: $e');
        }
      }
      
      // Merge with local - avoid duplicates by unique key
      final localRequests = LocalStorageService.getLeaveRequests();
      final Map<String, LeaveRequest> mergedByKey = {}; // Deduplicate by unique key
      
      // Helper to create unique key
      String makeKey(LeaveRequest req) => '${req.empId}_${req.startDate}_${req.endDate}_${req.type}_${req.status}';
      
      // Add local first
      for (var req in localRequests) {
        final key = makeKey(req);
        if (!mergedByKey.containsKey(key)) {
          mergedByKey[key] = req;
        }
      }
      
      // Add Firestore (Firestore takes precedence if duplicate)
      for (var req in requests) {
        final key = makeKey(req);
        mergedByKey[key] = req; // Firestore overwrites local duplicates
      }
      
      if (mergedByKey.isNotEmpty) {
        await LocalStorageService.saveLeaveRequests(mergedByKey.values.toList());
        print('✅ Synced ${requests.length} leave requests from Firestore, merged with ${localRequests.length} local. Total unique: ${mergedByKey.length}');
      } else {
        print('No leave requests to sync');
      }
    } catch (e) {
      print('Sync leave requests error: $e');
    }
  }

  // ==================== SYNC METHODS ====================

  /// Sync all local data to Firestore
  static Future<void> _syncLocalToFirestore() async {
    if (!_isOnline) return;
    
    try {
      // Sync employees
      final employees = LocalStorageService.getEmployees();
      for (var emp in employees) {
        await saveEmployee(emp);
      }
      
      // Sync attendance for all employees
      for (var emp in employees) {
        final attendance = LocalStorageService.getAttendance(emp.empId);
        for (var record in attendance) {
          await saveAttendance(emp.empId, record);
        }
      }
      
      // Sync leave requests
      final leaveRequests = LocalStorageService.getLeaveRequests();
      for (var req in leaveRequests) {
        await saveLeaveRequest(req);
      }
      
      print('Synced local data to Firestore');
    } catch (e) {
      print('Sync to Firestore error: $e');
    }
  }

  /// Sync all Firestore data to local
  static Future<void> _syncFirestoreToLocal() async {
    if (!_isOnline) return;
    
    try {
      await syncEmployeesFromFirestore();
      
      final employees = LocalStorageService.getEmployees();
      for (var emp in employees) {
        await syncAttendanceFromFirestore(emp.empId);
      }
      
      await syncLeaveRequestsFromFirestore();
      
      print('Synced Firestore data to local');
    } catch (e) {
      print('Sync from Firestore error: $e');
    }
  }

  /// Manual sync trigger
  static Future<void> syncNow() async {
    await _syncLocalToFirestore();
    await _syncFirestoreToLocal();
  }

  // ==================== HELPER METHODS ====================

  /// Mark item for later sync (when online)
  static Future<void> _markForSync(String type, String id) async {
    final pending = _prefs?.getStringList('pending_sync') ?? [];
    pending.add('$type:$id');
    await _prefs?.setStringList('pending_sync', pending);
  }

  /// Clear user data
  static Future<void> clearUser() async {
    await LocalStorageService.clearUser();
  }

  /// Save user
  static Future<bool> saveUser(String userId, String role) async {
    return await LocalStorageService.saveUser(userId, role);
  }

  /// Get user ID
  static String? getUserId() => LocalStorageService.getUserId();

  /// Get user role
  static String? getUserRole() => LocalStorageService.getUserRole();

  // Dispose resources
  static void dispose() {
    _syncTimer?.cancel();
  }
}

