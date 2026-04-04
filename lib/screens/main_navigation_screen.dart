import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/core/l10n/language_provider.dart';
import 'package:smart_room_finder/screens/home/home_screen.dart';
import 'package:smart_room_finder/screens/map/map_screen.dart';
import 'package:smart_room_finder/screens/favorite/favorite_screen.dart';
import 'package:smart_room_finder/screens/profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    MapScreen(),
    FavoriteScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.mintSoft,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, -2)),
          ],
          border: Border(top: BorderSide(color: AppColors.teal.withOpacity(0.08), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.mintSoft,
          selectedItemColor: AppColors.teal,
          unselectedItemColor: const Color(0xFF98A6B5),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: lang.tr('nav_home')),
            BottomNavigationBarItem(icon: const Icon(Icons.map_rounded), label: lang.tr('nav_map')),
            BottomNavigationBarItem(icon: const Icon(Icons.favorite_rounded), label: lang.tr('nav_favorite')),
            BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: lang.tr('nav_profile')),
          ],
        ),
      ),
    );
  }
}
