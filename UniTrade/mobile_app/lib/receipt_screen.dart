import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_service.dart';
import 'marketplace_screen.dart';

class ReceiptScreen extends StatefulWidget {
  final int orderId;
  final bool fromHistory;

  const ReceiptScreen({Key? key, required this.orderId, this.fromHistory = false}) : super(key: key);

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final data = await OrderService.getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _order = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F11),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE67E22))),
      );
    }

    if (_errorMessage.isNotEmpty || _order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F11),
        appBar: AppBar(backgroundColor: const Color(0xFF1E1E24)),
        body: Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red))),
      );
    }

    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final items = _order!['items'] as List<dynamic>;
    
    // Format tanggal
    DateTime createdAt = DateTime.parse(_order!['created_at']);
    String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        title: const Text('Struk Pembelian'),
        backgroundColor: const Color(0xFF1E1E24),
        elevation: 0,
        automaticallyImplyLeading: false, // Hilangkan tombol back
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil',
              style: TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReceiptRow('Nomor Pesanan', '#ORD-${_order!['id']}'),
                  const Divider(color: Colors.grey, height: 24),
                  _buildReceiptRow('Tanggal', formattedDate),
                  const Divider(color: Colors.grey, height: 24),
                  _buildReceiptRow('Metode Pembayaran', _order!['payment_method']),
                  const Divider(color: Colors.grey, height: 24),
                  const Text('Lokasi Pengiriman / Ketemuan', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_order!['delivery_address'] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.grey, height: 24),
                  const Text('Barang yang dibeli:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 12),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item['quantity']}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'], style: const TextStyle(color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatCurrency.format(item['price']),
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatCurrency.format(item['price'] * item['quantity']),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )).toList(),
                  const Divider(color: Colors.grey, height: 32, thickness: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        formatCurrency.format(_order!['total_amount']),
                        style: const TextStyle(color: Color(0xFFE67E22), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.fromHistory) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MarketplaceScreen()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(widget.fromHistory ? 'Kembali' : 'Kembali ke Beranda', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
