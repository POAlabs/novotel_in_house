import 'package:flutter/material.dart';
import 'config/routes.dart';

/// Main entry point for Novotel Westlands In House app
void main() {
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
