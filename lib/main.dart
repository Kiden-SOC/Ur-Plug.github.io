import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // IMPORTED THE PROVIDER PACKAGE
import 'firebase_options.dart';

// Imports your global app state controllers
import 'state/provider_profile_controller.dart';
import 'state/customer_profile_controller.dart';
import 'views/auth/login_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        // Both profile controllers are now active globally across the entire app
        ChangeNotifierProvider(create: (_) => ProviderProfileController()),
        ChangeNotifierProvider(create: (_) => CustomerProfileController()),
      ],
      child: const UrPlugApp(),
    ),
  );
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
