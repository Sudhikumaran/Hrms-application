import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/leave_request.dart';
import '../utils/mock_data.dart';
import '../services/local_storage_service.dart';

class LeaveScreen extends StatefulWidget {
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<LeaveRequest> leaveRequests = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedLeaveType;
  final List<String> _leaveTypes = [
    'Annual Leave',
    'Sick Leave',
    'Casual Leave',
    'Emergency Leave',
    'Maternity Leave',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeLeaveRequests();
    _selectedLeaveType = _leaveTypes.first;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _initializeLeaveRequests() async {
    await LocalStorageService.init();
    final stored = LocalStorageService.getLeaveRequests();
    if (stored.isNotEmpty) {
      leaveRequests = stored;
    } else {
      leaveRequests = List.from(MockData.leaveRequests);
      await LocalStorageService.saveLeaveRequests(leaveRequests);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/fortumars_logo.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Leave Management',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            SizedBox(width: 90),
          ],
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFF5F5F5),
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black87,
          tabs: [
            Tab(text: 'Apply Leave'),
            Tab(text: 'My Requests'),
            Tab(text: 'Balance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplyLeaveTab(),
          _buildMyRequestsTab(),
          _buildBalanceTab(),
        ],
      ),
    );
  }

  Widget _buildApplyLeaveTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            width: double.infinity,
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFf8f9fa)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply for Leave',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLeaveType,
                  decoration: InputDecoration(
                    labelText: 'Leave Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _leaveTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedLeaveType = value),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'From Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: _fromDateController,
                  readOnly: true,
                  onTap: () => _pickFromDate(context),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'To Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: _toDateController,
                  readOnly: true,
                  onTap: () => _pickToDate(context),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  controller: _reasonController,
                  maxLines: 4,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitLeaveRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Submit Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    if (leaveRequests.isEmpty) {
      return Center(
        child: Text(
          'No leave requests yet',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: leaveRequests.length,
      itemBuilder: (context, index) {
        return _buildLeaveRequestCard(leaveRequests[index]);
      },
    );
  }

  Widget _buildBalanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  'Leave Balance 2024',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBalanceItem('Total', '24', Colors.white),
                    _buildBalanceItem('Used', '8', Colors.white70),
                    _buildBalanceItem('Remaining', '16', Colors.white),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
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
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Leave Type Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildLeaveTypeBalance('Annual Leave', 12, 4, Colors.blue),
                _buildLeaveTypeBalance('Sick Leave', 8, 2, Colors.red),
                _buildLeaveTypeBalance('Casual Leave', 4, 2, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequest request) {
    Color statusColor = _getLeaveStatusColor(request.status);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.type,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'From: ${request.startDate}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              'To: ${request.endDate}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              request.reason,
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildLeaveTypeBalance(String type, int total, int used, Color color) {
    double percentage = used / total;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$used/$total used',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getLeaveStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickFromDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (selected != null) {
      setState(() {
        _fromDate = selected;
        _fromDateController.text = DateFormat('dd-MM-yyyy').format(selected);
        if (_toDate != null && _toDate!.isBefore(selected)) {
          _toDate = selected;
          _toDateController.text = DateFormat('dd-MM-yyyy').format(selected);
        }
      });
    }
  }

  Future<void> _pickToDate(BuildContext context) async {
    final start = _fromDate ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _toDate ?? start,
      firstDate: start,
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (selected != null) {
      setState(() {
        _toDate = selected;
        _toDateController.text = DateFormat('dd-MM-yyyy').format(selected);
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_selectedLeaveType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select leave type')));
      return;
    }
    if (_fromDate == null || _toDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both dates')));
      return;
    }
    if (_toDate!.isBefore(_fromDate!)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('To Date must be after From Date')));
      return;
    }
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter reason')));
      return;
    }

    final empId = LocalStorageService.getUserId() ?? 'EMP001';
    await LocalStorageService.init();
    final request = LeaveRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      empId: empId,
      type: _selectedLeaveType!,
      startDate: DateFormat('dd-MM-yyyy').format(_fromDate!),
      endDate: DateFormat('dd-MM-yyyy').format(_toDate!),
      reason: reason,
      status: 'Pending',
    );

    leaveRequests.add(request);
    await LocalStorageService.saveLeaveRequests(leaveRequests);

    _fromDate = null;
    _toDate = null;
    _fromDateController.clear();
    _toDateController.clear();
    _reasonController.clear();

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leave request submitted successfully'), backgroundColor: Colors.green),
    );
  }
}
