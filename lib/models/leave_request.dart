class LeaveRequest {
  final String id;
  final String empId;
  final String type;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;

  LeaveRequest({
    required this.id,
    required this.empId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'empId': empId,
        'type': type,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
        'status': status,
      };

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
        id: json['id'],
        empId: json['empId'],
        type: json['type'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        reason: json['reason'],
        status: json['status'],
      );
}



