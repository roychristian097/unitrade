import 'package:flutter/material.dart';
import 'theme.dart';
import 'dart:async';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    // Wait for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    
    // Navigate to Login Page and replace the splash screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor, // Dark background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using the combined logo and adjusting to a compact size
            Image.asset(
              'assets/images/logo_combined.png',
              width: 180, // Compact size
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24),
            // Optional: A subtle loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E22)),
            ),
          ],
        ),
      ),
    );
  }
}
