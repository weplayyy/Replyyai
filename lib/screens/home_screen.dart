import 'package:flutter/material.dart';
import 'tabs/chats_tab.dart';
import 'tabs/rooms_tab.dart';
import 'tabs/discover_tab.dart';
import 'tabs/notifications_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 4;
  final _pages = const [
    ChatsTab(),
    RoomsTab(),
    DiscoverTab(),
    NotificationsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0B2E), Color(0xFF0F0A1F)],
          ),
          border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          selectedItemColor: const Color(0xFFB794F6),
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chats'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups),
                label: 'Rooms'),
            BottomNavigationBarItem(
                icon: _dotIcon(Icons.explore_outlined),
                activeIcon: _dotIcon(Icons.explore),
                label: 'Discover'),
            BottomNavigationBarItem(
                icon: _dotIcon(Icons.notifications_outlined),
                activeIcon: _dotIcon(Icons.notifications),
                label: 'Notifications'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _dotIcon(IconData icon) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
