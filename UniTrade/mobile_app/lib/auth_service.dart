import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static String? token;
  static Map<String, dynamic>? currentUser;

  static const String baseUrl = 'http://192.168.100.63:8000';

  static Future<void> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      token = data['token'];
      currentUser = data['user'];
    } else {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Login failed');
    }
  }

  static Future<void> register(String name, String email, String password, String campus) async {
    final uri = Uri.parse('$baseUrl/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'campus': campus,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Registration failed');
    }
  }

  static void logout() {
    token = null;
    currentUser = null;
  }
}
