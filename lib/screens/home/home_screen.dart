import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/core/providers/favorite_provider.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:smart_room_finder/providers/preference_provider.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'package:smart_room_finder/services/auth_service.dart';
import 'package:smart_room_finder/services/chat_service.dart';
import 'package:smart_room_finder/services/fcm_service.dart';
import 'package:smart_room_finder/screens/notification/notification_screen.dart';
import 'package:smart_room_finder/widgets/ai_chat_box.dart';
import 'package:smart_room_finder/widgets/room_card.dart';
import 'package:smart_room_finder/widgets/section_title.dart';
import 'package:smart_room_finder/screens/search/search_result_screen.dart';
import 'package:smart_room_finder/screens/room_detail/room_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSwitchToProfile;
  const HomeScreen({super.key, this.onSwitchToProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Tất cả';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _bannerPage = 0;
  final PageController _bannerCtrl = PageController();
  UserModel? _currentUser;

  // ── Filter state ─────────────────────────────────────────
  String _filterType = 'Tất cả';
  String _filterLocation = 'Tất cả';
  String _filterPrice = 'Tất cả';
  String _filterArea = 'Tất cả';
  final Set<String> _filterAmenities = {};

  final List<String> _filterTypes = ['Tất cả', 'Chung cư', 'Phòng trọ', 'Nhà riêng', 'Biệt thự'];
  final List<String> _filterLocations = ['Tất cả', 'Quận 1', 'Quận 3', 'Quận 7', 'Quận 10', 'Bình Thạnh', 'Tân Bình', 'Gò Vấp', 'Thủ Đức'];
  final List<(String, int, int?)> _priceRanges = [
    ('Tất cả', 0, null),
    ('1 - 5 triệu', 1000000, 5000000),
    ('5 - 10 triệu', 5000000, 10000000),
    ('10 - 15 triệu', 10000000, 15000000),
    ('15 - 20 triệu', 15000000, 20000000),
    ('Trên 20 triệu', 20000000, null),
  ];
  // (label, minArea m², maxArea m²) — null = không giới hạn
  final List<(String, double, double?)> _areaRanges = [
    ('Tất cả', 0, null),
    ('Dưới 20m²', 0, 20),
    ('20 - 30m²', 20, 30),
    ('30 - 50m²', 30, 50),
    ('50 - 80m²', 50, 80),
    ('Trên 80m²', 80, null),
  ];
  final List<(String, IconData)> _amenityList = [
    ('Wifi', Icons.wifi_rounded),
    ('Máy lạnh', Icons.ac_unit_rounded),
    ('Tủ lạnh', Icons.kitchen_rounded),
    ('Máy giặt', Icons.local_laundry_service_rounded),
    ('Bếp', Icons.outdoor_grill_rounded),
    ('Chỗ để xe', Icons.directions_car_rounded),
    ('Bảo vệ', Icons.security_rounded),
    ('Hồ bơi', Icons.pool_rounded),
  ];

  int get _activeFilterCount {
    int c = 0;
    if (_filterType != 'Tất cả') c++;
    if (_filterLocation != 'Tất cả') c++;
    if (_filterPrice != 'Tất cả') c++;
    if (_filterArea != 'Tất cả') c++;
    c += _filterAmenities.length;
    return c;
  }

  // Chat box state — managed by AIChatBox widget


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

    // Load user thật từ Firebase
    _loadCurrentUser();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final roomProvider = context.read<RoomProvider>();
      final favoriteProvider = context.read<FavoriteProvider>();

      await roomProvider.fetchRooms();
      if (!mounted) return;

      await favoriteProvider.syncFavoritesForCurrentUser();
    });

    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUserData();
    if (mounted) setState(() => _currentUser = user);
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

  void _toggleFavorite(RoomModel room) {
    context.read<FavoriteProvider>().toggleFavorite(room.id);
  }

  List<RoomModel> _applyFilters(List<RoomModel> rooms, PreferenceProvider pref) {
    List<RoomModel> result = rooms;

    // Category filter (từ chip ngang)
    if (_selectedCategory != 'Tất cả') {
      final typeMap = {
        'Chung cư': RoomType.apartment,
        'Phòng trọ': RoomType.studio,
        'Nhà riêng': RoomType.house,
        'Biệt thự': RoomType.villa,
      };
      result = result.where((r) => r.type == typeMap[_selectedCategory]).toList();
    }

    // Search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((r) =>
          r.title.toLowerCase().contains(_searchQuery) ||
          r.address.toLowerCase().contains(_searchQuery) ||
          r.location.toLowerCase().contains(_searchQuery)).toList();
    }

    // Filter loại phòng (từ bottom sheet)
    if (_filterType != 'Tất cả') {
      final typeMap = {
        'Chung cư': RoomType.apartment,
        'Phòng trọ': RoomType.studio,
        'Nhà riêng': RoomType.house,
        'Biệt thự': RoomType.villa,
      };
      result = result.where((r) => r.type == typeMap[_filterType]).toList();
    }

    // Filter khu vực
    if (_filterLocation != 'Tất cả') {
      result = result.where((r) =>
          r.location.toLowerCase().contains(_filterLocation.toLowerCase()) ||
          r.address.toLowerCase().contains(_filterLocation.toLowerCase())).toList();
    }

    // Filter giá
    final priceRange = _priceRanges.firstWhere((p) => p.$1 == _filterPrice);
    if (priceRange.$2 > 0) {
      result = result.where((r) => r.price >= priceRange.$2).toList();
    }
    if (priceRange.$3 != null) {
      result = result.where((r) => r.price <= priceRange.$3!).toList();
    }

    // Filter diện tích
    final areaRange = _areaRanges.firstWhere((a) => a.$1 == _filterArea);
    if (areaRange.$2 > 0) {
      result = result.where((r) => r.area >= areaRange.$2).toList();
    }
    if (areaRange.$3 != null) {
      result = result.where((r) => r.area <= areaRange.$3!).toList();
    }

    // Filter tiện ích (normalize dấu)
    if (_filterAmenities.isNotEmpty) {
      result = result.where((r) {
        return _filterAmenities.every((selected) {
          final sNorm = _normalize(selected);
          return r.amenities.any((ra) {
            final raNorm = _normalize(ra);
            return raNorm.contains(sNorm) ||
                sNorm.contains(raNorm) ||
                _amenityAliases(selected).any((alias) => raNorm.contains(_normalize(alias)));
          });
        });
      }).toList();
    }

    return pref.applyPreference(result);
  }

  String _normalize(String s) {
    const w = 'àáảãạăắặẳẵằâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ';
    const wo = 'aaaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyyd';
    var r = s.toLowerCase();
    for (var i = 0; i < w.length; i++) r = r.replaceAll(w[i], wo[i]);
    return r;
  }

  List<String> _amenityAliases(String a) {
    final map = <String, List<String>>{
      'Wifi': ['wifi', 'wi-fi', 'mang', 'internet'],
      'Máy lạnh': ['may lanh', 'dieu hoa', 'lanh', 'air', 'ac'],
      'Tủ lạnh': ['tu lanh', 'refrigerator', 'fridge'],
      'Máy giặt': ['may giat', 'washing'],
      'Bếp': ['bep', 'kitchen'],
      'Chỗ để xe': ['cho de xe', 'parking', 'garage', 'ham xe'],
      'Bảo vệ': ['bao ve', 'security', 'an ninh'],
      'Hồ bơi': ['ho boi', 'pool', 'swim'],
    };
    return map[a] ?? [a.toLowerCase()];
  }

  void _showFilterSheet() {
    // Lưu state tạm để cancel không ảnh hưởng
    String tmpType = _filterType;
    String tmpLocation = _filterLocation;
    String tmpPrice = _filterPrice;
    String tmpArea = _filterArea;
    final tmpAmenities = Set<String>.from(_filterAmenities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bộ lọc',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () => setSheet(() {
                        tmpType = 'Tất cả';
                        tmpLocation = 'Tất cả';
                        tmpPrice = 'Tất cả';
                        tmpArea = 'Tất cả';
                        tmpAmenities.clear();
                      }),
                      child: const Text('Xóa tất cả',
                          style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
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
                      _sheetLabel('🏠 Loại phòng'),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: _filterTypes.map((t) => _sheetChip(
                          label: t, selected: tmpType == t,
                          onTap: () => setSheet(() => tmpType = t),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      _sheetLabel('📍 Khu vực'),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: _filterLocations.map((l) => _sheetChip(
                          label: l, selected: tmpLocation == l,
                          onTap: () => setSheet(() => tmpLocation = l),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      _sheetLabel('💰 Khoảng giá'),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: _priceRanges.map((p) => _sheetChip(
                          label: p.$1, selected: tmpPrice == p.$1,
                          onTap: () => setSheet(() => tmpPrice = p.$1),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      _sheetLabel('📐 Diện tích'),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: _areaRanges.map((a) => _sheetChip(
                          label: a.$1, selected: tmpArea == a.$1,
                          onTap: () => setSheet(() => tmpArea = a.$1),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      _sheetLabel('✨ Tiện ích'),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: _amenityList.map((a) {
                          final sel = tmpAmenities.contains(a.$1);
                          return GestureDetector(
                            onTap: () => setSheet(() {
                              if (sel) tmpAmenities.remove(a.$1);
                              else tmpAmenities.add(a.$1);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.teal.withValues(alpha: 0.1) : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sel ? AppColors.teal : Colors.grey[200]!, width: 1.5),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(a.$2, size: 15, color: sel ? AppColors.teal : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(a.$1, style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: sel ? AppColors.tealDark : AppColors.textPrimary)),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              // Nút Áp dụng
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filterType = tmpType;
                        _filterLocation = tmpLocation;
                        _filterPrice = tmpPrice;
                        _filterArea = tmpArea;
                        _filterAmenities.clear();
                        _filterAmenities.addAll(tmpAmenities);
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Áp dụng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary));

  Widget _sheetChip({required String label, required bool selected, required VoidCallback onTap}) {
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
          color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _currentUser?.name ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Bạn';
    final displayImageUrl = _currentUser?.profileImageUrl ??
        FirebaseAuth.instance.currentUser?.photoURL ??
        '';
    final displayLocation = _currentUser?.location ?? 'TP. Hồ Chí Minh';
    final roomProvider = context.watch<RoomProvider>();
    final pref = context.watch<PreferenceProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final filtered = _applyFilters(roomProvider.activePublicRooms, pref);

    return Stack(
      children: [
        Scaffold(
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
                        // ── Chuông + Avatar ──────────────────
                        Row(
                          children: [
                            // Icon chuông thông báo
                            StreamBuilder<int>(
                              stream: FCMService.unreadNotificationStream(),
                              builder: (context, snap) {
                                final unread = snap.data ?? 0;
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationScreen(),
                                    ),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.notifications_rounded,
                                          color: AppColors.teal,
                                          size: 22,
                                        ),
                                      ),
                                      if (unread > 0)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: const BoxDecoration(
                                              color: Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                unread > 9 ? '9+' : '$unread',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            // Avatar
                            GestureDetector(
                              onTap: () {
                                widget.onSwitchToProfile?.call();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.teal, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.mintGreen,
                                  backgroundImage: displayImageUrl.isNotEmpty
                                      ? NetworkImage(displayImageUrl)
                                      : null,
                                  child: displayImageUrl.isEmpty
                                      ? Text(
                                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
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
                                  onTap: _showFilterSheet,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(
                                        Icons.tune_rounded,
                                        color: AppColors.teal,
                                        size: 20,
                                      ),
                                      if (_activeFilterCount > 0)
                                        Positioned(
                                          top: -5, right: -5,
                                          child: Container(
                                            width: 14, height: 14,
                                            decoration: const BoxDecoration(
                                              color: Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$_activeFilterCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
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

                  // AI Feature Buttons — removed, replaced by floating chat

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
    ),

        // ── Floating AI Chat Box ───────────────────────────
        const Positioned(
          right: 16,
          bottom: 24,
          child: AIChatBox(),
        ),
      ],
    );
  }

  Widget _buildBannerCards() {
    return Column(
      children: [
        SizedBox(
          height: 150,
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