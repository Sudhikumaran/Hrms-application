class Employee {
  final String empId;
  final String name;
  final String role;
  final String department;
  final String shift;
  final String status;
  final double hourlyRate;
  final Location location;

  Employee({
    required this.empId,
    required this.name,
    required this.role,
    required this.department,
    required this.shift,
    required this.status,
    required this.hourlyRate,
    required this.location,
  });

  Map<String, dynamic> toJson() => {
        'empId': empId,
        'name': name,
        'role': role,
        'department': department,
        'shift': shift,
        'status': status,
        'hourlyRate': hourlyRate,
        'location': {'lat': location.lat, 'lng': location.lng},
      };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        empId: json['empId'],
        name: json['name'],
        role: json['role'],
        department: json['department'],
        shift: json['shift'],
        status: json['status'],
        hourlyRate: (json['hourlyRate'] as num).toDouble(),
        location: Location(
          lat: json['location']['lat'],
          lng: json['location']['lng'],
        ),
      );
}

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});
}

