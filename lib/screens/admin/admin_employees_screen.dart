import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/hybrid_storage_service.dart';

class AdminEmployeesScreen extends StatefulWidget {
  @override
  State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final employees = HybridStorageService.getEmployees();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Employees'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: employees.isEmpty ? null : [
          if (_isDeleting)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.delete_sweep),
              tooltip: 'Delete All Employees',
              onPressed: employees.isEmpty ? null : () => _showDeleteConfirmation(context),
            ),
        ],
      ),
      body: _isDeleting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Deleting all employees...',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : employees.isEmpty
          ? Center(
              child: Text(
                'No employees found',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF1976D2),
                      child: Text(
                        employee.name.substring(0, 2).toUpperCase(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      employee.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text('ID: ${employee.empId}'),
                        Text('Role: ${employee.role}'),
                        Text('Department: ${employee.department}'),
                        Text('Shift: ${employee.shift}'),
                      ],
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: employee.status == 'Active'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        employee.status,
                        style: TextStyle(
                          color: employee.status == 'Active' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    isThreeLine: false,
                    onTap: () => _openEdit(context, employee),
                  ),
                );
              },
            ),
    );
  }

  void _openEdit(BuildContext context, employee) {
    final nameCtrl = TextEditingController(text: employee.name);
    final roleCtrl = TextEditingController(text: employee.role);
    final deptCtrl = TextEditingController(text: employee.department);
    final shiftCtrl = TextEditingController(text: employee.shift);
    final statusCtrl = TextEditingController(text: employee.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Employee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 12),
                  _tf('Name', nameCtrl),
                  SizedBox(height: 8),
                  _tf('Role', roleCtrl),
                  SizedBox(height: 8),
                  _tf('Department', deptCtrl),
                  SizedBox(height: 8),
                  _tf('Shift', shiftCtrl),
                  SizedBox(height: 8),
                  _tf('Status', statusCtrl),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final updated = Employee(
                          empId: employee.empId,
                          name: nameCtrl.text.trim(),
                          role: roleCtrl.text.trim(),
                          department: deptCtrl.text.trim(),
                          shift: shiftCtrl.text.trim(),
                          status: statusCtrl.text.trim(),
                          hourlyRate: employee.hourlyRate,
                          location: employee.location,
                        );
                        await HybridStorageService.saveEmployee(updated);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: Icon(Icons.save),
                      label: Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tf(String label, TextEditingController c) => TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      );

  void _showDeleteConfirmation(BuildContext context) {
    final employees = HybridStorageService.getEmployees();
    final count = employees.length;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delete All Employees',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you absolutely sure you want to delete ALL $count employees?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'This action will:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• Delete all employees from Firestore'),
                    Text('• Clear all local employee data'),
                    Text('• Remove all employee login passwords'),
                    Text('• This action CANNOT be undone'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Type "DELETE ALL" to confirm',
                  border: OutlineInputBorder(),
                  hintText: 'DELETE ALL',
                ),
                onChanged: (value) {
                  // Store confirmation text for validation
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showFinalConfirmation(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showFinalConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final confirmController = TextEditingController();
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.dangerous, color: Colors.red, size: 32),
                  SizedBox(width: 8),
                  Text(
                    'Final Confirmation',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'This is your LAST chance to cancel.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      labelText: 'Type "DELETE ALL" to proceed',
                      border: OutlineInputBorder(),
                      hintText: 'DELETE ALL',
                      prefixIcon: Icon(Icons.edit),
                    ),
                    onChanged: (value) {
                      setDialogState(() {});
                    },
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This will permanently delete ALL employee data!',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  onPressed: confirmController.text.trim() == 'DELETE ALL'
                      ? () async {
                          Navigator.pop(dialogContext);
                          await _deleteAllEmployees(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('DELETE ALL'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAllEmployees(BuildContext context) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final result = await HybridStorageService.deleteAllEmployees();

      setState(() {
        _isDeleting = false;
      });

      if (!context.mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'All employees deleted successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Error deleting employees',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text('Delete Operation Details'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Deleted: ${result['deletedCount'] ?? 0} employees'),
                          if (result['errors'] != null && (result['errors'] as List).isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...((result['errors'] as List).map((e) => Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('• $e', style: TextStyle(color: Colors.red)),
                            ))),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting employees: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}

