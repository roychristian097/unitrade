import 'package:flutter/material.dart';
import 'theme.dart';
import 'dart:ui'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main_hub.dart';
import 'auth_service.dart';
import 'register_page.dart';
class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isLoading = false; // State untuk mengontrol animasi loading tombol

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengirim data input ke Backend FastAPI
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      await AuthService.login(email, password);

      if (!mounted) return;

      // Navigasi ke halaman utama (MainHub)
      Navigator.pushReplacement(context, 
        MaterialPageRoute(
          builder: (context) => const MainHub(showWelcome: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('âŒ Error: $e'), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor, 
      body: Stack(
        children: [
          // 1. Efek Pendaran Gradasi Oranye di Latar Belakang
          Positioned(
            bottom: -160,
            left: -50,
            right: -50,
            child: Container(
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFE67E22).withOpacity(0.25), 
                    Color(0xFFE67E22).withOpacity(0.05),
                    Colors.transparent,
                  ],
                  radius: 0.7,
                ),
              ),
            ),
          ),

          // 2. Konten Utama Kontainer Login
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar: Logo & Tombol Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD35400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              'assets/images/logo_combined.png',
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(context.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: Colors.grey, size: 20),
                            onPressed: () {
                              themeNotifier.value = context.isDark ? ThemeMode.light : ThemeMode.dark;
                            },
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, 
                                MaterialPageRoute(builder: (context) => const RegisterPage()),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: context.textColor.withOpacity(0.6), 
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 50),

                  // Kartu Login Sentral dengan Efek Frosted Glass
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: context.surfaceColor.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: context.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/images/logo_mark.png',
                                width: 52,
                                height: 52,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Welcome Back',
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Center(
                              child: Text(
                                'Sign in to your account and manage your dashboard.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            SizedBox(height: 28),

                            // Input Field: Email
                            Text(
                              'Email field',
                              style: TextStyle(
                                color: Color(0xFFE67E22),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              style: TextStyle(color: context.textColor),
                              decoration: InputDecoration(
                                hintText: 'Your email address',
                                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                                prefixIcon: Icon(Icons.mail_outline, color: Colors.grey[500], size: 20),
                                filled: true,
                                fillColor: context.surfaceHighlight,
                                contentPadding: EdgeInsets.symmetric(vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Color(0xFFE67E22).withOpacity(0.4)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE67E22), width: 1.5),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Input Field: Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    color: Color(0xFFE67E22),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: Color(0xFFE67E22),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _isPasswordObscured,
                              style: TextStyle(color: context.textColor),
                              decoration: InputDecoration(
                                hintText: 'Your password',
                                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500], size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.grey[500],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordObscured = !_isPasswordObscured;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: context.surfaceHighlight,
                                contentPadding: EdgeInsets.symmetric(vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: context.borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE67E22), width: 1.5),
                                ),
                              ),
                            ),
                            SizedBox(height: 28),

                            // Tombol Log in Berlogika Loading
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE67E22),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading 
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(color: context.textColor, strokeWidth: 2),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Log in',
                                            style: TextStyle(
                                              color: context.textColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward, color: context.textColor, size: 18),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 35),

                  // Tombol Metode Login Sosial berbentuk kapsul
                  _buildSocialButton(
                    text: 'Log in with Google',
                    icon: Icons.g_mobiledata_rounded, 
                    onPressed: () {},
                  ),
                  SizedBox(height: 12),
                  _buildSocialButton(
                    text: 'Log in with Apple',
                    icon: Icons.apple,
                    onPressed: () {},
                  ),
                  SizedBox(height: 40),

                  // Footer Hak Cipta
                  Text(
                    '© 2026 UniTrade, Inc. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: context.surfaceColor.withOpacity(0.6),
          side: BorderSide(color: context.borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), 
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.textColor, size: 22),
            SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(color: context.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
