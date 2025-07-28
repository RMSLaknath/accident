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

class _ReportAccidentScreenState extends State<ReportAccidentScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  static const LatLng _center = LatLng(6.927079, 79.861244);
  LatLng _currentLocation = _center;
  final Set<Marker> _markers = {};
  XFile? _selectedImage;
  
  // Animation controller for UI elements
  late AnimationController _animationController;
  // Fix: Initialize the animation with a default value instead of using late
  Animation<double> _fadeAnimation = const AlwaysStoppedAnimation<double>(1.0);

  // Add a variable to track upload progress
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _getCurrentLocation();
  }

  // Separate method to initialize animations to improve readability and organization
  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Start the animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    mapController?.dispose();
    super.dispose();
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

  // Modify the success dialog for better UI
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 72,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Accident Reported Successfully!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your accident report has been submitted along with the location and photo evidence.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  // Improve confirmation dialog
  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Confirm Report',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to report an accident at this location? This will capture a photo and share your current location.',
            style: TextStyle(
              height: 1.5,
              fontSize: 15,
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('CONFIRM'),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        );
      },
    ) ?? false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Report Accident',
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
              icon: const Icon(Icons.history, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccidentHistoryScreen(),
                  ),
                );
              },
              tooltip: 'View History',
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
          
          // Top Panel with helpful info - using FadeTransition for animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
              child: Card(
                elevation: 6,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.9),
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Tap "Report Accident" to capture and upload a photo of the accident.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Action Buttons Column with SlideTransition
          Positioned(
            bottom: 120,
            right: 20,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildFloatingButton(
                    context: context,
                    icon: Icons.warning_amber_rounded,
                    backgroundColor: Colors.red.shade700,
                    iconColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.white),
                              SizedBox(width: 10),
                              Text('SOS Alert Sent!'),
                            ],
                          ),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: EdgeInsets.only(
                            bottom: size.height * 0.1,
                            left: 20,
                            right: 20,
                          ),
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
          ),
          
          // Bottom Panel with Report Button - using SlideTransition for animation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report an Accident',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Take a photo and share your location',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          print('Report Accident button clicked.');
                          // Show confirmation dialog before proceeding
                          final confirmed = await _showConfirmationDialog();
                          if (confirmed) {
                            await _pickImage();
                            await _uploadImage();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'REPORT ACCIDENT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: backgroundColor,
          elevation: 0,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
