import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  NotificationModel({required this.id, required this.type, required this.title, required this.message, required this.timestamp, this.isRead = false});
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [
    NotificationModel(id: '1', type: 'Shift', title: 'New Shift Assigned', message: 'You are assigned Night Shift tomorrow.', timestamp: DateTime.now().subtract(Duration(hours: 1)), isRead: false),
    NotificationModel(id: '2', type: 'Leave', title: 'Leave Approved', message: 'Your sick leave for 3 Jul is approved.', timestamp: DateTime.now().subtract(Duration(hours: 4)), isRead: false),
    NotificationModel(id: '3', type: 'Policy', title: 'New Attendance Policy', message: 'Grace period updated.', timestamp: DateTime.now().subtract(Duration(days: 1)), isRead: true),
    NotificationModel(id: '4', type: 'Leave', title: 'Leave Request', message: 'Your leave was rejected.', timestamp: DateTime.now().subtract(Duration(days: 1, hours: 3)), isRead: false),
    NotificationModel(id: '5', type: 'Shift', title: 'Shift Change', message: 'Shift timing updated.', timestamp: DateTime.now().subtract(Duration(days: 2)), isRead: true),
  ];
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    List<NotificationModel> filtered = filter == 'All'
        ? notifications
        : filter == 'Unread'
            ? notifications.where((n) => !n.isRead).toList()
            : notifications.where((n) => n.type == filter).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _buildFilterChip('All'),
              SizedBox(width: 8),
              _buildFilterChip('Unread'),
              SizedBox(width: 8),
              _buildFilterChip('Shift'),
              SizedBox(width: 8),
              _buildFilterChip('Leave'),
              SizedBox(width: 8),
              _buildFilterChip('Policy'),
            ]),
          ),
          Divider(),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.notifications_none, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No notifications', style: TextStyle(color: Colors.grey[700]))]))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final n = filtered[i];
                      return ListTile(
                        leading: _iconForType(n.type),
                        title: Row(children:[
                          Expanded(child: Text(n.title,
                              style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold))),
                          if (!n.isRead)
                            Container(width:6, height:6, decoration: BoxDecoration(color:Colors.blue, shape: BoxShape.circle))
                        ]),
                        subtitle: Text(n.message, maxLines:2, overflow: TextOverflow.ellipsis),
                        trailing: Text(_formatTime(n.timestamp), style: TextStyle(fontSize:12, color: Colors.grey[600])),
                        onTap: () {
                          setState(() { n.isRead = true; });
                          showDialog(context: context, builder: (ctx) {
                            return AlertDialog(
                              title: Text(n.title),
                              content: Text(n.message),
                              actions:[TextButton(onPressed: ()=>Navigator.pop(ctx), child: Text('Close'))],
                            );
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => filter = label),
      selectedColor: Colors.blue[100],
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(color: selected ? Colors.blue : Colors.black87),
    );
  }

  Icon _iconForType(String type) {
    switch (type) {
      case 'Shift': return Icon(Icons.schedule, color: Colors.deepPurple);
      case 'Leave': return Icon(Icons.event_available, color: Colors.green);
      case 'Policy': return Icon(Icons.policy, color: Colors.amber.shade800);
      default: return Icon(Icons.notifications, color: Colors.blueGrey);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      // today
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
