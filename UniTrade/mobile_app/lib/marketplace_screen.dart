import 'dart:convert';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'product_detail_screen.dart';
import 'sell_item_screen.dart';
import 'auth_service.dart';
import 'chat_list_screen.dart';
import 'wishlist_screen.dart';
import 'notification_screen.dart';
import 'services_screen.dart' hide formatCurrency, CurrencyInputFormatter;
import 'service_detail_screen.dart';
import 'cart_screen.dart';

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

class Product {
  final int id;
  final int sellerId;
  final String sellerName;
  final String sellerCampus;
  final String name;
  final String description;
  final int price;
  final String category;
  final String condition;
  final String campus;
  final List<String> tags;
  final String imageUrl;
  final String itemType;
  final Map<String, dynamic> advancedDetails;
  final int stock;

  Product({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerCampus,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.campus,
    required this.tags,
    required this.imageUrl,
    required this.itemType,
    required this.advancedDetails,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      sellerName: json['seller_name'] ?? 'Unknown Seller',
      sellerCampus: json['seller_campus'] ?? 'Unknown Campus',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      campus: json['campus'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['image_url'] ?? '',
      itemType: json['item_type'] ?? 'Barang',
      advancedDetails: json['advanced_details'] ?? {},
      stock: json['stock'] ?? 1,
    );
  }
}

class MarketplaceScreen extends StatefulWidget {
  final bool showWelcome;

  const MarketplaceScreen({super.key, this.showWelcome = false});

  static final ValueNotifier<bool> refreshNotifier = ValueNotifier(false);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late Future<List<Product>> _productsFuture;

  // Filter States
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String _selectedCategory = 'Semua Kategori';
  final List<String> _categories = ['Semua Kategori', 'Elektronik', 'Pakaian', 'Otomotif', 'Jasa'];

  String _selectedCondition = 'Semua Kondisi';
  
  int _unreadNotifCount = 0;
  Timer? _pollingTimer;

  bool _isRefreshing = false;
  final List<String> _conditions = [
    'Semua Kondisi',
    'Baru (Brand New)',
    'Mulus (Like New)',
    'Pemakaian Wajar (Fair/Used)'
  ];
  
  // Location Filter
  bool _includeAllJabodetabek = true;
  String _selectedJabodetabekCampus = 'Pilih Kampus';
  List<String> _jabodetabekCampuses = [
    'Pilih Kampus',
    'Universitas Nasional - Jakarta Selatan, Pasar Minggu',
    'Universitas Indonesia - Depok, Beji',
    'Universitas Gunadarma - Depok, Margonda'
  ];

