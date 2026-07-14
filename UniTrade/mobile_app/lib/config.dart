import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // ==========================================
  // CONFIG SERVER IP HERE:
  // ==========================================
  // Use '10.0.2.2' for Android Emulator
  // Use 'localhost' or '127.0.0.1' for iOS Simulator / Web
  // Use your computer's local IP (e.g., '192.168.1.4') for physical devices
  static const String host = '192.168.1.4'; 
  static const String port = '8000';

  static String get baseUrl => 'http://$host:$port';
  static String get rawAuthority => '$host:$port';
}
