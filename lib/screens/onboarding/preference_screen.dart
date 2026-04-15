import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/providers/preference_provider.dart';
import 'package:smart_room_finder/screens/main_navigation_screen.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  String? _selectedLocation;
  RoomType? _selectedType;
  final Set<String> _selectedAmenities = {};
  // Khoảng giá: (label, minPrice, maxPrice) — null maxPrice = không giới hạn
  final List<(String, int, int?)> _priceRanges = const [
    ('Tất cả', 0, null),
    ('1 - 5 triệu', 1000000, 5000000),
    ('5 - 10 triệu', 5000000, 10000000),
    ('10 - 15 triệu', 10000000, 15000000),
    ('15 - 20 triệu', 15000000, 20000000),
    ('Trên 20 triệu', 20000000, null),
  ];

  int _selectedRangeIndex = 0; // mặc định "Tất cả"

  final List<String> _locations = [
    'Quận 1',
    'Quận 3',
    'Quận 7',
    'Quận 10',
    'Bình Thạnh',
    'Tân Bình',
    'Gò Vấp',
    'Thủ Đức',
    'Bình Chánh',
    'Nhà Bè',
  ];

  final List<(RoomType, String, IconData)> _types = [
    (RoomType.studio, 'Phòng trọ', Icons.single_bed_rounded),
    (RoomType.apartment, 'Chung cư', Icons.apartment_rounded),
    (RoomType.house, 'Nhà nguyên căn', Icons.house_rounded),
    (RoomType.villa, 'Biệt thự', Icons.villa_rounded),
  ];

  final List<(String, IconData)> _amenities = [
    ('Wifi', Icons.wifi_rounded),
    ('Máy lạnh', Icons.ac_unit_rounded),
    ('Tủ lạnh', Icons.kitchen_rounded),
    ('Máy giặt', Icons.local_laundry_service_rounded),
    ('Bếp', Icons.outdoor_grill_rounded),
    ('Chỗ để xe', Icons.directions_car_rounded),
    ('An ninh', Icons.security_rounded),
    ('Bình nóng lạnh', Icons.hot_tub_rounded),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 3) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  void _finish() {
    final pref = context.read<PreferenceProvider>();

    if (_selectedLocation != null) {
      pref.setLocation(_selectedLocation!);
    }

    if (_selectedType != null) {
      pref.setRoomType(_selectedType);
    }

    pref.setMaxPrice(_priceRanges[_selectedRangeIndex].$3 ?? 999999999);

    for (final a in _selectedAmenities) {
      pref.toggleAmenity(a);
    }

    pref.complete();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.mintLight,
              AppColors.mintSoft,
              AppColors.mintGreen,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildLocationStep(),
                    _buildTypeStep(),
                    _buildAmenitiesStep(),
                    _buildBudgetStep(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_page + 1}/4',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: _finish,
                child: const Text(
                  'Bỏ qua',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: i <= _page ? AppColors.teal : AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            _page == 3 ? 'Bắt đầu khám phá' : 'Tiếp theo',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            '📍',
            'Bạn muốn ở khu vực nào?',
            'Chúng tôi sẽ gợi ý phòng gần khu vực bạn chọn.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _locations.map((loc) {
                final sel = _selectedLocation == loc;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedLocation = sel ? null : loc;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? AppColors.teal : AppColors.mintGreen,
                        width: 1.5,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: AppColors.teal.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: sel ? Colors.white : AppColors.teal,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loc,
                          style: TextStyle(
                            color: sel ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            '🏠',
            'Bạn thích loại phòng nào?',
            'Chọn loại phòng phù hợp với nhu cầu của bạn.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: _types.map((t) {
                final sel = _selectedType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = sel ? null : t.$1;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: sel ? AppColors.teal : AppColors.mintGreen,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.white.withOpacity(0.2)
                                : AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            t.$3,
                            color: sel ? Colors.white : AppColors.teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          t.$2,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (sel)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            '✨',
            'Tiện ích bạn cần?',
            'Chọn những tiện ích quan trọng với bạn.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _amenities.map((a) {
                final sel = _selectedAmenities.contains(a.$1);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedAmenities.remove(a.$1);
                    } else {
                      _selectedAmenities.add(a.$1);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.teal.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? AppColors.teal : AppColors.mintGreen,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          a.$2,
                          color: sel ? AppColors.teal : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          a.$1,
                          style: TextStyle(
                            color: sel ? AppColors.tealDark : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            '💰',
            'Ngân sách hàng tháng?',
            'Chọn khoảng giá phù hợp với bạn.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: List.generate(_priceRanges.length, (i) {
                final range = _priceRanges[i];
                final sel = _selectedRangeIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRangeIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel ? AppColors.teal : AppColors.mintGreen,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: sel
                              ? AppColors.teal.withOpacity(0.25)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.white.withOpacity(0.2)
                                : AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            i == 0
                                ? Icons.all_inclusive_rounded
                                : Icons.attach_money_rounded,
                            color: sel ? Colors.white : AppColors.teal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          range.$1,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (sel)
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}