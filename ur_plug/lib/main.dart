import 'package:flutter/material.dart';
// Imports your login screen from your views directory
import 'views/auth/login_screen.dart'; 

void main() {
  runApp(const UrPlugApp());
}

class UrPlugApp extends StatelessWidget {
  const UrPlugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ur Plug',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Set the primary brand color for your entire app
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066FF),
          primary: const Color(0xFF0066FF),
        ),
        useMaterial3: true,
      ),
      // Set the LoginScreen as the starting point of the application
      home: const LoginScreen(),
    );
  }
}


