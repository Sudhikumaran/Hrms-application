import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../models/employee.dart';

class LocationService {
  static const String _officeLocationKey = 'office_location';

  // Save office location
  static Future<bool> saveOfficeLocation(Location location) async {
    final prefs = await SharedPreferences.getInstance();
    final locationJson = jsonEncode({'lat': location.lat, 'lng': location.lng});
    return await prefs.setString(_officeLocationKey, locationJson);
  }

  // Get office location
  static Future<Location?> getOfficeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final locationJson = prefs.getString(_officeLocationKey);
    if (locationJson == null) return null;
    try {
      final locationMap = jsonDecode(locationJson) as Map<String, dynamic>;
      return Location(
        lat: locationMap['lat'] as double,
        lng: locationMap['lng'] as double,
      );
    } catch (e) {
      return null;
    }
  }

  // Calculate distance between two points in meters (Haversine formula)
  static double calculateDistance(Location loc1, Location loc2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1Rad = loc1.lat * (math.pi / 180);
    final double lat2Rad = loc2.lat * (math.pi / 180);
    final double deltaLat = (loc2.lat - loc1.lat) * (math.pi / 180);
    final double deltaLng = (loc2.lng - loc1.lng) * (math.pi / 180);

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Check if location is within 150 meters of office
  static Future<bool> isWithinOfficeRange(Location currentLocation) async {
    final officeLocation = await getOfficeLocation();
    if (officeLocation == null) return false; // No office location set

    final distance = calculateDistance(currentLocation, officeLocation);
    return distance <= 150; // 150 meters
  }
}
