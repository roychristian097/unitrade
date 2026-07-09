import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class WishlistService {
  static Future<void> addToWishlist(int productId) async {
    final uri = Uri.parse('${AuthService.baseUrl}/wishlist/$productId');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to add to wishlist');
    }
  }

  static Future<void> removeFromWishlist(int productId) async {
    final uri = Uri.parse('${AuthService.baseUrl}/wishlist/$productId');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to remove from wishlist');
    }
  }
}
