import 'package:flutter/material.dart';
import 'screens/report_accident_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/first_aid_guide_screen.dart';
import 'screens/nearby_hospitals_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  String _profileImageUrl = '';
  bool _isLoadingProfileImage = true;

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.home_rounded,
      'label': 'Home',
      'activeIcon': Icons.home_filled
    },
    {
      'icon': Icons.location_on_outlined,
      'label': 'Map',
      'activeIcon': Icons.location_on_rounded
    },
    {
      'icon': Icons.notifications_outlined,
      'label': 'Alerts',
      'activeIcon': Icons.notifications_rounded
    },
    {
      'icon': Icons.person_outline_rounded,
      'label': 'Profile',
      'activeIcon': Icons.person_rounded
    },
  ];

  @override
  void initState() {
    super.initState();
    // Add short delay to ensure the widget is fully mounted
    Future.microtask(() => _loadProfileImage());
  }

  // Fix: Adding the getUserName method that was missing
  Future<String> _getUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'User';
      
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!docSnapshot.exists) return 'User';
      
      final data = docSnapshot.data();
      if (data != null && data.containsKey('name')) {
        return data['name'] as String? ?? 'User';
      }
      
      return 'User';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'User';
    }
  }

  Future<void> _loadProfileImage() async {
    if (!mounted) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoadingProfileImage = false);
        return;
      }
      
      // Use a try-catch specifically for the Firestore operation
      try {
        final DocumentSnapshot doc = 
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (!mounted) return;
        
        if (doc.exists) {
          final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          final String imageUrl = data?['profileImageUrl'] ?? '';
          
          if (mounted) {
            setState(() {
              _profileImageUrl = imageUrl;
              _isLoadingProfileImage = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingProfileImage = false);
        }
      } catch (firestoreError) {
        print('Firestore error: $firestoreError');
        if (mounted) setState(() => _isLoadingProfileImage = false);
      }
    } catch (e) {
      print('Error loading profile image: $e');
      if (mounted) setState(() => _isLoadingProfileImage = false);
    }
  }
  
  // When moving to profile screen, completely refresh the profile data on return
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 1: // Map tab
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
        break;
      case 3: // Profile tab
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        ).then((_) {
          // Wait a moment before reloading
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _loadProfileImage();
          });
        });
        break;
    }
  }

  // Fix: Update the profile avatar builder to handle errors better
  Widget _buildProfileAvatar() {
    if (_isLoadingProfileImage) {
      // Show loading indicator
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
          ),
          shape: BoxShape.circle,
        ),
        child: const CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      );
    } else if (_profileImageUrl.isNotEmpty) {
      // Display the profile image with better error handling
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
          ),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            _profileImageUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            // Use cacheWidth to optimize memory usage
            cacheWidth: 100, 
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Log the error but don't crash
              print('Error loading image: $error');
              
              // Return fallback avatar with initial
              return FutureBuilder<String>(
                future: _getUserName(),
                builder: (context, snapshot) {
                  final initial = snapshot.data?.isNotEmpty == true 
                    ? snapshot.data![0].toUpperCase() 
                    : '?';
                    
                  return CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    } else {
      // Fall back to showing the user's initials
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
          ),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: FutureBuilder<String>(
            future: _getUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                );
              }
              
              final initial = snapshot.data?.isNotEmpty == true 
                ? snapshot.data![0].toUpperCase() 
                : '?';
                
              return Text(
                initial,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFF),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.08),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Profile Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Row(
                            children: [
                              // Avatar - Updated to use our new method
                              _buildProfileAvatar(),
                              const SizedBox(width: 15),
                              // Welcome Text
                              Expanded(
                                child: FutureBuilder<String>(
                                  future: _getUserName(),
                                  builder: (context, snapshot) {
                                    return Text(
                                      'Welcome back,\n${snapshot.data ?? 'User'}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Notification Icon
                              _buildNotificationBadge(),
                            ],
                          ),
                        ),
                        // Connect Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildConnectButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: CustomScrollView(
          slivers: [
            // Emergency Actions Section
            _buildEmergencyActionsHeader(),
            _buildEmergencyButtons(),
            // Services Grid
            _buildServicesGrid(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildConnectButton() {
    // Add debug print to check for connection status
    debugPrint('Debug: Building connect button, connection state: active');
    
    return Container(
      height: 60,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // Add minimal error handling to avoid crashes
            try {
              debugPrint('Connect button tapped - checking connection');
              
              // Simple check to verify debug connection
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  debugPrint('Connection verified - debug is working');
                }
              });
            } catch (e) {
              // Silent catch to prevent crashes
              print('Error during connect action: $e');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bluetooth_searching,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Connect Safety Device',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Icon(Icons.notifications_none_rounded, 
            color: Colors.blue[700],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyActionsHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.emergency, color: Colors.red[700], size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Emergency Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButtons() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              _buildEmergencyButton(
                'SOS',
                Icons.warning_rounded,
                Colors.red[700]!,
                () {},
              ),
              _buildEmergencyButton(
                'Call Help',
                Icons.phone_rounded,
                Colors.green[700]!,
                () {},
              ),
              _buildEmergencyButton(
                'Share Location',
                Icons.location_on_rounded,
                Colors.orange[700]!,
                () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          // Increased aspect ratio to provide more height
          childAspectRatio: 0.95,
          // Added minimum height
          mainAxisExtent: 180,
        ),
        delegate: SliverChildListDelegate([
          _buildServiceCard(
            'Report Accident',
            Icons.car_crash,
            Colors.red.shade400,
            'Quick accident reporting',
            () => Navigator.push(context, 
              MaterialPageRoute(builder: (context) => const ReportAccidentScreen())
            ),
          ),
          _buildServiceCard(
            'Emergency Contacts',
            Icons.contacts_rounded,
            Colors.purple,
            'Quick access to emergency contacts',
            () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const EmergencyContactsScreen())
            ),
          ),
          _buildServiceCard(
            'First Aid Guide',
            Icons.medical_services_rounded,
            Colors.teal,
            'First aid instructions',
            () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const FirstAidGuideScreen())
            ),
          ),
          _buildServiceCard(
            'Nearby Hospitals',
            Icons.local_hospital_rounded,
            Colors.indigo,
            'Find nearby hospitals',
            () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const NearbyHospitalsScreen())
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: NavigationBar(
          height: 65,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          indicatorColor: Colors.blue.shade50,
          destinations: _navItems.map((item) {
            bool isSelected = _navItems.indexOf(item) == _selectedIndex;
            return NavigationDestination(
              icon: Icon(
                item['icon'],
                color: isSelected ? Colors.blue : Colors.grey[400],
              ),
              selectedIcon: Icon(
                item['activeIcon'],
                color: Colors.blue,
              ),
              label: item['label'],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, String description, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16), // Reduced padding
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Added this
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 28), // Slightly reduced icon size
              ),
              const SizedBox(height: 8), // Reduced spacing
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Slightly reduced font size
                ),
              ),
              const SizedBox(height: 4),
              Flexible( // Added Flexible
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.2, // Added line height
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
