import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/providers/favorite_provider.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'package:smart_room_finder/widgets/room_card.dart';
import 'package:smart_room_finder/screens/room_detail/room_detail_screen.dart';

/// Loại bỏ dấu tiếng Việt để so sánh không phân biệt dấu
String _removeDiacritics(String str) {
  const vietnamese = 'aàáạảãâầấậẩẫăằắặẳẵeèéẹẻẽêềếệểễiìíịỉĩoòóọỏõôồốộổỗơờớợởỡuùúụủũưừứựửữyỳýỵỷỹđ';
  const nonDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiioooooooooooooooooouuuuuuuuuuuuyyyyyd';
  String result = str.toLowerCase();
  for (int i = 0; i < vietnamese.length; i++) {
    result = result.replaceAll(vietnamese[i], nonDiacritics[i]);
  }
  return result;
}

String _sanitizeAmenity(String str) {
  return _removeDiacritics(str).replaceAll(RegExp(r'[\s\-]'), '');
}

class SearchResultScreen extends StatefulWidget {
  final String? initialSearch;
  const SearchResultScreen({super.key, this.initialSearch});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late TextEditingController _searchCtrl;
  bool _isLoading = false;

  // Filters
  String _selectedType = 'Tất cả';
  String _selectedLocation = 'Tất cả';
  String _selectedPrice = 'Tất cả';
  String _selectedArea = 'Tất cả';
  final Set<String> _selectedAmenities = {};

  final List<(String, int, int?)> _areaRanges = [
    ('Tất cả', 0, null),
    ('Dưới 20m²', 0, 20),
    ('20 - 40m²', 20, 40),
    ('40 - 60m²', 40, 60),
    ('60 - 100m²', 60, 100),
    ('Trên 100m²', 100, null),
  ];

  /// Alias mapping cho tiện ích — hỗ trợ nhiều cách viết
  static const Map<String, List<String>> _amenityAliases = {
    'Wifi': ['wifi', 'wi-fi', 'internet'],
    'Máy lạnh': ['may lanh', 'máy lạnh', 'dieu hoa', 'điều hòa', 'điều hoà', 'ac'],
    'Tủ lạnh': ['tu lanh', 'tủ lạnh'],
    'Máy giặt': ['may giat', 'máy giặt', 'giặt'],
    'Bếp': ['bep', 'bếp', 'nấu ăn', 'nau an'],
    'Chỗ để xe': ['cho de xe', 'chỗ để xe', 'để xe', 'de xe', 'hầm xe', 'ham xe', 'gửi xe', 'gui xe'],
    'Bảo vệ': ['bao ve', 'bảo vệ', 'an ninh', 'security'],
    'Hồ bơi': ['ho boi', 'hồ bơi', 'pool', 'bể bơi', 'be boi'],
  };

