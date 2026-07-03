import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OrderService {
  static Future<Map<String, dynamic>> checkout(String paymentMethod, String deliveryAddress) async {
    final uri = Uri.parse('${AuthService.baseUrl}/checkout');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
      body: json.encode({
        'payment_method': paymentMethod,
        'delivery_address': deliveryAddress,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to checkout');
    }
  }

  static Future<void> completeOrder(int orderId) async {
    final uri = Uri.parse('${AuthService.baseUrl}/orders/$orderId/complete');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to complete order');
    }
  }

  static Future<Map<String, dynamic>> getOrder(int orderId) async {
    final uri = Uri.parse('${AuthService.baseUrl}/orders/$orderId');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to get order details');
    }
  }

  static Future<List<dynamic>> getOrders() async {
    final uri = Uri.parse('${AuthService.baseUrl}/orders');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to get orders');
    }
  }
}

