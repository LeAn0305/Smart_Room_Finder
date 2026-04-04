import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:smart_room_finder/providers/preference_provider.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'package:smart_room_finder/widgets/room_card.dart';
import 'package:smart_room_finder/widgets/section_title.dart';
import 'package:smart_room_finder/screens/search/search_result_screen.dart';
import 'package:smart_room_finder/screens/room_detail/room_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Tất cả';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _bannerPage = 0;
  final PageController _bannerCtrl = PageController();

  final List<String> _categories = [
    'Tất cả',
    'Chung cư',
    'Phòng trọ',
    'Nhà riêng',
    'Biệt thự',
  ];

  final List<_BannerData> _banners = const [
    _BannerData(
      gradient: [Color(0xFF52CFCB), Color(0xFF2FAFB1)],
      icon: Icons.local_offer_rounded,
      title: 'Ưu đãi tháng 4',
      subtitle: 'Giảm 20% phí dịch vụ\ncho lần đăng đầu tiên',
      badge: 'HOT',
    ),
    _BannerData(
      gradient: [Color(0xFF3AA3E3), Color(0xFF2A7FBE)],
      icon: Icons.verified_rounded,
      title: 'Phòng đã xác minh',
      subtitle: 'Hơn 500+ phòng được\nkiểm duyệt chất lượng',
      badge: 'MỚI',
    ),
    _BannerData(
      gradient: [Color(0xFF7EDFD8), Color(0xFF52CFCB)],
      icon: Icons.support_agent_rounded,
      title: 'Hỗ trợ 24/7',
      subtitle: 'Đội ngũ tư vấn luôn\nsẵn sàng giúp bạn',
      badge: 'TIP',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted || !_bannerCtrl.hasClients) return;
    final next = (_bannerPage + 1) % _banners.length;
    _bannerCtrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  List<RoomModel> _applyFilters(List<RoomModel> rooms, PreferenceProvider pref) {
    List<RoomModel> result = rooms;

    if (_selectedCategory != 'Tất cả') {
      final typeMap = {
        'Chung cư': RoomType.apartment,
        'Phòng trọ': RoomType.studio,
        'Nhà riêng': RoomType.house,
        'Biệt thự': RoomType.villa,
      };
      result =
          result.where((r) => r.type == typeMap[_selectedCategory]).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
            (r) =>
                r.title.toLowerCase().contains(_searchQuery) ||
                r.address.toLowerCase().contains(_searchQuery) ||
                r.location.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    return pref.applyPreference(result);
  }

  @override
  Widget build(BuildContext context) {
    final user = UserModel.currentUser;
    final roomProvider = context.watch<RoomProvider>();
    final pref = context.watch<PreferenceProvider>();
    final filtered = _applyFilters(roomProvider.activePublicRooms, pref);

    return Scaffold(
      backgroundColor: AppColors.mintLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào buổi sáng,',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          user.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.teal, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(user.profileImageUrl),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm phòng trọ, khu vực...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.teal,
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            )
                          : GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SearchResultScreen(),
                                ),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: AppColors.teal,
                                size: 20,
                              ),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.teal,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.location,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _buildBannerCards(),

              const SizedBox(height: 16),

              _buildCategoryFilter(),

              const SizedBox(height: 4),

              SectionTitle(
                title: pref.completed ? 'Gợi ý cho bạn ✨' : 'Gợi ý cho bạn',
                actionText: 'Xem tất cả',
                onActionTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchResultScreen(),
                  ),
                ),
              ),

              SizedBox(
                height: 360,
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 60,
                              color: AppColors.teal.withOpacity(0.2),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Không tìm thấy phòng nào',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => RoomCard(
                          room: filtered[i],
                          isHorizontal: true,
                          onFavoriteTap: () => context
                              .read<RoomProvider>()
                              .toggleFavorite(filtered[i].id),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RoomDetailScreen(room: filtered[i]),
                            ),
                          ),
                        ),
                      ),
              ),

              SectionTitle(
                title: 'Phòng gần đây',
                actionText: 'Xem bản đồ',
                onActionTap: () {},
              ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length < 2 ? filtered.length : 2,
                itemBuilder: (_, i) {
                  final room = filtered[filtered.length - 1 - i];
                  return RoomCard(
                    room: room,
                    onFavoriteTap: () =>
                        context.read<RoomProvider>().toggleFavorite(room.id),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomDetailScreen(room: room),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCards() {
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _bannerCtrl,
            onPageChanged: (i) => setState(() => _bannerPage = i),
            itemCount: _banners.length,
            itemBuilder: (_, i) {
              final b = _banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: b.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: b.gradient.first.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 30,
                        bottom: -30,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                b.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      b.badge,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    b.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b.subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _bannerPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _bannerPage == i ? AppColors.teal : AppColors.mintGreen,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final sel = _selectedCategory == _categories[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = _categories[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: sel ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _categories[i],
                style: TextStyle(
                  color: sel ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BannerData {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  const _BannerData({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}