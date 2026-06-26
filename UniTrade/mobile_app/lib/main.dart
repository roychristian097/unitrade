import 'dart:convert'; // Huruf 'i' harus kecil
import 'package:http/http.dart' as http; 
import 'package:flutter/material.dart';
import 'login_page.dart'; // Import file login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniTrade App',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        brightness: Brightness.dark, 
      ),
      home: const LoginPage(), // Menjadikan LoginPage sebagai halaman utama
    );
  }
}

// File marketplace_screen.dart digunakan untuk halaman utama