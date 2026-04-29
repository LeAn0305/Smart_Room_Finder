import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/screens/admin/admin_navigation.dart';

class PostApprovalScreen extends StatefulWidget {
  const PostApprovalScreen({super.key});

  @override
  State<PostApprovalScreen> createState() => _PostApprovalScreenState();
}

class _PostApprovalScreenState extends State<PostApprovalScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tableSearchController = TextEditingController();

  int _selectedMenuIndex = 1;
  String _selectedStatus = 'Tất cả';
  String _selectedArea = 'Tất cả khu vực';
  String _selectedDateRange = '13/05/2025 - 19/05/2025';
  String _selectedSort = 'Mới nhất';
  String _selectedListingId = '';
  int _selectedPreviewIndex = 0;

  // ---- Firebase state ----
  List<_ModerationListing> _listings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableSearchController.dispose();
    super.dispose();
  }

  // =========================
  // FIREBASE: FETCH PENDING
  // =========================
  Future<void> _fetchPendingRooms() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final db = FirebaseFirestore.instance;

      // Query đơn giản: chỉ lọc isVerified=false.
      // Không dùng orderBy hay nhiều where để tránh cần Composite Index.
      // Các điều kiện khác (isDraft, isActive, approvalStatus) được lọc client-side
      // để tương thích với phòng cũ chưa có đủ field.
      final snap = await db
          .collection('rooms')
          .where('isVerified', isEqualTo: false)
          .get();

      final rooms = snap.docs
          .map((d) => RoomModel.fromMap(d.data(), d.id))
          // Lọc client-side: bỏ phòng đang ở nháp hoặc đã bị từ chối
          .where((r) =>
              r.isDraft == false &&
              r.isActive != false && // null cũng coi là active (backward compat)
              r.approvalStatus != RoomStatus.rejected)
          .toList()
        // Sắp xếp client-side: mới nhất lên đầu
        ..sort((a, b) {
          final at = a.postedAt;
          final bt = b.postedAt;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at);
        });

      // Fetch thông tin chủ trọ song song
      final ownerIds = rooms.map((r) => r.ownerId).toSet().toList();
      final ownerDocs = await Future.wait(
        ownerIds.map((uid) => db.collection('users').doc(uid).get()),
      );
      final ownerMap = <String, Map<String, dynamic>>{};
      for (final doc in ownerDocs) {
        if (doc.exists) ownerMap[doc.id] = doc.data()!;
      }

      final listings = rooms.map((room) {
        final owner = ownerMap[room.ownerId] ?? {};
        return _ModerationListing.fromRoom(room, owner);
      }).toList();

      if (!mounted) return;
      setState(() {
        _listings = listings;
        _selectedListingId = listings.isNotEmpty ? listings.first.id : '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu: $e';
      });
    }
  }

  // =========================
  // FIREBASE: APPROVE
  // =========================
  Future<void> _approveRoom(String roomId) async {
    final db = FirebaseFirestore.instance;
    final now = Timestamp.now();
    final historyEntry = RoomReviewHistory(
      id: db.collection('_').doc().id,
      time: now.toDate(),
      title: 'Bài đăng đã được xác minh',
      subtitle: 'Admin đã kiểm tra và xác nhận thông tin bài đăng hợp lệ.',
      actorName: 'Admin',
    );
    await db.collection('rooms').doc(roomId).update({
      'isVerified': true,
      'isActive': true,
      'approvalStatus': RoomStatus.verified.name,
      'updatedAt': now,
      'reviewHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });
    _removeListingFromState(roomId);
  }

  // =========================
  // DIALOG: Yêu cầu bổ sung
  // =========================
  Future<void> _showNeedsInfoDialog(String roomId, String ownerId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.blue, size: 22),
            SizedBox(width: 10),
            Text(
              'Yêu cầu bổ sung thông tin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vui lòng nhập lý do yêu cầu bổ sung. Chủ trọ sẽ nhận được thông báo này.',
              style: TextStyle(
                  color: Color(0xFF7A8898), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText:
                    'Ví dụ: Cần bổ sung ảnh mặt tiền, giấy chứng minh sở hữu...',
                hintStyle: const TextStyle(
                    color: Color(0xFFAFBCC9), fontSize: 12.5),
                filled: true,
                fillColor: const Color(0xFFF7FAFE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE3EBF5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE3EBF5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.blue, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF8A97A8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Gửi yêu cầu',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final reason = reasonCtrl.text.trim().isEmpty
          ? 'Admin yêu cầu bổ sung thêm thông tin hoặc giấy tờ.'
          : reasonCtrl.text.trim();
      await _requestMoreInfo(roomId: roomId, ownerId: ownerId, reason: reason);
    }
    reasonCtrl.dispose();
  }

  // =========================
  // DIALOG: Từ chối
  // =========================
  Future<void> _showRejectDialog(String roomId, String ownerId) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 10),
            Text(
              'Từ chối bài đăng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hành động này sẽ ẩn bài đăng và hủy tất cả đơn yêu cầu liên quan. '
              'Chủ trọ sẽ nhận được thông báo từ chối.',
              style: TextStyle(
                  color: Color(0xFF7A8898), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText:
                    'Ví dụ: Thông tin a và giấy tờ không khớp, nội dung vi phạm...',
                hintStyle: const TextStyle(
                    color: Color(0xFFAFBCC9), fontSize: 12.5),
                filled: true,
                fillColor: const Color(0xFFF7FAFE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE3EBF5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE3EBF5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFFEF4444), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF8A97A8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Xác nhận từ chối',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final reason = reasonCtrl.text.trim().isEmpty
          ? 'Bài đăng không đáp ứng tiêu chuẩn kiểm duyệt.'
          : reasonCtrl.text.trim();
      await _rejectRoom(roomId: roomId, ownerId: ownerId, reason: reason);
    }
    reasonCtrl.dispose();
  }

  // =========================
  // FIREBASE: REQUEST MORE INFO
  // =========================
  Future<void> _requestMoreInfo({
    required String roomId,
    required String ownerId,
    required String reason,
  }) async {
    final db = FirebaseFirestore.instance;
    final now = Timestamp.now();
    final historyEntry = RoomReviewHistory(
      id: db.collection('_').doc().id,
      time: now.toDate(),
      title: 'Yêu cầu bổ sung thông tin',
      subtitle: reason,
      actorName: 'Admin',
    );
    await db.collection('rooms').doc(roomId).update({
      'approvalStatus': RoomStatus.needsInfo.name,
      'moderationNote': reason, // Lưu lý do để chủ trọ có thể đọc
      'updatedAt': now,
      'reviewHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });
    // Hook thông báo — bạn làm Push Notification sẽ đọc từ đây
    await _sendOwnerNotification(
      db: db,
      ownerId: ownerId,
      roomId: roomId,
      type: 'needs_info',
      title: 'Bài đăng cần bổ sung thông tin',
      body: reason,
    );
    _removeListingFromState(roomId);
  }

  // =========================
  // FIREBASE: REJECT
  // =========================
  Future<void> _rejectRoom({
    required String roomId,
    required String ownerId,
    required String reason,
  }) async {
    final db = FirebaseFirestore.instance;
    final now = Timestamp.now();
    final batch = db.batch();

    // 1. Cập nhật trạng thái phòng → ẩn hoàn toàn
    final historyEntry = RoomReviewHistory(
      id: db.collection('_').doc().id,
      time: now.toDate(),
      title: 'Bài đăng bị từ chối',
      subtitle: reason,
      actorName: 'Admin',
    );
    batch.update(db.collection('rooms').doc(roomId), {
      'isDraft': true,
      'isActive': false,
      'approvalStatus': RoomStatus.rejected.name,
      'moderationNote': reason, // Lưu lý do để chủ trọ có thể đọc
      'updatedAt': now,
      'reviewHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
    });

    // 2. Hủy tất cả applications liên quan
    final appSnap = await db
        .collection('applications')
        .where('roomId', isEqualTo: roomId)
        .get();
    for (final doc in appSnap.docs) {
      batch.update(doc.reference, {
        'status': 'cancelled',
        'updatedAt': now.toDate().toIso8601String(),
      });
    }

    // 3. Xóa favorites liên quan
    final favSnap = await db
        .collection('favorites')
        .where('roomId', isEqualTo: roomId)
        .get();
    for (final doc in favSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Hook thông báo — bạn làm Push Notification sẽ đọc từ đây
    await _sendOwnerNotification(
      db: db,
      ownerId: ownerId,
      roomId: roomId,
      type: 'rejected',
      title: 'Bài đăng của bạn đã bị từ chối',
      body: reason,
    );
    _removeListingFromState(roomId);
  }

  // =============================================================
  // NOTIFICATION HOOK
  // Viết vào collection 'notifications' trên Firestore.
  // Bạn phụ trách Push Notification chỉ cần đọc từ collection này
  // và gửi FCM đến token của [ownerId] là xong.
  // Schema document notifications/:
  //   id         : String  — doc ID tự động
  //   receiverId : String  — uid của chủ trọ nhận thông báo
  //   roomId     : String  — ID phòng liên quan
  //   type       : String  — 'needs_info' | 'rejected' | 'verified'
  //   title      : String  — Tiêu đề thông báo
  //   body       : String  — Nội dung / lý do chi tiết
  //   isRead     : bool    — false khi mới tạo
  //   createdAt  : Timestamp
  // =============================================================
  Future<void> _sendOwnerNotification({
    required FirebaseFirestore db,
    required String ownerId,
    required String roomId,
    required String type,
    required String title,
    required String body,
  }) async {
    try {
      await db.collection('notifications').add({
        'receiverId': ownerId,
        'roomId': roomId,
        'type': type,
        'title': title,
        'body': body,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      // Không để lỗi notification ảnh hưởng luồng chính
      debugPrint('[Admin] Lỗi gửi notification: $e');
    }
  }

  /// Xóa listing khỏi danh sách sau khi admin thao tác xong.
  void _removeListingFromState(String roomId) {
    if (!mounted) return;
    setState(() {
      _listings.removeWhere((l) => l.id == roomId);
      // Chọn item tiếp theo nếu item bị xóa đang được chọn
      if (_selectedListingId == roomId) {
        _selectedListingId =
            _listings.isNotEmpty ? _listings.first.id : '';
        _selectedPreviewIndex = 0;
      }
    });
  }

  // =========================
  // RESPONSIVE HELPERS
  // =========================
  bool _isMobile(double width) => width < 700;

  bool _isTablet(double width) => width >= 700 && width <= 1024;

  bool _isDesktop(double width) => width > 1024;

  void _handleMenuSelection(BuildContext context, int index) {
    if (index == _selectedMenuIndex) {
      return;
    }

    if (index == 0) {
      openAdminDashboard(context);
      return;
    }

    if (index == 2) {
      openAdminUsers(context);
      return;
    }

    if (index == 3) {
      openAdminReports(context);
      return;
    }

    if (index == 4) {
      openAdminSupport(context);
      return;
    }

    if (index == 5) {
      openAdminSettings(context);
      return;
    }

    setState(() => _selectedMenuIndex = index);
  }

  _ModerationListing? get _selectedListing {
    if (_listings.isEmpty || _selectedListingId.isEmpty) return null;
    return _listings.firstWhere(
      (item) => item.id == _selectedListingId,
      orElse: () => _listings.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = _isMobile(screenWidth);
        final isDesktop = _isDesktop(screenWidth);

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF4F8FC),
          drawer: isDesktop
              ? null
              : Drawer(
                  width: math.min(screenWidth * 0.82, 320).toDouble(),
                  child: SafeArea(
                    child: _AdminSidebar(
                      selectedIndex: _selectedMenuIndex,
                      onSelected: (index) {
                        _handleMenuSelection(context, index);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (isDesktop)
                  SizedBox(
                    width: 248,
                    child: _AdminSidebar(
                      selectedIndex: _selectedMenuIndex,
                      onSelected: (index) {
                        _handleMenuSelection(context, index);
                      },
                    ),
                  ),
                Expanded(
                  child: _buildContent(
                    context: context,
                    width: screenWidth,
                    isMobile: isMobile,
                    isDesktop: isDesktop,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================
  // BUILD CONTENT
  // =========================
  Widget _buildContent({
    required BuildContext context,
    required double width,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final contentMaxWidth = isDesktop ? 1380.0 : 1120.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 16 : 24,
        isMobile ? 16 : 24,
        24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminTopbar(
                width: width,
                isMobile: isMobile,
                title: 'Duyệt bài đăng phòng',
                subtitle:
                    'Kiểm tra thông tin, giấy tờ và xác nhận chất lượng bài đăng trước khi hiển thị công khai.',
                searchController: _searchController,
                searchHint: 'Tìm kiếm bài đăng, chủ trọ hoặc khu vực...',
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(height: 20),
              _buildFilterSection(width),
              const SizedBox(height: 18),
              _buildMainSection(width),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // BUILD FILTER SECTION
  // =========================
  Widget _buildFilterSection(double width) {
    final isMobile = _isMobile(width);
    final isTablet = _isTablet(width);

    final searchBox = _AdminSearchField(
      controller: _tableSearchController,
      hintText: 'Tìm theo mã phòng, tiêu đề, chủ trọ...',
    );

    final statusBox = _FilterDropdown(
      label: 'Trạng thái',
      value: _selectedStatus,
      items: _statusOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedStatus = value);
      },
    );

    final areaBox = _FilterDropdown(
      label: 'Khu vực',
      value: _selectedArea,
      items: _areaOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedArea = value);
      },
    );

    final dateBox = _FilterDropdown(
      label: 'Ngày đăng',
      value: _selectedDateRange,
      items: _dateRangeOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedDateRange = value);
      },
      leadingIcon: Icons.calendar_today_rounded,
    );

    final filterButton = _FilterActionButton(
      label: 'Bộ lọc',
      icon: Icons.tune_rounded,
      onTap: () {},
    );

    if (isMobile) {
      return Column(
        children: [
          searchBox,
          const SizedBox(height: 12),
          statusBox,
          const SizedBox(height: 12),
          areaBox,
          const SizedBox(height: 12),
          dateBox,
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: filterButton,
          ),
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(flex: 5, child: searchBox),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: statusBox),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: areaBox),
              const SizedBox(width: 12),
              Expanded(child: dateBox),
              const SizedBox(width: 12),
              filterButton,
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: searchBox),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: statusBox),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: areaBox),
        const SizedBox(width: 12),
        Expanded(flex: 3, child: dateBox),
        const SizedBox(width: 12),
        filterButton,
      ],
    );
  }

  // =========================
  // BUILD MAIN SECTION
  // =========================
  Widget _buildMainSection(double width) {
    // Loading state
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: Color(0xFFB0BEC5)),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  style: const TextStyle(
                      color: Color(0xFF7A8798), fontSize: 13)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _fetchPendingRooms,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final selectedListing = _selectedListing;

    // Shared builder for list card
    Widget listCard({required bool compact}) => _ModerationListCard(
          isCompact: compact,
          selectedSort: _selectedSort,
          selectedListingId: _selectedListingId,
          listings: _listings,
          onSortChanged: (value) {
            if (value == null) return;
            setState(() => _selectedSort = value);
          },
          onSelectListing: (listing) {
            setState(() {
              _selectedListingId = listing.id;
              _selectedPreviewIndex = 0;
            });
          },
        );

    // Shared builder for detail panel
    Widget detailPanel({required bool compact}) => selectedListing == null
        ? _buildEmptyDetail()
        : _ListingDetailPanel(
            listing: selectedListing,
            isCompact: compact,
            selectedPreviewIndex: _selectedPreviewIndex,
            onPreviewChanged: (index) {
              setState(() => _selectedPreviewIndex = index);
            },
            onApprove: () => _approveRoom(selectedListing.id),
            onNeedsInfo: () => _showNeedsInfoDialog(
              selectedListing.id,
              selectedListing.ownerId,
            ),
            onReject: () => _showRejectDialog(
              selectedListing.id,
              selectedListing.ownerId,
            ),
          );

    if (_isMobile(width)) {
      return Column(children: [
        listCard(compact: true),
        const SizedBox(height: 16),
        detailPanel(compact: true),
      ]);
    }

    if (_isTablet(width)) {
      return Column(children: [
        listCard(compact: false),
        const SizedBox(height: 16),
        detailPanel(compact: false),
      ]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: listCard(compact: false)),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: detailPanel(compact: false)),
      ],
    );
  }

  Widget _buildEmptyDetail() {
    return _AdminSurfaceCard(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.fact_check_outlined,
                  size: 48, color: AppColors.blue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không có bài đăng chờ duyệt',
              style: TextStyle(
                color: Color(0xFF1E2B3A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tất cả bài đăng đã được xử lý.',
              style: TextStyle(color: Color(0xFF8A97A8), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// SIDEBAR
// =========================
class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5BC3F4), AppColors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Room Finder',
                        style: TextStyle(
                          color: Color(0xFF1E2B3A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Nền tảng tìm phòng thông minh',
                        style: TextStyle(
                          color: Color(0xFF7A8798),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              children: [
                for (var i = 0; i < _adminMenus.length; i++) ...[
                  _SidebarMenuTile(
                    data: _adminMenus[i],
                    isSelected: selectedIndex == i,
                    onTap: () => onSelected(i),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4ECF6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Giữ nền tảng an toàn',
                    style: TextStyle(
                      color: Color(0xFF233244),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Xác minh danh tính và kiểm duyệt thường xuyên để đảm bảo chất lượng nội dung.',
                    style: TextStyle(
                      color: Color(0xFF7A8798),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFEAF4FF),
                        foregroundColor: AppColors.blueDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Xem hướng dẫn',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '© 2025 Smart Room Finder\nPhiên bản 1.0.0',
                style: TextStyle(
                  color: Color(0xFF9CA8B7),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuTile extends StatelessWidget {
  const _SidebarMenuTile({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _AdminMenuItem data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFD8E9FF) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              data.icon,
              color: isSelected
                  ? AppColors.blueDark
                  : const Color(0xFF6F8093),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.blueDark
                      : const Color(0xFF33455A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// TOPBAR
// =========================
class _AdminTopbar extends StatelessWidget {
  const _AdminTopbar({
    required this.width,
    required this.isMobile,
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.searchHint,
    required this.onMenuTap,
  });

  final double width;
  final bool isMobile;
  final String title;
  final String subtitle;
  final TextEditingController searchController;
  final String searchHint;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final isHeaderStacked = !isMobile && width < 1220;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF1E2B3A),
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF7A8798),
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );

    final searchField = Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283A53).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: searchHint,
          hintStyle: const TextStyle(
            color: Color(0xFF9AA6B5),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF93A3B8),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Ctrl K',
              style: TextStyle(
                color: Color(0xFF8C99A8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );

    final actionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TopbarActionButton(
          icon: Icons.notifications_none_rounded,
          badgeCount: 8,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2EAF3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFD8F5F0),
                child: Text(
                  'A',
                  style: TextStyle(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Color(0xFF1E2B3A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Quản trị viên',
                    style: TextStyle(
                      color: Color(0xFF8A97A8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF92A1B2),
              ),
            ],
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopbarActionButton(
                icon: Icons.menu_rounded,
                onTap: onMenuTap,
                badgeCount: 0,
              ),
              const SizedBox(width: 12),
              Expanded(child: titleBlock),
            ],
          ),
          const SizedBox(height: 16),
          searchField,
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: actionRow,
          ),
        ],
      );
    }

    if (isHeaderStacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 16),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: actionRow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          searchField,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: titleBlock),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: searchField),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.topRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: actionRow,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopbarActionButton extends StatelessWidget {
  const _TopbarActionButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EAF3)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                color: const Color(0xFF657588),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5D5F),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =========================
// FILTER WIDGETS
// =========================
class _AdminSearchField extends StatelessWidget {
  const _AdminSearchField({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF3)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF99A6B5),
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9BA7B5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.leadingIcon,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF7F8EA0),
          ),
          borderRadius: BorderRadius.circular(18),
          style: const TextStyle(
            color: Color(0xFF253548),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      if (leadingIcon != null) ...[
                        Icon(
                          leadingIcon,
                          size: 16,
                          color: const Color(0xFF8B9AAD),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Color(0xFF9AA6B5),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blueDark,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2EAF3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );
  }
}

// =========================
// LIST CARD
// =========================
class _ModerationListCard extends StatelessWidget {
  const _ModerationListCard({
    required this.isCompact,
    required this.selectedSort,
    required this.selectedListingId,
    required this.listings,
    required this.onSortChanged,
    required this.onSelectListing,
  });

  final bool isCompact;
  final String selectedSort;
  final String selectedListingId;
  final List<_ModerationListing> listings;
  final ValueChanged<String?> onSortChanged;
  final ValueChanged<_ModerationListing> onSelectListing;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      const Text(
                        'Danh sách bài đăng chờ duyệt',
                        style: TextStyle(
                          color: Color(0xFF1E2B3A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${listings.length}',
                          style: const TextStyle(
                            color: AppColors.blueDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: isCompact ? 132 : 140,
                  child: _CompactDropdown(
                    value: selectedSort,
                    items: _sortOptions,
                    onChanged: onSortChanged,
                  ),
                ),
              ],
            ),
          ),
          if (!isCompact) const _ModerationHeaderRow(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            itemCount: listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final listing = listings[index];
              final isSelected = listing.id == selectedListingId;

              if (isCompact) {
                return _ModerationMobileTile(
                  listing: listing,
                  isSelected: isSelected,
                  onTap: () => onSelectListing(listing),
                );
              }

              return _ModerationDesktopRow(
                listing: listing,
                isSelected: isSelected,
                onTap: () => onSelectListing(listing),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
            child: Column(
              children: [
                if (isCompact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hiển thị 1 - ${listings.length} trong ${listings.length} kết quả',
                        style: const TextStyle(
                          color: Color(0xFF8B9AAC),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: _PaginationBar(),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Text(
                        'Hiển thị 1 - ${listings.length} trong ${listings.length} kết quả',
                        style: const TextStyle(
                          color: Color(0xFF8B9AAC),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const _PaginationBar(),
                    ],
                  ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7EE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFE4C7)),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: Color(0xFF8B6A39),
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'Các bài đăng chưa xác minh vẫn có thể hiển thị trên trang chủ với nhãn ',
                        ),
                        TextSpan(
                          text: 'Chưa xác minh',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(text: ' để người dùng tham khảo.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationHeaderRow extends StatelessWidget {
  const _ModerationHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          SizedBox(width: 26),
          Expanded(flex: 4, child: _HeaderLabel('Mã phòng')),
          Expanded(flex: 4, child: _HeaderLabel('Tiêu đề')),
          Expanded(flex: 3, child: _HeaderLabel('Chủ trọ')),
          Expanded(flex: 3, child: _HeaderLabel('Khu vực')),
          Expanded(flex: 3, child: _HeaderLabel('Trạng thái')),
          Expanded(flex: 2, child: _HeaderLabel('Ngày đăng')),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF8291A5),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ModerationDesktopRow extends StatelessWidget {
  const _ModerationDesktopRow({
    required this.listing,
    required this.isSelected,
    required this.onTap,
  });

  final _ModerationListing listing;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7FBFF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF9AC4FF) : const Color(0xFFE4ECF6),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _SelectionCheckbox(isSelected: isSelected),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _RoomPhotoWidget(
                    imageUrl: listing.mainImageUrl,
                    width: 64,
                    height: 50,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.roomCode,
                          style: const TextStyle(
                            color: Color(0xFF26384B),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          listing.shortAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8C9AA9),
                            fontSize: 11.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF24364A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8B99AA),
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: _OwnerCell(
                name: listing.ownerName,
                email: listing.ownerEmail,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                listing.area,
                style: const TextStyle(
                  color: Color(0xFF8A99AA),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusChip(status: listing.status),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                listing.postedAtShort,
                style: const TextStyle(
                  color: Color(0xFF6E8094),
                  fontSize: 11.5,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModerationMobileTile extends StatelessWidget {
  const _ModerationMobileTile({
    required this.listing,
    required this.isSelected,
    required this.onTap,
  });

  final _ModerationListing listing;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7FBFF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF9AC4FF) : const Color(0xFFE4ECF6),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _SelectionCheckbox(isSelected: isSelected),
                const SizedBox(width: 10),
                _RoomPhotoWidget(
                  imageUrl: listing.mainImageUrl,
                  width: 72,
                  height: 58,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.roomCode,
                        style: const TextStyle(
                          color: Color(0xFF223448),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF324659),
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CompactInfoPill(
                    icon: Icons.person_outline_rounded,
                    label: listing.ownerName,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactInfoPill(
                    icon: Icons.place_outlined,
                    label: listing.area,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatusChip(status: listing.status),
                const Spacer(),
                Text(
                  listing.postedAtShort,
                  style: const TextStyle(
                    color: Color(0xFF7F8EA0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// DETAIL PANEL
// =========================
class _ListingDetailPanel extends StatelessWidget {
  const _ListingDetailPanel({
    required this.listing,
    required this.isCompact,
    required this.selectedPreviewIndex,
    required this.onPreviewChanged,
    required this.onApprove,
    required this.onNeedsInfo,
    required this.onReject,
  });

  final _ModerationListing listing;
  final bool isCompact;
  final int selectedPreviewIndex;
  final ValueChanged<int> onPreviewChanged;
  final VoidCallback onApprove;
  final VoidCallback onNeedsInfo;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final allImages = listing.allImageUrls;
    final safePreviewIndex =
        allImages.isEmpty ? 0 : selectedPreviewIndex.clamp(0, allImages.length - 1).toInt();

    return _AdminSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi tiết bài đăng',
                  style: TextStyle(
                    color: Color(0xFF1E2B3A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF5FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  listing.roomCode,
                  style: const TextStyle(
                    color: AppColors.blueDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF9AA6B4),
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (isCompact)
            Column(
              children: [
                _RoomPhotoWidget(
                  imageUrl: allImages.isNotEmpty ? allImages[safePreviewIndex] : '',
                  width: double.infinity,
                  height: 220,
                  borderRadius: 20,
                ),
                const SizedBox(height: 10),
                if (allImages.length > 1)
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: allImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSel = index == safePreviewIndex;
                        return InkWell(
                          onTap: () => onPreviewChanged(index),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 90,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.blueDark
                                    : const Color(0xFFE2EAF3),
                              ),
                            ),
                            child: _RoomPhotoWidget(
                              imageUrl: allImages[index],
                              width: 84,
                              height: 68,
                              borderRadius: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _RoomPhotoWidget(
                    imageUrl: allImages.isNotEmpty ? allImages[safePreviewIndex] : '',
                    width: double.infinity,
                    height: 220,
                    borderRadius: 20,
                  ),
                ),
                if (allImages.length > 1) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 110,
                    child: Column(
                      children: [
                        for (var i = 0; i < allImages.length && i < 4; i++) ...[
                          InkWell(
                            onTap: () => onPreviewChanged(i),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 110,
                              height: 64,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: i == safePreviewIndex
                                      ? AppColors.blueDark
                                      : const Color(0xFFE2EAF3),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  _RoomPhotoWidget(
                                    imageUrl: allImages[i],
                                    width: 104,
                                    height: 58,
                                    borderRadius: 12,
                                  ),
                                  if (i == 3 && allImages.length > 4)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.38),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '+${allImages.length - 4} ảnh',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (i != 3 && i != allImages.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 16),
          Text(
            listing.title,
            style: const TextStyle(
              color: Color(0xFF213347),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                listing.price,
                style: const TextStyle(
                  color: AppColors.blueDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _StatusChip(status: listing.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.place_outlined,
                  color: Color(0xFF9AA8B7),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  listing.address,
                  style: const TextStyle(
                    color: Color(0xFF7B8A9C),
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE7EDF5), height: 1),
          const SizedBox(height: 18),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(title: 'Chủ trọ'),
                const SizedBox(height: 6),
                Text(
                  'Ngày đăng • ${listing.postedAtFull}',
                  style: const TextStyle(
                    color: Color(0xFF8A97A8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            _SectionLabel(
              title: 'Chủ trọ',
              trailing: Text(
                'Ngày đăng    ${listing.postedAtFull}',
                style: const TextStyle(
                  color: Color(0xFF8A97A8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4ECF6)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE4F8F4),
                      child: Text(
                        listing.ownerName.substring(0, 1),
                        style: const TextStyle(
                          color: AppColors.tealDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.ownerName,
                            style: const TextStyle(
                              color: Color(0xFF223447),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            listing.ownerPhone,
                            style: const TextStyle(
                              color: Color(0xFF627589),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            listing.ownerEmail,
                            style: const TextStyle(
                              color: Color(0xFF8A98AA),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoStatTile(
                        label: 'Ngày đăng',
                        value: listing.postedAtFull,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoStatTile(
                        label: 'Cập nhật lần cuối',
                        value: listing.updatedAtFull,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel(title: 'Tiện ích'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: listing.amenities
                .map((item) => _AmenityChip(label: item))
                .toList(),
          ),
          const SizedBox(height: 18),
          const _SectionLabel(title: 'Mô tả'),
          const SizedBox(height: 10),
          Text(
            listing.description,
            style: const TextStyle(
              color: Color(0xFF708196),
              fontSize: 12.5,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.blueDark,
            ),
            child: const Text(
              'Xem thêm',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          _SectionLabel(
            title: 'Giấy tờ tài liệu',
            trailing: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.blueDark,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                'Xem tất cả',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: listing.documents
                .map(
                  (document) => _DocumentCard(document: document),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          const _SectionLabel(title: 'Lịch sử duyệt'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5EDF6)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < listing.reviewHistory.length; i++) ...[
                  _ReviewHistoryTile(entry: listing.reviewHistory[i]),
                  if (i != listing.reviewHistory.length - 1)
                    const Divider(
                      height: 1,
                      color: Color(0xFFE6EDF6),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (isCompact)
            Column(
              children: [
                _ModerationActionButton(
                  label: 'Xác minh',
                  icon: Icons.check_circle_outline_rounded,
                  backgroundColor: const Color(0xFF22B573),
                  foregroundColor: Colors.white,
                  onTap: onApprove,
                ),
                const SizedBox(height: 10),
                _ModerationActionButton(
                  label: 'Yêu cầu bổ sung',
                  icon: Icons.edit_note_rounded,
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  onTap: onNeedsInfo,
                ),
                const SizedBox(height: 10),
                _ModerationActionButton(
                  label: 'Từ chối',
                  icon: Icons.close_rounded,
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  onTap: onReject,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ModerationActionButton(
                    label: 'Xác minh',
                    icon: Icons.check_circle_outline_rounded,
                    backgroundColor: const Color(0xFF22B573),
                    foregroundColor: Colors.white,
                    onTap: onApprove,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModerationActionButton(
                    label: 'Yêu cầu bổ sung',
                    icon: Icons.edit_note_rounded,
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    onTap: onNeedsInfo,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModerationActionButton(
                    label: 'Từ chối',
                    icon: Icons.close_rounded,
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    onTap: onReject,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// =========================
// SHARED DETAIL WIDGETS
// =========================
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF26384A),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoStatTile extends StatelessWidget {
  const _InfoStatTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EDF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF95A2B3),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF334559),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4ECF6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppColors.tealDark,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5C6D80),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final RoomDocument document;

  // Icon và màu sắc dựa theo loại file
  IconData get _icon {
    return switch (document.fileType.toUpperCase()) {
      'PDF' => Icons.picture_as_pdf_rounded,
      'JPG' || 'PNG' || 'JPEG' => Icons.image_outlined,
      _ => Icons.description_outlined,
    };
  }

  Color get _accent {
    return switch (document.fileType.toUpperCase()) {
      'PDF' => const Color(0xFFEF6A5B),
      'JPG' || 'PNG' || 'JPEG' => const Color(0xFF22B573),
      _ => const Color(0xFFF59E0B),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EDF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _accent, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            document.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF324558),
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${document.fileType} • ${document.fileSize}',
            style: const TextStyle(
              color: Color(0xFF96A2B2),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewHistoryTile extends StatelessWidget {
  const _ReviewHistoryTile({required this.entry});

  final RoomReviewHistory entry;

  IconData get _icon => Icons.history_rounded;
  Color get _accent => const Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${entry.time.day.toString().padLeft(2, '0')}/${entry.time.month.toString().padLeft(2, '0')}/${entry.time.year} '
        '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Color(0xFF8D99A9),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.title,
                  style: const TextStyle(
                    color: Color(0xFF2B3E52),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7D8DA0),
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.actorName,
                  style: const TextStyle(
                    color: Color(0xFF96A5B5),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModerationActionButton extends StatelessWidget {
  const _ModerationActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// =========================
// SHARED SMALL UI
// =========================
class _AdminSurfaceCard extends StatelessWidget {
  const _AdminSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF233244).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CompactDropdown extends StatelessWidget {
  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EBF5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF7F8EA0),
          ),
          style: const TextStyle(
            color: Color(0xFF33465B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SelectionCheckbox extends StatelessWidget {
  const _SelectionCheckbox({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.blue : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isSelected ? AppColors.blue : const Color(0xFFCFD9E5),
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              size: 13,
              color: Colors.white,
            )
          : null,
    );
  }
}

class _OwnerCell extends StatelessWidget {
  const _OwnerCell({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE9F8F4),
          child: Text(
            name.substring(0, 1),
            style: const TextStyle(
              color: AppColors.tealDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF304458),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF96A2B2),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactInfoPill extends StatelessWidget {
  const _CompactInfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF93A2B4)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF536577),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.keyboard_arrow_left_rounded,
          size: 18,
          color: Color(0xFF7E8EA0),
        ),
        const SizedBox(width: 8),
        for (final page in ['1', '2', '3', '4']) ...[
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: page == '1' ? const Color(0xFFEFF4FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: page == '1'
                    ? const Color(0xFFCFE0FF)
                    : const Color(0xFFE3EBF5),
              ),
            ),
            child: Text(
              page,
              style: TextStyle(
                color: page == '1' ? AppColors.blueDark : const Color(0xFF7D8C9E),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        const SizedBox(width: 4),
        const Text(
          '10 / trang',
          style: TextStyle(
            color: Color(0xFF7E8EA0),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      'Đã xác minh' => (
          const Color(0xFFE7F9F0),
          const Color(0xFF22B573),
        ),
      'Chờ xác minh' => (
          const Color(0xFFFFF3E4),
          const Color(0xFFF59E0B),
        ),
      'Cần bổ sung' => (
          const Color(0xFFEAF2FF),
          const Color(0xFF3B82F6),
        ),
      _ => (
          const Color(0xFFFFE8E9),
          const Color(0xFFEF4444),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: config.$2,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Widget hiển thị ảnh phòng thật từ Firebase Storage.
/// Tự động fallback về placeholder nếu URL rỗng hoặc lỗi tải ảnh.
class _RoomPhotoWidget extends StatelessWidget {
  const _RoomPhotoWidget({
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: hasUrl
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _buildPlaceholder();
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFE5DD), Color(0xFFD6E1EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Color(0xFFABB8C4),
          size: 24,
        ),
      ),
    );
  }
}

// =========================
// STATIC OPTIONS (non-mock)
// =========================
const List<_AdminMenuItem> _adminMenus = [
  _AdminMenuItem(label: 'Tổng quan', icon: Icons.dashboard_outlined),
  _AdminMenuItem(label: 'Duyệt bài đăng', icon: Icons.fact_check_outlined),
  _AdminMenuItem(label: 'Người dùng', icon: Icons.group_outlined),
  _AdminMenuItem(label: 'Báo cáo', icon: Icons.bar_chart_rounded),
  _AdminMenuItem(label: 'Hỗ trợ', icon: Icons.support_agent_outlined),
  _AdminMenuItem(label: 'Cài đặt', icon: Icons.settings_outlined),
];

const List<String> _statusOptions = [
  'Tất cả',
  'Chờ xác minh',
  'Đã xác minh',
  'Cần bổ sung',
  'Từ chối',
];

const List<String> _areaOptions = [
  'Tất cả khu vực',
  'TP.HCM',
  'Hà Nội',
  'Đà Nẵng',
  'Cần Thơ',
];

const List<String> _dateRangeOptions = [
  '13/05/2025 - 19/05/2025',
  '07 ngày gần đây',
  '30 ngày gần đây',
  'Tháng này',
];

const List<String> _sortOptions = [
  'Mới nhất',
  'Cũ nhất',
  'Ưu tiên cần xử lý',
];

// =========================
// MODELS (internal UI)
// =========================
class _AdminMenuItem {
  const _AdminMenuItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

/// Internal UI model được build từ [RoomModel] + dữ liệu chủ trọ.
/// Tách biệt UI data khỏi domain model để dễ render.
class _ModerationListing {
  const _ModerationListing({
    required this.id,
    required this.ownerId,
    required this.roomCode,
    required this.title,
    required this.subtitle,
    required this.shortAddress,
    required this.area,
    required this.address,
    required this.status,
    required this.postedAtShort,
    required this.postedAtFull,
    required this.updatedAtFull,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.price,
    required this.mainImageUrl,
    required this.allImageUrls,
    required this.amenities,
    required this.description,
    required this.documents,
    required this.reviewHistory,
  });

  final String id;
  /// UID của chủ trọ trên Firebase Auth — dùng để gửi thông báo.
  final String ownerId;
  final String roomCode;
  final String title;
  final String subtitle;
  final String shortAddress;
  final String area;
  final String address;
  final String status;
  final String postedAtShort;
  final String postedAtFull;
  final String updatedAtFull;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String price;

  /// URL ảnh đại diện hiển thị trong list row.
  final String mainImageUrl;

  /// Danh sách tất cả URL ảnh dùng trong gallery chi tiết.
  final List<String> allImageUrls;

  final List<String> amenities;
  final String description;

  /// Giấy tờ pháp lý (map từ RoomDocument).
  final List<RoomDocument> documents;

  /// Lịch sử kiểm duyệt (map từ RoomReviewHistory).
  final List<RoomReviewHistory> reviewHistory;

  /// Tạo _ModerationListing từ [RoomModel] và dữ liệu chủ trọ.
  factory _ModerationListing.fromRoom(
    RoomModel room,
    Map<String, dynamic> ownerData,
  ) {
    final posted = room.postedAt;
    final updated = room.updatedAt;

    String fmt(DateTime? dt) {
      if (dt == null) return '--';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    String fmtShort(DateTime? dt) {
      if (dt == null) return '--';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}\n'
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final statusLabel = switch (room.approvalStatus) {
      RoomStatus.verified => 'Đã xác minh',
      RoomStatus.rejected => 'Từ chối',
      RoomStatus.needsInfo => 'Cần bổ sung',
      RoomStatus.pending => 'Chờ xác minh',
    };

    final priceFormatted =
        '${_formatPrice(room.price)} đ/tháng';

    // Tập hợp tất cả URL ảnh: ảnh chính + ảnh phụ
    final allUrls = [
      if (room.mainImageUrl.isNotEmpty) room.mainImageUrl,
      ...room.subImageUrls.where((u) => u != room.mainImageUrl),
    ];

    return _ModerationListing(
      id: room.id,
      ownerId: room.ownerId,
      roomCode: 'SRF-${room.id.substring(0, math.min(5, room.id.length)).toUpperCase()}',
      title: room.title,
      subtitle: room.description.isNotEmpty
          ? room.description
          : room.amenities.take(2).join(', '),
      shortAddress: room.address,
      area: room.location,
      address: room.address,
      status: statusLabel,
      postedAtShort: fmtShort(posted),
      postedAtFull: fmt(posted),
      updatedAtFull: fmt(updated),
      ownerName: (ownerData['displayName'] ??
              ownerData['name'] ??
              ownerData['fullName'] ??
              'Chủ trọ')
          .toString(),
      ownerPhone:
          (ownerData['phone'] ?? ownerData['phoneNumber'] ?? '--').toString(),
      ownerEmail: (ownerData['email'] ?? '--').toString(),
      price: priceFormatted,
      mainImageUrl: room.mainImageUrl.isNotEmpty
          ? room.mainImageUrl
          : (room.imageUrl.isNotEmpty ? room.imageUrl : ''),
      allImageUrls: allUrls,
      amenities: room.amenities,
      description: room.description,
      documents: room.documents,
      reviewHistory: room.reviewHistory,
    );
  }

  static String _formatPrice(double price) {
    if (price >= 1000000) {
      final millions = price / 1000000;
      return '${millions % 1 == 0 ? millions.toInt() : millions.toStringAsFixed(1)} triệu';
    }
    if (price >= 1000) {
      return '${(price / 1000).toInt()}.${((price % 1000) / 100).toInt()}00K';
    }
    return price.toInt().toString();
  }
}
