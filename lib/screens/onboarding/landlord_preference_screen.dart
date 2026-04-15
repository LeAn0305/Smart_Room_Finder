import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/providers/preference_provider.dart';
import 'package:smart_room_finder/screens/main_navigation_screen.dart';

class LandlordPreferenceScreen extends StatefulWidget {
  const LandlordPreferenceScreen({super.key});

  @override
  State<LandlordPreferenceScreen> createState() => _LandlordPreferenceScreenState();
}

class _LandlordPreferenceScreenState extends State<LandlordPreferenceScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  final Set<String> _selectedLocations = {};
  final Set<RoomType> _selectedTypes = {};

  final List<String> _locations = [
    'Quận 1', 'Quận 3', 'Quận 7', 'Quận 10',
    'Bình Thạnh', 'Tân Bình', 'Gò Vấp', 'Thủ Đức',
    'Bình Chánh', 'Nhà Bè',
  ];

  final List<(RoomType, String, IconData, String)> _types = [
    (RoomType.studio, 'Phòng trọ', Icons.single_bed_rounded, 'Phòng trọ, gác lửng, mini'),
    (RoomType.apartment, 'Chung cư', Icons.apartment_rounded, 'Căn hộ chung cư, studio'),
    (RoomType.house, 'Nhà nguyên căn', Icons.house_rounded, 'Nhà phố, nhà hẻm'),
    (RoomType.villa, 'Biệt thự', Icons.villa_rounded, 'Biệt thự, nhà vườn'),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 1) {
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

    // Lưu khu vực đầu tiên được chọn (hoặc tất cả nếu muốn mở rộng sau)
    if (_selectedLocations.isNotEmpty) {
      pref.setLocation(_selectedLocations.first);
      pref.setSelectedLocations(_selectedLocations);
    }

    if (_selectedTypes.isNotEmpty) {
      pref.setRoomType(_selectedTypes.first);
      pref.setSelectedRoomTypes(_selectedTypes);
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
            colors: [AppColors.mintLight, AppColors.mintSoft, AppColors.mintGreen],
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
                '${_page + 1}/2',
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
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(2, (i) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: i <= _page ? AppColors.teal : AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final canNext = _page == 0 ? _selectedLocations.isNotEmpty : _selectedTypes.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: canNext ? _next : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text(
            _page == 1 ? 'Bắt đầu quản lý' : 'Tiếp theo',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
          Text(title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4)),
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
            'Khu vực bạn cho thuê?',
            'Chọn một hoặc nhiều khu vực bạn đang quản lý phòng.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _locations.map((loc) {
                final sel = _selectedLocations.contains(loc);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedLocations.remove(loc);
                    } else {
                      _selectedLocations.add(loc);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? AppColors.teal : AppColors.mintGreen,
                        width: 1.5,
                      ),
                      boxShadow: sel
                          ? [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: sel ? Colors.white : AppColors.teal, size: 16),
                        const SizedBox(width: 6),
                        Text(loc,
                            style: TextStyle(
                              color: sel ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            )),
                        if (sel) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedLocations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Đã chọn ${_selectedLocations.length} khu vực: ${_selectedLocations.join(', ')}',
                      style: const TextStyle(fontSize: 13, color: AppColors.tealDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            'Loại phòng bạn cho thuê?',
            'Chọn loại phòng bạn đang hoặc sẽ cho thuê.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: _types.map((t) {
                final sel = _selectedTypes.contains(t.$1);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedTypes.remove(t.$1);
                    } else {
                      _selectedTypes.add(t.$1);
                    }
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
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sel ? Colors.white.withValues(alpha: 0.2) : AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(t.$3, color: sel ? Colors.white : AppColors.teal, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.$2,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: sel ? Colors.white : AppColors.textPrimary,
                                  )),
                              const SizedBox(height: 2),
                              Text(t.$4,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: sel ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
                                  )),
                            ],
                          ),
                        ),
                        if (sel)
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
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
}
