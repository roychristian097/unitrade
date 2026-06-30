import 'theme.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'checkout_screen.dart';
import 'marketplace_screen.dart'; // import to reuse Product and formatCurrency
import 'auth_service.dart';
import 'chat_detail_screen.dart';
import 'chat_list_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Product> _relatedProducts = [];
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    _fetchRelatedProducts();
  }

  Future<void> _fetchRelatedProducts() async {
    try {
      final uri = Uri.http('192.168.1.3:8000', '/products');
      final response = await http.get(uri).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        final allProducts = jsonResponse.map((p) => Product.fromJson(p)).toList();
        
        // Exclude current product and take up to 4
        setState(() {
          _relatedProducts = allProducts.where((p) => p.id != widget.product.id).take(4).toList();
          _isLoadingRelated = false;
        });
      } else {
        setState(() => _isLoadingRelated = false);
      }
    } catch (e) {
      setState(() => _isLoadingRelated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: _buildAppBar(isDesktop),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.grey[400], size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Back to Marketplace",
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Hero Section
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildImageSection()),
                        SizedBox(width: 48),
                        Expanded(flex: 4, child: _buildRightDetailsSection()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 300, child: _buildImageSection()),
                        SizedBox(height: 24),
                        _buildRightDetailsSection(),
                      ],
                    ),

              SizedBox(height: 48),

              // Description & Reviews Section
              isDesktop ? _buildBottomDetailsDesktop() : _buildBottomDetailsMobile(),
              
              SizedBox(height: 48),

              // Related Products
              Text(
                "Related Products",
                style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildRelatedProducts(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.product.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'http://192.168.1.3:8000${widget.product.imageUrl}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Center(child: Icon(Icons.image_outlined, color: context.colors.border, size: 80)),
              ),
            )
          else
            Center(child: Icon(Icons.image_outlined, color: context.colors.border, size: 80)),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.product.campus,
                style: TextStyle(color: context.colors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRightDetailsSection() {
    String tag = widget.product.tags.isNotEmpty ? widget.product.tags[0] : widget.product.category.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(tag, style: TextStyle(color: context.colors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            Text("Condition: ${widget.product.condition}", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        SizedBox(height: 12),
        Text(
          widget.product.name,
          style: TextStyle(color: context.colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          "Rp ${formatCurrency(widget.product.price)}",
          style: TextStyle(color: context.colors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 24),
        
        // Buttons
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        productName: widget.product.name,
                        productId: widget.product.id,
                        price: widget.product.price,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.shopping_bag_outlined, color: context.colors.textPrimary, size: 18),
                label: Text("Buy Now", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        otherUserId: widget.product.sellerId,
                        otherUserName: widget.product.sellerName,
                        productId: widget.product.id,
                        productName: widget.product.name,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.chat_bubble_outline, color: context.colors.textPrimary, size: 18),
                label: Text("Chat with Seller", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2A2A2E),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2E),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.favorite_border, color: context.colors.textPrimary),
                onPressed: () {},
              ),
            )
          ],
        ),
        SizedBox(height: 32),

        // Info Box
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: context.colors.primary, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text("Handover Location: Cafeteria Lounge UNAS", style: TextStyle(color: Colors.grey[400], fontSize: 13))),
                ],
              ),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: context.colors.primary, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text("Transaction Protection: Meet in public, inspect item before pay.", style: TextStyle(color: Colors.grey[400], fontSize: 13))),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Seller Box
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.colors.primary,
                child: Text(widget.product.sellerName.isNotEmpty ? widget.product.sellerName[0].toUpperCase() : "U", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.product.sellerName, style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text("Verified", style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(widget.product.sellerCampus, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        Icon(Icons.star_half, color: Colors.amber, size: 12),
                        SizedBox(width: 6),
                        Text("(7 reviews)", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Reward Points", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      SizedBox(width: 4),
                      Text("750 pts", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomDetailsDesktop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Description", style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Text(
            widget.product.description,
            style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
          ),
        ),
        SizedBox(height: 48),
        Text("Product Reviews (0)", style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Text("No reviews left for this product yet.", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Widget _buildBottomDetailsMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Description", style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Text(
          widget.product.description,
          style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
        ),
        SizedBox(height: 32),
        Text("Product Reviews (0)", style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Text("No reviews left for this product yet.", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Widget _buildRelatedProducts(bool isDesktop) {
    if (_isLoadingRelated) {
      return Center(child: CircularProgressIndicator(color: context.colors.primary));
    }
    if (_relatedProducts.isEmpty) {
      return Text("No related products found.", style: TextStyle(color: Colors.grey[600], fontSize: 14));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 1, // 4 columns on desktop, 1 on mobile
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isDesktop ? 0.85 : 1.2,
      ),
      itemCount: _relatedProducts.length,
      itemBuilder: (context, index) {
        final prod = _relatedProducts[index];
        return _buildRelatedProductCard(prod);
      },
    );
  }

  Widget _buildRelatedProductCard(Product product) {
    String tag1 = product.tags.isNotEmpty ? product.tags[0] : product.category.toUpperCase();
    String tag2 = product.tags.length > 1 ? product.tags[1] : 'GOOD';

    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
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
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: context.colors.primary, size: 10),
                          SizedBox(width: 4),
                          Text(product.campus, style: TextStyle(color: context.colors.textPrimary, fontSize: 9)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
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
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colors.cardBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(tag2, style: TextStyle(color: context.colors.textPrimary, fontSize: 9)),
                      )
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rp ${formatCurrency(product.price)}",
                        style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("View", style: TextStyle(color: context.colors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Reuse the appbar from marketplace
  AppBar _buildAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: context.colors.background,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.trending_up, color: context.colors.textPrimary, size: 16),
          ),
          SizedBox(width: 8),
          Text(
            'UniTrade',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListScreen()));
          }),
          SizedBox(width: 32),
          IconButton(icon: Icon(Icons.light_mode_outlined, color: Colors.grey, size: 20), onPressed: () {}),
          IconButton(icon: Icon(Icons.favorite_border, color: Colors.grey, size: 20), onPressed: () {}),
          IconButton(icon: Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 20), onPressed: () {}),
        ] else ...[
          IconButton(icon: Icon(Icons.light_mode_outlined, color: Colors.grey, size: 20), onPressed: () {}),
        ],
        IconButton(
          icon: Badge(
            backgroundColor: Colors.red,
            child: Icon(Icons.notifications_none, color: Colors.grey, size: 20),
          ),
          onPressed: () {},
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
                    Text(AuthService.currentUser?['name'] ?? "Guest", style: TextStyle(color: context.colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(AuthService.currentUser?['campus'] ?? "Universitas Nasional", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
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

  Widget _buildBottomNavBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        border: Border(top: BorderSide(color: context.colors.textPrimary.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavIcon(Icons.storefront, "Home", isActive: true),
            _buildBottomNavIcon(Icons.build_circle_outlined, "Services"),
            _buildBottomNavIcon(Icons.chat_bubble_outline, "Chat", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListScreen()));
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
          Icon(icon, color: isActive ? context.colors.primary : Colors.grey, size: 24),
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
}
