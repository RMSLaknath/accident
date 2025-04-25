import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AccidentHistoryScreen extends StatefulWidget {
  const AccidentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AccidentHistoryScreen> createState() => _AccidentHistoryScreenState();
}

class _AccidentHistoryScreenState extends State<AccidentHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _accidentReports = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccidentReports();
  }

  Future<void> _loadAccidentReports() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Using get() instead of stream to avoid needing the composite index
      final snapshot = await _firestore
          .collection('accident_reports')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final reports = snapshot.docs.map((doc) => doc.data()).toList();
      
      // Sort the reports manually
      reports.sort((a, b) {
        final aTime = (a['timestamp'] as Timestamp).toDate();
        final bTime = (b['timestamp'] as Timestamp).toDate();
        return bTime.compareTo(aTime); // Descending order (newest first)
      });

      setState(() {
        _accidentReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  // Method to open the location in map
  Future<void> _openLocationOnMap(double latitude, double longitude) async {
    // Option 1: Open in Google Maps app or browser
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // If we can't launch external maps, show a dialog with map inside the app
        if (!mounted) return;
        _showMapDialog(latitude, longitude);
      }
    } catch (e) {
      // Fallback to in-app map
      if (!mounted) return;
      _showMapDialog(latitude, longitude);
    }
  }

  // Method to show map in a dialog
  void _showMapDialog(double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: SizedBox(
            width: double.infinity,
            height: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Accident Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(latitude, longitude),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('accidentLocation'),
                        position: LatLng(latitude, longitude),
                        infoWindow: const InfoWindow(title: 'Accident Location'),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accident History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: currentUser == null
          ? const Center(
              child: Text('You need to be logged in to view your history.'),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_accidentReports.isEmpty) {
      return const Center(child: Text('No accident reports found.'));
    }

    return ListView.builder(
      itemCount: _accidentReports.length,
      itemBuilder: (context, index) {
        var data = _accidentReports[index];
        var timestamp = (data['timestamp'] as Timestamp).toDate();
        var formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(timestamp);
        var location = data['location'] as Map<String, dynamic>;
        var imageUrl = data['imageUrl'] as String;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: Icon(
                          Icons.error,
                          color: Colors.red[300],
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reported on $formattedDate',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location: ${location['latitude'].toStringAsFixed(6)}, ${location['longitude'].toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            final latitude = location['latitude'] as double;
                            final longitude = location['longitude'] as double;
                            _openLocationOnMap(latitude, longitude);
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('View on Map'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Share functionality could be added here
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
