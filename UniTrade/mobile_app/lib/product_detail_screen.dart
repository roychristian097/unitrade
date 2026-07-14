import 'theme.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'wishlist_service.dart';
import 'cart_service.dart';
import 'checkout_screen.dart';
import 'marketplace_screen.dart'; // import to reuse Product and formatCurrency
import 'auth_service.dart';
import 'config.dart';
import 'chat_detail_screen.dart';
import 'sell_item_screen.dart';
import 'cart_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Product> _relatedProducts = [];
  bool _isLoadingRelated = true;
  bool _isWishlisted = false;
  bool _isLoadingWishlist = true;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _fetchRelatedProducts();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    try {
      final token = AuthService.token;
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/wishlist/${widget.product.id}/check'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isWishlisted = data['is_wishlisted'] ?? false;
          _isLoadingWishlist = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingWishlist = false);
    }
  }

  Future<void> _toggleWishlist() async {
    try {
      final token = AuthService.token;
      if (token == null) return;
      
      setState(() {
        _isWishlisted = !_isWishlisted;
      });
      
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/wishlist/${widget.product.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode != 200) {
        setState(() {
          _isWishlisted = !_isWishlisted;
        });
      }
    } catch (e) {
      setState(() {
        _isWishlisted = !_isWishlisted;
      });
    }
  }

  Future<void> _fetchRelatedProducts() async {
    try {
      final uri = Uri.http(AppConfig.rawAuthority, '/products');
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
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // space for bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section with overlaid app bar
                _buildImageHero(),

                // Product info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Product info header section (Name, Seller, Price, Stock)
                      _buildHeaderSection().animate().fade(delay: 100.ms).slideX(begin: -0.1),
                      const SizedBox(height: 24),

                      // Condition chip & Location
                      _buildConditionAndLocation().animate().fade(delay: 200.ms).slideX(begin: -0.1),
                      const SizedBox(height: 24),

                      // Advanced details
                      _buildAdvancedDetails(),

                      // Description
                      _buildDescriptionSection().animate().fade(delay: 300.ms).slideX(begin: -0.1),
                      const SizedBox(height: 24),

                      // Seller card
                      _buildSellerCard(),
                      const SizedBox(height: 28),

                      // Related Products
                      Text("Related Products", style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildRelatedProducts(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom sticky bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar().animate().fade(duration: 400.ms).slideY(begin: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Product name
        Text(
          widget.product.name,
          style: TextStyle(color: context.textColor, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
        ),
        const SizedBox(height: 8),

        // Seller name
        Row(
          children: [
            Text("By ", style: TextStyle(color: context.textMuted, fontSize: 14)),
            Text(
              widget.product.sellerName,
              style: TextStyle(color: context.colors.primary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            // Rating
            Icon(Icons.star_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 2),
            Text("4.9", style: TextStyle(color: context.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(" (2.2k)", style: TextStyle(color: context.textMuted, fontSize: 12)),
            Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 18),
          ],
        ),
        const SizedBox(height: 16),

        // Price + Quantity
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (() {
                      String priceText = "Rp ${formatCurrency(widget.product.price)}";
                      if (widget.product.itemType == 'Jasa' && widget.product.advancedDetails['max_price'] != null) {
                        priceText += " - Rp ${formatCurrency(int.tryParse(widget.product.advancedDetails['max_price'].toString()) ?? 0)}";
                      }
                      return priceText;
                    })(),
                    style: TextStyle(color: context.textColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Quantity selector
            _buildQuantitySelector(),
          ],
        ),
        const SizedBox(height: 8),

        // Stock badge
        if (widget.product.itemType == 'Barang')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.product.stock <= 0
                  ? Colors.red.withValues(alpha: 0.1)
                  : context.colors.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.product.stock <= 0 ? 'Sold Out' : 'Stok: ${widget.product.stock}',
              style: TextStyle(
                color: widget.product.stock <= 0 ? Colors.red : context.colors.successGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConditionAndLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoChip(Icons.verified_outlined, "Kondisi: ${widget.product.condition}"),
        const SizedBox(height: 10),
        _buildInfoChip(Icons.location_on_outlined, widget.product.advancedDetails['handover_location']?.isNotEmpty == true ? widget.product.advancedDetails['handover_location'] : 'Lokasi bisa disesuaikan'),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Description", style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          widget.product.description,
          style: TextStyle(color: context.textMuted, fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildImageHero() {
    return Stack(
      children: [
        // Main image
        Container(
          height: 380,
          width: double.infinity,
          color: context.surfaceHighlight,
          child: widget.product.imageUrl.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          backgroundColor: context.bgColor,
                          appBar: AppBar(
                            backgroundColor: context.bgColor,
                            iconTheme: IconThemeData(color: context.textColor),
                            elevation: 0,
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              child: Image.network(
                                  '${AppConfig.baseUrl}${widget.product.imageUrl}',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    '${AppConfig.baseUrl}${widget.product.imageUrl}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        Center(child: Icon(Icons.image_outlined, color: context.textMuted, size: 80)),
                  ),
                )
              : Center(child: Icon(Icons.image_outlined, color: context.colors.border, size: 80)),
        ),

        // Gradient overlay at top for safe area
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Top icons
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
              Row(
                children: [
                  _buildCircleButton(
                    _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    _toggleWishlist,
                    iconColor: _isWishlisted ? Colors.redAccent : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  _buildCircleButton(Icons.share_rounded, () {}),
                  const SizedBox(width: 8),
                  _buildCircleButton(Icons.shopping_cart_outlined, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
                  }),
                ],
              ),
            ],
          ),
        ),

        // Campus badge
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.colors.promoGradientStart, context.colors.promoGradientEnd],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: context.colors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(widget.product.campus, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap, {Color iconColor = Colors.white}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceHighlight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.remove_rounded, color: context.textMuted, size: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$_quantity', style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          InkWell(
            onTap: () => setState(() => _quantity++),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.colors.promoGradientStart, context.colors.promoGradientEnd],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: context.textMuted, fontSize: 13))),
      ],
    );
  }

  Widget _buildAdvancedDetails() {
    if (widget.product.advancedDetails.isEmpty) return const SizedBox.shrink();

    if (widget.product.itemType == 'Barang') {
      final warranty = widget.product.advancedDetails['warranty'];
      final minNego = widget.product.advancedDetails['min_nego'];
      if ((warranty == null || warranty == 'Tidak ada') && minNego == null) return const SizedBox.shrink();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Item Details", style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (warranty != null && warranty != 'Tidak ada')
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildInfoChip(Icons.security_rounded, "Garansi Personal: $warranty"),
            ),
          if (minNego != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildInfoChip(Icons.price_change_outlined, "Harga Minimum Nego: Rp ${formatCurrency(int.tryParse(minNego.toString()) ?? 0)}"),
            ),
          const SizedBox(height: 16),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSellerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(color: context.colors.cardShadow, blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.colors.promoGradientStart, context.colors.promoGradientEnd],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                widget.product.sellerName.isNotEmpty ? widget.product.sellerName[0].toUpperCase() : "U",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.product.sellerName, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: context.colors.successGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text("Verified", style: TextStyle(color: context.colors.successGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(widget.product.sellerCampus, style: TextStyle(color: context.textMuted, fontSize: 11)),
              ],
            ),
          ),
          // Chat button
          if (AuthService.currentUser != null && AuthService.currentUser!['id'] != widget.product.sellerId)
            InkWell(
              onTap: () {
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
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.chat_bubble_outline_rounded, color: context.colors.primary, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    if (_isLoadingRelated) {
      return Center(child: CircularProgressIndicator(color: context.colors.primary));
    }
    if (_relatedProducts.isEmpty) {
      return Text("No related products found.", style: TextStyle(color: context.textMuted, fontSize: 14));
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _relatedProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _buildRelatedProductCard(_relatedProducts[index]);
        },
      ),
    );
  }

  Widget _buildRelatedProductCard(Product product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: context.colors.cardShadow, blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        '${AppConfig.baseUrl}${product.imageUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: context.surfaceHighlight, child: Icon(Icons.image_outlined, color: context.textMuted, size: 32)),
                      )
                    : Container(color: context.surfaceHighlight, child: Icon(Icons.image_outlined, color: context.textMuted, size: 32)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.textColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rp ${formatCurrency(product.price)}",
                    style: TextStyle(color: context.colors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isOwner = AuthService.currentUser != null && AuthService.currentUser!['id'] == widget.product.sellerId;
    final isSoldOut = widget.product.itemType == 'Barang' && widget.product.stock <= 0;

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, bottom: MediaQuery.of(context).padding.bottom + 12, top: 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: isOwner
          ? Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => SellItemScreen(existingProduct: widget.product),
                      ));
                    },
                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    label: const Text("Edit Listing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => _deleteProduct(context),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                // Chat button
                InkWell(
                  onTap: () {
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
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: context.surfaceHighlight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Icon(Icons.chat_bubble_outline_rounded, color: context.textColor, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                // Buy Now
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSoldOut ? null : () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => CheckoutScreen(
                          totalPrice: widget.product.price * _quantity,
                          buyNowItem: {
                            'product_id': widget.product.id,
                            'quantity': _quantity,
                          },
                        ),
                      ));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isSoldOut ? context.textMuted : context.colors.primary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      "Buy Now",
                      style: TextStyle(color: isSoldOut ? context.textMuted : context.colors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Add to Cart
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isSoldOut ? null : () async {
                      try {
                        await CartService.addToCart(widget.product.id, quantity: _quantity);
                        CartScreen.refreshNotifier.value = !CartScreen.refreshNotifier.value;
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.product.itemType == 'Jasa' ? "Jasa berhasil ditambahkan ke keranjang" : "Berhasil ditambahkan ke keranjang"),
                              backgroundColor: context.colors.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Gagal menambahkan: $e")),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSoldOut ? context.textMuted : context.colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: isSoldOut ? 0 : 4,
                      shadowColor: context.colors.primary.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      isSoldOut ? "Sold Out" : (widget.product.itemType == 'Jasa' ? "Pesan Jasa" : "+ Cart"),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _deleteProduct(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Listing"),
        content: Text("Are you sure you want to delete this listing?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
        ]
      )
    );
    if (confirm != true) return;
    try {
      final uri = Uri.http(AppConfig.rawAuthority, '/products/${widget.product.id}');
      final response = await http.delete(uri);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Listing deleted successfully")));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete listing")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
