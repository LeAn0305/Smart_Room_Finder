import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/report_model.dart';
import 'package:smart_room_finder/screens/admin/admin_navigation.dart';
import 'package:smart_room_finder/screens/admin/admin_shared_widgets.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  int _selectedMenuIndex = 3;
  String _selectedReportId = '';
  String _selectedType = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  String _selectedPriority = 'Tất cả';
  String _selectedTime = '7 ngày qua';
  String _adminDisplayName = 'Admin';
  int _currentPage = 1;
  int _pageSize = 10;

  // Firebase state
  List<_ReportItem> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAdminName();
    _fetchReports();
  }

  Future<void> _fetchAdminName() async {
    final name = await fetchAdminDisplayName();
    if (mounted) setState(() => _adminDisplayName = name);
  }

  Future<void> _fetchReports() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();

      final items = <_ReportItem>[];
      for (final doc in snap.docs) {
        final d = doc.data();
        final createdAt = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final rawRoomId = d['roomId'] ?? d['postId'] ?? d['targetId'] ?? d['reportedRoomId'] ?? '';
        final roomId = rawRoomId.toString().trim();
        final reporterId = d['reporterId'] as String? ?? '';

        // Fetch reporter name + avatar
        String senderName = 'Người dùng';
        String senderEmail = '';
        String senderAvatarUrl = '';
        if (reporterId.isNotEmpty) {
          try {
            final uDoc = await FirebaseFirestore.instance.collection('users').doc(reporterId).get();
            if (uDoc.exists) {
              final ud = uDoc.data()!;
              senderName = ud['displayName'] ?? ud['name'] ?? ud['fullName'] ?? 'Người dùng';
              senderEmail = ud['email'] ?? '';
              senderAvatarUrl = ud['profileImageUrl'] ?? ud['photoURL'] ?? ud['avatarUrl'] ?? '';
            }
          } catch (_) {}
        }

        // Fetch room title
        String roomTitle = '';
        Map<String, dynamic>? roomData;
        if (roomId.isNotEmpty) {
          try {
            final rDoc = await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
            if (rDoc.exists) {
              roomData = rDoc.data();
              roomTitle = roomData?['title'] ?? roomData?['name'] ?? 'Phòng #${roomId.substring(0, 6)}';
            }
          } catch (_) {}
        }

        final reason = d['reason'] as String? ?? 'Khác';
        final mappedReason = _mapReason(reason);
        final status = d['status'] as String? ?? 'pending';

        final descRaw = d['description'] ?? d['content'] ?? d['note'];
        String descStr = descRaw?.toString().trim() ?? '';
        
        String finalSubtitle = descStr.isNotEmpty ? descStr : 'Lý do: $mappedReason';
        String finalTitle = roomTitle.isNotEmpty ? roomTitle : '';

        if (finalTitle.isEmpty) {
           if (descStr.isEmpty) {
             finalTitle = 'Không có nội dung chi tiết';
           } else {
             finalTitle = 'Bài đăng không xác định';
           }
        }

        items.add(_ReportItem(
          id: doc.id,
          title: finalTitle.length > 60 ? finalTitle.substring(0, 60) : finalTitle,
          subtitle: finalSubtitle,
          sender: senderName,
          senderEmail: senderEmail,
          senderAvatarUrl: senderAvatarUrl,
          type: mappedReason,
          priority: _mapPriority(reason),
          status: _mapStatus(status),
          timeAgo: _timeAgo(createdAt),
          createdAt: DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
          rawCreatedAt: createdAt,
          description: descStr.isNotEmpty ? descStr : finalSubtitle,
          roomId: roomId,
          reporterId: reporterId,
          firestoreStatus: status,
          color: _colorForName(senderName),
          roomData: roomData,
        ));
      }

      if (mounted) {
        setState(() {
          _reports = items;
          _isLoading = false;
          if (items.isNotEmpty) _selectedReportId = items.first.id;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  // Helpers
  static String _mapReason(String r) {
    final low = r.toLowerCase();
    if (low.contains('giá không đúng') || low.contains('sai giá') || low.contains('giá')) return 'Sai giá';
    if (low.contains('thông tin sai lệch') || low.contains('ảnh không thực tế') || low.contains('tin giả')) return 'Thông tin sai lệch';
    if (low.contains('không còn trống') || low.contains('hết phòng')) return 'Hết phòng';
    if (low.contains('lừa đảo') || low.contains('scam')) return 'Lừa đảo';
    return 'Lý do khác';
  }

  static String _mapPriority(String r) {
    final type = _mapReason(r);
    if (type == 'Lừa đảo') return 'Cao';
    return 'Trung bình';
  }

  static String _mapStatus(String s) {
    switch (s) {
      case 'resolved': return 'Đã giải quyết';
      case 'processing': return 'Đang xử lý';
      default: return 'Mới';
    }
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  static Color _colorForName(String name) {
    final colors = [Color(0xFF2F9BEF), Color(0xFF47C7B5), Color(0xFFF59E0B), Color(0xFF9B5CFF), Color(0xFF22B573)];
    return colors[name.hashCode.abs() % colors.length];
  }

  List<_ReportItem> get _filteredReports {
    var list = List<_ReportItem>.from(_reports);
    if (_selectedType != 'Tất cả') list = list.where((r) => r.type == _selectedType).toList();
    if (_selectedStatus != 'Tất cả') list = list.where((r) => r.status == _selectedStatus).toList();
    if (_selectedPriority != 'Tất cả') list = list.where((r) => r.priority == _selectedPriority).toList();
    if (_selectedTime != 'Tất cả') {
      final now = DateTime.now();
      DateTime? cutoff;
      switch (_selectedTime) {
        case '7 ngày qua': cutoff = now.subtract(const Duration(days: 7));
        case '30 ngày qua': cutoff = now.subtract(const Duration(days: 30));
        case 'Quý này': cutoff = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1);
        case 'Năm nay': cutoff = DateTime(now.year);
      }
      if (cutoff != null) list = list.where((r) => r.rawCreatedAt != null && r.rawCreatedAt!.isAfter(cutoff!)).toList();
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) list = list.where((r) => r.title.toLowerCase().contains(q) || r.sender.toLowerCase().contains(q)).toList();
    return list;
  }

  _ReportItem? get _selectedReport {
    if (_reports.isEmpty) return null;
    try { return _reports.firstWhere((r) => r.id == _selectedReportId); } catch (_) { return _reports.first; }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(id).update({'status': newStatus});
      final idx = _reports.indexWhere((r) => r.id == id);
      if (idx != -1 && mounted) {
        setState(() {
          _reports[idx] = _reports[idx].copyWith(status: _mapStatus(newStatus), firestoreStatus: newStatus);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _hideRoom(_ReportItem report) async {
    try {
      if (report.roomId.isEmpty) throw 'Không tìm thấy bài đăng liên quan.';
      
      print('AdminReport - Hiding Room ID: ${report.roomId}');
      await FirebaseFirestore.instance.collection('rooms').doc(report.roomId).update({
        'approvalStatus': 'needsInfo',
        'isActive': false,
      });
      await _updateStatus(report.id, 'resolved');
      
      // Reload danh sách để UI cập nhật
      await _fetchReports();
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã ẩn bài đăng thành công.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi ẩn phòng: $e')));
    }
  }

  Future<void> _deleteReport(String id) async {
    try {
      print('AdminReport - Deleting Report ID: $id');
      await FirebaseFirestore.instance.collection('reports').doc(id).delete();
      
      // Sau khi xoá thành công, cập nhật lại danh sách trên UI
      await _fetchReports();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã bỏ qua và xóa báo cáo.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xoá báo cáo: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isMobile(double width) => width < 700;
  bool _isTablet(double width) => width >= 700 && width <= 1024;
  bool _isDesktop(double width) => width > 1024;

  void _handleMenuSelection(BuildContext context, int index) {
    if (index == 4 || index == 5) { showAdminComingSoon(context); return; }
    if (index == _selectedMenuIndex) return;
    switch (index) {
      case 0: openAdminDashboard(context);
      case 1: openPostApproval(context);
      case 2: openAdminUsers(context);
    }
    setState(() => _selectedMenuIndex = index);
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
                    child: AdminSidebar(
                      selectedIndex: _selectedMenuIndex,
                      onSelected: (index) {
                        _handleMenuSelection(context, index);
                        Navigator.of(context).pop();
                      },
                      onLogout: () => showAdminLogoutDialog(context),
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (isDesktop)
                  SizedBox(
                    width: 248,
                    child: AdminSidebar(
                      selectedIndex: _selectedMenuIndex,
                      onSelected: (index) => _handleMenuSelection(context, index),
                      onLogout: () => showAdminLogoutDialog(context),
                    ),
                  ),
                Expanded(
                  child: _buildContent(
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

  Widget _buildContent({
    required double width,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final contentMaxWidth = isDesktop ? 1380.0 : 1120.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 24,
        isMobile ? 14 : 24,
        isMobile ? 14 : 24,
        24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminTopbar(
                width: width,
                isMobile: isMobile,
                title: 'Quản lý báo cáo',
                subtitle: 'Xử lý các báo cáo vi phạm, lừa đảo hoặc phản hồi từ người dùng.',
                searchController: _searchController,
                searchHint: 'Tìm kiếm báo cáo...',
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                adminDisplayName: _adminDisplayName,
              ),
              const SizedBox(height: 20),
              _buildStatsSection(width),
              const SizedBox(height: 18),
              _buildFilterSection(width),
              const SizedBox(height: 18),
              _buildMainSection(width),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(double width) {
    // Compute stats from real data
    final total = _reports.length;
    final newCount = _reports.where((r) => r.firestoreStatus == 'pending').length;
    final processing = _reports.where((r) => r.firestoreStatus == 'processing').length;
    final resolved = _reports.where((r) => r.firestoreStatus == 'resolved').length;
    final stats = [
      _ReportStat(title: 'Tổng báo cáo', value: '$total', icon: Icons.bar_chart_rounded, accent: AppColors.blue, changeText: '', isPositive: true),
      _ReportStat(title: 'Mới', value: '$newCount', icon: Icons.inbox_rounded, accent: const Color(0xFFF59E0B), changeText: 'Chưa xử lý', isPositive: false),
      _ReportStat(title: 'Đang xử lý', value: '$processing', icon: Icons.pending_actions_rounded, accent: const Color(0xFF9B5CFF), changeText: '', isPositive: true),
      _ReportStat(title: 'Đã giải quyết', value: '$resolved', icon: Icons.check_circle_outline_rounded, accent: const Color(0xFF22B573), changeText: '+Đã xong', isPositive: true),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _isDesktop(width) ? 4 : _isMobile(width) ? 1 : 2;
        const spacing = 16.0;
        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * spacing)) / crossAxisCount;
        return Wrap(
          spacing: spacing, runSpacing: spacing,
          children: stats.map((s) => SizedBox(width: itemWidth, child: _StatCard(data: s))).toList(),
        );
      },
    );
  }

  Widget _buildFilterSection(double width) {
    final isMobile = _isMobile(width);
    final isTablet = _isTablet(width);

    final typeBox = _FilterDropdown(
      label: 'Loại báo cáo',
      value: _selectedType,
      items: _typeOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() { _selectedType = value; _currentPage = 1; });
      },
    );

    final statusBox = _FilterDropdown(
      label: 'Trạng thái',
      value: _selectedStatus,
      items: _statusOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() { _selectedStatus = value; _currentPage = 1; });
      },
    );

    final priorityBox = _FilterDropdown(
      label: 'Mức độ ưu tiên',
      value: _selectedPriority,
      items: _priorityOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() { _selectedPriority = value; _currentPage = 1; });
      },
    );

    final timeBox = _FilterDropdown(
      label: 'Thời gian',
      value: _selectedTime,
      items: _timeOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() { _selectedTime = value; _currentPage = 1; });
      },
    );



    if (isMobile) {
      return _AdminSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            typeBox,
            const SizedBox(height: 12),
            statusBox,
            const SizedBox(height: 12),
            priorityBox,
            const SizedBox(height: 12),
            timeBox,
          ],
        ),
      );
    }

    if (isTablet) {
      return _AdminSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: typeBox),
                const SizedBox(width: 12),
                Expanded(child: statusBox),
                const SizedBox(width: 12),
                Expanded(child: priorityBox),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: timeBox),
              ],
            ),
          ],
        ),
      );
    }

    return _AdminSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(child: typeBox),
          const SizedBox(width: 12),
          Expanded(child: statusBox),
          const SizedBox(width: 12),
          Expanded(child: priorityBox),
          const SizedBox(width: 12),
          SizedBox(width: 130, child: timeBox),
        ],
      ),
    );
  }

  Widget _buildMainSection(double width) {
    final isMobile = _isMobile(width);
    final isDesktop = _isDesktop(width);

    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(60),
        child: CircularProgressIndicator(),
      ));
    }
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF5B6E)),
          const SizedBox(height: 12),
          Text('Không thể tải dữ liệu', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          TextButton.icon(icon: const Icon(Icons.refresh), label: const Text('Thử lại'), onPressed: _fetchReports),
        ]),
      ));
    }
    final displayReports = _filteredReports;
    if (displayReports.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFFBBC8D8)),
          const SizedBox(height: 12),
          const Text('Chưa có báo cáo nào', style: TextStyle(color: Color(0xFF8EA0B4), fontWeight: FontWeight.w700)),
        ]),
      ));
    }
    final selected = _selectedReport;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: _ReportTableCard(
              reports: _pagedReports(displayReports),
              totalFiltered: displayReports.length,
              selectedReportId: _selectedReportId,
              isCompact: false,
              currentPage: _currentPage,
              pageSize: _pageSize,
              onSelectReport: (r) => setState(() => _selectedReportId = r.id),
              onPageChanged: (p) => setState(() => _currentPage = p),
              onPageSizeChanged: (s) { if (s != null) setState(() { _pageSize = s; _currentPage = 1; }); },
            ),
          ),
          const SizedBox(width: 16),
          if (selected != null)
            SizedBox(
              width: 320,
              child: _ReportDetailPanel(
                report: selected,
                onMarkProcessing: () => _updateStatus(selected.id, 'processing'),
                onMarkResolved: () => _updateStatus(selected.id, 'resolved'),
                onDismiss: () => _updateStatus(selected.id, 'dismissed'),
                onHideRoom: () => _hideRoom(selected),
                onDeleteReport: () => _deleteReport(selected.id),
              ),
            ),
        ],
      );
    }

    return Column(children: [
      _ReportTableCard(
        reports: _pagedReports(displayReports),
        totalFiltered: displayReports.length,
        selectedReportId: _selectedReportId,
        isCompact: isMobile,
        currentPage: _currentPage,
        pageSize: _pageSize,
        onSelectReport: (r) => setState(() => _selectedReportId = r.id),
        onPageChanged: (p) => setState(() => _currentPage = p),
        onPageSizeChanged: (s) { if (s != null) setState(() { _pageSize = s; _currentPage = 1; }); },
      ),
      const SizedBox(height: 16),
      if (selected != null)
        _ReportDetailPanel(
          report: selected,
          onMarkProcessing: () => _updateStatus(selected.id, 'processing'),
          onMarkResolved: () => _updateStatus(selected.id, 'resolved'),
          onDismiss: () => _updateStatus(selected.id, 'dismissed'),
          onHideRoom: () => _hideRoom(selected),
          onDeleteReport: () => _deleteReport(selected.id),
        ),
    ]);
  }

  List<_ReportItem> _pagedReports(List<_ReportItem> filtered) {
    final start = (_currentPage - 1) * _pageSize;
    if (start >= filtered.length) return [];
    final end = math.min(start + _pageSize, filtered.length);
    return filtered.sublist(start, end);
  }
}

