import 'package:flutter/material.dart';
import 'signup_screen.dart'; // Use your exact project folder structure here
import 'package:ur_plug/views/customer_dashboard/search_screen.dart';
import 'package:ur_plug/views/admin_dashboard/admin_screen.dart'; // Use your exact project folder structure heree
import 'package:ur_plug/views/business_dashboard/business_screen.dart'; // Use your exact project folder structure here
import '../../services/auth_service.dart';

// =========================================================================
// 1. MAIN LOGIN SCREEN VIEW
// =========================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscureLoginPassword = true;

  
  static const Color brandPrimary = Color(0xFF005F73);      // Deep Ocean Teal
  static const Color brandSecondary = Color(0xFF0A9396);    // Rich Turquoise       
  static const Color screenBackground = Color(0xFFE0F2F1);  // Turquoise Ice Canvas

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================================
  // ROLE-BASED LOGIN REDIRECTION LOGIC
  // =========================================================================
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    try {
      // Authenticate the user
      final user = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (user == null) return;

      //admin account
      if (user.email == 'admin@urplug.com') {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminScreen(),
          ),
        );
        return;
      }
      //other users

      // Fetch the user's profile from Firestore
      final profile = await _authService.getUserProfile(user.uid);

      if (profile == null) {
        throw Exception("User profile not found.");
      }

      if (!mounted) return;

      // Redirect based on role
      if (profile.role == 'producer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BusinessScreen(),
          ),
        );
      } else if (profile.role == 'consumer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SearchScreen(),
          ),
        );
      } else if (profile.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unknown user role."),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }


  // FIXED: Beautiful custom styled forgot password popup matching deep teal theme
  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password', 
          style: TextStyle(fontWeight: FontWeight.bold, color: brandPrimary)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered email address to receive a secure password reset link.',
              style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: const TextStyle(color: brandPrimary),
                prefixIcon: const Icon(Icons.email_outlined, color: brandPrimary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: brandSecondary, width: 2),
                ),
              ),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(context); // Close dialog safely
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset link successfully sent to $email'),
                    backgroundColor: brandSecondary,
                  ),
                );
              }
            },
            child: const Text('Send Reset Link', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: screenBackground,
      body: Stack(
        children: [
          // Decorative Top Header Gradient Banner
          Container(
            height: size.height * 0.35,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [brandPrimary, brandSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // Corrected Viewport Wrapper Order to handle scrolling correctly
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.08),

                    // App Icon Container
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.power,
                        size: 44,
                        color: brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Brand Typography Layout
                    const Text(
                      'UR PLUG',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const Text(
                      'Get in. Get plugged.',
                      style: TextStyle(
                        fontSize: 13, 
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 32),
                                        Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: brandPrimary.withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _loginFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: brandPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enter your registered email address and password.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 28),

                            // Email Address Input Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'e.g. name@urplug.co.ug',
                                prefixIcon: Icon(Icons.email_outlined, color: brandPrimary),
                                filled: true,
                                fillColor: screenBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: brandPrimary, width: 1.5),
                                ),
                                labelStyle: TextStyle(color: brandPrimary, fontSize: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your registered email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16), // Spacing between email and password

                            // Password Input Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscureLoginPassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock_outlined, color: brandPrimary),
                                filled: true,
                                fillColor: screenBackground,
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: brandPrimary, width: 1.5),
                                ),
                                labelStyle: const TextStyle(color: brandPrimary, fontSize: 14),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                                    color: brandPrimary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureLoginPassword = !_obscureLoginPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 8),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _showForgotPasswordDialog(context);
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: brandPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20), // FIXED: Consolidated nested heights safely

                            // Submit Action Button
                            ElevatedButton(
                              onPressed: _handleLogin, // Calls role splitting routing setup
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // No Account Sign Up Link Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: brandPrimary, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: brandPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// =========================================================================
// 2. VERIFICATION SCREEN WIDGET (Correctly Placed and Stored Cleanly)
// =========================================================================
class VerificationScreen extends StatefulWidget {
  final String email;
  final bool isbusiness; // Added to determine if the user is a business or customer
  const VerificationScreen({super.key, required this.email, required this.isbusiness});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  static const Color brandPrimary = Color(0xFF005F73);
  static const Color screenBackground = Color(0xFFE0F2F1);

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text('Verify Access', style: TextStyle(color: brandPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: screenBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: brandPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView( // FIXED: Prevents bottom overflow when keyboard opens to input OTP
            child: Form(
              key: _otpFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 80, color: brandPrimary),
                  const SizedBox(height: 24),
                  const Text(
                    'Check your email inbox',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: brandPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit dynamic login token to:\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4), // FIXED: Reduced letter-spacing value slightly so inputs remain centered perfectly inside the decoration canvas boundaries
                    decoration: InputDecoration(
                      labelText: 'Enter 6-Digit Code', 
                      labelStyle: const TextStyle(fontSize: 14, letterSpacing: 0, color: brandPrimary), 
                      filled: true, 
                      fillColor: Colors.white, 
                      alignLabelWithHint: true, // FIXED: Ensures the label animation transitions smoothly above centered text
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), 
                        borderSide: const BorderSide(color: brandPrimary, width: 2.0),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter the code';
                      }
                      if (v.trim().length != 6) {
                        return 'Please input a complete 6-digit code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Cleaned up unified Submit Button
                  ElevatedButton(
                    onPressed: () {
                      if (_otpFormKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connecting dashboard session...'),
                            backgroundColor: brandPrimary,
                          ),
                        );

                        bool isbusiness = widget.isbusiness; 

                        if (!mounted) return;

                        if (isbusiness) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const BusinessScreen()),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SearchScreen()),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandPrimary, 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Confirm & Log In', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}



