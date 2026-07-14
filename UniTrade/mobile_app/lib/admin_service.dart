import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminService {
  static const String baseUrl = 'http://192.168.100.63:8000/admin';

  static Future<List<dynamic>> getPendingUsers() async {
    return _get('/users');
  }

  static Future<List<dynamic>> getPendingProducts() async {
    return _get('/products');
  }

  static Future<List<dynamic>> getPendingServices() async {
    return _get('/services');
  }

  static Future<void> approveUser(int id) async {
    await _post('/users/$id/approve');
  }

  static Future<void> rejectUser(int id) async {
    await _post('/users/$id/reject');
  }

  static Future<void> approveProduct(int id) async {
    await _post('/products/$id/approve');
  }

  static Future<void> rejectProduct(int id) async {
    await _post('/products/$id/reject');
  }

  static Future<void> approveService(int id) async {
    await _post('/services/$id/approve');
  }

  static Future<void> rejectService(int id) async {
    await _post('/services/$id/reject');
  }

  static Future<List<dynamic>> _get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  static Future<void> _post(String path) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Action failed');
    }
  }
}
