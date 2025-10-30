class AttendanceRecord {
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final double hours;
  final String location;
  final String method;

  AttendanceRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.hours,
    required this.location,
    required this.method,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'status': status,
        'hours': hours,
        'location': location,
        'method': method,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        date: json['date'],
        checkIn: json['checkIn'],
        checkOut: json['checkOut'],
        status: json['status'],
        hours: (json['hours'] as num).toDouble(),
        location: json['location'],
        method: json['method'],
      );
}



