import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_service.dart';
import 'receipt_screen.dart';
import 'auth_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  Future<List<dynamic>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = OrderService.getOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF1E1E24),
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat pesanan.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final orders = snapshot.data!;
          final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final createdAt = DateTime.parse(order['created_at']);
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(createdAt);
              final firstItem = order['first_item'];
              final totalItemTypes = order['total_item_types'] ?? 1;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReceiptScreen(orderId: order['id'], fromHistory: true),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shopping_bag, color: Color(0xFFE67E22), size: 18),
                              const SizedBox(width: 8),
                              Text('Belanja', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text(formattedDate, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Berhasil', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (firstItem != null)
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: (firstItem['image_url'] != null && firstItem['image_url'].toString().isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        firstItem['image_url'].toString().startsWith('http')
                                            ? firstItem['image_url']
                                            : '${AuthService.baseUrl}${firstItem['image_url']}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstItem['name'],
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${firstItem['quantity']} barang',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      if (totalItemTypes > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('+${totalItemTypes - 1} jenis barang lainnya', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ),
                      const Divider(color: Colors.grey, height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.local_shipping, color: Colors.grey, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Estimasi Sampai: ${DateFormat('dd MMM yyyy').format(createdAt.add(const Duration(days: 1)))} (Sesuai Kesepakatan)',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Belanja', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency.format(order['total_amount']),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReceiptScreen(orderId: order['id'], fromHistory: true),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE67E22),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Lihat Detail', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
