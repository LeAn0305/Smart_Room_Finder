import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/core/providers/favorite_provider.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:smart_room_finder/services/auth_service.dart';
import 'package:smart_room_finder/providers/preference_provider.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'package:smart_room_finder/services/fcm_service.dart';
import 'package:smart_room_finder/services/notification_permission_service.dart';
import 'package:smart_room_finder/widgets/room_card.dart';
import 'package:smart_room_finder/widgets/section_title.dart';
import 'package:smart_room_finder/screens/search/search_result_screen.dart';
import 'package:smart_room_finder/screens/room_detail/room_detail_screen.dart';
import 'package:smart_room_finder/screens/notification/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Tất cả';
  UserModel? _currentUser;
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
    _loadUser();

    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final roomProvider = context.read<RoomProvider>();
      final favoriteProvider = context.read<FavoriteProvider>();

      await roomProvider.fetchRooms();
      if (!mounted) return;

      await favoriteProvider.syncFavoritesForCurrentUser();

      // Xin quyền notification (Android 13+) và khởi tạo FCM
      if (mounted) {
        // Android: xin quyền qua permission_handler
        // Web: Firebase Messaging tự xử lý khi gọi getToken()
        // Windows/Desktop: bỏ qua
        final granted = await NotificationPermissionService.requestWithExplanation(context);
        if (granted) {
          await FCMService.initFCM();
        } else {
          // Trên Web, vẫn thử init FCM (browser sẽ hỏi quyền)
          if (!mounted) return;
          await FCMService.initFCM();
        }
      }
    });

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

  Future<void> _loadUser() async {
    final u = await AuthService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _currentUser = u;
      });
    }
  }

  void _toggleFavorite(RoomModel room) {
    context.read<FavoriteProvider>().toggleFavorite(room.id);
  }

  /// Mở filter sheet trực tiếp từ Home (không qua màn trung gian).
  /// Sau khi bấm Áp dụng sẽ push sang SearchResultScreen với các filter đã chọn.
  void _showHomeFilterSheet(BuildContext context) {
    // Các giá trị filter tạm thời trong sheet
    String tempType = 'Tất cả';
    String tempLocation = 'Tất cả';
    String tempPrice = 'Tất cả';
    String tempArea = 'Tất cả';
    Set<String> tempAmenities = {};

    final types = ['Tất cả', 'Chung cư', 'Phòng trọ', 'Nhà riêng', 'Biệt thự'];
    final locations = ['Tất cả', 'Quận 1', 'Quận 3', 'Quận 7', 'Quận 10', 'Bình Thạnh', 'Tân Bình', 'Gò Vấp', 'Thủ Đức'];
    final priceRanges = [
      'Tất cả', 'Dưới 1 triệu', '1 - 5 triệu', '5 - 10 triệu',
      '10 - 15 triệu', '15 - 20 triệu', 'Trên 20 triệu',
    ];
    final areaRanges = [
      'Tất cả', 'Dưới 20m²', '20 - 40m²', '40 - 60m²', '60 - 100m²', 'Trên 100m²',
    ];
    final amenities = [
      ('Wifi', Icons.wifi_rounded),
      ('Máy lạnh', Icons.ac_unit_rounded),
      ('Tủ lạnh', Icons.kitchen_rounded),
      ('Máy giặt', Icons.local_laundry_service_rounded),
      ('Bếp', Icons.outdoor_grill_rounded),
      ('Chỗ để xe', Icons.directions_car_rounded),
      ('Bảo vệ', Icons.security_rounded),
      ('Hồ bơi', Icons.pool_rounded),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bộ lọc nâng cao',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () => setSheetState(() {
                        tempType = 'Tất cả';
                        tempLocation = 'Tất cả';
                        tempPrice = 'Tất cả';
                        tempArea = 'Tất cả';
                        tempAmenities.clear();
                      }),
                      child: const Text('Xóa tất cả', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loại phòng
                      _filterSheetLabel('🏠 Loại phòng'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: types.map((t) => _filterSheetChip(
                          label: t, selected: tempType == t,
                          onTap: () => setSheetState(() => tempType = t),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      // Khu vực
                      _filterSheetLabel('📍 Khu vực'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: locations.map((l) => _filterSheetChip(
                          label: l, selected: tempLocation == l,
                          onTap: () => setSheetState(() => tempLocation = l),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      // Khoảng giá
                      _filterSheetLabel('💰 Khoảng giá'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: priceRanges.map((p) => _filterSheetChip(
                          label: p, selected: tempPrice == p,
                          onTap: () => setSheetState(() => tempPrice = p),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      // Diện tích
                      _filterSheetLabel('📐 Diện tích'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: areaRanges.map((a) => _filterSheetChip(
                          label: a, selected: tempArea == a,
                          onTap: () => setSheetState(() => tempArea = a),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      // Tiện ích
                      _filterSheetLabel('✨ Tiện ích'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: amenities.map((a) {
                          final sel = tempAmenities.contains(a.$1);
                          return GestureDetector(
                            onTap: () => setSheetState(() {
                              if (sel) tempAmenities.remove(a.$1);
                              else tempAmenities.add(a.$1);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.teal.withValues(alpha: 0.1) : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sel ? AppColors.teal : Colors.grey[200]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(a.$2, size: 15, color: sel ? AppColors.teal : AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(a.$1, style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: sel ? AppColors.tealDark : AppColors.textPrimary,
                                  )),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Nút Áp dụng — đóng sheet và push sang SearchResultScreen với filter
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx); // Đóng sheet
                      // Push sang SearchResultScreen với filter đã chọn
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchResultScreen(
                            initialType: tempType,
                            initialLocation: tempLocation,
                            initialPrice: tempPrice,
                            initialArea: tempArea,
                            initialAmenities: Set.from(tempAmenities),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Áp dụng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterSheetLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary));

  Widget _filterSheetChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.teal : Colors.grey[200]!, width: 1.5),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textPrimary,
        )),
      ),
    );
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
    // Dùng _currentUser nếu đã load xong; không fallback về sampleUsers để tránh hiển thị sai tên
    final user = _currentUser;
    final displayName = user?.name ?? '...';
    final displayAvatar = user?.profileImageUrl ?? '';
    final displayLocation = user?.location ?? 'TP. Hồ Chí Minh';
    final roomProvider = context.watch<RoomProvider>();
    final pref = context.watch<PreferenceProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final filtered = _applyFilters(roomProvider.activePublicRooms, pref);

    return Scaffold(
      backgroundColor: AppColors.mintLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
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
                              displayName,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Icon chuông thông báo
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationScreen(),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.teal,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Avatar user — dùng _UserAvatar để handle lỗi load ảnh
                            _UserAvatar(
                              imageUrl: displayAvatar,
                              displayName: displayName,
                            ),
                          ],
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
                            color: AppColors.blue.withValues(alpha: 0.06),
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
                                  onTap: () {
                                    // Mở filter sheet trực tiếp từ Home
                                    // Sau khi Áp dụng sẽ push sang SearchResultScreen với filter đã chọn
                                    _showHomeFilterSheet(context);
                                  },
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
                          displayLocation,
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
                        builder: (_) => const SearchResultScreen(),
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
                                  color: AppColors.teal.withValues(alpha: 0.2),
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
                            itemBuilder: (_, i) {
                              final room = filtered[i];
                              final isFavorite = favoriteProvider.isFavorite(
                                room.id,
                              );

                              return RoomCard(
                                room: room.copyWith(isFavorite: isFavorite),
                                isHorizontal: true,
                                onFavoriteTap: () => _toggleFavorite(room),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RoomDetailScreen(room: room),
                                  ),
                                ),
                              );
                            },
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
                    itemCount: filtered.length < 3 ? filtered.length : 3,
                    itemBuilder: (_, i) {
                      final room = filtered[filtered.length - 1 - i];
                      final isFavorite = favoriteProvider.isFavorite(room.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: RoomCard(
                          room: room.copyWith(isFavorite: isFavorite),
                          onFavoriteTap: () => _toggleFavorite(room),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomDetailScreen(room: room),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
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
                        color: b.gradient.first.withValues(alpha: 0.35),
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
                            color: Colors.white.withValues(alpha: 0.08),
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
                            color: Colors.white.withValues(alpha: 0.06),
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
                                color: Colors.white.withValues(alpha: 0.2),
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
                                      color: Colors.white.withValues(alpha: 0.25),
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
                                      color: Colors.white.withValues(alpha: 0.85),
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
                    color: Colors.black.withValues(alpha: 0.04),
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

/// Widget hiển thị avatar user, fallback về chữ cái đầu tên nếu không có ảnh hoặc lỗi load
class _UserAvatar extends StatelessWidget {
  final String imageUrl;
  final String displayName;

  const _UserAvatar({required this.imageUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.teal.withValues(alpha: 0.15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(initials),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildInitials(initials);
                },
              )
            : _buildInitials(initials),
      ),
    );
  }

  Widget _buildInitials(String initials) {
    return Container(
      color: AppColors.teal.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.teal,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
