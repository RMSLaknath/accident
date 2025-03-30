import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'homescreen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ProtectGO360',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3), // Changed to blue
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF64B5F6),
          tertiary: const Color(0xFF1976D2),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(), // Always start with splash screen
      routes: {
        '/profile': (context) => const ProfileScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MyHomePage(),
      },
    );
  }
}
