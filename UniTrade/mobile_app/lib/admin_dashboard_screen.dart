import 'package:flutter/material.dart';
import 'theme.dart';
import 'admin_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.textMuted,
          indicatorColor: context.colors.primary,
          tabs: [
            Tab(text: 'Users'),
            Tab(text: 'Products'),
            Tab(text: 'Services'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminListTab(
            fetchData: AdminService.getPendingUsers,
            onApprove: AdminService.approveUser,
            onReject: AdminService.rejectUser,
            buildTitle: (item) => item['name'],
            buildSubtitle: (item) => 'Email: ${item['email']}\nCampus: ${item['campus']}',
          ),
          AdminListTab(
            fetchData: AdminService.getPendingProducts,
            onApprove: AdminService.approveProduct,
            onReject: AdminService.rejectProduct,
            buildTitle: (item) => item['name'],
            buildSubtitle: (item) => 'Seller: ${item['seller_name']}\nPrice: Rp ${item['price']}',
          ),
          AdminListTab(
            fetchData: AdminService.getPendingServices,
            onApprove: AdminService.approveService,
            onReject: AdminService.rejectService,
            buildTitle: (item) => item['title'],
            buildSubtitle: (item) => 'Seller: ${item['seller_name']}\nPrice: Rp ${item['price']}',
          ),
        ],
      ),
    );
  }
}

class AdminListTab extends StatefulWidget {
  final Future<List<dynamic>> Function() fetchData;
  final Future<void> Function(int) onApprove;
  final Future<void> Function(int) onReject;
  final String Function(dynamic) buildTitle;
  final String Function(dynamic) buildSubtitle;

  const AdminListTab({
    super.key,
    required this.fetchData,
    required this.onApprove,
    required this.onReject,
    required this.buildTitle,
    required this.buildSubtitle,
  });

  @override
  State<AdminListTab> createState() => _AdminListTabState();
}

class _AdminListTabState extends State<AdminListTab> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await widget.fetchData();
      setState(() {
        _items = items;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(int id, bool isApprove) async {
    try {
      if (isApprove) {
        await widget.onApprove(id);
      } else {
        await widget.onReject(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isApprove ? 'Approved' : 'Rejected'), backgroundColor: isApprove ? Colors.green : Colors.red));
      _loadData(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: context.colors.primary));
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No pending items.',
          style: TextStyle(color: context.colors.textMuted, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          color: context.colors.cardBg,
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(widget.buildTitle(item), style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
            subtitle: Text(widget.buildSubtitle(item), style: TextStyle(color: context.colors.textMuted)),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _handleAction(item['id'], true),
                ),
                IconButton(
                  icon: Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _handleAction(item['id'], false),
                ),
              ],
            ),
          ).animate(delay: (50 * index).ms).fade(duration: 300.ms).slideX(begin: 0.1),
        );
      },
    );
  }
}
