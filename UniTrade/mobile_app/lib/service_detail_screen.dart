import 'package:http/http.dart' as http;
import 'theme.dart';
import 'package:flutter/material.dart';
import 'services_screen.dart'; // import to reuse ServiceItem and formatCurrency
import 'auth_service.dart';
import 'chat_detail_screen.dart';
import 'chat_list_screen.dart';
import 'main_hub.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceItem service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: _buildAppBar(isDesktop),
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: context.textMuted, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Back to Services",
                      style: TextStyle(color: context.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Hero Section
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildImageSection()),
                        const SizedBox(width: 48),
                        Expanded(flex: 4, child: _buildRightDetailsSection()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 300, child: _buildImageSection()),
                        const SizedBox(height: 24),
                        _buildRightDetailsSection(),
                      ],
                    ),

              const SizedBox(height: 48),

              // Description & Reviews Section
              isDesktop ? _buildBottomDetailsDesktop() : _buildBottomDetailsMobile(),
              
              const SizedBox(height: 48),
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
        color: context.surfaceHighlight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.service.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'http://192.168.1.3:8000${widget.service.imageUrl}',
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.service.category.toUpperCase(),
                style: TextStyle(color: context.colors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRightDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.service.category.toUpperCase(), style: TextStyle(color: context.colors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.service.title,
          style: TextStyle(color: context.colors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          widget.service.maxPrice != null
              ? "Rp ${formatCurrency(widget.service.price)} - Rp ${formatCurrency(widget.service.maxPrice!)} / hr"
              : "Rp ${formatCurrency(widget.service.price)} / hr",
          style: TextStyle(color: context.colors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        
        // Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, 
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        otherUserId: widget.service.sellerId,
                        otherUserName: widget.service.sellerName,
                        productId: widget.service.id,
                        productName: widget.service.title,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.chat_bubble_outline, color: context.colors.textPrimary, size: 18),
                label: const Text("Chat with Freelancer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A2E), // Changed color so Pesan Jasa stands out
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E24),
                      title: const Text("Pesan Jasa", style: TextStyle(color: Colors.white)),
                      content: const Text(
                        "Pemesanan jasa dilakukan dengan berdiskusi langsung dengan penyedia jasa mengenai detail pekerjaan dan jadwal. Silakan hubungi penyedia jasa via chat.",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(context, 
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  otherUserId: widget.service.sellerId,
                                  otherUserName: widget.service.sellerName,
                                  productId: widget.service.id,
                                  productName: widget.service.title,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE67E22)),
                          child: const Text("Hubungi via Chat", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.handshake_outlined, color: Colors.white, size: 18),
                label: const Text("Pesan Jasa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: context.surfaceHighlight,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.favorite_border, color: context.colors.textPrimary),
                onPressed: () {},
              ),
            )
          ],
        ),
        const SizedBox(height: 32),

        // Info Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: context.colors.textMuted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.service.campus != null && widget.service.campus!.isNotEmpty 
                          ? widget.service.campus! 
                          : widget.service.sellerCampus,
                      style: TextStyle(color: context.colors.textMuted, fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (widget.service.meetupLocation != null && widget.service.meetupLocation!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.meeting_room, color: context.colors.textMuted, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Titik Temu / Pickup: ${widget.service.meetupLocation!}",
                        style: TextStyle(color: context.colors.textMuted, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Seller Box
        Container(
          padding: const EdgeInsets.all(16),
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
                child: Text(widget.service.sellerName.isNotEmpty ? widget.service.sellerName[0].toUpperCase() : "U", style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.service.sellerName, style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text("Verified", style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.service.sellerCampus, style: TextStyle(color: context.textMuted, fontSize: 11)),
                  ],
                ),
              ),
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
        const SizedBox(height: 16),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Text(
            widget.service.description,
            style: TextStyle(color: context.textMuted, fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 48),
        Text("Service Reviews (0)", style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text("No reviews left for this service yet.", style: TextStyle(color: context.textMuted, fontSize: 14)),
      ],
    );
  }

  Widget _buildBottomDetailsMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Description", style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          widget.service.description,
          style: TextStyle(color: context.textMuted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        Text("Service Reviews (0)", style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text("No reviews left for this service yet.", style: TextStyle(color: context.textMuted, fontSize: 14)),
      ],
    );
  }

  AppBar _buildAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: context.colors.background,
      elevation: 0,
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
        if (isDesktop) ...[
          _buildAppBarTab("Marketplace", icon: Icons.storefront, onTap: () {
            Navigator.pushReplacement(context,  MaterialPageRoute(builder: (context) => const MainHub()));
          }),
          const SizedBox(width: 16),
          _buildAppBarTab("Services", isActive: true, icon: Icons.build_circle_outlined),
          const SizedBox(width: 16),
          _buildAppBarTab("Chat", icon: Icons.chat_bubble_outline, onTap: () {
            Navigator.push(context,  MaterialPageRoute(builder: (context) => const ChatListScreen()));
          }),
          const SizedBox(width: 32),
        ],
        if (isDesktop) const SizedBox(width: 16),
        if (isDesktop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.textPrimary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: context.textMuted,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AuthService.currentUser?['name'] ?? "Guest", style: TextStyle(color: context.colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(AuthService.currentUser?['campus'] ?? "Universitas Nasional", style: TextStyle(color: context.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        if (isDesktop) const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildAppBarTab(String title, {bool isActive = false, required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? context.colors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? context.colors.primary : context.textMuted, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isActive ? context.colors.primary : context.textMuted,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavIcon(Icons.storefront, "Home", onTap: () {
              Navigator.pushReplacement(context,  MaterialPageRoute(builder: (context) => const MainHub()));
            }),
            _buildBottomNavIcon(Icons.build_circle_outlined, "Services", isActive: true),
            _buildBottomNavIcon(Icons.chat_bubble_outline, "Chat", onTap: () {
              Navigator.push(context,  MaterialPageRoute(builder: (context) => const ChatListScreen()));
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
          Icon(icon, color: isActive ? context.colors.primary : context.textMuted, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? context.colors.primary : context.textMuted,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Service"),
        content: Text("Are you sure you want to delete this service?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
        ]
      )
    );
    if (confirm != true) return;
    try {
      final uri = Uri.http('192.168.1.3:8000', '/services/${widget.service.id}');
      final response = await http.delete(uri);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Service deleted successfully")));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete service")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
