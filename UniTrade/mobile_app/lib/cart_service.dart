import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CartService {
  static Future<List<dynamic>> getCart() async {
    final uri = Uri.parse('${AuthService.baseUrl}/cart');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['cart_items'] ?? [];
    } else {
      throw Exception('Failed to load cart');
    }
  }

  static Future<void> addToCart(int productId, {int quantity = 1}) async {
    final uri = Uri.parse('${AuthService.baseUrl}/cart');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
      body: json.encode({
        'product_id': productId,
        'quantity': quantity,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to add to cart');
    }
  }

  static Future<void> removeFromCart(int cartId) async {
    final uri = Uri.parse('${AuthService.baseUrl}/cart/$cartId');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to remove from cart');
    }
  }

  static Future<void> updateCartQuantity(int cartId, int quantity) async {
    final uri = Uri.parse('${AuthService.baseUrl}/cart/$cartId');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
      body: json.encode({
        'quantity': quantity,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to update cart quantity');
    }
  }
}
