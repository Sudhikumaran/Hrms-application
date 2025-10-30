import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/employee.dart';
import '../../services/location_service.dart';
import '../../services/local_storage_service.dart';

class AdminLocationScreen extends StatefulWidget {
  @override
  State<AdminLocationScreen> createState() => _AdminLocationScreenState();
}

class _AdminLocationScreenState extends State<AdminLocationScreen> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  Location? _currentOfficeLocation;
  bool _isLoading = false;
  bool _isLoadingGps = false;
  // Policy
  double _radius = LocalStorageService.getPolicySettings()['radius'] as double;
  String _workStart = LocalStorageService.getPolicySettings()['workStart'] as String;
  String _workEnd = LocalStorageService.getPolicySettings()['workEnd'] as String;
  int _lateGrace = LocalStorageService.getPolicySettings()['lateGrace'] as int;

  @override
  void initState() {
    super.initState();
    _loadOfficeLocation();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _loadOfficeLocation() async {
    final location = await LocationService.getOfficeLocation();
    setState(() {
      _currentOfficeLocation = location;
      if (location != null) {
        _latController.text = location.lat.toStringAsFixed(6);
        _lngController.text = location.lng.toStringAsFixed(6);
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingGps = true;
    });

    try {
      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are permanently denied.')),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Current location obtained successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGps = false;
        });
      }
    }
  }

  Future<void> _saveLocation() async {
    if (_latController.text.isEmpty || _lngController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter latitude and longitude.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final lat = double.parse(_latController.text);
      final lng = double.parse(_lngController.text);

      final location = Location(lat: lat, lng: lng);
      final success = await LocationService.saveOfficeLocation(location);

      if (success) {
        setState(() {
          _currentOfficeLocation = location;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Office location saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save location.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid coordinates. Please enter valid numbers.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Location Management'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Employees can only check-in within 150 meters of the office location.',
                      style: TextStyle(color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Policy Settings
            Text('Policy Settings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            _buildPolicyCard(),
            SizedBox(height: 20),

            // Current Location Display
            if (_currentOfficeLocation != null) ...[
              Text(
                'Current Office Location',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationInfo('Latitude', _currentOfficeLocation!.lat.toStringAsFixed(6)),
                    SizedBox(height: 8),
                    _buildLocationInfo('Longitude', _currentOfficeLocation!.lng.toStringAsFixed(6)),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],

            // Manual Entry Section
            Text(
              'Set Office Location',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _latController,
              decoration: InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g., 11.1085',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _lngController,
              decoration: InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g., 77.3411',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 20),

            // GPS Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoadingGps ? null : _getCurrentLocation,
                icon: _isLoadingGps
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.my_location),
                label: Text(_isLoadingGps ? 'Getting Location...' : 'Use Current GPS Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveLocation,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _numField('Radius (meters)', _radius.toStringAsFixed(0), (v){ _radius = double.tryParse(v) ?? _radius; })),
            SizedBox(width: 8),
            Expanded(child: _textField('Late grace (min)', _lateGrace.toString(), (v){ _lateGrace = int.tryParse(v) ?? _lateGrace; })),
          ]),
          SizedBox(height: 8),
          Row(children: [
            Expanded(child: _textField('Work start (HH:mm)', _workStart, (v){ _workStart = v; })),
            SizedBox(width: 8),
            Expanded(child: _textField('Work end (HH:mm)', _workEnd, (v){ _workEnd = v; })),
          ]),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () async {
                await LocalStorageService.savePolicySettings(radiusMeters: _radius, workStart: _workStart, workEnd: _workEnd, lateGraceMinutes: _lateGrace);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Policy settings saved')));
                }
              },
              icon: Icon(Icons.save),
              label: Text('Save Policy'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(String label, String initial, Function(String) onChanged) {
    return TextFormField(
      initialValue: initial,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[50]),
      onChanged: onChanged,
    );
  }

  Widget _textField(String label, String initial, Function(String) onChanged) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[50]),
      onChanged: onChanged,
    );
  }
}

