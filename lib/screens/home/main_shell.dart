import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../family/family_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;



  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onAvatarTap: () => setState(() => _index = 3)),
      FamilyScreen(onAvatarTap: () => setState(() => _index = 3)),
      NotificationsScreen(onAvatarTap: () => setState(() => _index = 3)),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