// _AdminSidebar removed – now uses shared AdminSidebar from admin_shared_widgets.dart


class _AdminTopbar extends StatelessWidget {
  const _AdminTopbar({
    required this.width,
    required this.isMobile,
    required this.searchController,
    required this.onMenuTap,
  });

  final double width;
  final bool isMobile;
  final TextEditingController searchController;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final isHeaderStacked = !isMobile && width < 1180;

    final titleBlock = Text(
      'Quản lý báo cáo',
      style: TextStyle(
        color: const Color(0xFF1E2B3A),
        fontSize: isMobile ? 24 : 28,
        fontWeight: FontWeight.w800,
      ),
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
          hintText: 'Tìm kiếm báo cáo...',
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
              '⌘ K',
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
              _Avatar(name: 'Admin', size: 38, color: Color(0xFF2F9BEF)),
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
        Expanded(flex: 3, child: searchField),
        const SizedBox(width: 20),
        actionRow,
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _ReportStat data;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(data.icon, color: data.accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7A8798),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: Color(0xFF1E2B3A),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      data.isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: data.isPositive
                          ? const Color(0xFF00A86B)
                          : const Color(0xFFFF5B6E),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.changeText,
                      style: TextStyle(
                        color: data.isPositive
                            ? const Color(0xFF00A86B)
                            : const Color(0xFFFF5B6E),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'so với tuần trước',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF8EA0B4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

class _ReportTableCard extends StatelessWidget {
  const _ReportTableCard({
    required this.reports,
    required this.totalFiltered,
    required this.selectedReportId,
    required this.isCompact,
    required this.currentPage,
    required this.pageSize,
    required this.onSelectReport,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final List<_ReportItem> reports;
  final int totalFiltered;
  final String selectedReportId;
  final bool isCompact;
  final int currentPage;
  final int pageSize;
  final ValueChanged<_ReportItem> onSelectReport;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onPageSizeChanged;

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
                const Expanded(
                  child: Text(
                    'Danh sách báo cáo',
                    style: TextStyle(
                      color: Color(0xFF1E2B3A),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!isCompact)
                  Text(
                    'Tổng: $totalFiltered báo cáo',
                    style: const TextStyle(
                      color: Color(0xFF7D8EA3),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF90A0B4),
                  size: 18,
                ),
              ],
            ),
          ),
          if (!isCompact) const _ReportTableHeader(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Color(0xFFEAF0F7),
            ),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportTableRow(
                report: report,
                isSelected: report.id == selectedReportId,
                isCompact: isCompact,
                onTap: () => onSelectReport(report),
              );
            },
          ),
          _PaginationBar(
            currentPage: currentPage,
            pageSize: pageSize,
            totalItems: totalFiltered,
            onPageChanged: onPageChanged,
            onPageSizeChanged: onPageSizeChanged,
          ),
        ],
      ),
    );
  }
}

