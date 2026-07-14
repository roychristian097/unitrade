import 'dart:convert'; // Huruf 'i' harus kecil
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'login_page.dart'; // Import file login
import 'splash_screen.dart'; // Import file splash screen
import 'auth_service.dart';
import 'chat_service.dart';
import 'admin_service.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'UniTrade App',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFE67E22),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE67E22),
              secondary: Color(0xFFD35400),
              surface: Colors.white,
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
                TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFE67E22),
            scaffoldBackgroundColor: const Color(0xFF0F0F11),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE67E22),
              secondary: Color(0xFFD35400),
              surface: Color(0xFF1E1E22),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
                TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              },
            ),
          ),
          home:
              const SplashScreen(), // Menjadikan SplashScreen sebagai halaman utama
        );
      },
    );
  }
}
