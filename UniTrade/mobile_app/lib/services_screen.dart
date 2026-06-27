import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme.dart';
import 'sell_service_screen.dart';

class ServiceItem {
  final int id;
  final int sellerId;
  final String sellerName;
  final String title;
  final String description;
  final String category;
  final int price;

  ServiceItem({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      sellerName: json['seller_name'] ?? 'Unknown Seller',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? 0,
    );
  }
}

String formatCurrency(int value) {
  return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
}

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<ServiceItem>> _servicesFuture;

  String _selectedCategory = 'Semua Kategori';
  final List<String> _categories = ['Semua Kategori', 'Desain', 'IT Support', 'Tutor', 'Writing', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _servicesFuture = fetchServices();
  }

  Future<List<ServiceItem>> fetchServices() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.3:8000/services')).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((s) => ServiceItem.fromJson(s)).toList();
      } else {
        throw Exception('Gagal memuat services');
      }
    } catch (e) {
      return [];
    }
  }

  void _refresh() {
    setState(() {
      _servicesFuture = fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text("Student Services", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 24)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SellServiceScreen()),
          );
          if (result == true) {
            _refresh();
          }
        },
        backgroundColor: context.colors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Category Filter Horizontal List
          Container(
            height: 50,
            margin: EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: context.colors.primary,
                    backgroundColor: context.colors.cardBg,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : context.colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? context.colors.primary : context.colors.border,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<ServiceItem>>(
              future: _servicesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Tidak ada layanan tersedia", style: TextStyle(color: context.colors.textPrimary)));
                }

                // Filter items
                var filteredServices = snapshot.data!;
                if (_selectedCategory != 'Semua Kategori') {
                  filteredServices = filteredServices.where((s) => s.category == _selectedCategory).toList();
                }

                if (filteredServices.isEmpty) {
                  return Center(child: Text("Tidak ada layanan di kategori ini.", style: TextStyle(color: context.colors.textPrimary)));
                }

                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    final svc = filteredServices[index];
                    return _buildServiceCard(svc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem svc) {
    return GlassContainer(
      padding: EdgeInsets.all(12),
      borderRadius: AppTheme.radiusButton,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    svc.category, 
                    style: TextStyle(color: context.colors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            svc.title, 
            style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Spacer(),
          Row(
            children: [
              Icon(Icons.person, size: 12, color: context.colors.textMuted),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  svc.sellerName, 
                  style: TextStyle(color: context.colors.textMuted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Rp ${formatCurrency(svc.price)}", 
            style: TextStyle(color: context.colors.accent, fontSize: 14, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }
}
