import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cart_service.dart';
import 'checkout_screen.dart';
import 'theme.dart';
import 'config.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  static final ValueNotifier<bool> refreshNotifier = ValueNotifier(false);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> _cartItems = [];
  bool _isLoading = true;
  final TextEditingController _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCart();
    CartScreen.refreshNotifier.addListener(_onRefreshNotifierChanged);
  }

  void _onRefreshNotifierChanged() {
    if (mounted) {
      _fetchCart();
    }
  }

  @override
  void dispose() {
    CartScreen.refreshNotifier.removeListener(_onRefreshNotifierChanged);
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _fetchCart() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await CartService.getCart();
      setState(() {
        _cartItems = items;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cart: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeItem(int cartId) async {
    try {
      await CartService.removeFromCart(cartId);
      _fetchCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from cart')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove item: $e')),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: Text("Clear Cart", style: TextStyle(color: context.textColor)),
        content: Text("Remove all items from your cart?", style: TextStyle(color: context.textMuted)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel", style: TextStyle(color: context.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Clear", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true) {
      for (var item in _cartItems) {
        await CartService.removeFromCart(item['cart_id']);
      }
      _fetchCart();
    }
  }

  Future<void> _updateQuantity(int cartId, int newQuantity) async {
    if (newQuantity < 1) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await CartService.updateCartQuantity(cartId, newQuantity);
      _fetchCart();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update quantity: $e')),
        );
      }
    }
  }

  int get _totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + ((item['price'] as int) * (item['quantity'] as int)));
  }

  int get _shippingTax => _cartItems.isNotEmpty ? 15000 : 0;

  @override
  Widget build(BuildContext context) {
    final fmtCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: Text(
          'Cart',
          style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: context.textMuted),
              onPressed: _clearCart,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)))
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    // Cart items list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return _buildCartItem(item, fmtCurrency).animate(delay: (50 * index).ms).fade(duration: 300.ms).slideX(begin: 0.1, duration: 300.ms);
                        },
                      ),
                    ),

                    // Bottom section: promo + summary + checkout
                    _buildBottomSection(fmtCurrency).animate().fade(duration: 400.ms).slideY(begin: 0.2, duration: 400.ms),
                  ],
                ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined, size: 64, color: context.colors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Start browsing and add items to your cart',
            style: TextStyle(color: context.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, NumberFormat fmtCurrency) {
    return Dismissible(
      key: ValueKey(item['cart_id']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(item['cart_id']),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: context.colors.cardShadow, blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 90,
                height: 90,
                child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                    ? item['image_url'].toString().startsWith('assets/')
                        ? Image.asset(item['image_url'], fit: BoxFit.cover)
                        : Image.network(
                            item['image_url'].toString().startsWith('http')
                                ? item['image_url']
                                : '${AppConfig.baseUrl}${item['image_url']}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: context.surfaceHighlight,
                              child: Icon(Icons.image_not_supported, color: context.textMuted),
                            ),
                          )
                    : Container(
                        color: context.surfaceHighlight,
                        child: Icon(Icons.image_not_supported, color: context.textMuted),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmtCurrency.format(item['price']),
                    style: TextStyle(color: context.colors.primary, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  // Quantity controls
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _updateQuantity(item['cart_id'], (item['quantity'] as int) - 1),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.surfaceHighlight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.remove_rounded, color: context.textMuted, size: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '${item['quantity']}',
                          style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: () => _updateQuantity(item['cart_id'], (item['quantity'] as int) + 1),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [context.colors.promoGradientStart, context.colors.promoGradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(NumberFormat fmtCurrency) {
    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Promo code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: context.surfaceHighlight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, color: context.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Enter Promo Code",
                      hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Order summary
          _buildSummaryRow("Sub Total", fmtCurrency.format(_totalPrice)),
          const SizedBox(height: 8),
          _buildSummaryRow("Shipping & Tax", fmtCurrency.format(_shippingTax)),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: context.borderColor,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total", style: TextStyle(color: context.textColor, fontSize: 17, fontWeight: FontWeight.bold)),
              Text(
                fmtCurrency.format(_totalPrice + _shippingTax),
                style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(totalPrice: _totalPrice),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
                shadowColor: context.colors.primary.withValues(alpha: 0.4),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.textMuted, fontSize: 14)),
        Text(value, style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
