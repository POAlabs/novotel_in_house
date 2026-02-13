import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/routes.dart';
import 'services/auth_service.dart';

/// Main entry point for Novotel Westlands In House app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize Firebase
  // If Firebase is not configured, app will run in demo mode
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AuthService.firebaseInitialized = true;
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Running in demo mode with dummy accounts');
    AuthService.firebaseInitialized = false;
  }
  
  runApp(const NovotelInHouseApp());
}

/// Root application widget
class NovotelInHouseApp extends StatelessWidget {
  const NovotelInHouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App metadata
      title: 'Novotel Westlands In House',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
        ),
        useMaterial3: true,
      ),
      
      // Navigation setup
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutes(),
    );
  }
}
