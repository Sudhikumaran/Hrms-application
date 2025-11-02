import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../models/leave_request.dart';
import '../../models/employee.dart';

class AdminLeavesScreen extends StatefulWidget {
  @override
  State<AdminLeavesScreen> createState() => _AdminLeavesScreenState();
}

class _AdminLeavesScreenState extends State<AdminLeavesScreen> {
  final Set<String> _selected = {};

  List<LeaveRequest> _requests = [];
  Map<String, Employee> _employeeMap = {}; // Map empId to Employee

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    await LocalStorageService.init();
    final stored = LocalStorageService.getLeaveRequests();
    final employees = LocalStorageService.getEmployees();
    // Build employee map for quick lookup
    _employeeMap = {for (var emp in employees) emp.empId: emp};
    setState(() {
      _requests = stored;
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _bulkUpdate(String status) async {
    await _updateRequests(
      ids: _selected,
      status: status,
      note: status == 'Approved' ? 'Approved in bulk' : 'Rejected in bulk',
    );
    setState(() => _selected.clear());
  }

  Future<void> _updateRequests({required Set<String> ids, required String status, required String note}) async {
    final updated = _requests.map((r) {
      if (ids.contains(r.id)) {
        return LeaveRequest(
          id: r.id,
          empId: r.empId,
          type: r.type,
          startDate: r.startDate,
          endDate: r.endDate,
          reason: '${r.reason} | Note: $note',
          status: status,
        );
      }
      return r;
    }).toList();
    await LocalStorageService.saveLeaveRequests(updated);
    setState(() => _requests = updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ${ids.length} request(s) to $status')),
      );
    }
  }

  void _approveOne(LeaveRequest r) async {
    final note = await _askNote('Approve');
    if (note == null) return;
    await _updateRequests(ids: {r.id}, status: 'Approved', note: note);
  }

  void _rejectOne(LeaveRequest r) async {
    final note = await _askNote('Reject');
    if (note == null) return;
    await _updateRequests(ids: {r.id}, status: 'Rejected', note: note);
  }

  Future<String?> _askNote(String action) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action with note'),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: 'Note')), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(action)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Leave Approvals'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          if (_selected.isNotEmpty)
            Row(children: [
              Text('${_selected.length} selected'),
              SizedBox(width: 8),
              IconButton(onPressed: () => _bulkUpdate('Approved'), icon: Icon(Icons.done_all)),
              IconButton(onPressed: () => _bulkUpdate('Rejected'), icon: Icon(Icons.clear_all)),
            ]),
        ],
      ),
      body: _requests.isEmpty
          ? Center(child: Text('No leave requests'))
          : ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => SizedBox(height: 8),
        itemBuilder: (context, i) {
          final r = _requests[i];
          final selected = _selected.contains(r.id);
          final employee = _employeeMap[r.empId];
          final employeeName = employee?.name ?? r.empId;
          return GestureDetector(
            onLongPress: () => _toggleSelect(r.id),
            child: Card(
              elevation: 2,
              child: ExpansionTile(
                leading: Checkbox(value: selected, onChanged: (_) => _toggleSelect(r.id)),
                title: Text(employeeName, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${r.type} • ${r.status}'),
                trailing: selected ? null : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.check, color: Colors.green), onPressed: () => _approveOne(r)),
                    IconButton(icon: Icon(Icons.close, color: Colors.red), onPressed: () => _rejectOne(r)),
                  ],
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Employee ID', r.empId),
                        SizedBox(height: 8),
                        _buildDetailRow('Leave Type', r.type),
                        SizedBox(height: 8),
                        _buildDetailRow('Reason', r.reason),
                        SizedBox(height: 8),
                        _buildDetailRow('Dates', 'From ${r.startDate} to ${r.endDate}'),
                        SizedBox(height: 8),
                        _buildDetailRow('Status', r.status),
                        SizedBox(height: 8),
                        _buildDetailRow('SLA', '${_pendingDays(r.startDate)} days'),
                      ],
                    ),
                  ),
                  if (!selected)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _approveOne(r),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _rejectOne(r),
                            tooltip: 'Reject',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _pendingDays(String start) {
    try {
      final d = DateTime.parse(start);
      return DateTime.now().difference(d).inDays.abs();
    } catch (_) {
      return 0;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }
}


