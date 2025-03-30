import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmergencyContact {
  final String? id;
  final String userId;
  final String name;
  final String relationship;
  final String phoneNumber;

  EmergencyContact({
    this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'relationship': relationship,
      'phoneNumber': phoneNumber,
    };
  }
}

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  bool _isLoading = true;
  String _error = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Maximum number of emergency contacts allowed
  final int _maxContacts = 3;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize Firebase: $e';
        _isLoading = false;
      });
    }
  }

  String _name = '';
  String _relationship = '';
  String _phoneNumber = '';

  Future<void> _addContact() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add contacts')),
      );
      return;
    }

    // Check if user already has maximum number of contacts
    final contactsSnapshot = await _firestore
        .collection('emergency_contacts')
        .where('userId', isEqualTo: user.uid)
        .get();
    
    if (contactsSnapshot.docs.length >= _maxContacts) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              Text('Limit Reached'),
            ],
          ),
          content: const Text(
            'You can only add up to 3 emergency contacts. Please remove an existing contact before adding a new one.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.person_add, color: Colors.blue),
            Text('Add Emergency Contact'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => _name = value,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Relationship',
                prefixIcon: const Icon(Icons.family_restroom),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => _relationship = value,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => _phoneNumber = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_name.isNotEmpty && _relationship.isNotEmpty && _phoneNumber.isNotEmpty) {
                try {
                  await _firestore.collection('emergency_contacts').add({
                    'userId': user.uid,
                    'name': _name,
                    'relationship': _relationship,
                    'phoneNumber': _phoneNumber,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add contact: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(_error)),
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view contacts')),
      );
    }

    // Enhanced color scheme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    final secondaryColor = isDark ? Colors.indigo.shade300 : Colors.indigo.shade500;
    final backgroundColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;
    final surfaceColor = isDark ? Colors.grey.shade800 : Colors.white;
    final accentColor = isDark ? Colors.tealAccent.shade200 : Colors.teal.shade500;

    return Scaffold(
      backgroundColor: backgroundColor,
      // Remove SafeArea and handle padding manually
      body: Column(
        children: [
          // Enhanced header design
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10), // Small padding at top
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency Contacts',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Add people to contact in emergencies',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          // Show help dialog
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(25),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  Icon(Icons.contact_phone_outlined,
                                    size: 50,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Emergency Contacts Help',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'Add up to 3 emergency contacts who will be notified immediately in case of an accident. Make sure to add people who can respond quickly to emergency situations.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.textTheme.bodyMedium?.color,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text('Got it'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Enhanced contact list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('emergency_contacts')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}', 
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  );
                }
        
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                    ),
                  );
                }
        
                final docs = snapshot.data?.docs ?? [];
                
                // Contact count indicator with modern design
                Widget contactCounter = Container(
                  margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.1), 
                        secondaryColor.withOpacity(0.05)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.people, color: primaryColor, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Emergency Contacts',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${docs.length}',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' of ',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '$_maxContacts',
                                    style: TextStyle(
                                      color: secondaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' contacts added',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (docs.length < _maxContacts)
                        GestureDetector(
                          onTap: _addContact,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn().slideY(
                  begin: -0.2,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuad,
                );
                
                if (docs.isEmpty) {
                  return Column(
                    children: [
                      contactCounter,
                      Expanded(
                        child: SingleChildScrollView( // Added SingleChildScrollView
                          child: SafeArea( // Added SafeArea
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40), // Added top spacing
                                  Container(
                                    padding: const EdgeInsets.all(30),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.1),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.contact_phone_outlined,
                                      size: 80,
                                      color: primaryColor.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    'No contacts yet',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 40),
                                    child: Text(
                                      'Add emergency contacts who will be notified in case of an accident',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  ElevatedButton.icon(
                                    onPressed: _addContact,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Your First Contact'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: accentColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40), // Added bottom spacing
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(
                          duration: const Duration(milliseconds: 800),
                        ),
                      ),
                    ],
                  );
                }
        
                return Column(
                  children: [
                    contactCounter,
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final contactInitial = data['name']?[0] ?? 'N';
                          
                          // Generate a color based on the contact's name
                          final List<Color> avatarColors = [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                            Colors.teal.shade400,
                            Colors.amber.shade600,
                            Colors.indigo.shade400,
                          ];
                          final colorIndex = contactInitial.codeUnitAt(0) % avatarColors.length;
        
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark 
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // Show more details or actions when tapped
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Contact details for ${data['name']}'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  splashColor: avatarColors[colorIndex].withOpacity(0.1),
                                  highlightColor: avatarColors[colorIndex].withOpacity(0.05),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Row(
                                      children: [
                                        Hero(
                                          tag: 'contact_${doc.id}',
                                          child: Container(
                                            width: 65,
                                            height: 65,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  avatarColors[colorIndex],
                                                  avatarColors[colorIndex].withOpacity(0.7),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: avatarColors[colorIndex].withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                contactInitial,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['name'] ?? 'No name',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.textTheme.bodyLarge?.color,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: avatarColors[colorIndex].withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.family_restroom, size: 14, color: avatarColors[colorIndex]),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        data['relationship'] ?? 'No relationship',
                                                        style: TextStyle(
                                                          color: avatarColors[colorIndex],
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 12,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  Icon(Icons.phone, size: 14, color: Colors.grey.shade700),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      data['phoneNumber'] ?? 'No number',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade700,
                                                        fontSize: 14,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _ActionButton(
                                              icon: Icons.phone,
                                              color: Colors.green,
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Calling ${data['name']}...'),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 12),
                                            _ActionButton(
                                              icon: Icons.delete_outline,
                                              color: Colors.red,
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  backgroundColor: Colors.transparent,
                                                  builder: (context) => Container(
                                                    padding: const EdgeInsets.all(20),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.only(
                                                        topLeft: Radius.circular(25),
                                                        topRight: Radius.circular(25),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 50,
                                                          height: 5,
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey.shade300,
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 20),
                                                        const Icon(
                                                          Icons.delete_forever,
                                                          color: Colors.red,
                                                          size: 60,
                                                        ),
                                                        const SizedBox(height: 15),
                                                        const Text(
                                                          'Delete Contact',
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 10),
                                                        Text(
                                                          'Are you sure you want to delete ${data['name']}?',
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            color: Colors.grey.shade700,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 25),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: OutlinedButton(
                                                                onPressed: () => Navigator.pop(context),
                                                                style: OutlinedButton.styleFrom(
                                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                                  side: BorderSide(color: Colors.grey.shade300),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(10),
                                                                  ),
                                                                ),
                                                                child: const Text('Cancel'),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 15),
                                                            Expanded(
                                                              child: ElevatedButton(
                                                                onPressed: () async {
                                                                  Navigator.pop(context);
                                                                  try {
                                                                    await _firestore
                                                                        .collection('emergency_contacts')
                                                                        .doc(doc.id)
                                                                        .delete();
                                                                    
                                                                    if (mounted) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text('Contact deleted successfully'),
                                                                          behavior: SnackBarBehavior.floating,
                                                                        ),
                                                                      );
                                                                    }
                                                                  } catch (e) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      SnackBar(
                                                                        content: Text('Failed to delete contact: $e'),
                                                                        behavior: SnackBarBehavior.floating,
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.red,
                                                                  foregroundColor: Colors.white,
                                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(10),
                                                                  ),
                                                                ),
                                                                child: const Text('Delete'),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                            delay: Duration(milliseconds: 100 * index),
                            duration: const Duration(milliseconds: 400),
                          ).slideX(
                            begin: 0.2,
                            delay: Duration(milliseconds: 50 * index),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutQuad,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('emergency_contacts')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final docsLength = snapshot.data?.docs.length ?? 0;
          if (snapshot.hasData && docsLength < _maxContacts) {
            return FloatingActionButton.extended(
              onPressed: _addContact,
              backgroundColor: accentColor,
              elevation: 4,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Contact'),
            ).animate().scale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.bounceOut,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// New widget for action buttons
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}
