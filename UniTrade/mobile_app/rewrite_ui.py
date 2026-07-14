import re
import os

filepath = r"c:\unitrade\UniTrade\mobile_app\lib\marketplace_screen.dart"

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Chunk 1 replacement
chunk1_start = content.find("  @override\n  Widget build(BuildContext context) {")
chunk1_end = content.find("  void _showMobileFilterSheet() {")

if chunk1_start == -1 or chunk1_end == -1:
    print("Error finding chunk 1 bounds")

chunk1_replacement = """  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(isDesktop),
      body: RefreshIndicator(
        color: const Color(0xFF00AA5B),
        backgroundColor: Colors.white,
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopTabs(),
              _buildFlashSaleWidget(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _buildProductGrid(isDesktop),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _applyFilters(),
                style: TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "paket gift box buat cewek",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          _buildActionIcon(Icons.chat_bubble_outline, _unreadNotifCount, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListScreen()));
          }),
          SizedBox(width: 16),
          _buildActionIcon(Icons.shopping_cart_outlined, 12, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
          }),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: _buildQuickCategoryChips(),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.black, size: 24),
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildTopTabs() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTab("For Shandy", isActive: true),
              _buildTab("Mall", isMall: true),
              _buildTab("Elektronik"),
              _buildTab("Handphone & Gadg..."),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String title, {bool isActive = false, bool isMall = false}) {
    return Column(
      children: [
        Row(
          children: [
            if (isMall)
              Container(
                margin: EdgeInsets.only(right: 4),
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(4)),
                child: Icon(Icons.check, color: Colors.white, size: 10),
              ),
            Text(
              isMall ? "Mall" : title,
              style: TextStyle(
                color: isActive ? Color(0xFF00AA5B) : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        if (isActive)
          Container(
            margin: EdgeInsets.only(top: 4),
            height: 3,
            width: 40,
            color: Color(0xFF00AA5B),
          )
      ],
    );
  }

  Widget _buildQuickCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ["Android OS", "Stand Handphone", "iOS", "Screen Protector"].map((cat) {
          return Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text(cat, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlashSaleWidget() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Flash Sale", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                child: Text("11:29:50", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildFlashSaleItem("Rp288.150", "Rp499.000")),
              SizedBox(width: 8),
              Expanded(child: _buildFlashSaleItem("Rp23.800", "Rp35.500")),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildFlashSaleItem("Rp155.000", "Rp217.000")),
              SizedBox(width: 8),
              Expanded(child: _buildFlashSaleItem("Rp105.000", "Rp229.000")),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFlashSaleItem(String price, String originalPrice) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(child: Icon(Icons.image, color: Colors.grey)),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(originalPrice, style: TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.lineThrough)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavIcon(Icons.thumb_up, "Buat Kamu", isActive: true),
            _buildBottomNavIcon(Icons.play_circle_outline, "Feed"),
            _buildBottomNavIcon(Icons.shopping_bag_outlined, "Mall"),
            _buildBottomNavIcon(Icons.receipt_long, "Transaksi"),
            _buildBottomNavIcon(Icons.person_outline, "Akun"),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Color(0xFF00AA5B) : Colors.grey, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Color(0xFF00AA5B) : Colors.grey,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

"""

# Chunk 2 replacement
chunk2_start = content.find("  Widget _buildProductGrid(bool isDesktop) {")
if chunk2_start == -1:
    print("Error finding chunk 2 start")
chunk2_end = len(content)

chunk2_replacement = """  Widget _buildProductGrid(bool isDesktop) {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)));
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red)));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Center(child: Text("Tidak ada produk", style: TextStyle(color: Colors.grey)));
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.55,
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
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl.startsWith('http') ? product.imageUrl : 'http://127.0.0.1:8000${product.imageUrl}',
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey.shade200, child: Icon(Icons.image, color: Colors.grey)),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomLeft: Radius.circular(8))),
                    child: Text(">10%", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (product.itemType == 'Barang')
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Text("PreOrder", style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  )
              ],
            ),
            // Banner strip
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    color: Colors.red.shade700,
                    child: Text("XTRA\\nVOUCHER", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, height: 1.1)),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    color: Color(0xFF00AA5B),
                    child: Text("GRATIS\\nONGKIR", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, height: 1.1)),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    color: Colors.black87,
                    child: Text("Bonus\\nCashback", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold, height: 1.1)),
                  ),
                )
              ],
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: Color(0xFF00AA5B), size: 14),
                      SizedBox(width: 4),
                      Text("Power Shop", style: TextStyle(color: Color(0xFF00AA5B), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  SizedBox(height: 6),
                  Text("Rp${formatCurrency(product.price)}", style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text("Harga Diskon", style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text("Hemat s.d 8% Pakai Bonus", style: TextStyle(color: Colors.orange.shade800, fontSize: 10)),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 12),
                      Text(" 4.9 • 100+ terjual", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.local_shipping, color: Color(0xFF00AA5B), size: 12),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text("Instant - Kota Admini...", style: TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
"""

new_content = content[:chunk1_start] + chunk1_replacement + content[chunk1_end:chunk2_start] + chunk2_replacement

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Rewrite successful")
