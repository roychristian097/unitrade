import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'marketplace_screen.dart';
import 'services_screen.dart';
import 'cart_screen.dart';
import 'sell_hub_screen.dart';
import 'dashboard_screen.dart';
import 'profile_page.dart';
import 'chat_list_screen.dart';
import 'admin_dashboard_screen.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'theme.dart';
import 'dart:async';

class MainHub extends StatefulWidget {
  final bool showWelcome;
  const MainHub({super.key, this.showWelcome = false});

  @override
  State<MainHub> createState() => _MainHubState();
}

class _MainHubState extends State<MainHub> {
  int _currentIndex = 0;
  int _unreadChatCount = 0;
  Timer? _pollingTimer;
  
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(6, (index) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    _fetchUnreadChats();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchUnreadChats());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadChats() async {
    try {
      final count = await ChatService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadChatCount = count;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Widget _buildOffstageNavigator(int index, Widget child) {
    return Offstage(
      offstage: _currentIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) => child,
          );
        },
      ),
    );
  }

  List<Widget> get _screens {
    final screens = <Widget>[
      _buildOffstageNavigator(0, MarketplaceScreen(showWelcome: widget.showWelcome)),
      _buildOffstageNavigator(1, const SellHubScreen()),
      _buildOffstageNavigator(2, ChatListScreen()),
      _buildOffstageNavigator(3, const CartScreen()),
    ];

    if (AuthService.currentUser != null && AuthService.currentUser!['role'] == 'ADMIN') {
      screens.add(_buildOffstageNavigator(4, AdminDashboardScreen()));
      screens.add(_buildOffstageNavigator(5, const ProfilePage()));
    } else {
      screens.add(_buildOffstageNavigator(4, const ProfilePage()));
    }

    return screens;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final isFirstRouteInCurrentTab = !await _navigatorKeys[_currentIndex].currentState!.maybePop();
        
        if (isFirstRouteInCurrentTab) {
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            context.bgColor.withValues(alpha: 0.85),
            context.bgColor,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavIcon(Icons.storefront, "Home", 0),
            _buildBottomNavIcon(Icons.add_box_outlined, "Sell", 1),
            _buildBottomNavIcon(Icons.chat_bubble_outline, "Chat", 2, badgeCount: _unreadChatCount),
            _buildBottomNavIcon(Icons.shopping_cart_outlined, "Cart", 3),
            if (AuthService.currentUser != null && AuthService.currentUser!['role'] == 'ADMIN')
              _buildBottomNavIcon(Icons.admin_panel_settings, "Admin", 4),
            _buildBottomNavIcon(
              Icons.person_outline, 
              "Profile", 
              AuthService.currentUser != null && AuthService.currentUser!['role'] == 'ADMIN' ? 5 : 4
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, String label, int index, {int badgeCount = 0}) {
    bool isActive = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == -1) return;
        if (_currentIndex == index) {
          _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: isActive ? const Color(0xFFE67E22) : Colors.grey, size: 24),
              if (badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFE67E22) : Colors.grey,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
