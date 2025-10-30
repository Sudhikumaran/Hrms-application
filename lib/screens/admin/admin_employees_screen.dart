import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/local_storage_service.dart';

class AdminEmployeesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final employees = LocalStorageService.getEmployees();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Employees'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: employees.isEmpty
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
                        await LocalStorageService.updateEmployee(updated);
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
}

