import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'sell_item_screen.dart';
import 'sell_service_screen.dart';
import 'auth_service.dart';
import 'marketplace_screen.dart'; // for Product
import 'services_screen.dart' hide formatCurrency; // for ServiceItem
import 'product_detail_screen.dart';
import 'service_detail_screen.dart';

class SellHubScreen extends StatefulWidget {
  const SellHubScreen({super.key});

  @override
  State<SellHubScreen> createState() => _SellHubScreenState();
}

class _SellHubScreenState extends State<SellHubScreen> {
  Future<Map<String, List<dynamic>>>? _listingsFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _fetchUserListings();
  }

  Future<Map<String, List<dynamic>>> _fetchUserListings() async {
    final uri = Uri.http('192.168.100.63:8000', '/user/listings');
    final headers = {'Content-Type': 'application/json'};
    if (AuthService.token != null) {
      headers['Authorization'] = 'Bearer ${AuthService.token}';
    }

    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      final products = (data['products'] as List).map((p) => Product.fromJson(p)).toList();
      final services = (data['services'] as List).map((s) => ServiceItem.fromJson(s)).toList();
      
      return {
        'products': products,
        'services': services,
      };
    } else {
      throw Exception('Failed to load user listings');
    }
  }

  void _refreshListings() {
    setState(() {
      _listingsFuture = _fetchUserListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Seller Dashboard",
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: context.textMuted),
            onPressed: () {},
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshListings();
          await _listingsFuture;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header text
              Text(
                "Mau jualan apa hari ini, ${AuthService.currentUser?['name']?.split(' ')[0] ?? 'Seller'}?",
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Big action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildSellOptionCard(
                      context,
                      title: "Jual Barang",
                      subtitle: "Buku, Elektronik, dll",
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFFE67E22), // Orange
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SellItemScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSellOptionCard(
                      context,
                      title: "Tawarkan Jasa",
                      subtitle: "Tutor, Desain, dll",
                      icon: Icons.design_services_outlined,
                      color: const Color(0xFF3498DB), // Blue
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SellServiceScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Section for active listings (static for now)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Barang & Jasa Saya",
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text("Lihat Semua", style: TextStyle(color: context.colors.primary)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              // Listings section
              FutureBuilder<Map<String, List<dynamic>>>(
                future: _listingsFuture ?? _fetchUserListings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Gagal memuat data", style: TextStyle(color: Colors.red)));
                  } else if (!snapshot.hasData || (snapshot.data!['products']!.isEmpty && snapshot.data!['services']!.isEmpty)) {
                    return _buildEmptyListingsState(context);
                  }

                  final products = snapshot.data!['products'] as List<Product>;
                  final services = snapshot.data!['services'] as List<ServiceItem>;
                  
                  final List<Widget> listWidgets = [];
                  
                  for (var product in products) {
                    listWidgets.add(_buildListingItem(context, product: product));
                  }
                  
                  for (var service in services) {
                    listWidgets.add(_buildListingItem(context, service: service));
                  }
                  
                  return Column(children: listWidgets);
                },
              ),
              const SizedBox(height: 80), // Padding to clear bottom nav
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSellOptionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: context.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: context.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyListingsState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront, color: context.textMuted.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text(
            "Belum ada barang atau jasa yang Anda jual.",
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildListingItem(BuildContext context, {Product? product, ServiceItem? service}) {
    final title = product?.name ?? service?.title ?? '';
    final price = product?.price ?? service?.price ?? 0;
    final imageUrl = product?.imageUrl ?? service?.imageUrl ?? '';
    
    // Normally we should read approval_status from DB, but we didn't put it in Product model.
    // For now, let's just assume PENDING if we don't have it, or we could add it to model later.
    // We'll just show the item.
    
    return GestureDetector(
      onTap: () {
        if (product != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))).then((_) => _refreshListings());
        } else if (service != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service))).then((_) => _refreshListings());
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: context.colors.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl.startsWith('http') ? imageUrl : 'http://192.168.100.63:8000$imageUrl',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.image_not_supported, color: context.textMuted),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rp ${formatCurrency(price)}",
                    style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: context.colors.primary, size: 20),
              onPressed: () {
                if (product != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SellItemScreen(existingProduct: product))).then((_) => _refreshListings());
                } else if (service != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SellServiceScreen(existingService: service))).then((_) => _refreshListings());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
