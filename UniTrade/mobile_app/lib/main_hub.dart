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
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 24.0),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavIcon(Icons.storefront_outlined, "home", 0),
              _buildBottomNavIcon(Icons.add_box_outlined, "sell", 1),
              _buildBottomNavIcon(Icons.chat_bubble_outline, "chat", 2, badgeCount: _unreadChatCount),
              _buildBottomNavIcon(Icons.shopping_cart_outlined, "cart", 3),
              if (AuthService.currentUser != null && AuthService.currentUser!['role'] == 'ADMIN')
                _buildBottomNavIcon(Icons.admin_panel_settings_outlined, "admin", 4),
              _buildBottomNavIcon(
                Icons.person_outline, 
                "profile", 
                AuthService.currentUser != null && AuthService.currentUser!['role'] == 'ADMIN' ? 5 : 4
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, String label, int index, {int badgeCount = 0}) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16.0 : 12.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4F1B4) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.black : Colors.white60,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
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
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              child: SizedBox(
                width: isActive ? null : 0,
                child: Padding(
                  padding: EdgeInsets.only(left: isActive ? 8.0 : 0.0),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
