import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';

class FirstAidGuideScreen extends StatefulWidget {
  const FirstAidGuideScreen({super.key});

  @override
  State<FirstAidGuideScreen> createState() => _FirstAidGuideScreenState();
}

class _FirstAidGuideScreenState extends State<FirstAidGuideScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Emergency',
    'Wounds',
    'Injuries',
    'Medical'
  ];

  final List<Map<String, dynamic>> _firstAidGuides = [
    {
      'title': 'CPR (Cardiopulmonary Resuscitation)',
      'subtitle': 'For cardiac arrest emergencies',
      'content': [
        '1. Check if the person is responsive by tapping their shoulder and shouting "Are you okay?"',
        '2. Call emergency services (911 or local emergency number) immediately',
        '3. Place the person on their back on a firm surface',
        '4. Kneel beside them and place the heel of one hand on the center of their chest',
        '5. Place your other hand on top and interlock your fingers',
        '6. Keep your arms straight and position your shoulders above your hands',
        '7. Press down hard and fast at a rate of 100-120 compressions per minute',
        '8. Allow the chest to completely recoil after each compression',
        '9. Continue until professional help arrives or the person shows signs of life',
      ],
      'icon': Icons.favorite,
      'color': Colors.red,
      'emergencyLevel': 'Critical',
      'category': 'Emergency',
      'localImage': 'assets/images/first_aid/cpr.png',
      'videoLink':
          'https://www.youtube.com/watch?v=cosVBV96E2g' // Changed from youtu.be format
    },
    {
      'title': 'Bleeding Control',
      'subtitle': 'For severe bleeding wounds',
      'content': [
        '1. Apply direct pressure to the wound using a clean cloth or bandage',
        '2. If blood soaks through, add more material without removing the original bandage',
        '3. Maintain pressure for at least 15 minutes',
        '4. If possible, elevate the wounded area above the level of the heart',
        '5. Once bleeding is controlled, secure the bandage firmly',
        '6. Seek medical attention as soon as possible',
      ],
      'icon': Icons.healing,
      'color': Colors.deepOrange,
      'emergencyLevel': 'Urgent',
      'category': 'Wounds',
      'localImage': 'assets/images/first_aid/bleeding.png',
      'videoLink':
          'https://www.youtube.com/watch?v=NxO5LvgqZe0' // Changed from youtu.be format
    },
    {
      'title': 'Choking',
      'subtitle': 'When someone cannot breathe, cough or speak',
      'content': [
        '1. Ask the person "Are you choking?" If they can\'t speak and nod yes, take action',
        '2. Stand behind the person and slightly to one side',
        '3. Support their chest with one hand and lean them forward',
        '4. Give up to 5 sharp blows between their shoulder blades with the heel of your hand',
        '5. Check if the obstruction has cleared after each blow',
        '6. If back blows fail, perform abdominal thrusts (Heimlich maneuver)',
        '7. Stand behind them and put both arms around their waist',
        '8. Make a fist with one hand and place it above the navel',
        '9. Grab your fist with your other hand and pull sharply inwards and upwards',
        '10. Repeat up to 5 times, checking if the obstruction clears after each attempt',
      ],
      'icon': Icons.air,
      'color': Colors.blue,
      'emergencyLevel': 'Critical',
      'category': 'Emergency',
      'localImage': 'assets/images/first_aid/choking.png',
      'videoLink':
          'https://www.youtube.com/watch?v=PA9hpOnvtCk' // Changed from youtu.be format
    },
    {
      'title': 'Burns',
      'subtitle': 'For thermal, chemical, or electrical burns',
      'content': [
        '1. Remove the person from the source of the burn',
        '2. Cool the burn with cool (not cold) running water for 10-15 minutes',
        '3. Do not use ice, as it can cause further damage',
        '4. Remove jewelry and tight items from the burned area before swelling occurs',
        '5. Cover the burn with a clean, dry, non-stick bandage',
        '6. Do not apply butter, oil, or ointments to serious burns',
        '7. Seek medical attention for all but minor burns',
      ],
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
      'emergencyLevel': 'Urgent',
      'category': 'Wounds',
      'localImage': 'assets/images/first_aid/burns.png',
      'videoLink':
          'https://www.youtube.com/watch?v=EaJmzB8YgS0' // Changed from youtu.be format
    },
    {
      'title': 'Fractures & Sprains',
      'subtitle': 'For suspected broken bones or joint injuries',
      'content': [
        '1. Keep the injured area immobile - don\'t try to realign bones',
        '2. Apply ice wrapped in a cloth to reduce swelling',
        '3. For suspected fractures, immobilize the area with a splint if available',
        '4. For sprains, follow the RICE method: Rest, Ice, Compression, Elevation',
        '5. Seek medical attention for proper diagnosis and treatment',
      ],
      'icon': Icons.accessibility_new,
      'color': Colors.purple,
      'emergencyLevel': 'Moderate',
      'category': 'Injuries',
      'localImage': 'assets/images/first_aid/fracture.png',
      'videoLink':
          'https://www.youtube.com/watch?v=fEDMwZdF7id' // Changed from youtu.be format
    },
    {
      'title': 'Stroke',
      'subtitle': 'Remember FAST: Face, Arms, Speech, Time',
      'content': [
        'Face: Ask the person to smile. Does one side of the face droop?',
        'Arms: Ask the person to raise both arms. Does one arm drift downward?',
        'Speech: Ask the person to repeat a simple phrase. Is the speech slurred or strange?',
        'Time: If you notice any of these signs, call emergency services immediately',
        'Note the time when symptoms first appeared - this information is crucial for treatment',
      ],
      'icon': Icons.timer,
      'color': Colors.teal,
      'emergencyLevel': 'Critical',
      'category': 'Medical',
      'localImage': 'assets/images/first_aid/stroke.png',
      'videoLink':
          'https://www.youtube.com/watch?v=mA1_CJUSG5I' // Changed from youtu.be format
    },
  ];

  List<Map<String, dynamic>> get _filteredGuides {
    return _firstAidGuides.where((guide) {
      // Filter by search query
      final matchesSearch = guide['title']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          guide['subtitle'].toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by category
      final matchesCategory =
          _selectedCategory == 'All' || guide['category'] == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Verify assets at startup
    _verifyAssets();
  }

  // New method to verify if assets exist
  Future<void> _verifyAssets() async {
    for (final guide in _firstAidGuides) {
      final String assetPath = guide['localImage'] as String;
      try {
        // Try to load the asset to see if it exists
        await rootBundle.load(assetPath);
      } catch (e) {
        debugPrint('Asset not found: $assetPath');
        // Use a default image instead since this one doesn't exist
        guide['localImage'] = 'assets/images/first_aid/default.png';
      }
    }

    // Force rebuild to show correct images
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Guide'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search first aid guides...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ChoiceChip(
                      label: Text(_categories[index]),
                      selected: _selectedCategory == _categories[index],
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory =
                              selected ? _categories[index] : 'All';
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.redAccent,
                      labelStyle: TextStyle(
                        color: _selectedCategory == _categories[index]
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _filteredGuides.isEmpty
                  ? const Center(
                      child: Text('No guides found matching your search'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _filteredGuides.length,
                      itemBuilder: (context, index) {
                        final guide = _filteredGuides[index];
                        return EnhancedFirstAidGuideCard(
                          title: guide['title'],
                          subtitle: guide['subtitle'],
                          content: List<String>.from(guide['content']),
                          icon: guide['icon'],
                          color: guide['color'],
                          emergencyLevel: guide['emergencyLevel'],
                          imageUrl: guide['localImage'],
                          videoLink: guide['videoLink'],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEmergencyDialog(context),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.phone),
        label: const Text('Emergency Call'),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About First Aid Guide'),
          content: const SingleChildScrollView(
            child: Text(
              'This guide provides basic first aid instructions for common emergencies. '
              'In case of a real emergency, always call emergency services immediately. '
              'The information provided here is for educational purposes only and is not '
              'a substitute for professional medical training or advice.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Emergency Services'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEmergencyButton(
                context,
                'Emergency (911)',
                Icons.local_hospital,
                Colors.red,
                '911',
              ),
              const SizedBox(height: 8),
              _buildEmergencyButton(
                context,
                'Poison Control',
                Icons.warning,
                Colors.purple,
                '1-800-222-1222',
              ),
              const SizedBox(height: 8),
              _buildEmergencyButton(
                context,
                'Local Emergency',
                Icons.local_police,
                Colors.blue,
                '119',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmergencyButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String number,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        // In a real app, implement phone call functionality here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling $number...')),
        );
        Navigator.of(context).pop();
      },
    );
  }
}

class EnhancedFirstAidGuideCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> content;
  final IconData icon;
  final Color color;
  final String emergencyLevel;
  final String
      imageUrl; // This will be replaced by localImage in implementation
  final String videoLink;

  const EnhancedFirstAidGuideCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.icon,
    required this.color,
    required this.emergencyLevel,
    required this.imageUrl,
    required this.videoLink,
  });

  @override
  State<EnhancedFirstAidGuideCard> createState() =>
      _EnhancedFirstAidGuideCardState();
}

class _EnhancedFirstAidGuideCardState extends State<EnhancedFirstAidGuideCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _getEmergencyBorderSide(),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Hero(
              tag: widget.title,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
            ),
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(widget.subtitle),
                const SizedBox(height: 4),
                _buildEmergencyTag(),
              ],
            ),
            trailing: IconButton(
              icon: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _animation,
              ),
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                  if (_expanded) {
                    _controller.forward();
                  } else {
                    _controller.reverse();
                  }
                });
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child:
                _expanded ? _buildExpandedContent() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTag() {
    Color tagColor;
    switch (widget.emergencyLevel) {
      case 'Critical':
        tagColor = Colors.red;
        break;
      case 'Urgent':
        tagColor = Colors.orange;
        break;
      default:
        tagColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tagColor),
      ),
      child: Text(
        widget.emergencyLevel,
        style: TextStyle(
          fontSize: 12,
          color: tagColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  BorderSide _getEmergencyBorderSide() {
    Color borderColor;
    switch (widget.emergencyLevel) {
      case 'Critical':
        borderColor = Colors.red;
        break;
      case 'Urgent':
        borderColor = Colors.orange;
        break;
      default:
        borderColor = Colors.green;
        break;
    }

    return BorderSide(color: borderColor, width: 2);
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        // Updated Image section with proper fallback
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(),
          ),
        ),

        // Content section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...widget.content.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      step,
                      style: const TextStyle(height: 1.3),
                    ),
                  )),
            ],
          ),
        ),

        // Updated Action buttons with improved video handling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.video_library, color: Colors.white),
                  label: const Text('Watch Video',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _showVideoOptions(context),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing ${widget.title}...')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Added ${widget.title} to favorites')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // New method to build image with proper fallbacks
  Widget _buildImageWidget() {
    // Generate a unique color based on the title for the placeholder
    final int colorValue = widget.title.hashCode | 0xFF000000;
    final Color placeholderColor = Color(colorValue).withOpacity(0.7);

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [placeholderColor.withOpacity(0.6), placeholderColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Try to load the asset image with proper error handling
          if (widget.imageUrl.startsWith('assets/'))
            Opacity(
              opacity: 0.8,
              child: Image.asset(
                widget.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading image ${widget.imageUrl}: $error');
                  // Return empty container on error - placeholder will show instead
                  return Container();
                },
              ),
            ),

          // Placeholder content - this will always show but be partially
          // visible if the image loads successfully
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 60, color: Colors.white),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          // "First Aid" label
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: widget.color, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'First Aid',
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Debug info for asset path - only show in debug mode
          if (false) // Change to true for debugging
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                color: Colors.black.withOpacity(0.7),
                child: Text(
                  widget.imageUrl,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Enhanced method to show video options dialog
  void _showVideoOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Watch Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'How would you like to open the video for "${widget.title}"?'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser, color: Colors.white),
                label: const Text('Open in Browser',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _launchURL(widget.videoLink, LaunchMode.externalApplication);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon:
                    const Icon(Icons.play_circle_outline, color: Colors.white),
                label: const Text('Open YouTube App',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _openYouTubeApp(widget.videoLink);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Improved method to launch URLs
  Future<void> _launchURL(String url, LaunchMode mode) async {
    // Ensure the URL is a full YouTube URL
    String formattedUrl = url;

    // Convert youtu.be links to full youtube.com links
    if (url.contains('youtu.be')) {
      final videoId = url.split('/').last;
      formattedUrl = 'https://www.youtube.com/watch?v=$videoId';
    }

    final Uri uri = Uri.parse(formattedUrl);

    try {
      final bool canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        final bool launched = await launchUrl(
          uri,
          mode: mode,
        );

        if (!launched) {
          _showVideoError('Failed to open the video link.');
        }
      } else {
        _showVideoError('Cannot open this video link on your device.');
      }
    } catch (e) {
      _showVideoError('Error: ${e.toString()}');
    }
  }

  // Method to specifically attempt to open the YouTube app
  Future<void> _openYouTubeApp(String url) async {
    String videoId = '';

    // Extract video ID from URL
    if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/')[1];
    } else if (url.contains('youtube.com/watch?v=')) {
      videoId = url.split('v=')[1];
      // Handle additional parameters
      int ampersandPosition = videoId.indexOf('&');
      if (ampersandPosition != -1) {
        videoId = videoId.substring(0, ampersandPosition);
      }
    }

    if (videoId.isNotEmpty) {
      // Try to open in YouTube app
      final Uri youtubeAppUri =
          Uri.parse('youtube://www.youtube.com/watch?v=$videoId');
      final Uri youtubeWebUri =
          Uri.parse('https://www.youtube.com/watch?v=$videoId');

      try {
        final bool canLaunchApp = await canLaunchUrl(youtubeAppUri);
        if (canLaunchApp) {
          await launchUrl(youtubeAppUri);
        } else {
          // Fallback to web
          await launchUrl(
            youtubeWebUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        // Final fallback - just try the original URL in external browser
        _launchURL(url, LaunchMode.externalApplication);
      }
    } else {
      // If we couldn't extract a valid video ID, try the original URL
      _launchURL(url, LaunchMode.externalApplication);
    }
  }

  void _showVideoError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Copy URL',
          textColor: Colors.white,
          onPressed: () {
            // Implementation would typically copy the URL to clipboard
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video URL copied to clipboard')),
            );
          },
        ),
      ),
    );
  }
}
