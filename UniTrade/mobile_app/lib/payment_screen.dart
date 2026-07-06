import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_service.dart';
import 'receipt_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int orderId;
  final String paymentMethod;
  final int totalAmount;

  const PaymentScreen({
    Key? key,
    required this.orderId,
    required this.paymentMethod,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;

  Future<void> _completePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await OrderService.completeOrder(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran berhasil dikonfirmasi!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ReceiptScreen(orderId: widget.orderId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: const Color(0xFF1E1E24),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Total Tagihan',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency.format(widget.totalAmount),
              style: const TextStyle(color: Color(0xFFE67E22), fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            if (widget.paymentMethod == 'QRIS') ...[
              const Text(
                'Silakan scan QRIS di bawah ini untuk membayar:',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  'assets/images/qris.jpg',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 250,
                    height: 250,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Text(
                        'Gambar QRIS belum\ndimasukkan ke folder\nassets/images/qris.jpg',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Icon(Icons.delivery_dining, color: Color(0xFFE67E22), size: 100),
              const SizedBox(height: 24),
              const Text(
                'Metode COD Dipilih!',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Harap siapkan uang tunai pas sesuai total tagihan saat kurir atau penjual tiba di lokasi Anda.',
                style: TextStyle(color: Colors.grey[400], fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.paymentMethod == 'QRIS' ? 'Saya Sudah Bayar' : 'Selesaikan Pesanan',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
