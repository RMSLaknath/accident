import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  _NearbyHospitalsScreenState createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  GoogleMapController? mapController;
  static const LatLng _center = LatLng(6.927079, 79.861244);
  LatLng _currentLocation = _center;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFetchHospitals();
  }

  Future<void> _getCurrentLocationAndFetchHospitals() async {
    await _getCurrentLocation();
    _fetchNearbyHospitals();
  }

  Future<void> _fetchNearbyHospitals() async {
    // Example hospitals data - Replace with actual API call
    final List<Map<String, dynamic>> hospitals = [
      {
        'name': 'National Hospital',
        'position': const LatLng(6.9271, 79.8612),
      },
      {
        'name': 'Nawaloka Hospital',
        'position': const LatLng(6.9175, 79.8528),
      },
      // Add more hospitals
    ];

    setState(() {
      _markers.addAll(
        hospitals.map(
          (hospital) => Marker(
            markerId: MarkerId(hospital['name']),
            position: hospital['position'],
            infoWindow: InfoWindow(
              title: hospital['name'],
              snippet: 'Tap to get directions',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        ),
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are required')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 15),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Hospitals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            markers: _markers,
          ),
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildFloatingButton(
                  context: context,
                  icon: Icons.my_location,
                  backgroundColor: Colors.white,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  onPressed: _getCurrentLocation,
                  tooltip: 'My Location',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required BuildContext context,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Tooltip(
        message: tooltip,
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          elevation: 0,
          mini: false,
          child: Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}