class _ReportTableHeader extends StatelessWidget {
  const _ReportTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: const Color(0xFFF7FAFD),
      child: const Row(
        children: [
          SizedBox(width: 32),
          _HeaderCell('Mã báo cáo', flex: 2),
          _HeaderCell('Nội dung bị báo cáo', flex: 4),
          _HeaderCell('Người gửi', flex: 3),
          _HeaderCell('Loại', flex: 2),
          _HeaderCell('Ưu tiên', flex: 2),
          _HeaderCell('Trạng thái', flex: 2),
          _HeaderCell('Thời gian', flex: 2),
        ],
      ),
    );
  }
}

class _ReportTableRow extends StatelessWidget {
  const _ReportTableRow({
    required this.report,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final _ReportItem report;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          color: isSelected ? const Color(0xFFEAF4FF) : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SelectionDot(isSelected: isSelected),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      report.id,
                      style: const TextStyle(
                        color: AppColors.blueDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusChip(label: report.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                report.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E2B3A),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                report.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7D8EA3),
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TypeChip(label: report.type),
                  _PriorityChip(label: report.priority),
                  _MetaPill(icon: Icons.person_outline, text: report.sender),
                  _MetaPill(icon: Icons.schedule_rounded, text: report.timeAgo),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        color: isSelected ? const Color(0xFFEAF4FF) : Colors.white,
        child: Row(
          children: [
            SizedBox(width: 32, child: _SelectionDot(isSelected: isSelected)),
            Expanded(flex: 2, child: _TableText(report.id, isStrong: true)),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1E2B3A),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8A99AA),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _Avatar(name: report.sender, size: 30, color: report.color, imageUrl: report.senderAvatarUrl),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.sender,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1E2B3A),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          report.senderEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8A99AA),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: _TypeChip(label: report.type)),
            Expanded(flex: 2, child: _PriorityChip(label: report.priority)),
            Expanded(flex: 2, child: _StatusChip(label: report.status)),
            Expanded(flex: 2, child: _TableText(report.timeAgo)),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailPanel extends StatelessWidget {
  const _ReportDetailPanel({
    required this.report,
    this.onMarkProcessing,
    this.onMarkResolved,
    this.onDismiss,
    this.onHideRoom,
    this.onDeleteReport,
  });

  final _ReportItem report;
  final VoidCallback? onMarkProcessing;
  final VoidCallback? onMarkResolved;
  final VoidCallback? onDismiss;
  final VoidCallback? onHideRoom;
  final VoidCallback? onDeleteReport;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi tiết báo cáo',
                  style: TextStyle(
                    color: Color(0xFF1E2B3A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.close_rounded),
                color: const Color(0xFF90A0B4),
                tooltip: 'Đóng',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                  report.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E2B3A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(label: report.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Được tạo: ${report.createdAt}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _smallMutedStyle,
                ),
              ),
              const SizedBox(width: 8),
              Text(report.timeAgo, style: _smallMutedStyle),
            ],
          ),
          const SizedBox(height: 18),
          const _DetailLabel('Mô tả báo cáo'),
          const SizedBox(height: 8),
          Text(
            report.description,
            style: const TextStyle(
              color: Color(0xFF52657A),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const _DetailLabel('Bài đăng liên quan'),
          const SizedBox(height: 10),
          _RelatedListingCard(report: report),
          const SizedBox(height: 18),
          const _DetailLabel('Người gửi báo cáo'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: report.sender, size: 38, color: report.color, imageUrl: report.senderAvatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.sender,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1E2B3A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      report.senderEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _smallMutedStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '32 bài đăng',
                    style: TextStyle(
                      color: Color(0xFF52657A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Thành viên từ 12/2024',
                    style: TextStyle(
                      color: Color(0xFF8EA0B4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _DetailLabel('Lịch sử xử lý'),
          const SizedBox(height: 10),
          const _TimelineItem(
            title: 'Báo cáo được tạo',
            time: '19/05/2025 09:15',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PanelButton(
                  label: 'Ẩn bài',
                  icon: Icons.visibility_off_outlined,
                  foreground: Colors.white,
                  background: const Color(0xFFFF4D4F),
                  border: const Color(0xFFFF4D4F),
                  onTap: () {
                    if (onHideRoom != null) onHideRoom!();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PanelButton(
                  label: 'Bỏ qua',
                  icon: Icons.close_rounded,
                  foreground: const Color(0xFF52657A),
                  background: Colors.white,
                  border: const Color(0xFFE2EAF3),
                  onTap: () {
                    if (onDeleteReport != null) onDeleteReport!();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelatedListingCard extends StatelessWidget {
  const _RelatedListingCard({required this.report});

  final _ReportItem report;

  @override
  Widget build(BuildContext context) {
    if (report.roomId.isEmpty || report.roomData == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2EAF3)),
        ),
        child: const Center(
          child: Text(
            'Không có bài đăng liên quan',
            style: TextStyle(
              color: Color(0xFF8EA0B4),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final data = report.roomData!;
    final title = data['title'] ?? data['name'] ?? 'Phòng #${report.roomId.substring(0, 6)}';
    final address = data['address'] ?? data['location'] ?? 'Không có địa chỉ';
    
    final images = data['images'];
    String? imageUrl;
    if (images is List && images.isNotEmpty) {
      imageUrl = images.first.toString();
    } else if (data['imageUrl'] is String) {
      imageUrl = data['imageUrl'];
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2EAF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFE2EAF3),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFFB7A18C),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E2B3A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7D8EA3),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.open_in_new_rounded),
            color: AppColors.blue,
            iconSize: 18,
            tooltip: 'Mở bài đăng',
          ),
        ],
      ),
    );
  }
}


class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.time,
  });

  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 1, height: 30, color: const Color(0xFFD9E5F2)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: _smallMutedStyle),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF52657A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'Hệ thống',
          style: TextStyle(
            color: Color(0xFF8EA0B4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int currentPage;
  final int pageSize;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = math.max(1, (totalItems / pageSize).ceil());
    final isFirst = currentPage <= 1;
    final isLast = currentPage >= totalPages;

    // Build page number buttons: show up to 5 pages around current
    final pages = <int>[];
    if (totalPages <= 5) {
      for (var i = 1; i <= totalPages; i++) { pages.add(i); }
    } else {
      final start = math.max(1, currentPage - 2);
      final end = math.min(totalPages, start + 4);
      for (var i = start; i <= end; i++) { pages.add(i); }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hiển thị', style: _paginationTextStyle),
              const SizedBox(width: 8),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2EAF3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8EA0B4),
                      size: 18,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF4C5F75),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    onChanged: onPageSizeChanged,
                    items: const [10, 20, 50]
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('trên mỗi trang', style: _paginationTextStyle),
              const SizedBox(width: 12),
              Text(
                'Tổng: $totalItems',
                style: _paginationTextStyle,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: isFirst ? () {} : () => onPageChanged(currentPage - 1),
                isDisabled: isFirst,
              ),
              for (final page in pages)
                _PageNumberButton(
                  page: page,
                  isSelected: currentPage == page,
                  onTap: () => onPageChanged(page),
                ),
              if (totalPages > 5 && pages.last < totalPages) ...[  
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('...', style: TextStyle(color: Color(0xFF7D8EA3), fontWeight: FontWeight.w800)),
                ),
                _PageNumberButton(
                  page: totalPages,
                  isSelected: currentPage == totalPages,
                  onTap: () => onPageChanged(totalPages),
                ),
              ],
              _PageIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: isLast ? () {} : () => onPageChanged(currentPage + 1),
                isDisabled: isLast,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(10),
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          key: ValueKey(value),
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF8EA0B4),
            size: 18,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: Color(0xFF7D8EA3),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2EAF3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.blue),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            color: Color(0xFF253548),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
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
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blueDark,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2EAF3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF7D8EA3),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2EAF3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: const Icon(Icons.refresh_rounded, size: 18),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF8392A6),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TableText extends StatelessWidget {
  const _TableText(this.text, {this.isStrong = false});

  final String text;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: isStrong ? AppColors.blueDark : const Color(0xFF63748A),
        fontSize: 11,
        fontWeight: isStrong ? FontWeight.w900 : FontWeight.w700,
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.blue : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.blue : const Color(0xFFC8D3DF),
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 11)
          : null,
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5EDF6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF8B9AAF), size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF63748A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  const _DetailLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: _detailLabelStyle);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.size,
    required this.color,
    this.imageUrl = '',
  });

  final String name;
  final double size;
  final Color color;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final initials = _AvatarInitials(name: name, size: size, color: color);

    if (imageUrl.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => initials,
            loadingBuilder: (_, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return initials;
            },
          ),
        ),
      );
    }

    return initials;
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({
    required this.name,
    required this.size,
    required this.color,
  });

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitial(name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// _SidebarMenuTile removed (now using shared AdminSidebar)


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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2EAF3)),
              ),
              child: Icon(icon, color: const Color(0xFF57687B)),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5B6E),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
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
    );
  }
}

