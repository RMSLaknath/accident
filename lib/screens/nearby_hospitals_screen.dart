import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // Add this import for clipboard
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin, sin;

// Replace with your Google Maps API key
const String googleApiKey = 'AIzaSyDxZq74_kDlP7lhHsyVm8Jk1FK9pMNSFE0';

class Hospital {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final String phoneNumber;
  final String? placeId;
  double distance = 0.0; // Distance from current location in km

  Hospital({
    required this.id,
    required this.name,
    required this.position,
    this.address = '',
    this.phoneNumber = '',
    this.placeId,
  });

  void calculateDistance(LatLng userLocation) {
    // Haversine formula to calculate distance between two coordinates
    const double earthRadius = 6371; // Earth radius in kilometers
    double lat1 = userLocation.latitude;
    double lon1 = userLocation.longitude;
    double lat2 = position.latitude;
    double lon2 = position.longitude;

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * asin(sqrt(a));
    distance = earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }
}

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  _NearbyHospitalsScreenState createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  static const LatLng _center =
      LatLng(6.927079, 79.861244); // Colombo, Sri Lanka
  LatLng _currentLocation = _center;
  final Set<Marker> _markers = {};
  List<Hospital> _hospitals = [];
  Hospital? _nearestHospital;
  bool _isLoading = true;
  String? _errorMessage;

  // For animation effects
  late AnimationController _animationController;
  // Initialize with default value to avoid late initialization error
  Animation<double> _fadeAnimation = const AlwaysStoppedAnimation<double>(1.0);

  // Adding a variable to track which hospitals have had their details fetched
  final Set<String> _fetchedHospitalDetails = {};

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _getCurrentLocationAndFetchHospitals();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocationAndFetchHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _getCurrentLocation();
      await _fetchNearbyHospitals();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // New method to fetch nearby hospitals using Google Places API
  Future<void> _fetchNearbyHospitals() async {
    // Clear existing hospitals
    setState(() {
      _hospitals = [];
      _nearestHospital = null;
    });

    try {
      // URL for Google Places API to search for nearby hospitals
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${_currentLocation.latitude},${_currentLocation.longitude}'
          '&radius=5000' // Search within 5km
          '&type=hospital'
          '&key=$googleApiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];

          // Convert API results to Hospital objects
          final List<Hospital> hospitals = results.map((place) {
            final location = place['geometry']['location'];
            final position = LatLng(
              location['lat'],
              location['lng'],
            );

            // Get formatted address or use vicinity as fallback
            final address = place['vicinity'] ?? '';

            // Place ID can be used later to fetch more details like phone number
            final placeId = place['place_id'] as String;

            // Place name
            final name = place['name'] as String;

            return Hospital(
              id: placeId,
              name: name,
              position: position,
              address: address,
              placeId: placeId,
              // Phone number is not available in the nearby search, would need an additional API call
              phoneNumber: '',
            );
          }).toList();

          // Calculate distances for all hospitals
          for (var hospital in hospitals) {
            hospital.calculateDistance(_currentLocation);
          }

          // Sort by distance
          hospitals.sort((a, b) => a.distance.compareTo(b.distance));

          setState(() {
            _hospitals = hospitals;
            _nearestHospital = hospitals.isNotEmpty ? hospitals.first : null;

            // Update markers on the map
            _updateMapMarkers();
          });

          // If we have hospitals, focus the map view
          if (hospitals.isNotEmpty) {
            _focusOnUserAndNearestHospital();
          }

          // Fetch details for the nearest hospital to get phone number
          if (_nearestHospital != null) {
            await _fetchHospitalDetails(_nearestHospital!);

            // Fetch details for next 4 hospitals in background to improve UX
            for (int i = 1; i < hospitals.length && i < 5; i++) {
              _fetchHospitalDetails(hospitals[i]);
            }
          }
        } else {
          setState(() {
            _errorMessage = 'API Error: ${data['status']}';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Network error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching hospitals: ${e.toString()}';
      });
    }
  }

  // Method to fetch details for a hospital to get phone number
  Future<void> _fetchHospitalDetails(Hospital hospital) async {
    if (hospital.placeId == null ||
        _fetchedHospitalDetails.contains(hospital.id)) return;

    try {
      // Add to set to prevent duplicate fetches
      _fetchedHospitalDetails.add(hospital.id);

      final url =
          Uri.parse('https://maps.googleapis.com/maps/api/place/details/json'
              '?place_id=${hospital.placeId}'
              '&fields=name,formatted_phone_number,international_phone_number'
              '&key=$googleApiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];

          // Try to get formatted_phone_number first, fallback to international_phone_number
          String phoneNumber = '';
          if (result.containsKey('formatted_phone_number')) {
            phoneNumber = result['formatted_phone_number'];
          } else if (result.containsKey('international_phone_number')) {
            phoneNumber = result['international_phone_number'];
          }

          if (phoneNumber.isNotEmpty) {
            final index = _hospitals.indexWhere((h) => h.id == hospital.id);
            if (index != -1) {
              // Create a new Hospital object with the updated phone number
              final updatedHospital = Hospital(
                id: hospital.id,
                name: hospital.name,
                position: hospital.position,
                address: hospital.address,
                phoneNumber: phoneNumber,
                placeId: hospital.placeId,
              );
              updatedHospital.distance = hospital.distance;

              setState(() {
                _hospitals[index] = updatedHospital;
                if (_nearestHospital?.id == hospital.id) {
                  _nearestHospital = updatedHospital;
                }
              });
            }
          }
        }
      }
    } catch (e) {
      // Just log the error, don't update state to avoid disrupting the UI
      print('Error fetching hospital details: ${e.toString()}');
    }
  }

  // Update map markers based on current location and hospitals
  void _updateMapMarkers() {
    // Clear existing markers
    _markers.clear();

    // Add marker for current location
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: _currentLocation,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Add markers for all hospitals
    for (var i = 0; i < _hospitals.length; i++) {
      final hospital = _hospitals[i];
      _markers.add(
        Marker(
          markerId: MarkerId(hospital.id),
          position: hospital.position,
          infoWindow: InfoWindow(
            title: hospital.name,
            snippet: '${hospital.distance.toStringAsFixed(2)} km away',
          ),
          // Use a different color for the nearest hospital
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
  }

  void _focusOnUserAndNearestHospital() {
    if (_nearestHospital == null || mapController == null) return;

    // Create LatLngBounds that include both current location and nearest hospital
    final bounds = LatLngBounds(
      southwest: LatLng(
        _currentLocation.latitude < _nearestHospital!.position.latitude
            ? _currentLocation.latitude
            : _nearestHospital!.position.latitude,
        _currentLocation.longitude < _nearestHospital!.position.longitude
            ? _currentLocation.longitude
            : _nearestHospital!.position.longitude,
      ),
      northeast: LatLng(
        _currentLocation.latitude > _nearestHospital!.position.latitude
            ? _currentLocation.latitude
            : _nearestHospital!.position.latitude,
        _currentLocation.longitude > _nearestHospital!.position.longitude
            ? _currentLocation.longitude
            : _nearestHospital!.position.longitude,
      ),
    );

    // Animate camera to show both points with padding
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // 100 is padding in pixels
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are required');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      throw Exception('Error getting location: $e');
    }
  }

  Future<void> _openDirections(LatLng destination) async {
    final lat = destination.latitude;
    final lng = destination.longitude;

    // Google Maps URL for directions
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch maps application')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _callHospital(String phoneNumber, String hospitalName) async {
    if (phoneNumber.isEmpty) {
      // If phone number is not available, show a loading dialog while fetching
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Flexible(
                  // Wrap in Flexible to allow text to shrink or wrap
                  child: Text(
                    'Fetching Phone Number',
                    style: TextStyle(
                      fontSize: 18, // Reduce font size a bit
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow
                        .ellipsis, // Allow text to show ellipsis if needed
                  ),
                ),
              ],
            ),
            content: const Text(
              'Please wait while we try to get the hospital\'s phone number...',
              textAlign: TextAlign.center,
            ),
          );
        },
      );

      // Try to find the hospital in our list
      final hospital = _hospitals.firstWhere((h) => h.name == hospitalName,
          orElse: () =>
              Hospital(id: '', name: '', position: const LatLng(0, 0)));

      // If we found the hospital and it has a place ID, try to fetch its details
      if (hospital.id.isNotEmpty && hospital.placeId != null) {
        await _fetchHospitalDetails(hospital);

        // Close the loading dialog
        if (mounted) Navigator.of(context).pop();

        // Get the updated hospital info
        final updatedHospital = _hospitals.firstWhere(
            (h) => h.id == hospital.id,
            orElse: () =>
                Hospital(id: '', name: '', position: const LatLng(0, 0)));

        // If we got a phone number, try calling again
        if (updatedHospital.phoneNumber.isNotEmpty) {
          _callHospital(updatedHospital.phoneNumber, hospitalName);
          return;
        }
      } else {
        // Close the loading dialog if it's open
        if (mounted) Navigator.of(context).pop();
      }

      // Show error if we couldn't get a phone number
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Phone number not available for $hospitalName'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    // Clean the phone number - remove all non-digit characters except the plus sign
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Check for CALL_PHONE permission first
    bool hasPermission = false;

    // On Android, check for CALL_PHONE permission
    if (Theme.of(context).platform == TargetPlatform.android) {
      try {
        // For newer Flutter versions that have permission_handler package
        // You would check permission here with something like:
        // hasPermission = await Permission.phone.request().isGranted;

        // Since we don't know if you have that package, we'll proceed without checking
        hasPermission = true;
      } catch (e) {
        print('Error checking call permission: $e');
        hasPermission = false;
      }
    } else {
      // iOS doesn't need CALL_PHONE permission
      hasPermission = true;
    }

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone call permission is required')),
      );
      return;
    }

    // Try different URI formats
    List<String> urlFormats = [
      'tel:$cleanedNumber',
      'tel://$cleanedNumber',
      'tel:+$cleanedNumber'
    ];

    bool launched = false;

    for (String url in urlFormats) {
      if (launched) break;

      final uri = Uri.parse(url);
      print('Attempting to call with URL: $url');

      try {
        // Try to launch the phone dialer
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          print('Successfully launched phone app with URL: $url');
          break;
        }
      } catch (e) {
        print('Error launching call with $url: $e');
      }
    }

    // If we still couldn't launch the phone app, try our fallback solution
    if (!launched) {
      print('Could not launch phone app with any URL format');
      _showPhoneNumberDialog(cleanedNumber, hospitalName);
    }
  }

  // Add a new method to show a dialog with the phone number
  void _showPhoneNumberDialog(String phoneNumber, String hospitalName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Call $hospitalName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unable to launch phone app directly. Please dial this number manually:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tap and hold the number to copy it',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CLOSE'),
            ),
            // Add a copy button for convenience
            ElevatedButton.icon(
              onPressed: () async {
                // Copy to clipboard functionality
                await Clipboard.setData(ClipboardData(text: phoneNumber));
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('COPY'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Nearby Hospitals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.black38,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: _getCurrentLocationAndFetchHospitals,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: _center,
              zoom: 12.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            markers: _markers,
          ),

          // Semi-transparent overlay at the top for contrast
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null && !_isLoading)
            Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Finding Hospitals',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocationAndFetchHospitals,
                        icon: const Icon(Icons.refresh),
                        label: const Text('TRY AGAIN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Finding nearby hospitals...',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Nearest hospital card
          if (_nearestHospital != null && !_isLoading && _errorMessage == null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: 6,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.local_hospital,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nearest Hospital',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _nearestHospital!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                                width:
                                    4), // Add small spacing before the distance badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, // Reduced from 10
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Text(
                                '${_nearestHospital!.distance.toStringAsFixed(1)}km',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13, // Slightly reduced font size
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _nearestHospital!.address,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _openDirections(_nearestHospital!.position),
                                icon: const Icon(Icons.directions),
                                label: const Text('DIRECTIONS'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _callHospital(
                                  _nearestHospital!.phoneNumber,
                                  _nearestHospital!.name),
                              icon: _nearestHospital!.phoneNumber.isEmpty
                                  ? const Icon(Icons.phone_callback)
                                  : const Icon(Icons.call),
                              label: _nearestHospital!.phoneNumber.isEmpty
                                  ? const Text('GET NUMBER')
                                  : const Text('CALL'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                side: BorderSide(
                                    color: theme.colorScheme.primary),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Hospital list
          if (!_isLoading && _errorMessage == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Nearby Hospitals',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_hospitals.length} Found',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _hospitals.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.local_hospital,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No hospitals found nearby',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _hospitals.length,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                itemBuilder: (context, index) {
                                  final hospital = _hospitals[index];
                                  final isNearest = index == 0;

                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isNearest
                                            ? Colors.green.shade200
                                            : Colors.grey.shade200,
                                        width: isNearest ? 2 : 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        mapController?.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                              hospital.position, 16),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isNearest
                                                    ? Colors.green.shade100
                                                    : theme.colorScheme.primary
                                                        .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.local_hospital,
                                                  color: isNearest
                                                      ? Colors.green.shade700
                                                      : theme
                                                          .colorScheme.primary,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                width: 12), // Reduced from 16
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          hospital.name,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize:
                                                                15, // Slightly reduced
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      if (isNearest)
                                                        Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 4),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal:
                                                                6, // Reduced from 8
                                                            vertical: 2,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .green.shade100,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Text(
                                                            'Nearest',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  11, // Reduced from 12
                                                              color: Colors
                                                                  .green
                                                                  .shade700,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${hospital.distance.toStringAsFixed(2)} km away',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Space-efficient action buttons
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.directions,
                                                    color: theme
                                                        .colorScheme.primary,
                                                    size: 22, // Reduced size
                                                  ),
                                                  onPressed: () =>
                                                      _openDirections(
                                                          hospital.position),
                                                  tooltip: 'Get Directions',
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth:
                                                        36, // Reduced from default
                                                    minHeight:
                                                        36, // Reduced from default
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                      6), // Reduced from 8
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    hospital.phoneNumber.isEmpty
                                                        ? Icons.phone_callback
                                                        : Icons.call,
                                                    color: theme
                                                        .colorScheme.secondary,
                                                    size: 22, // Reduced size
                                                  ),
                                                  onPressed: () =>
                                                      _callHospital(
                                                          hospital.phoneNumber,
                                                          hospital.name),
                                                  tooltip: hospital
                                                          .phoneNumber.isEmpty
                                                      ? 'Get Phone Number'
                                                      : 'Call Hospital',
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth:
                                                        36, // Reduced from default
                                                    minHeight:
                                                        36, // Reduced from default
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                      6), // Reduced from 8
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // My location button
          Positioned(
            right: 20,
            bottom: 270,
            child: FloatingActionButton(
              onPressed: () {
                mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation, 15),
                );
              },
              backgroundColor: Colors.white,
              elevation: 4,
              child: Icon(
                Icons.my_location,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
