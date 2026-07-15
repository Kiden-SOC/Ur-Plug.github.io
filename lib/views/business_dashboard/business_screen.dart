import '../auth/login_screen.dart';
import 'package:flutter/material.dart';

class BusinessScreen extends StatelessWidget {
  const BusinessScreen({super.key});

  // App Palette Configuration
  static const Color brandPrimary = Color(0xFF005F73);      // Deep Ocean Teal
  static const Color brandSecondary = Color(0xFF0A9396);    // Rich Turquoise       
  static const Color screenBackground = Color(0xFFE0F2F1);  // Turquoise Ice Canvas

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      
      // Clean Theme-Matched App Bar Header with active sign-out
      appBar: AppBar(
        title: const Text(
          'Business Dashboard', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout to Login Screen',
            onPressed: () {
              // Force reset the navigation tree and drop user back at the entry page safely
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Business Dashboard Module\n\nCurrently under active layout design by David.', 
            textAlign: TextAlign.center,
            style: TextStyle(
              color: brandPrimary, 
              fontSize: 15, 
              fontWeight: FontWeight.w500, 
              height: 1.4
            ),
          ),
        ),
      ),
    );
  }
}
