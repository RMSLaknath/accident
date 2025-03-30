import 'package:accident/homescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' show Random, cos, pi, sin;
import 'package:accident/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _typewriterController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shineAnimation;
  bool _showTagline = false;
  final List<String> _taglines = ['Smart.', 'Protect.', 'Fast.'];
  int _currentTagline = 0;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Pulse effect controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Typewriter effect controller
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 0.9, curve: Curves.easeInOut),
      ),
    );

    // Start animations sequence
    _controller.forward();

    // Show taglines sequentially
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _showTagline = true);
        _animateTaglines();
      }
    });

    // Navigate after animations complete
    Future.delayed(const Duration(milliseconds: 4500), checkAuthAndNavigate);
  }

  void _animateTaglines() {
    if (_currentTagline < _taglines.length - 1) {
      _typewriterController.forward().then((_) {
        _typewriterController.reset();
        setState(() => _currentTagline++);
        Future.delayed(const Duration(milliseconds: 300), _animateTaglines);
      });
    }
  }

  Future<void> checkAuthAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              user != null ? const MyHomePage() : const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade700;
    final secondaryColor = Colors.blue.shade500;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Updated gradient background
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.5 + (_glowAnimation.value * 0.5),
                        colors: [
                          Colors.white,
                          Colors.blue.shade50,
                          Colors.white,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                },
              ),

              // Updated particle effects
              CustomPaint(
                painter: ParticlesPainter(
                  animation: _pulseController,
                  color: primaryColor,
                ),
                size: Size.infinite,
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Updated logo container
                    Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Updated glow effect
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  primaryColor.withOpacity(0.2 * _glowAnimation.value),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                          
                          // Updated logo container with shield icon
                          Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5 * _glowAnimation.value,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.shield, // Changed from shield_outlined to shield
                              size: 60,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Updated app name
                    Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: ShimmerText(
                        text: 'ProtectGO360',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 1.5,
                        ),
                        baseColor: primaryColor,
                        highlightColor: secondaryColor,
                      ),
                    ),

                    // Updated taglines
                    if (_showTagline)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _taglines.asMap().entries.map((entry) {
                            final isActive = entry.key == _currentTagline;
                            return AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                color: isActive ? primaryColor : Colors.grey.shade600,
                                fontSize: isActive ? 18 : 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(entry.value),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Add ParticlesPainter implementation
class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final List<Particle> particles = [];

  ParticlesPainter({
    required this.animation,
    required this.color,
  }) {
    // Initialize particles
    for (var i = 0; i < 30; i++) {
      particles.add(Particle());
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      final progress = (animation.value + particle.offset) % 1.0;
      final position = Offset(
        particle.dx * size.width,
        size.height * progress,
      );
      canvas.drawCircle(position, particle.radius * progress, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

class Particle {
  final double dx = Random().nextDouble();
  final double offset = Random().nextDouble();
  final double radius = Random().nextDouble() * 2 + 1;
}

// Add ShimmerText implementation
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerText({
    super.key,
    required this.text,
    required this.style,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            widget.baseColor,
            widget.highlightColor,
            widget.baseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientRotation(_shimmerController.value * 2 * pi),
        ).createShader(bounds);
      },
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}
