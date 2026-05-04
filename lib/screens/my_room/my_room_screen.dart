import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'package:smart_room_finder/screens/post_room/post_room_screen.dart';

class MyRoomScreen extends StatefulWidget {
  const MyRoomScreen({super.key});

  @override
  State<MyRoomScreen> createState() => _MyRoomScreenState();
}

class _MyRoomScreenState extends State<MyRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _sortBy = 'newest';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RoomModel> _applySort(List<RoomModel> list) {
    List<RoomModel> filtered = _searchQuery.isEmpty
        ? List.from(list)
        : list
            .where(
              (r) =>
                  r.title.toLowerCase().contains(_searchQuery) ||
                  r.address.toLowerCase().contains(_searchQuery),
            )
            .toList();

    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'views':
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'newest':
        filtered.sort(
          (a, b) => (b.postedAt ?? DateTime(0)).compareTo(
            a.postedAt ?? DateTime(0),
          ),
        );
        break;
    }
    return filtered;
  }

  void _toggleActive(RoomModel room) {
    context.read<RoomProvider>().toggleActive(room.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          room.isActive ? 'Đã ẩn "${room.title}"' : 'Đã hiện "${room.title}"',
        ),
        backgroundColor: AppColors.tealDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _deleteRoom(RoomModel room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xóa phòng?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('Bạn có chắc muốn xóa "${room.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<RoomProvider>().deleteRoom(room.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${room.title}"'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _duplicateRoom(RoomModel room) {
    context.read<RoomProvider>().duplicateRoom(room);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã nhân bản "${room.title}"'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    _tabController.animateTo(2);
  }

  void _renewRoom(RoomModel room) {
    context.read<RoomProvider>().renewRoom(room.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã gia hạn "${room.title}" thêm 30 ngày'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _editRoom(RoomModel room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostRoomScreen(editRoom: room)),
    );
  }

  void _showSortSheet() {
    final options = [
      ('newest', Icons.access_time_rounded, 'Mới nhất'),
      ('views', Icons.visibility_rounded, 'Lượt xem nhiều nhất'),
      ('price_low', Icons.arrow_upward_rounded, 'Giá thấp đến cao'),
      ('price_high', Icons.arrow_downward_rounded, 'Giá cao đến thấp'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sắp xếp theo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((o) {
              final sel = _sortBy == o.$1;
              return GestureDetector(
                onTap: () {
                  setState(() => _sortBy = o.$1);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.mintSoft : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? AppColors.teal : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        o.$2,
                        color:
                            sel ? AppColors.teal : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        o.$3,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              sel ? AppColors.tealDark : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (sel)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.teal,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomProvider>();
    final activeRooms = _applySort(provider.myActiveRooms);
    final hiddenRooms = _applySort(provider.myHiddenRooms);
    final draftRooms = _applySort(provider.myDraftRooms);
    final myRooms = <RoomModel>[];
      myRooms.addAll(activeRooms);
      myRooms.addAll(hiddenRooms);
      myRooms.addAll(draftRooms);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              _buildHeader(),
              _buildStats(myRooms),
              _buildSearchBar(),
              _buildTabBar(
                activeRooms.length,
                hiddenRooms.length,
                draftRooms.length,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoomList(activeRooms, tab: 'active'),
                    _buildRoomList(hiddenRooms, tab: 'hidden'),
                    _buildRoomList(draftRooms, tab: 'draft'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostRoomScreen()),
        ),
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Đăng phòng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          const Expanded(
            child: Text(
              'Phòng trọ của tôi',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.sort_rounded,
                color: AppColors.teal,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(List<RoomModel> rooms) {
    final totalViews = rooms.fold(0, (s, r) => s + r.viewCount);
    final totalContacts = rooms.fold(0, (s, r) => s + r.contactCount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _statChip(
            Icons.home_work_rounded,
            '${rooms.length}',
            'Tổng phòng',
            AppColors.teal,
          ),
          const SizedBox(width: 8),
          _statChip(
            Icons.visibility_rounded,
            '$totalViews',
            'Lượt xem',
            Colors.blue,
          ),
          const SizedBox(width: 8),
          _statChip(
            Icons.phone_rounded,
            '$totalContacts',
            'Liên hệ',
            Colors.green,
          ),
          const SizedBox(width: 8),
          _statChip(
            Icons.warning_amber_rounded,
            '${rooms.where((r) => r.isExpired).length}',
            'Hết hạn',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm phòng của bạn...',
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.teal,
              size: 20,
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
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(int active, int hidden, int draft) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.teal,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'Đang đăng ($active)'),
          Tab(text: 'Đã ẩn ($hidden)'),
          Tab(text: 'Nháp ($draft)'),
        ],
      ),
    );
  }

  Widget _buildRoomList(List<RoomModel> rooms, {required String tab}) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab == 'active'
                  ? Icons.home_work_outlined
                  : tab == 'hidden'
                      ? Icons.visibility_off_outlined
                      : Icons.drafts_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              tab == 'active'
                  ? 'Chưa có phòng đang đăng'
                  : tab == 'hidden'
                      ? 'Không có phòng bị ẩn'
                      : 'Không có bản nháp',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: rooms.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (_, i) => _buildRoomCard(rooms[i]),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final daysLeft = room.daysLeft;
    final isExpiringSoon = daysLeft <= 5 && daysLeft > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isExpiringSoon
            ? Border.all(color: Colors.orange, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: _buildRoomImage(room.imageUrl),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: room.isDraft
                        ? Colors.grey
                        : room.isActive
                            ? Colors.green
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    room.isDraft
                        ? 'Nháp'
                        : room.isActive
                            ? 'Đang đăng'
                            : 'Đã ẩn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (isExpiringSoon)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Còn $daysLeft ngày',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.teal, AppColors.tealDark],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    '${(room.price / 1000000).toStringAsFixed(1)}tr/tháng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.textSecondary,
                      size: 13,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        room.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniStat(
                      Icons.visibility_rounded,
                      '${room.viewCount}',
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _miniStat(
                      Icons.phone_rounded,
                      '${room.contactCount}',
                      Colors.green,
                    ),
                    if (room.area > 0) ...[
                      const SizedBox(width: 12),
                      _miniStat(
                        Icons.square_foot_rounded,
                        '${room.area}m²',
                        AppColors.teal,
                      ),
                    ],
                    if (room.bedrooms > 0) ...[
                      const SizedBox(width: 12),
                      _miniStat(
                        Icons.bed_rounded,
                        '${room.bedrooms} PN',
                        Colors.purple,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.mintSoft),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _actionBtn(
                      Icons.edit_rounded,
                      'Sửa',
                      AppColors.teal,
                      () => _editRoom(room),
                    ),
                    const SizedBox(width: 6),
                    _actionBtn(
                      room.isActive
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      room.isActive ? 'Ẩn' : 'Hiện',
                      room.isActive ? Colors.orange : Colors.green,
                      () => _toggleActive(room),
                    ),
                    const SizedBox(width: 6),
                    _actionBtn(
                      Icons.copy_rounded,
                      'Nhân bản',
                      Colors.purple,
                      () => _duplicateRoom(room),
                    ),
                    const SizedBox(width: 6),
                    if (room.isExpired || room.daysLeft <= 5)
                      _actionBtn(
                        Icons.autorenew_rounded,
                        'Gia hạn',
                        Colors.blue,
                        () => _renewRoom(room),
                      )
                    else
                      _actionBtn(
                        Icons.delete_outline_rounded,
                        'Xóa',
                        Colors.redAccent,
                        () => _deleteRoom(room),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomImage(String imgPath) {
    if (imgPath.startsWith('assets/')) {
      return Image.asset(
        imgPath,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorImage(),
      );
    } else if (imgPath.startsWith('http') || kIsWeb) {
      return Image.network(
        imgPath,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorImage(),
      );
    } else {
      return Image.file(
        File(imgPath),
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorImage(),
      );
    }
  }

  Widget _errorImage() => Container(
        height: 150,
        color: AppColors.mintSoft,
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.teal,
          size: 40,
        ),
      );

  Widget _miniStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}