import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cart_service.dart';
import 'checkout_screen.dart';
import 'theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  static final ValueNotifier<bool> refreshNotifier = ValueNotifier(false);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> _cartItems = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('My Cart', style: TextStyle(color: context.textColor)),
        backgroundColor: context.surfaceColor,
        iconTheme: IconThemeData(color: context.textColor),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)))
          : _cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: context.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: TextStyle(color: context.textMuted, fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return Card(
                      color: context.surfaceColor,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: context.borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                                  ? item['image_url'].toString().startsWith('assets/')
                                      ? Image.asset(
                                          item['image_url'],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          item['image_url'].toString().startsWith('http')
                                              ? item['image_url']
                                              : 'http://192.168.1.3:8000${item['image_url']}',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 80,
                                            height: 80,
                                            color: context.surfaceHighlight,
                                            child: Icon(Icons.image_not_supported, color: context.textMuted),
                                          ),
                                        )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: context.surfaceHighlight,
                                      child: Icon(Icons.image_not_supported, color: context.textMuted),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatCurrency.format(item['price']),
                                    style: const TextStyle(color: Color(0xFFE67E22), fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _updateQuantity(item['cart_id'], (item['quantity'] as int) - 1),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: context.surfaceHighlight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Icon(Icons.remove, color: context.textColor, size: 16),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          '${item['quantity']}',
                                          style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _updateQuantity(item['cart_id'], (item['quantity'] as int) + 1),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: context.surfaceHighlight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Icon(Icons.add, color: context.textColor, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _removeItem(item['cart_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: TextStyle(color: context.textMuted, fontSize: 14)),
                        Text(
                          formatCurrency.format(_totalPrice),
                          style: TextStyle(color: context.textColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(totalPrice: _totalPrice),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Checkout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
