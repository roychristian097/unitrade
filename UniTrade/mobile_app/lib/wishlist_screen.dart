import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme.dart';
import 'auth_service.dart';

class WishlistItem {
  final int id;
  final int productId;
  final String title;
  final int price;
  final String imageUrl;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      title: json['product'] != null ? json['product']['title'] ?? 'Unknown' : 'Unknown',
      price: json['product'] != null ? json['product']['price'] ?? 0 : 0,
      imageUrl: json['product'] != null ? json['product']['image_url'] ?? '' : '',
    );
  }
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<List<WishlistItem>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _wishlistFuture = fetchWishlist();
  }

  Future<List<WishlistItem>> fetchWishlist() async {
    try {
      final token = AuthService.token;
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/wishlist'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((w) => WishlistItem.fromJson(w)).toList();
      } else {
        throw Exception('Failed to load wishlist');
      }
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text("My Wishlist"),
      ),
      body: FutureBuilder<List<WishlistItem>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "Your wishlist is empty",
                style: TextStyle(color: context.colors.textMuted, fontSize: 16),
              ),
            );
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.colors.cardBg,
                          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                        ),
                        child: item.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                                child: Image.network(item.imageUrl, fit: BoxFit.cover),
                              )
                            : Icon(Icons.image, color: context.colors.textMuted),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text("Rp ${item.price}", style: TextStyle(color: context.colors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.favorite, color: Colors.redAccent),
                        onPressed: () {
                          // Implement remove from wishlist later
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remove feature coming soon!')));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
