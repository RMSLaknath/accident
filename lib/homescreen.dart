import 'package:accident/screens/auth/login_screen.dart';
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

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Force navigation to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _getUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        return userData.data()?['name'] ?? 'User';
      }
      return 'User';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'User';
    }
  }

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
        );
        break;
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
                              // Avatar
                              Container(
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
                                      return Text(
                                        snapshot.data?.isNotEmpty == true 
                                          ? snapshot.data![0].toUpperCase() 
                                          : '?',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
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
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bluetooth_searching,
                  color: Colors.white.withOpacity(0.9),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
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

  // Update service card style
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
