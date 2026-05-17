import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'package:smart_room_finder/services/gemini_service.dart';
import 'package:smart_room_finder/widgets/room_card.dart';
import 'package:smart_room_finder/screens/room_detail/room_detail_screen.dart';
import 'package:smart_room_finder/core/providers/favorite_provider.dart';

class AISearchScreen extends StatefulWidget {
  const AISearchScreen({super.key});

  @override
  State<AISearchScreen> createState() => _AISearchScreenState();
}

class _AISearchScreenState extends State<AISearchScreen> {
  final _ctrl = TextEditingController();
  bool _isSearching = false;
  List<RoomModel> _results = [];
  String _parsedInfo = '';
  bool _hasSearched = false;

  static const _examples = [
    'Phòng trọ dưới 4 triệu, có wifi, gần Quận 3',
    'Chung cư mini 30m² có máy lạnh, máy giặt',
    'Nhà riêng 2 phòng ngủ dưới 10 triệu Bình Thạnh',
    'Phòng sinh viên gần trường, giá rẻ',
  ];

  Future<void> _search() async {
    final query = _ctrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _results = [];
      _parsedInfo = '';
    });

    final rooms = context.read<RoomProvider>().activePublicRooms;
    final criteria = await GeminiService.parseSearchQuery(query);
    final filtered = GeminiService.filterRoomsByAI(rooms, criteria);

    // Tạo mô tả filter đã áp dụng
    final infoParts = <String>[];
    if (criteria['maxPrice'] != null) {
      infoParts.add('Giá ≤ ${(criteria['maxPrice'] / 1000000).toStringAsFixed(1)}tr');
    }
    if (criteria['minArea'] != null) {
      infoParts.add('Diện tích ≥ ${criteria['minArea']}m²');
    }
    if (criteria['location'] != null) {
      infoParts.add('Khu vực: ${criteria['location']}');
    }
    if (criteria['roomType'] != null) {
      infoParts.add('Loại: ${criteria['roomType']}');
    }
    if (criteria['amenities'] != null &&
        (criteria['amenities'] as List).isNotEmpty) {
      infoParts.add('Tiện ích: ${(criteria['amenities'] as List).join(', ')}');
    }

    setState(() {
      _isSearching = false;
      _results = filtered;
      _parsedInfo = infoParts.join(' • ');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();

    return Scaffold(
      backgroundColor: AppColors.mintLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.teal, size: 22),
            SizedBox(width: 8),
            Text('Tìm kiếm thông minh',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.mintGreen),
        ),
      ),
      body: Column(
        children: [
          // Search input
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.mintLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.3)),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          maxLines: 2,
                          minLines: 1,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText:
                                'Mô tả phòng bạn muốn tìm bằng ngôn ngữ tự nhiên...',
                            hintStyle: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            prefixIcon: Icon(Icons.auto_awesome_rounded,
                                color: AppColors.teal, size: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _search,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.teal, AppColors.tealDark]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.search_rounded,
                                color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
                // Filter info
                if (_parsedInfo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_rounded,
                            size: 14, color: AppColors.teal),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _parsedInfo,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.teal,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Examples
          if (!_hasSearched)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 Thử tìm kiếm:',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    ..._examples.map((e) => GestureDetector(
                          onTap: () {
                            _ctrl.text = e;
                            _search();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.mintGreen, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded,
                                    size: 16, color: AppColors.teal),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(e,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textPrimary)),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 14, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),

          // Results
          if (_hasSearched && !_isSearching)
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 52,
                              color: AppColors.teal.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text('Không tìm thấy phòng phù hợp',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          const Text('Thử mô tả khác hoặc bớt điều kiện',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Text(
                                'Tìm thấy ${_results.length} phòng',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _results.length,
                            itemBuilder: (context, i) {
                              final room = _results[i];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RoomDetailScreen(room: room),
                                  ),
                                ),
                                child: RoomCard(
                                  room: room,
                                  onFavoriteTap: () => favoriteProvider
                                      .toggleFavorite(room.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),

          // Loading
          if (_isSearching)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.teal),
                    SizedBox(height: 16),
                    Text('AI đang phân tích yêu cầu...',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
