import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ChatService {
  static const String baseUrl = 'http://192.168.100.63:8000';

  static Future<List<dynamic>> getChats() async {
    if (AuthService.token == null) throw Exception("Not logged in");
    final response = await http.get(
      Uri.parse('$baseUrl/chats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load chats');
    }
  }

  static Future<List<dynamic>> getChatHistory(int otherUserId, int productId) async {
    if (AuthService.token == null) throw Exception("Not logged in");
    final response = await http.get(
      Uri.parse('$baseUrl/chats/$otherUserId/$productId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load chat history');
    }
  }

  static Future<void> sendMessage(int receiverId, int productId, String message) async {
    if (AuthService.token == null) throw Exception("Not logged in");
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.token}',
      },
      body: json.encode({
        'receiver_id': receiverId,
        'product_id': productId,
        'message': message,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to send message');
    }
  }
}