class _PageIconButton extends StatelessWidget {
  const _PageIconButton({
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: isDisabled ? null : onTap,
      icon: Icon(icon, size: 18),
      color: isDisabled ? const Color(0xFFCDD9E5) : const Color(0xFF8EA0B4),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  final int page;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: page > 9 ? 34 : 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEAF4FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              color: isSelected ? AppColors.blueDark : const Color(0xFF66768A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

const TextStyle _detailLabelStyle = TextStyle(
  color: Color(0xFF1E2B3A),
  fontSize: 13,
  fontWeight: FontWeight.w900,
);

const TextStyle _smallMutedStyle = TextStyle(
  color: Color(0xFF8EA0B4),
  fontSize: 11,
  fontWeight: FontWeight.w600,
);

const TextStyle _paginationTextStyle = TextStyle(
  color: Color(0xFF7D8EA3),
  fontSize: 12,
  fontWeight: FontWeight.w700,
);

Color _typeColor(String type) {
  switch (type) {
    case 'Thông tin sai lệch':
      return AppColors.blue;
    case 'Sai giá':
      return const Color(0xFF9B5CFF);
    case 'Lừa đảo':
      return const Color(0xFFFF5B6E);
    case 'Hết phòng':
      return const Color(0xFFF59E0B);
    case 'Lý do khác':
    default:
      return const Color(0xFF52657A);
  }
}

Color _priorityColor(String priority) {
  switch (priority) {
    case 'Cao':
      return const Color(0xFFFF5B6E);
    case 'Trung bình':
      return const Color(0xFFF59E0B);
    case 'Thấp':
      return const Color(0xFF22B573);
    default:
      return AppColors.blue;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'Mới':
      return const Color(0xFF9B5CFF);
    case 'Đang xử lý':
      return const Color(0xFFF59E0B);
    case 'Đã giải quyết':
      return const Color(0xFF22B573);
    default:
      return AppColors.blue;
  }
}

String _getInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

// _adminMenus removed (now using shared AdminSidebar)


const List<String> _typeOptions = [
  'Tất cả',
  'Thông tin sai lệch',
  'Sai giá',
  'Hết phòng',
  'Lừa đảo',
  'Lý do khác',
];
const List<String> _statusOptions = [
  'Tất cả',
  'Mới',
  'Đang xử lý',
  'Đã giải quyết',
];
const List<String> _priorityOptions = ['Tất cả', 'Cao', 'Trung bình', 'Thấp'];
const List<String> _timeOptions = [
  '7 ngày qua',
  '30 ngày qua',
  'Quý này',
  'Năm nay',
];

// (mock data removed - data loaded from Firestore)

// =====================
// DATA CLASSES
// =====================
// _AdminMenuItem removed (now using shared AdminSidebar)

class _ReportStat {
  const _ReportStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.changeText = '',
    this.isPositive = true,
  });
  final String title;
  final String value;
  final String changeText;
  final bool isPositive;
  final IconData icon;
  final Color accent;
}

class _ReportItem {
  const _ReportItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sender,
    required this.senderEmail,
    required this.type,
    required this.priority,
    required this.status,
    required this.timeAgo,
    required this.createdAt,
    required this.description,
    required this.color,
    this.rawCreatedAt,
    this.roomId = '',
    this.reporterId = '',
    this.firestoreStatus = 'pending',
    this.senderAvatarUrl = '',
    this.roomData,
  });

  final String id;
  final String title;
  final String subtitle;
  final String sender;
  final String senderEmail;
  final String type;
  final String priority;
  final String status;
  final String timeAgo;
  final String createdAt;
  final String description;
  final Color color;
  final DateTime? rawCreatedAt;
  final String roomId;
  final String reporterId;
  final String firestoreStatus;
  final String senderAvatarUrl;
  final Map<String, dynamic>? roomData;

  _ReportItem copyWith({String? status, String? firestoreStatus}) {
    return _ReportItem(
      id: id, title: title, subtitle: subtitle,
      sender: sender, senderEmail: senderEmail,
      senderAvatarUrl: senderAvatarUrl,
      type: type, priority: priority,
      status: status ?? this.status,
      timeAgo: timeAgo, createdAt: createdAt,
      rawCreatedAt: rawCreatedAt,
      description: description, color: color,
      roomId: roomId, reporterId: reporterId,
      firestoreStatus: firestoreStatus ?? this.firestoreStatus,
      roomData: roomData,
    );
  }
}

