import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'marketplace_screen.dart';
import 'services_screen.dart';
import 'sell_hub_screen.dart';
import 'dashboard_screen.dart';
import 'chat_list_screen.dart';
import 'admin_dashboard_screen.dart';
import 'auth_service.dart';
import 'theme.dart';

class MainHub extends StatefulWidget {
  final bool showWelcome;
  const MainHub({super.key, this.showWelcome = false});

  @override
  State<MainHub> createState() => _MainHubState();
}

class _MainHubState extends State<MainHub> {
  int _currentIndex = 0;
  
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(5, (index) => GlobalKey<NavigatorState>());

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
    ];

    if (AuthService.currentUser != null && AuthService.currentUser!['role'] == 'ADMIN') {
      screens.add(_buildOffstageNavigator(3, AdminDashboardScreen()));
      screens.add(_buildOffstageNavigator(4, DashboardScreen()));
    } else {
      screens.add(_buildOffstageNavigator(3, DashboardScreen()));
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
            _buildBottomNavIcon(Icons.chat_bubble_outline, "Chat", 2),
            _buildBottomNavIcon(Icons.shopping_cart_outlined, "Cart", -1),
            if (AuthService.currentUser != null && AuthService.currentUser!['role'] == 'ADMIN')
              _buildBottomNavIcon(Icons.admin_panel_settings, "Admin", 3),
            _buildBottomNavIcon(
              Icons.person_outline, 
              "Profile", 
              AuthService.currentUser != null && AuthService.currentUser!['role'] == 'ADMIN' ? 4 : 3
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, String label, int index) {
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
          Icon(icon, color: isActive ? const Color(0xFFE67E22) : Colors.grey, size: 24),
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