  late bool _showWelcomeMessage;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
    _showWelcomeMessage = widget.showWelcome;
    fetchCampuses();
    _fetchUnreadNotifs();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchUnreadNotifs());
    MarketplaceScreen.refreshNotifier.addListener(_onRefreshNotifierChanged);
  }

  Future<void> _fetchUnreadNotifs() async {
    try {
      final token = AuthService.token;
      if (token == null) return;
      final response = await http.get(
        Uri.parse('http://192.168.100.63:8000/notifications/unread_count'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final count = json.decode(response.body)['unread_count'] ?? 0;
        if (mounted) {
          setState(() {
            _unreadNotifCount = count;
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _onRefreshNotifierChanged() {
    if (mounted) {
      _applyFilters();
    }
  }

  @override
  void dispose() {
    MarketplaceScreen.refreshNotifier.removeListener(_onRefreshNotifierChanged);
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<List<Product>> fetchProducts() async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};
      if (_searchController.text.isNotEmpty) {
        queryParams['q'] = _searchController.text;
      }
      if (_selectedCategory != 'Semua Kategori') {
        queryParams['category'] = _selectedCategory;
      }
      if (_selectedCondition != 'Semua Kondisi') {
        queryParams['condition'] = _selectedCondition;
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
      final uri = Uri.http('192.168.100.63:8000', '/products', queryParams);

      final response = await http.get(uri).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((product) => Product.fromJson(product)).toList();
      } else {
        throw Exception('Gagal memuat produk');
      }
    } catch (e) {
      // Return dummy data fallback if backend fails
      return [];
    }
  }

  Future<void> fetchCampuses() async {
    try {
      final uri = Uri.http('192.168.100.63:8000', '/campuses');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        setState(() {
          final Set<String> campusSet = {'Pilih Kampus'};
          campusSet.addAll(_jabodetabekCampuses);
          for (var c in jsonResponse) {
            campusSet.add(c.toString());
          }
          _jabodetabekCampuses = campusSet.toList();
        });
      }
    } catch (e) {
      // Ignored
    }
  }

  void _applyFilters() {
    setState(() {
      _productsFuture = fetchProducts();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _productsFuture = fetchProducts();
    });
    await fetchCampuses();
    await _productsFuture;
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
      backgroundColor: context.bgColor,
      extendBody: true,
      appBar: isDesktop ? _buildAppBar(isDesktop) : null,

      body: RefreshIndicator(
        color: const Color(0xFFE67E22),
        backgroundColor: context.surfaceColor,
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Selamat datang, $_welcomeName 😊",
                        style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showWelcomeMessage = false;
                          });
                        },
                        child: Icon(Icons.close, color: context.textMuted, size: 18),
                      )
                    ],
                  ),
                ),
              isDesktop
                  ? Column(
                      children: [
                        _buildHeaderSection(),
                        SizedBox(height: 24),
                        _buildPromoBanner(),
                        SizedBox(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 280, child: _buildSidebarFilters()),
                            SizedBox(width: 32),
                            Expanded(child: _buildProductGrid(isDesktop)),
                          ],
                        ),
                      ],
                    )
                  : SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMobileSearchBar(),
                          SizedBox(height: 24),
                          _buildPromoBanner(),
                          SizedBox(height: 24),
                          _buildQuickCategoryChips(),
                          SizedBox(height: 24),
                          _buildFlashDeals(),
                          SizedBox(height: 24),
                          _buildProductGrid(isDesktop),
                          SizedBox(height: 100), // Padding for transparent navbar
                        ],
                      ),
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
      backgroundColor: context.bgColor,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD35400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/logo_combined.png',
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      actions: [
        if (isDesktop) ...[
          _buildAppBarTab("Marketplace", isActive: true, icon: Icons.storefront),
          SizedBox(width: 16),
          _buildAppBarTab("Services", icon: Icons.build_circle_outlined),
          SizedBox(width: 16),
          _buildAppBarTab("Chat", icon: Icons.chat_bubble_outline, onTap: () {
            Navigator.push(context,  MaterialPageRoute(builder: (context) => ChatListScreen()));
          }),
          SizedBox(width: 32),
          IconButton(
            icon: Icon(context.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: Colors.grey, size: 20),
            onPressed: () {
              themeNotifier.value = context.isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(icon: Icon(Icons.favorite_border, color: Colors.grey, size: 20), onPressed: () {}),
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 20), 
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
            }
          ),
        ] else ...[
          IconButton(
            icon: Icon(context.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: Colors.grey, size: 20),
            onPressed: () {
              themeNotifier.value = context.isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
        IconButton(
          icon: _unreadNotifCount > 0 
            ? Badge(
                backgroundColor: Colors.red,
                label: Text(_unreadNotifCount > 99 ? '99+' : '$_unreadNotifCount', style: const TextStyle(color: Colors.white, fontSize: 8)),
                child: const Icon(Icons.notifications_none, color: Colors.grey, size: 20),
              )
            : const Icon(Icons.notifications_none, color: Colors.grey, size: 20),
          onPressed: () {
            Navigator.push(context,  MaterialPageRoute(builder: (context) => const NotificationScreen())).then((_) {
              _fetchUnreadNotifs();
            });
          },
        ),
        if (isDesktop) SizedBox(width: 16),
        if (isDesktop)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.textColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 16, color: context.textColor),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AuthService.currentUser?['name'] ?? "Guest", style: TextStyle(color: context.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text("120 pts", style: TextStyle(color: Color(0xFFE67E22), fontSize: 10)),
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
          color: isActive ? Color(0xFFE67E22).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? const Color(0xFFE67E22) : Colors.grey, size: 16),
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

  Widget _buildBottomNavBar() {
    return Container(
      padding: EdgeInsets.only(top: 32, bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            context.bgColor.withOpacity(0.85),
            context.bgColor,
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavIcon(Icons.storefront, "Home", isActive: true),
            _buildBottomNavIcon(Icons.build_circle_outlined, "Services"),
            _buildBottomNavIcon(Icons.chat_bubble_outline, "Chat", onTap: () {
              Navigator.push(context,  MaterialPageRoute(builder: (context) => ChatListScreen()));
            }),
            _buildBottomNavIcon(Icons.shopping_cart_outlined, "Cart"),
            _buildBottomNavIcon(Icons.person_outline, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFFE67E22) : Colors.grey, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? context.colors.primary : Colors.grey,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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
                "Campus Marketplace",
                style: TextStyle(color: context.textColor, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Buy and sell textbooks, electronics, and dorm gear within your university zone.",
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      height: 180,
      width: double.infinity,
      child: PageView(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Back to Campus Sale! 🎓", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Get up to 50% off on textbooks and electronics this week.", style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE67E22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text("Shop Now", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceHighlight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.borderColor),
            ),
            child: Center(child: Text("Swipe for more deals!", style: TextStyle(color: context.textColor))),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD35400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            'assets/images/logo_combined.png',
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4))
              ]
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _applyFilters(),
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        IconButton(
          icon: Icon(context.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: context.textColor, size: 24),
          onPressed: () {
            themeNotifier.value = context.isDark ? ThemeMode.light : ThemeMode.dark;
          },
        ),
        Stack(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.borderColor),
              ),
              child: Icon(Icons.shopping_cart_outlined, color: context.textColor, size: 24),
            ),
            if (_unreadNotifCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text("$_unreadNotifCount", style: TextStyle(color: Colors.white, fontSize: 10)),
                )
              )
          ]
        ),
      ],
    );
  }

  Widget _buildQuickCategoryChips() {
    // Add "Lainnya" (More) category for UI purpose
    final displayCategories = [..._categories, 'Lainnya'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Categories", style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceEvenly,
          children: displayCategories.map((category) {
            IconData iconData;
            if (category == 'Semua Kategori') iconData = Icons.grid_view;
            else if (category == 'Elektronik') iconData = Icons.phone_iphone;
            else if (category == 'Pakaian') iconData = Icons.checkroom;
            else if (category == 'Otomotif') iconData = Icons.directions_car;
            else if (category == 'Jasa') iconData = Icons.handyman;
            else iconData = Icons.more_horiz;

            bool isSelected = _selectedCategory == category;

            return GestureDetector(
              onTap: () {
                 if (category == 'Lainnya') {
                   // Optional: show a modal or dialog with all categories
                   return;
                 }
                 setState(() {
                   _selectedCategory = category;
                   _applyFilters();
                 });
              },
              child: SizedBox(
                 width: (MediaQuery.of(context).size.width - 48 - 48) / 3,
                 child: Column(
                   children: [
                     Container(
                       height: 64,
                       width: 64,
                       decoration: BoxDecoration(
                         color: isSelected ? const Color(0xFFE67E22) : context.surfaceColor,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: isSelected ? const Color(0xFFE67E22) : context.borderColor),
                         boxShadow: [
                           BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: Offset(0, 2))
                         ]
                       ),
                       child: Icon(iconData, color: isSelected ? Colors.white : const Color(0xFFE67E22), size: 28),
                     ),
                     SizedBox(height: 8),
                     Text(category == 'Semua Kategori' ? 'Semua' : category, style: TextStyle(color: context.textColor, fontSize: 12), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                   ]
                 )
              )
            );
          }).toList(),
        ),
      ]
    );
  }

  Widget _buildFlashDeals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Flash Deals for You", style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: (){}, child: Text("See All", style: TextStyle(color: Colors.blue))),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length > 4 ? 4 : snapshot.data!.length,
                itemBuilder: (context, index) {
                  final product = snapshot.data![index];
                  return Container(
                    width: 140,
                    margin: EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(product.imageUrl, fit: BoxFit.cover, width: double.infinity,
                               errorBuilder: (context, error, stackTrace) =>
                                    Container(color: context.surfaceHighlight, child: Center(child: Icon(Icons.image, color: Colors.grey, size: 40))),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: TextStyle(color: context.textColor, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              SizedBox(height: 4),
                              Text("Rp ${product.price}", style: TextStyle(color: const Color(0xFFE67E22), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMobileFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceHighlight,
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
                    Text("FILTERS", style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 24),
                    _buildFilterLabel("CATEGORY"),
                    _buildDropdownCategory(setModalState),
                    SizedBox(height: 20),
                    _buildFilterLabel("CONDITION"),
                    _buildDropdownCondition(setModalState),
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
                            style: TextStyle(color: context.textColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedJabodetabekCampus,
                          isExpanded: true,
                          dropdownColor: context.surfaceColor,
                          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
                          style: TextStyle(color: context.textColor, fontSize: 12),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedCategory = 'Semua Kategori';
                                _selectedCondition = 'Semua Kondisi';
                                _minPriceController.clear();
                                _maxPriceController.clear();
                                _includeAllJabodetabek = true;
                                _selectedJabodetabekCampus = 'Pilih Kampus';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE67E22)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text("Reset", style: TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _applyFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE67E22),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text("Apply Filters", style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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
        color: context.surfaceHighlight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: context.textColor, size: 18),
              SizedBox(width: 8),
              Text("SEARCH FILTERS", style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 24),
          _buildFilterLabel("KEYWORDS"),
          _buildTextField("Search...", _searchController),
          SizedBox(height: 20),
          _buildFilterLabel("CATEGORY"),
          _buildDropdownCategory(),
          SizedBox(height: 20),
          _buildFilterLabel("CONDITION"),
          _buildDropdownCondition(),
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
                  style: TextStyle(color: context.textColor, fontSize: 13),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedJabodetabekCampus,
                isExpanded: true,
                dropdownColor: context.surfaceColor,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
                style: TextStyle(color: context.textColor, fontSize: 12),
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
                backgroundColor: context.textColor,
                foregroundColor: Colors.black,
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
      style: TextStyle(color: context.textColor, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        filled: true,
        fillColor: context.surfaceColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownCategory([StateSetter? setModalState]) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: context.surfaceColor,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
          style: TextStyle(color: context.textColor, fontSize: 13),
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

  Widget _buildDropdownCondition([StateSetter? setModalState]) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCondition,
          isExpanded: true,
          dropdownColor: context.surfaceColor,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
          style: TextStyle(color: context.textColor, fontSize: 13),
          onChanged: (String? newValue) {
            if (setModalState != null) {
              setModalState(() {
                _selectedCondition = newValue!;
              });
            } else {
              setState(() {
                _selectedCondition = newValue!;
              });
            }
          },
          items: _conditions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductGrid(bool isDesktop) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)));
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red)));
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                "Tidak ada produk yang cocok dengan filter pencarian Anda.",
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
            crossAxisCount: isDesktop ? 3 : 2, // 3 kolom di desktop, 2 di HP
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 0.85 : 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(products[index]);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    String tag1 = product.tags.isNotEmpty ? product.tags[0] : product.category.toUpperCase();
    String tag2 = product.tags.length > 1 ? product.tags[1] : 'GOOD';

    return InkWell(
      onTap: () async {
        if (product.itemType == 'Jasa') {
          ServiceItem service = ServiceItem(
            id: product.id,
            sellerId: product.sellerId,
            sellerName: product.sellerName,
            sellerCampus: product.sellerCampus,
            title: product.name,
            description: product.description,
            category: product.category,
            price: product.price,
            maxPrice: int.tryParse(product.advancedDetails['max_price']?.toString() ?? ''),
            campus: product.campus,
            meetupLocation: product.advancedDetails['meetup_location']?.toString(),
            imageUrl: product.imageUrl,
          );
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(service: service),
            ),
          );
          if (result == true) {
            setState(() {
              _productsFuture = fetchProducts();
            });
          }
        } else {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
          if (result == true) {
            setState(() {
              _productsFuture = fetchProducts();
            });
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder Area
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(color: context.surfaceHighlight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (product.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          product.imageUrl.startsWith('http')
                              ? product.imageUrl
                              : 'http://192.168.100.63:8000${product.imageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image_outlined, color: context.colors.border, size: 50),
                        ),
                      )
                    else
                      Center(child: Icon(Icons.image_outlined, color: context.colors.border, size: 50)),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        constraints: BoxConstraints(maxWidth: 120),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, color: Color(0xFFE67E22), size: 10),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.campus.split(' - ').first, 
                                style: TextStyle(color: Colors.white, fontSize: 9),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tag1, style: TextStyle(color: Color(0xFFE67E22), fontSize: 10, fontWeight: FontWeight.bold)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.cardBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(tag2, style: TextStyle(color: context.textColor, fontSize: 9)),
                        )
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    Text(
                      (() {
                        String pText = "Rp ${formatCurrency(product.price)}";
                        if (product.itemType == 'Jasa' && product.advancedDetails['max_price'] != null) {
                          pText += " - Rp ${formatCurrency(int.tryParse(product.advancedDetails['max_price'].toString()) ?? 0)}";
                        }
                        return pText;
                      })(),
                      style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
