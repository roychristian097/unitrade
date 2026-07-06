import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'theme.dart';
import 'login_page.dart';
import 'wishlist_screen.dart';
import 'notification_screen.dart';
import 'order_history_screen.dart';
import 'cart_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final token = AuthService.token;
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/user/profile'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _profileData = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());

    String name = _profileData?['name'] ?? 'Unknown User';
    String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    String campus = _profileData?['campus'] ?? 'Unknown Campus';
    String id = "STU${_profileData?['id'] ?? '00000'}";
    int points = _profileData?['points'] ?? 0;
    
    // For now we mock these based on the screenshot, as the API might not have them
    int salesRevenue = 0; 
    int itemsSold = 0;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Image.asset(
                'assets/images/logo_combined.png',
                height: 28,
                fit: BoxFit.contain,
                color: context.isDark ? null : Colors.black,
              ),
            ],
          ),
          actions: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeManager.themeNotifier,
              builder: (context, currentMode, child) {
                final isDark = currentMode == ThemeMode.dark;
                return IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.grey),
                  onPressed: () {
                    ThemeManager.toggleTheme();
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.shopping_cart_outlined, color: Colors.grey),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
              },
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_none, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(context,  MaterialPageRoute(builder: (context) => NotificationScreen()));
                  },
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '1',
                      style: TextStyle(color: context.colors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
            SizedBox(width: 4),
            CircleAvatar(
              radius: 14,
              backgroundColor: context.colors.primary,
              child: Text(initial, style: TextStyle(color: context.colors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.menu, color: Colors.grey),
              color: context.colors.cardBg,
              onSelected: (value) {
                if (value == 'logout') {
                  AuthService.logout();
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
      body: _profileData == null
          ? Center(child: Text("Gagal memuat profil", style: TextStyle(color: context.colors.textPrimary)))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Profile Card
                  GlassContainer(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: context.colors.primary,
                          child: Text(
                            initial, 
                            style: TextStyle(color: context.colors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          name, 
                          style: TextStyle(color: context.colors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)
                        ),
                        SizedBox(height: 4),
                        Text(
                          "$campus â€¢ ID: $id",
                          style: TextStyle(color: context.colors.textMuted, fontSize: 14),
                        ),
                        SizedBox(height: 24),
                        Divider(color: context.colors.textPrimary.withValues(alpha: 0.05)),
                        SizedBox(height: 16),
                        
                        // Stats row 1
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("REPUTATION POINTS", style: TextStyle(color: context.colors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: context.colors.primary, size: 24),
                                      SizedBox(width: 8),
                                      Text("$points pts", style: TextStyle(color: context.colors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("SALES REVENUE", style: TextStyle(color: context.colors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  SizedBox(height: 8),
                                  Text("Rp $salesRevenue", style: TextStyle(color: context.colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        
                        // Stats row 2
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ITEMS SOLD", style: TextStyle(color: context.colors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              SizedBox(height: 8),
                              Text("$itemsSold deals", style: TextStyle(color: context.colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),

                  // Actions List Card
                  GlassContainer(
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                    child: Column(
                      children: [
                        _buildActionItem(
                          icon: Icons.shopping_bag_outlined, 
                          title: "Purchases (Order History)", 
                          isSelected: true,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
                          },
                        ),
                        _buildActionItem(
                          icon: Icons.sell_outlined, 
                          title: "Sales Panel", 
                          isSelected: false,
                          onTap: () {},
                        ),
                        _buildActionItem(
                          icon: Icons.assignment_outlined, 
                          title: "Freelance Gigs", 
                          isSelected: false,
                          onTap: () {},
                        ),
                        _buildActionItem(
                          icon: Icons.inventory_2_outlined, 
                          title: "My Listings", 
                          isSelected: false,
                          onTap: () {},
                        ),
                        _buildActionItem(
                          icon: Icons.workspace_premium_outlined, 
                          title: "Rep Points", 
                          isSelected: false,
                          onTap: () {},
                        ),
                        _buildActionItem(
                          icon: Icons.favorite_border, 
                          title: "My Wishlist", 
                          isSelected: false,
                          onTap: () {
                            Navigator.push(context,  MaterialPageRoute(builder: (context) => WishlistScreen()));
                          },
                        ),
                        _buildActionItem(
                          icon: Icons.logout, 
                          title: "Log Out", 
                          isSelected: false,
                          onTap: () {
                            AuthService.logout();
                            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => LoginPage()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildActionItem({
    required IconData icon, 
    required String title, 
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black87 : context.colors.textMuted, size: 20),
            SizedBox(width: 16),
            Text(
              title, 
              style: TextStyle(
                color: isSelected ? Colors.black87 : context.colors.textPrimary, 
                fontSize: 16, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500
              )
            ),
          ],
        ),
      ),
    );
  }
}
