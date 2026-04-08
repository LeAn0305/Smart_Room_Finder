import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/providers/favorite_provider.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'package:smart_room_finder/widgets/room_card.dart';
import 'package:smart_room_finder/screens/room_detail/room_detail_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String? initialSearch;
  const SearchResultScreen({super.key, this.initialSearch});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late TextEditingController _searchCtrl;

  // Filters
  String _selectedType = 'Tất cả';
  String _selectedLocation = 'Tất cả';
  String _selectedPrice = 'Tất cả';
  final Set<String> _selectedAmenities = {};

  final List<String> _types = ['Tất cả', 'Chung cư', 'Phòng trọ', 'Nhà riêng', 'Biệt thự'];
  final List<String> _locations = ['Tất cả', 'Quận 1', 'Quận 3', 'Quận 7', 'Quận 10', 'Bình Thạnh', 'Tân Bình', 'Gò Vấp', 'Thủ Đức'];
  final List<(String, int, int?)> _priceRanges = [
    ('Tất cả', 0, null),
    ('1 - 5 triệu', 1000000, 5000000),
    ('5 - 10 triệu', 5000000, 10000000),
    ('10 - 15 triệu', 10000000, 15000000),
    ('15 - 20 triệu', 15000000, 20000000),
    ('Trên 20 triệu', 20000000, null),
  ];
  final List<(String, IconData)> _amenities = [
    ('Wifi', Icons.wifi_rounded),
    ('Máy lạnh', Icons.ac_unit_rounded),
    ('Tủ lạnh', Icons.kitchen_rounded),
    ('Máy giặt', Icons.local_laundry_service_rounded),
    ('Bếp', Icons.outdoor_grill_rounded),
    ('Chỗ để xe', Icons.directions_car_rounded),
    ('Bảo vệ', Icons.security_rounded),
    ('Hồ bơi', Icons.pool_rounded),
  ];

  List<RoomModel> _results = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialSearch ?? '');
    _searchCtrl.addListener(_applyFilters);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final all = context.read<RoomProvider>().activePublicRooms;
    final query = _searchCtrl.text.toLowerCase();

    final typeMap = {
      'Chung cư': RoomType.apartment,
      'Phòng trọ': RoomType.studio,
      'Nhà riêng': RoomType.house,
      'Biệt thự': RoomType.villa,
    };

    final priceRange = _priceRanges.firstWhere((p) => p.$1 == _selectedPrice);

    setState(() {
      _results = all.where((r) {
        // Search
        if (query.isNotEmpty &&
            !r.title.toLowerCase().contains(query) &&
            !r.address.toLowerCase().contains(query) &&
            !r.location.toLowerCase().contains(query)) return false;

        // Loại phòng
        if (_selectedType != 'Tất cả' && r.type != typeMap[_selectedType]) return false;

        // Khu vực
        if (_selectedLocation != 'Tất cả' &&
            !r.location.toLowerCase().contains(_selectedLocation.toLowerCase()) &&
            !r.address.toLowerCase().contains(_selectedLocation.toLowerCase())) return false;

        // Giá
        if (priceRange.$2 > 0 && r.price < priceRange.$2) return false;
        if (priceRange.$3 != null && r.price > priceRange.$3!) return false;

        // Tiện ích
        if (_selectedAmenities.isNotEmpty) {
          final hasAll = _selectedAmenities.every((a) =>
              r.amenities.any((ra) => ra.toLowerCase().contains(a.toLowerCase())));
          if (!hasAll) return false;
        }

        return true;
      }).toList();
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedType != 'Tất cả') count++;
    if (_selectedLocation != 'Tất cả') count++;
    if (_selectedPrice != 'Tất cả') count++;
    count += _selectedAmenities.length;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _selectedType = 'Tất cả';
      _selectedLocation = 'Tất cả';
      _selectedPrice = 'Tất cả';
      _selectedAmenities.clear();
    });
    _applyFilters();
  }

  void _showFilterSheet() {
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
                    const Text('Bộ lọc',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _selectedType = 'Tất cả';
                          _selectedLocation = 'Tất cả';
                          _selectedPrice = 'Tất cả';
                          _selectedAmenities.clear();
                        });
                      },
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
                      _filterLabel('🏠 Loại phòng'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _types.map((t) {
                          final sel = _selectedType == t;
                          return _filterChip(
                            label: t, selected: sel,
                            onTap: () => setSheetState(() => _selectedType = t),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Khu vực
                      _filterLabel('📍 Khu vực'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _locations.map((l) {
                          final sel = _selectedLocation == l;
                          return _filterChip(
                            label: l, selected: sel,
                            onTap: () => setSheetState(() => _selectedLocation = l),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Khoảng giá
                      _filterLabel('💰 Khoảng giá'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _priceRanges.map((p) {
                          final sel = _selectedPrice == p.$1;
                          return _filterChip(
                            label: p.$1, selected: sel,
                            onTap: () => setSheetState(() => _selectedPrice = p.$1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Tiện ích
                      _filterLabel('✨ Tiện ích'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _amenities.map((a) {
                          final sel = _selectedAmenities.contains(a.$1);
                          return GestureDetector(
                            onTap: () => setSheetState(() {
                              if (sel) _selectedAmenities.remove(a.$1);
                              else _selectedAmenities.add(a.$1);
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
                                  Text(a.$1,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
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
              // Nút áp dụng
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
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

  Widget _filterLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary));

  Widget _filterChip({required String label, required bool selected, required VoidCallback onTap}) {
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
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textPrimary,
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();

    return Scaffold(
      backgroundColor: AppColors.mintLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ô search
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: widget.initialSearch == null,
                        decoration: InputDecoration(
                          hintText: 'Tìm tên phòng, khu vực...',
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () { _searchCtrl.clear(); _applyFilters(); },
                                  child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Nút filter
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _activeFilterCount > 0 ? AppColors.teal : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                          ),
                          child: Icon(Icons.tune_rounded,
                              color: _activeFilterCount > 0 ? Colors.white : AppColors.teal, size: 20),
                        ),
                        if (_activeFilterCount > 0)
                          Positioned(
                            top: 4, right: 4,
                            child: Container(
                              width: 16, height: 16,
                              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                              child: Center(
                                child: Text('$_activeFilterCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Active filter chips ───────────────────────────
            if (_activeFilterCount > 0)
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_selectedType != 'Tất cả') _activeChip(_selectedType, () => setState(() { _selectedType = 'Tất cả'; _applyFilters(); })),
                    if (_selectedLocation != 'Tất cả') _activeChip(_selectedLocation, () => setState(() { _selectedLocation = 'Tất cả'; _applyFilters(); })),
                    if (_selectedPrice != 'Tất cả') _activeChip(_selectedPrice, () => setState(() { _selectedPrice = 'Tất cả'; _applyFilters(); })),
                    ..._selectedAmenities.map((a) => _activeChip(a, () => setState(() { _selectedAmenities.remove(a); _applyFilters(); }))),
                    GestureDetector(
                      onTap: _resetFilters,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Text('Xóa tất cả',
                            style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Kết quả ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text('${_results.length} phòng',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  if (_activeFilterCount > 0) ...[
                    const SizedBox(width: 6),
                    Text('(đã lọc)', style: TextStyle(fontSize: 12, color: AppColors.teal.withValues(alpha: 0.8))),
                  ],
                ],
              ),
            ),

            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: AppColors.teal.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          const Text('Không tìm thấy phòng nào',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Xóa bộ lọc', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final room = _results[i];
                        final isFav = favoriteProvider.isFavorite(room.id);
                        return RoomCard(
                          room: room.copyWith(isFavorite: isFav),
                          onFavoriteTap: () => context.read<FavoriteProvider>().toggleFavorite(room.id),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => RoomDetailScreen(room: room))),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.tealDark, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}
