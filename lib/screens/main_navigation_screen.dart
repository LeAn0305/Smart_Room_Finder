import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/core/l10n/language_provider.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:smart_room_finder/screens/home/home_screen.dart';
import 'package:smart_room_finder/screens/map/map_screen.dart';
import 'package:smart_room_finder/screens/favorite/favorite_screen.dart';
import 'package:smart_room_finder/screens/chat/chat_screen.dart';
import 'package:smart_room_finder/screens/profile/profile_screen.dart';
import 'package:smart_room_finder/services/auth_service.dart';
import 'package:smart_room_finder/services/chat_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  UserRole? _userRole;
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await AuthService.getCurrentUserData();
    if (!mounted) return;
    setState(() {
      _userRole = user?.role;
      _roleLoaded = true;
      // Nếu đang ở tab Chat (index 3) mà là admin → reset về Home
      if (_isAdmin && _selectedIndex == 3) {
        _selectedIndex = 0;
      }
    });
  }

  bool get _isAdmin => _userRole == UserRole.admin;

  // Pages luôn cố định 5, dùng Visibility để ẩn/hiện
  // Tránh rebuild index khi role thay đổi
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Chờ load role xong mới render để tránh flash
    if (!_roleLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }

    // Build pages và nav items dựa trên role
    final pages = _isAdmin
        ? [
            HomeScreen(onSwitchToProfile: () => setState(() => _selectedIndex = 3)),
            const MapScreen(),
            const FavoriteScreen(),
            const ProfileScreen(),
          ]
        : [
            HomeScreen(onSwitchToProfile: () => setState(() => _selectedIndex = 4)),
            const MapScreen(),
            const FavoriteScreen(),
            const ChatScreen(),
            const ProfileScreen(),
          ];

    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    final navItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
          icon: const Icon(Icons.home_rounded),
          label: lang.tr('nav_home')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.map_rounded),
          label: lang.tr('nav_map')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.favorite_rounded),
          label: lang.tr('nav_favorite')),
      if (!_isAdmin)
        BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: ChatService.totalUnreadStream(),
              builder: (context, snap) {
                final count = snap.data ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Chat'),
      BottomNavigationBarItem(
          icon: const Icon(Icons.person_rounded),
          label: lang.tr('nav_profile')),
    ];

    return Scaffold(
      body: pages[safeIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.mintSoft,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -2)),
          ],
          border: Border(
              top: BorderSide(
                  color: AppColors.teal.withValues(alpha: 0.08), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.mintSoft,
          selectedItemColor: AppColors.teal,
          unselectedItemColor: const Color(0xFF98A6B5),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: navItems,
        ),
      ),
    );
  }
}
