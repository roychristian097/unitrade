import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme.dart';
import 'auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String productName;
  final int productId;
  final int price;

  const CheckoutScreen({
    super.key,
    required this.productName,
    required this.productId,
    required this.price,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'POINTS';
  bool _isProcessing = false;

  Future<void> _processCheckout() async {
    setState(() => _isProcessing = true);
    
    // Simulate network delay for smooth UI
    await Future.delayed(Duration(seconds: 2));

    try {
      final token = AuthService.token;
      if (token == null) throw Exception("Please login first");

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/checkout'),
        headers: {'Authorization': 'Bearer $token'},
        // Simplification: In a real app we'd pass payload here
      );

      if (!mounted) return;
      
      // Usually backend returns success or not. For now we assume success
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: context.colors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
          title: Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
          content: Text(
            "Order Placed Successfully!",
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                child: Text("Back to App"),
              ),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text("Checkout"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order Summary", style: TextStyle(color: context.colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.productName, style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Divider(color: context.colors.border),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total", style: TextStyle(color: context.colors.textMuted, fontSize: 16)),
                      Text("Rp ${widget.price}", style: TextStyle(color: context.colors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text("Payment Method", style: TextStyle(color: context.colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildPaymentOption("UniTrade Points", "POINTS", Icons.stars, context.colors.accent),
            SizedBox(height: 12),
            _buildPaymentOption("Manual Transfer", "MANUAL", Icons.account_balance, Colors.blueAccent),
            SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processCheckout,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
                ),
                child: _isProcessing 
                    ? CircularProgressIndicator(color: context.colors.textPrimary)
                    : Text("Confirm Payment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, String value, IconData icon, Color iconColor) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: GlassContainer(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              activeColor: context.colors.primary,
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
