import 'package:accident/screens/accident_history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class ReportAccidentScreen extends StatefulWidget {
  const ReportAccidentScreen({super.key});

  @override
  _ReportAccidentScreenState createState() => _ReportAccidentScreenState();
}

class _ReportAccidentScreenState extends State<ReportAccidentScreen> {
  GoogleMapController? mapController;
  static const LatLng _center = LatLng(6.927079, 79.861244);
  LatLng _currentLocation = _center;
  final Set<Marker> _markers = {};
  XFile? _selectedImage;

  // Add a variable to track upload progress
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: _currentLocation,
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
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

  Future<void> _pickImage() async {
    print('Attempting to pick an image...');
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
      print('Image selected: ${_selectedImage!.path}');
    } else {
      print('No image selected.');
    }
  }

  // Add method to show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Accident Reported Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your accident report has been submitted along with the location and photo evidence.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      print('No image to upload.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture an image first.')),
      );
      return;
    }

    try {
      // Set uploading state to true
      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      // Create a BuildContext reference to capture the dialog context
      BuildContext? dialogContext;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          dialogContext = context; // Store dialog context
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
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
                    const Text('Uploading Photo'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                    const SizedBox(height: 8),
                    const Text(
                      'Please wait while we upload your photo and report the accident...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      // Ensure the user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Close dialog if user is not authenticated
        if (dialogContext != null) {
          Navigator.of(dialogContext!).pop();
        }
        
        print('User not authenticated.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated. Please log in.')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // 1. Upload the image to Firebase Storage (accident_images/)
      print('Uploading image...');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('accident_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Track upload progress
      final uploadTask = storageRef.putFile(File(_selectedImage!.path));
      
      // Listen to upload progress and update UI
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        
        // Update progress in the main state
        setState(() {
          _uploadProgress = progress;
        });
        
        // Force rebuild of dialog with new progress
        if (dialogContext != null && mounted) {
          Navigator.of(dialogContext!).pop(); // Close current dialog
          
          // Show updated dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              dialogContext = context;
              return AlertDialog(
                title: Row(
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
                    const Text('Uploading Photo'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                    const SizedBox(height: 8),
                    const Text(
                      'Please wait while we upload your photo and report the accident...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          );
        }
      });

      // Wait for the upload to complete
      await uploadTask;
      
      // 2. Get the download URL of the image
      final downloadUrl = await storageRef.getDownloadURL();
      print('Image uploaded successfully. Download URL: $downloadUrl');

      // 3. Create a document in Firestore
      final timestamp = DateTime.now();
      
      // 4. Save metadata (who, when, where, image link)
      await FirebaseFirestore.instance.collection('accident_reports').add({
        'userId': user.uid,              // who
        'timestamp': timestamp,          // when
        'location': {                    // where
          'latitude': _currentLocation.latitude,
          'longitude': _currentLocation.longitude,
        },
        'imageUrl': downloadUrl,         // link to image
      });

      print('Accident report saved to Firestore.');
      
      // Close the progress dialog
      if (dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }
      
      // Reset upload state
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });

      // Show success dialog with green checkmark
      _showSuccessDialog();
    } catch (e) {
      // Close the progress dialog
      Navigator.of(context).pop();
      
      // Reset upload state
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
      
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  // Add this method to show confirmation dialog
  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Text('Confirm Report'),
            ],
          ),
          content: const Text(
            'Are you sure you want to report an accident at this location? This will capture a photo and share your current location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('CONFIRM'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
      },
    ) ?? false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Accident',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
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
              zoom: 11.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            markers: _markers,
          ),
          
          // Top Panel with helpful info
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tap "Report Accident" to capture and upload a photo of the accident.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Buttons Column
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildFloatingButton(
                  context: context,
                  icon: Icons.history,
                  backgroundColor: theme.colorScheme.secondary,
                  iconColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccidentHistoryScreen(),
                      ),
                    );
                  },
                  tooltip: 'View Accident History',
                  heroTag: 'history_button',
                ),
                const SizedBox(height: 16),
                _buildFloatingButton(
                  context: context,
                  icon: Icons.warning_amber_rounded,
                  backgroundColor: Colors.red.shade700,
                  iconColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('SOS Alert Sent!'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'SOS Emergency',
                  heroTag: 'sos_button',
                ),
                const SizedBox(height: 16),
                _buildFloatingButton(
                  context: context,
                  icon: Icons.my_location,
                  backgroundColor: Colors.white,
                  iconColor: theme.colorScheme.secondary,
                  onPressed: _getCurrentLocation,
                  tooltip: 'My Location',
                  heroTag: 'location_button',
                ),
              ],
            ),
          ),
          
          // Bottom Panel with Report Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report an Accident',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo and share your current location',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        print('Report Accident button clicked.');
                        // Show confirmation dialog before proceeding
                        final confirmed = await _showConfirmationDialog();
                        if (confirmed) {
                          await _pickImage();
                          await _uploadImage();
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        'REPORT ACCIDENT',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
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
    required String heroTag,
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
          heroTag: heroTag,
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
