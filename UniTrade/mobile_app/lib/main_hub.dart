import 'package:flutter/material.dart';
import 'marketplace_screen.dart';
import 'services_screen.dart';
import 'dashboard_screen.dart';
import 'chat_list_screen.dart';
import 'admin_dashboard_screen.dart';
import 'auth_service.dart';

class MainHub extends StatefulWidget {
  final bool showWelcome;
  const MainHub({super.key, this.showWelcome = false});

  @override
  State<MainHub> createState() => _MainHubState();
}

class _MainHubState extends State<MainHub> {
  int _currentIndex = 0;

  List<Widget> get _screens {
    final screens = <Widget>[
      MarketplaceScreen(showWelcome: widget.showWelcome),
      ServicesScreen(),
      ChatListScreen(),
      DashboardScreen(),
    ];
    if (AuthService.currentUser != null && AuthService.currentUser!['role'] == 'ADMIN') {
      screens.insert(3, AdminDashboardScreen());
    }
    return screens;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Marketplace"),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "Services"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Messages"),
          if (AuthService.currentUser != null && AuthService.currentUser!['role'] == 'ADMIN')
            BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