  final List<String> _types = ['Tất cả', 'Chung cư', 'Phòng trọ', 'Nhà riêng', 'Biệt thự'];
  final List<String> _locations = ['Tất cả', 'Quận 1', 'Quận 3', 'Quận 7', 'Quận 10', 'Bình Thạnh', 'Tân Bình', 'Gò Vấp', 'Thủ Đức'];
  final List<(String, int, int?)> _priceRanges = [
    ('Tất cả', 0, null),
    ('Dưới 1 triệu', 0, 1000000),
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

  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500)); // Fake delay for UX

    if (!mounted) return;
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
      final filtered = all.where((r) {
        // Search
        if (query.isNotEmpty &&
            !r.title.toLowerCase().contains(query) &&
            !r.address.toLowerCase().contains(query) &&
            !r.location.toLowerCase().contains(query)) {
          return false;
        }

        // Loại phòng
        if (_selectedType != 'Tất cả' && r.type != typeMap[_selectedType]) return false;

        // Khu vực
        if (_selectedLocation != 'Tất cả') {
          final searchLoc = _selectedLocation.toLowerCase();
          RegExp regex;
          if (searchLoc.startsWith('quận ')) {
            final num = searchLoc.split(' ')[1];
            // Hỗ trợ cả các định dạng viết tắt phổ biến: "Quận 1", "Q1", "Q.1", "Q 1" 
            // \b đảm bảo "Q1" không dính với "Q10"
            regex = RegExp(r'\b(quận|q)\s*\.?\s*' + num + r'\b', caseSensitive: false);
          } else {
            regex = RegExp(r'\b' + RegExp.escape(searchLoc) + r'\b', caseSensitive: false);
          }
          
          if (!regex.hasMatch(r.location.toLowerCase()) && !regex.hasMatch(r.address.toLowerCase())) {
            return false;
          }
        }

        // Giá
        final minPrice = priceRange.$2;
        final maxPrice = priceRange.$3;
        if (_selectedPrice != 'Tất cả') {
          if (r.price < minPrice) return false;
          if (maxPrice != null && r.price > maxPrice) return false; // Dùng > để lấy cả giá trị đúng bằng maxPrice
        }

        // Diện tích
        if (_selectedArea != 'Tất cả') {
          final areaRange = _areaRanges.firstWhere((a) => a.$1 == _selectedArea);
          final minArea = areaRange.$2;
          final maxArea = areaRange.$3;
          if (r.area < minArea) return false;
          if (maxArea != null && r.area > maxArea) return false; // Dùng > để lấy cả diện tích bằng biên trên
        }

        // Tiện ích — so sánh normalize dấu + alias
        if (_selectedAmenities.isNotEmpty) {
          final hasAll = _selectedAmenities.every((filterAmenity) {
            final aliases = _amenityAliases[filterAmenity] ?? [filterAmenity];
            return r.amenities.any((roomAmenity) {
              final normalizedRoom = _sanitizeAmenity(roomAmenity);
              return aliases.any((alias) =>
                  normalizedRoom.contains(_sanitizeAmenity(alias)));
            });
          });
          if (!hasAll) return false;
        }

        return true;
      }).toList();

      if (_selectedAmenities.isNotEmpty) {
        _results = filtered.map((r) {
          final sorted = List<String>.from(r.amenities);
          sorted.sort((a, b) {
            final aMatch = _selectedAmenities.any((sel) {
              final aliases = _amenityAliases[sel] ?? [sel];
              final normA = _sanitizeAmenity(a);
              return aliases.any((al) => normA.contains(_sanitizeAmenity(al)));
            });
            final bMatch = _selectedAmenities.any((sel) {
              final aliases = _amenityAliases[sel] ?? [sel];
              final normB = _sanitizeAmenity(b);
              return aliases.any((al) => normB.contains(_sanitizeAmenity(al)));
            });
            if (aMatch && !bMatch) return -1;
            if (!aMatch && bMatch) return 1;
            return 0;
          });
          return r.copyWith(amenities: sorted);
        }).toList();
      } else {
        _results = filtered;
      }
      _isLoading = false;
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedType != 'Tất cả') count++;
    if (_selectedLocation != 'Tất cả') count++;
    if (_selectedPrice != 'Tất cả') count++;
    if (_selectedArea != 'Tất cả') count++;
    count += _selectedAmenities.length;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _selectedType = 'Tất cả';
      _selectedLocation = 'Tất cả';
      _selectedPrice = 'Tất cả';
      _selectedArea = 'Tất cả';
      _selectedAmenities.clear();
    });
    _applyFilters();
  }

  void _showFilterSheet() {
    String tempType = _selectedType;
    String tempLocation = _selectedLocation;
    String tempPrice = _selectedPrice;
    String tempArea = _selectedArea;
    Set<String> tempAmenities = Set.from(_selectedAmenities);

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
                          tempType = 'Tất cả';
                          tempLocation = 'Tất cả';
                          tempPrice = 'Tất cả';
                          tempArea = 'Tất cả';
                          tempAmenities.clear();
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
                          final sel = tempType == t;
                          return _filterChip(
                            label: t, selected: sel,
                            onTap: () => setSheetState(() => tempType = t),
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
                          final sel = tempLocation == l;
                          return _filterChip(
                            label: l, selected: sel,
                            onTap: () => setSheetState(() => tempLocation = l),
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
                          final sel = tempPrice == p.$1;
                          return _filterChip(
                            label: p.$1, selected: sel,
                            onTap: () => setSheetState(() => tempPrice = p.$1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Diện tích
                      _filterLabel('📐 Diện tích'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _areaRanges.map((a) {
                          final sel = tempArea == a.$1;
                          return _filterChip(
                            label: a.$1, selected: sel,
                            onTap: () => setSheetState(() => tempArea = a.$1),
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
                          final sel = tempAmenities.contains(a.$1);
                          return GestureDetector(
                            onTap: () => setSheetState(() {
                              if (sel) {
                                tempAmenities.remove(a.$1);
                              } else {
                                tempAmenities.add(a.$1);
                              }
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
                      setState(() {
                        _selectedType = tempType;
                        _selectedLocation = tempLocation;
                        _selectedPrice = tempPrice;
                        _selectedArea = tempArea;
                        _selectedAmenities = tempAmenities;
                      });
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
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (_selectedType != 'Tất cả') _activeChip('🏠 $_selectedType', () => setState(() { _selectedType = 'Tất cả'; _applyFilters(); })),
                      if (_selectedLocation != 'Tất cả') _activeChip('📍 $_selectedLocation', () => setState(() { _selectedLocation = 'Tất cả'; _applyFilters(); })),
                      if (_selectedPrice != 'Tất cả') _activeChip('💰 $_selectedPrice', () => setState(() { _selectedPrice = 'Tất cả'; _applyFilters(); })),
                      if (_selectedArea != 'Tất cả') _activeChip('📐 $_selectedArea', () => setState(() { _selectedArea = 'Tất cả'; _applyFilters(); })),
                      ..._selectedAmenities.map((a) => _activeChip('✨ $a', () => setState(() { _selectedAmenities.remove(a); _applyFilters(); }))),
                      GestureDetector(
                        onTap: _resetFilters,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.redAccent.withValues(alpha: 0.12), Colors.redAccent.withValues(alpha: 0.06)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.filter_alt_off_rounded, size: 13, color: Colors.redAccent),
                              SizedBox(width: 4),
                              Text('Xóa tất cả',
                                  style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Kết quả header ──────────────────────────────
            if (!_isLoading && _results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _activeFilterCount > 0
                      ? AppColors.teal.withValues(alpha: 0.07)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _activeFilterCount > 0
                        ? AppColors.teal.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _activeFilterCount > 0 ? Icons.filter_list_rounded : Icons.home_rounded,
                      size: 18,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tìm thấy ',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${_results.length} phòng',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.tealDark),
                    ),
                    if (_activeFilterCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_activeFilterCount bộ lọc',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tealDark),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (_activeFilterCount > 0)
                      GestureDetector(
                        onTap: _resetFilters,
                        child: Text(
                          'Đặt lại',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
                        backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.search_off_rounded, size: 56, color: AppColors.teal.withValues(alpha: 0.35)),
                            ),
                            const SizedBox(height: 20),
                            const Text('Không tìm thấy phòng phù hợp',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 8),
                            Text(
                              _activeFilterCount > 0
                                  ? 'Thử giảm bớt tiêu chí lọc hoặc thay đổi khu vực để tìm thêm kết quả.'
                                  : 'Thử tìm kiếm với từ khóa khác.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                            ),
                            const SizedBox(height: 20),
                            if (_activeFilterCount > 0)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _resetFilters,
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('Xóa tất cả bộ lọc', style: TextStyle(fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.teal,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final room = _results[i];
                        final isFav = favoriteProvider.isFavorite(room.id);
                        return TweenAnimationBuilder<double>(
                          key: ValueKey('${room.id}_${_results.length}'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (i * 80).clamp(0, 400)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: RoomCard(
                            room: room.copyWith(isFavorite: isFav),
                            onFavoriteTap: () => context.read<FavoriteProvider>().toggleFavorite(room.id),
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => RoomDetailScreen(room: room))),
                          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withValues(alpha: 0.12),
            AppColors.teal.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.tealDark, fontWeight: FontWeight.w700)),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 12, color: AppColors.tealDark),
            ),
          ),
        ],
      ),
    );
  }
}
