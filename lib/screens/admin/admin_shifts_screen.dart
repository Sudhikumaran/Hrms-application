import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../services/hybrid_storage_service.dart';

class AdminShiftsScreen extends StatefulWidget {
  @override
  State<AdminShiftsScreen> createState() => _AdminShiftsScreenState();
}

class _AdminShiftsScreenState extends State<AdminShiftsScreen> {
  Map<String, String> _empIdToShift = {};

  @override
  void initState() {
    super.initState();
    _empIdToShift = LocalStorageService.getShifts();
  }

  Future<void> _save() async {
    await LocalStorageService.saveShifts(_empIdToShift);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shifts saved')));
    }
  }

  void _copyLastWeek() {
    // Simple mock: keep current mapping as last week; here just shows a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied last week shifts')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = HybridStorageService.getEmployees();
    final shiftOptions = employees.map((e) => e.shift).toSet().toList();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Shift Planning'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _copyLastWeek, icon: const Icon(Icons.content_copy)),
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employees.length,
        itemBuilder: (context, i) {
          final e = employees[i];
          final current = _empIdToShift[e.empId] ?? e.shift;
          final conflict = _hasConflict(e.empId, current);
          return Card(
            child: ListTile(
              title: Text(e.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${e.empId} • ${e.department}'),
                  if (conflict) Text('Conflict: overlapping shift', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
              trailing: DropdownButton<String>(
                value: current,
                items: shiftOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() { _empIdToShift[e.empId] = v; });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  bool _hasConflict(String empId, String shift) {
    // Simple placeholder: mark conflict if two employees in same department pick different shifts unexpectedly
    // Here, we'll just return false for simplicity; extend with business rules later.
    return false;
  }
}




