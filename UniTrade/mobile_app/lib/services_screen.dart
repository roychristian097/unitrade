import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'package:http/http.dart' as http;
import 'sell_service_screen.dart';
import 'auth_service.dart';
import 'chat_list_screen.dart';
import 'marketplace_screen.dart'; 
import 'service_detail_screen.dart';
import 'wishlist_screen.dart';
import 'notification_screen.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    int value = int.parse(cleanText);
    String formatted = value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatCurrency(int value) {
  return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
}

class ServiceItem {
  final int id;
  final int sellerId;
  final String sellerName;
  final String sellerCampus;
  final String title;
  final String description;
  final String category;
  final int price;
  final String imageUrl;

  ServiceItem({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerCampus,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      sellerName: json['seller_name'] ?? 'Unknown Seller',
      sellerCampus: json['seller_campus'] ?? 'Unknown Campus',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? 0,
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class ServicesScreen extends StatefulWidget {
  final bool showWelcome;

  const ServicesScreen({super.key, this.showWelcome = false});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<ServiceItem>> _servicesFuture;

  // Filter States
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String _selectedCategory = 'Semua Kategori';
  final List<String> _categories = ['Semua Kategori', 'Desain', 'IT Support', 'Tutor', 'Writing', 'Lainnya'];
  
  // Location Filter
  bool _includeAllJabodetabek = true;
  String _selectedJabodetabekCampus = 'Pilih Kampus';
  final List<String> _jabodetabekCampuses = [
    'Pilih Kampus',
    'Universitas Nasional - Jakarta Selatan, Pasar Minggu',
    'Universitas Indonesia - Depok, Beji',
    'Universitas Gunadarma - Depok, Margonda'
  ];

  late bool _showWelcomeMessage;

  @override
  void initState() {
    super.initState();
    _servicesFuture = fetchServices();
    _showWelcomeMessage = widget.showWelcome;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<List<ServiceItem>> fetchServices() async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};
      if (_searchController.text.isNotEmpty) {
        queryParams['q'] = _searchController.text;
      }
      if (_selectedCategory != 'Semua Kategori') {
        queryParams['category'] = _selectedCategory;
      }
      if (_minPriceController.text.isNotEmpty) {
        queryParams['min_price'] = _minPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      }
      if (_maxPriceController.text.isNotEmpty) {
        queryParams['max_price'] = _maxPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      }
      if (!_includeAllJabodetabek && _selectedJabodetabekCampus != 'Pilih Kampus') {
        queryParams['campus'] = _selectedJabodetabekCampus;
      }

      final baseUrlUri = Uri.parse(AuthService.baseUrl);
      final uri = Uri(
        scheme: baseUrlUri.scheme,
        host: baseUrlUri.host,
        port: baseUrlUri.port,
        path: '/services',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(uri).timeout(Duration(seconds: 5));

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

  void _applyFilters() {
    setState(() {
      _servicesFuture = fetchServices();
    });
  }

  String get _welcomeName {
    if (AuthService.currentUser != null && AuthService.currentUser!['email'] != null) {
      String email = AuthService.currentUser!['email'];
      return email.split('@')[0];
    }
    return "tester";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: _buildAppBar(isDesktop),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _servicesFuture = fetchServices();
          });
        },
        child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), 
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showWelcomeMessage)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: context.colors.textPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Selamat datang, $_welcomeName ðŸ˜Š",
                        style: TextStyle(color: context.colors.background, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showWelcomeMessage = false;
                          });
                        },
                        child: Icon(Icons.close, color: context.colors.background.withValues(alpha: 0.54), size: 18),
                      )
                    ],
                  ),
                ),
              _buildHeaderSection(),
              SizedBox(height: 32),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 280,
                          child: _buildSidebarFilters(),
                        ),
                        SizedBox(width: 32),
                        Expanded(
                          child: _buildServiceGrid(isDesktop),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMobileSearchBar(),
                        SizedBox(height: 24),
                        _buildServiceGrid(isDesktop),
                      ],
                    ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  AppBar _buildAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: context.colors.background,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text(
            'UniTrade',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        if (isDesktop) ...[
          _buildAppBarTab("Marketplace", icon: Icons.storefront, onTap: () {
            Navigator.pushReplacement(context,  MaterialPageRoute(builder: (context) => MarketplaceScreen()));
          }),
          SizedBox(width: 16),
          _buildAppBarTab("Services", isActive: true, icon: Icons.build_circle_outlined),
          SizedBox(width: 16),
          _buildAppBarTab("Chat", icon: Icons.chat_bubble_outline, onTap: () {
            Navigator.push(context,  MaterialPageRoute(builder: (context) => ChatListScreen()));
          }),
          SizedBox(width: 32),
          ValueListenableBuilder<ThemeMode>(valueListenable: ThemeManager.themeNotifier, builder: (_, mode, _) { return IconButton(icon: Icon(mode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: context.colors.primary, size: 20), onPressed: () { ThemeManager.toggleTheme(); }); }),
          IconButton(icon: Icon(Icons.favorite_border, color: Colors.grey, size: 20), onPressed: () {
            Navigator.push(context,  MaterialPageRoute(builder: (context) => WishlistScreen()));
          }),
          IconButton(icon: Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 20), onPressed: () {}),
        ] else ...[
          ValueListenableBuilder<ThemeMode>(valueListenable: ThemeManager.themeNotifier, builder: (_, mode, _) { return IconButton(icon: Icon(mode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: context.colors.primary, size: 20), onPressed: () { ThemeManager.toggleTheme(); }); }),
        ],
        IconButton(
          icon: Badge(
            backgroundColor: Colors.red,
            child: Icon(Icons.notifications_none, color: Colors.grey, size: 20),
          ),
          onPressed: () {
            Navigator.push(context,  MaterialPageRoute(builder: (context) => const NotificationScreen()));
          },
        ),
        if (isDesktop) SizedBox(width: 16),
        if (isDesktop)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 16, color: context.colors.textPrimary),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AuthService.currentUser?['name'] ?? "Guest", style: TextStyle(color: context.colors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text("120 pts", style: TextStyle(color: context.colors.primary, fontSize: 10)),
                  ],
                ),
                SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
              ],
            ),
          ),
        if (isDesktop) SizedBox(width: 24),
      ],
    );
  }

  Widget _buildAppBarTab(String title, {bool isActive = false, required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? context.colors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? context.colors.primary : Colors.grey, size: 16),
            SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isActive ? context.colors.primary : Colors.grey,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Campus Services",
                style: TextStyle(color: context.colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Find student freelancers and services within your university zone.",
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(context, 
              MaterialPageRoute(builder: (context) => SellServiceScreen()),
            );
            if (result == true) {
              _applyFilters();
            }
          },
          icon: Icon(Icons.add, color: context.colors.textPrimary, size: 18),
          label: Text("Offer A Service", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _applyFilters(),
            style: TextStyle(color: context.colors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Search for design, tutoring, etc...",
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
              filled: true,
              fillColor: context.colors.cardBg,
              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(width: 12),
        InkWell(
          onTap: _showMobileFilterSheet,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.tune, color: context.colors.textPrimary, size: 20),
          ),
        ),
      ],
    );
  }

  void _showMobileFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.cardBg,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text("FILTERS", style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 24),
                    _buildFilterLabel("CATEGORY"),
                    _buildDropdownCategory(setModalState),
                    SizedBox(height: 20),
                    _buildFilterLabel("PRICE RANGE (RP)"),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Min", _minPriceController, isNumber: true, formatters: [CurrencyInputFormatter()])),
                        SizedBox(width: 12),
                        Expanded(child: _buildTextField("Max", _maxPriceController, isNumber: true, formatters: [CurrencyInputFormatter()])),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildFilterLabel("CAMPUS ZONE FILTER"),
                    Row(
                      children: [
                        Checkbox(
                          value: _includeAllJabodetabek,
                          onChanged: (val) {
                            setModalState(() {
                              _includeAllJabodetabek = val ?? true;
                              if (_includeAllJabodetabek) {
                                _selectedJabodetabekCampus = 'Pilih Kampus';
                              }
                            });
                          },
                          activeColor: context.colors.primary,
                          checkColor: context.colors.background,
                        ),
                        Expanded(
                          child: Text(
                            "Include all campus at Jabodetabek area",
                            style: TextStyle(color: context.colors.textPrimary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.colors.cardBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedJabodetabekCampus,
                          isExpanded: true,
                          dropdownColor: context.colors.cardBg,
                          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
                          style: TextStyle(color: context.colors.textPrimary, fontSize: 12),
                          onChanged: (String? newValue) {
                            setModalState(() {
                              _selectedJabodetabekCampus = newValue!;
                              if (newValue == 'Pilih Kampus') {
                                _includeAllJabodetabek = true;
                              } else {
                                _includeAllJabodetabek = false;
                              }
                            });
                          },
                          items: _jabodetabekCampuses.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text("Apply Filters", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSidebarFilters() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: context.colors.textPrimary, size: 18),
              SizedBox(width: 8),
              Text("SEARCH FILTERS", style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 24),
          _buildFilterLabel("KEYWORDS"),
          _buildTextField("Search...", _searchController),
          SizedBox(height: 20),
          _buildFilterLabel("CATEGORY"),
          _buildDropdownCategory(),
          SizedBox(height: 20),
          _buildFilterLabel("PRICE RANGE (RP)"),
          Row(
            children: [
              Expanded(child: _buildTextField("Min", _minPriceController, isNumber: true, formatters: [CurrencyInputFormatter()])),
              SizedBox(width: 12),
              Expanded(child: _buildTextField("Max", _maxPriceController, isNumber: true, formatters: [CurrencyInputFormatter()])),
            ],
          ),
          SizedBox(height: 20),
          _buildFilterLabel("CAMPUS ZONE FILTER"),
          Row(
            children: [
              Checkbox(
                value: _includeAllJabodetabek,
                onChanged: (val) {
                  setState(() {
                    _includeAllJabodetabek = val ?? true;
                    if (_includeAllJabodetabek) {
                      _selectedJabodetabekCampus = 'Pilih Kampus';
                    }
                  });
                },
                activeColor: context.colors.primary,
                checkColor: context.colors.background,
              ),
              Expanded(
                child: Text(
                  "Include all campus at Jabodetabek area",
                  style: TextStyle(color: context.colors.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.colors.cardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedJabodetabekCampus,
                isExpanded: true,
                dropdownColor: context.colors.cardBg,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
                style: TextStyle(color: context.colors.textPrimary, fontSize: 12),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedJabodetabekCampus = newValue!;
                    if (newValue == 'Pilih Kampus') {
                      _includeAllJabodetabek = true;
                    } else {
                      _includeAllJabodetabek = false;
                    }
                  });
                },
                items: _jabodetabekCampuses.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.textPrimary,
                foregroundColor: context.colors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool isNumber = false, List<TextInputFormatter>? formatters}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: formatters,
      style: TextStyle(color: context.colors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        filled: true,
        fillColor: context.colors.cardBg,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownCategory([StateSetter? setModalState]) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: context.colors.cardBg,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
          style: TextStyle(color: context.colors.textPrimary, fontSize: 13),
          onChanged: (String? newValue) {
            if (setModalState != null) {
              setModalState(() {
                _selectedCategory = newValue!;
              });
            } else {
              setState(() {
                _selectedCategory = newValue!;
              });
            }
          },
          items: _categories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildServiceGrid(bool isDesktop) {
    return FutureBuilder<List<ServiceItem>>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: context.colors.primary));
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red)));
        }

        final services = snapshot.data ?? [];

        if (services.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                "Tidak ada layanan yang cocok dengan filter pencarian Anda.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 1, 
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: isDesktop ? 0.85 : 1.2,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return _buildServiceCard(services[index]);
          },
        );
      },
    );
  }

  Widget _buildServiceCard(ServiceItem service) {
    String tag1 = service.category.toUpperCase();

    return InkWell(
      onTap: () {
        Navigator.push(context,  MaterialPageRoute(builder: (context) => ServiceDetailScreen(service: service)));
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: GlassContainer(
        padding: EdgeInsets.all(0),
        borderRadius: AppTheme.radiusCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder Area
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (service.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          service.imageUrl.startsWith('http')
                              ? service.imageUrl
                              : 'http://192.168.1.3:8000${service.imageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.build_circle_outlined, color: context.colors.border, size: 50),
                        ),
                      )
                    else
                      Center(child: Icon(Icons.build_circle_outlined, color: context.colors.border, size: 50)),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: context.colors.primary, size: 10),
                            SizedBox(width: 4),
                            Text(service.sellerCampus, style: TextStyle(color: context.colors.textPrimary, fontSize: 9)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Content Area
            Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tag1, style: TextStyle(color: context.colors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      service.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Rp ${formatCurrency(service.price)}",
                          style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "View details ->",
                          style: TextStyle(color: context.colors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailSheet(BuildContext context, ServiceItem service, ScrollController controller) {
    return SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), 
      controller: controller,
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          SizedBox(height: 24),
          if (service.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                service.imageUrl.startsWith('http')
                    ? service.imageUrl
                    : 'http://192.168.1.3:8000${service.imageUrl}',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 200, color: context.colors.cardBg, child: Icon(Icons.broken_image, size: 50)),
              ),
            ),
          SizedBox(height: 16),
          Text(service.category.toUpperCase(), style: TextStyle(color: context.colors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(service.title, style: TextStyle(color: context.colors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Rp ${formatCurrency(service.price)}", style: TextStyle(color: context.colors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Divider(color: context.colors.cardBg),
          SizedBox(height: 16),
          Text("Deskripsi", style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(service.description, style: TextStyle(color: context.colors.textMuted, fontSize: 14)),
          SizedBox(height: 16),
          Divider(color: context.colors.cardBg),
          SizedBox(height: 16),
          Text("Penjual", style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, color: context.colors.textMuted, size: 16),
              SizedBox(width: 8),
              Text(service.sellerName, style: TextStyle(color: context.colors.textMuted, fontSize: 14)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: context.colors.textMuted, size: 16),
              SizedBox(width: 8),
              // Use seller name if no campus is provided for service
              Expanded(child: Text(service.sellerName, style: TextStyle(color: context.colors.textMuted, fontSize: 14))),
            ],
          ),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Hubungi Penjual", style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
