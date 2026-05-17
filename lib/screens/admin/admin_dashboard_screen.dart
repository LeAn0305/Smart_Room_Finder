import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
// admin_navigation.dart is used via admin_shared_widgets.dart
import 'package:smart_room_finder/screens/admin/admin_shared_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  final int _selectedMenuIndex = 0;
  String _selectedPeriod = '7 ngày qua';
  String _selectedStatusFilter = 'Tất cả';
  bool _isLoadingData = true;
  String _adminDisplayName = 'Admin';
  DateTime _lastFetchTime = DateTime.now();

  // Pagination
  int _activityPage = 1;
  int _alertPage = 1;
  static const int _activityPageSize = 5;
  static const int _alertPageSize = 3;

  // Instance data (moved from top-level vars)
  var _adminStats = <_AdminStat>[];
  var _weeklyChartData = <_ChartPoint>[];
  var _listingStatuses = <_ListingStatus>[];
  var _quickInsights = <_QuickInsight>[];
  var _allRecentActivities = <_RecentActivity>[];
  var _allAlerts = <_AlertItem>[];

  // Raw rooms data for chart period rebuild
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _rawRooms = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _activityPage = 1));
    _fetchAdminName();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminName() async {
    final name = await fetchAdminDisplayName();
    if (mounted) setState(() => _adminDisplayName = name);
  }

  // =========================
  // FETCH FROM FIRESTORE
  // =========================
  Future<void> _fetchDashboardData() async {
    try {
      final fs  = FirebaseFirestore.instance;
      final now = DateTime.now();
      final results = await Future.wait([
        fs.collection('rooms').get(),
        fs.collection('users').get(),
        fs.collection('reports').get(),
        fs.collection('support_tickets').get(),
      ]);

      final rooms   = results[0].docs;
      final users   = results[1].docs;
      final reports = results[2].docs;
      final support = results[3].docs;

      DateTime? parseDate(dynamic raw) {
        if (raw is Timestamp) return raw.toDate();
        if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
        return null;
      }

      // --- Status classification using approvalStatus with fallback ---
      String classifyRoom(Map<String, dynamic> d) {
        final approvalStatus = (d['approvalStatus'] ?? '').toString().toLowerCase();
        if (approvalStatus.isNotEmpty) {
          if (approvalStatus == 'verified') return 'verified';
          if (approvalStatus == 'rejected') return 'rejected';
          if (approvalStatus == 'needsinfo' || approvalStatus == 'needs_info') return 'needsInfo';
          return 'pending';
        }
        // Fallback for old data without approvalStatus
        if (d['isVerified'] == true) return 'verified';
        if (d['isDraft'] == true) return 'rejected';
        return 'pending';
      }

      int verified = 0, pending = 0, rejected = 0, needsInfo = 0;
      for (final d in rooms) {
        switch (classifyRoom(d.data())) {
          case 'verified': verified++;
          case 'rejected': rejected++;
          case 'needsInfo': needsInfo++;
          default: pending++;
        }
      }

      _adminStats = [
        _AdminStat(title: 'Bài đăng chờ duyệt', value: '${pending + needsInfo}', changeText: '—', isPositive: false, icon: Icons.assignment_late_outlined, accent: const Color(0xFFF59E0B)),
        _AdminStat(title: 'Người dùng',          value: '${users.length}',       changeText: '—', isPositive: true,  icon: Icons.groups_2_outlined,         accent: const Color(0xFF22B573)),
        _AdminStat(title: 'Báo cáo mới',         value: '${reports.length}',     changeText: '—', isPositive: false, icon: Icons.flag_outlined,             accent: AppColors.blue),
        _AdminStat(title: 'Yêu cầu hỗ trợ',     value: '${support.length}',     changeText: '—', isPositive: true,  icon: Icons.headset_mic_outlined,      accent: const Color(0xFF8B5CF6)),
      ];

      _rawRooms = rooms;
      _weeklyChartData = _buildChartData(rooms, 7, now, parseDate);

      _listingStatuses = [
        _ListingStatus(label: 'Đã xác minh',  count: verified,  color: const Color(0xFF57C98D)),
        _ListingStatus(label: 'Chờ xác minh', count: pending,   color: const Color(0xFFFFB84D)),
        _ListingStatus(label: 'Cần bổ sung',  count: needsInfo, color: const Color(0xFF3B82F6)),
        _ListingStatus(label: 'Bị từ chối',   count: rejected,  color: const Color(0xFFFF6B6B)),
      ];

      final total    = rooms.length;
      final vRate    = total == 0 ? '0%' : '${(verified / total * 100).toStringAsFixed(1)}%';
      final todayCnt = rooms.where((d) {
        final date = parseDate(d.data()['postedAt']);
        return date != null && date.year == now.year && date.month == now.month && date.day == now.day;
      }).length;
      final newUsers = users.where((d) {
        final date = parseDate(d.data()['createdAt']);
        return date != null && now.difference(date).inDays <= 7;
      }).length;

      _quickInsights = [
        _QuickInsight(title: 'Tỷ lệ xác minh',       value: vRate,       changeText: 'Trên $total phòng',   icon: Icons.verified_rounded,         accent: const Color(0xFF22B573), isPositive: true),
        _QuickInsight(title: 'Đăng mới hôm nay',      value: '$todayCnt', changeText: 'Trong ngày hôm nay',  icon: Icons.note_add_rounded,         accent: AppColors.blue,          isPositive: true),
        _QuickInsight(title: 'Người dùng mới (tuần)',  value: '$newUsers', changeText: '7 ngày gần nhất',     icon: Icons.person_add_alt_1_rounded, accent: const Color(0xFF8B5CF6), isPositive: true),
        _QuickInsight(title: 'Tổng số phòng',          value: '$total',    changeText: 'Toàn hệ thống',       icon: Icons.home_work_outlined,       accent: const Color(0xFFF59E0B), isPositive: true),
      ];

      final sorted = [...rooms]..sort((a, b) {
        final da = parseDate(a.data()['postedAt']);
        final db = parseDate(b.data()['postedAt']);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      // Tạo map uid → user data để cross-reference nhanh
      final userMap = <String, Map<String, dynamic>>{
        for (final u in users) u.id: u.data(),
      };

      _allRecentActivities = sorted.map((doc) {
        final d  = doc.data();
        final id = doc.id;
        final String status;
        final cls = classifyRoom(d);
        switch (cls) {
          case 'verified':  status = 'Đã xác minh';
          case 'rejected':  status = 'Bị từ chối';
          case 'needsInfo': status = 'Cần bổ sung';
          default:          status = 'Chờ duyệt';
        }
        final date    = parseDate(d['postedAt']);
        final dateStr = date == null ? '—'
            : '${date.day}/${date.month}/${date.year}\n${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

        // Lấy tên chủ trọ từ users collection qua ownerId
        final ownerId  = (d['ownerId'] ?? d['postedBy'] ?? '').toString();
        final ownerDoc = userMap[ownerId] ?? {};
        final ownerName = (ownerDoc['displayName'] ??
                ownerDoc['name'] ??
                ownerDoc['fullName'] ??
                (ownerId.isNotEmpty ? 'Chủ trọ' : 'Ẩn danh'))
            .toString();
        final ownerEmail = (ownerDoc['email'] ?? '').toString();

        return _RecentActivity(
          roomCode:   'SRF-${id.substring(0, math.min(6, id.length)).toUpperCase()}',
          roomName:   (d['title']    ?? 'Chưa đặt tên').toString(),
          ownerName:  ownerName,
          ownerEmail: ownerEmail,
          status:     status,
          postedAt:   dateStr,
          imageAsset: (d['mainImageUrl'] ?? d['imageUrl'] ?? '').toString(),
        );
      }).toList();

      _allAlerts = [
        for (final doc in reports)
          _AlertItem(
            title:    'Báo cáo nội dung',
            subtitle: (doc.data()['reason'] ?? doc.data()['message'] ?? 'Nội dung vi phạm').toString(),
            timeAgo:  _timeAgo(doc.data()['createdAt']),
            icon:     Icons.report_gmailerrorred_rounded,
            accent:   const Color(0xFFFF6B6B),
          ),
        for (final doc in support)
          _AlertItem(
            title:    'Yêu cầu hỗ trợ mới',
            subtitle: (doc.data()['message'] ?? doc.data()['subject'] ?? 'Cần phản hồi').toString(),
            timeAgo:  _timeAgo(doc.data()['createdAt']),
            icon:     Icons.info_outline_rounded,
            accent:   AppColors.blue,
          ),
      ];

      _lastFetchTime = DateTime.now();
      if (mounted) setState(() => _isLoadingData = false);
    } catch (e) {
      debugPrint('❌ Dashboard fetch error: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  static String _timeAgo(dynamic raw) {
    DateTime? date;
    if (raw is Timestamp) date = raw.toDate();
    else if (raw is String && raw.isNotEmpty) date = DateTime.tryParse(raw);
    if (date == null) return '—';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24)   return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }


  static List<_ChartPoint> _buildChartData(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
    int days,
    DateTime now,
    DateTime? Function(dynamic) parseDate,
  ) {
    return List.generate(days, (i) {
      final day = now.subtract(Duration(days: days - 1 - i));
      final count = rooms.where((d) {
        final date = parseDate(d.data()['postedAt']);
        return date != null && date.year == day.year && date.month == day.month && date.day == day.day;
      }).length;
      return _ChartPoint(label: '${day.day}/${day.month}', value: count.toDouble());
    });
  }

  void _rebuildChartForPeriod(String period) {
    final days = switch (period) {
      '14 ngày qua' => 14,
      '30 ngày qua' => 30,
      _ => 7,
    };
    DateTime? parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
      return null;
    }
    setState(() {
      _selectedPeriod = period;
      _weeklyChartData = _buildChartData(_rawRooms, days, DateTime.now(), parseDate);
    });
  }

  // Filtered activities based on search
  List<_RecentActivity> get _filteredActivities {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allRecentActivities;
    return _allRecentActivities.where((a) =>
      a.roomCode.toLowerCase().contains(query) ||
      a.roomName.toLowerCase().contains(query) ||
      a.ownerName.toLowerCase().contains(query) ||
      a.ownerEmail.toLowerCase().contains(query) ||
      a.status.toLowerCase().contains(query)
    ).toList();
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

    handleAdminMenuSelection(context, _selectedMenuIndex, index);
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
                      onSelected: (index) {
                        _handleMenuSelection(context, index);
                      },
                      onLogout: () => showAdminLogoutDialog(context),
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
  // BUILD MAIN CONTENT
  // =========================
  Widget _buildContent({
    required BuildContext context,
    required double width,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final contentMaxWidth = isDesktop ? 1320.0 : 1080.0;

    if (_isLoadingData && _adminStats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 120),
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

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
              AdminTopbar(
                width: width,
                isMobile: isMobile,
                title: 'Dashboard Admin',
                subtitle: 'Theo dõi hoạt động nền tảng, duyệt bài đăng và xử lý cảnh báo nhanh chóng.',
                searchController: _searchController,
                searchHint: 'Tìm kiếm bài đăng, người dùng hoặc cảnh báo...',
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                adminDisplayName: _adminDisplayName,
              ),
              const SizedBox(height: 20),
              _buildStatsSection(width),
              const SizedBox(height: 20),
              _buildAnalyticsSection(width),
              const SizedBox(height: 20),
              _buildBottomSection(width),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // BUILD STATS SECTION
  // =========================
  Widget _buildStatsSection(double width) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sectionWidth = constraints.maxWidth;
        final crossAxisCount = _isDesktop(width) ? 4 : 2;
        const spacing = 16.0;
        final itemWidth =
            (sectionWidth - ((crossAxisCount - 1) * spacing)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _adminStats
              .map(
                (stat) => SizedBox(
                  width: itemWidth,
                  child: _StatCard(data: stat),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // =========================
  // BUILD ANALYTICS SECTION
  // =========================
  Widget _buildAnalyticsSection(double width) {
    if (_isMobile(width)) {
      return Column(
        children: [
          _WeeklyActivityCard(
            selectedPeriod: _selectedPeriod,
            chartData: _weeklyChartData,
            onPeriodChanged: (value) => _rebuildChartForPeriod(value),
          ),
          const SizedBox(height: 16),
          _ListingStatusCard(
            selectedFilter: _selectedStatusFilter,
            listingStatuses: _listingStatuses,
            lastFetchTime: _lastFetchTime,
            onFilterChanged: (value) {
              setState(() => _selectedStatusFilter = value);
            },
          ),
          const SizedBox(height: 16),
          _QuickInsightsCard(insights: _quickInsights),
        ],
      );
    }

    if (_isTablet(width)) {
      return Column(
        children: [
          _WeeklyActivityCard(
            selectedPeriod: _selectedPeriod,
            chartData: _weeklyChartData,
            onPeriodChanged: (value) => _rebuildChartForPeriod(value),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ListingStatusCard(
                  selectedFilter: _selectedStatusFilter,
                  listingStatuses: _listingStatuses,
                  lastFetchTime: _lastFetchTime,
                  onFilterChanged: (value) {
                    setState(() => _selectedStatusFilter = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickInsightsCard(insights: _quickInsights),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _WeeklyActivityCard(
            selectedPeriod: _selectedPeriod,
            chartData: _weeklyChartData,
            onPeriodChanged: (value) => _rebuildChartForPeriod(value),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _ListingStatusCard(
            selectedFilter: _selectedStatusFilter,
            listingStatuses: _listingStatuses,
            lastFetchTime: _lastFetchTime,
            onFilterChanged: (value) {
              setState(() => _selectedStatusFilter = value);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _QuickInsightsCard(insights: _quickInsights),
        ),
      ],
    );
  }

  // =========================
  // BUILD BOTTOM SECTION
  // =========================
  Widget _buildBottomSection(double width) {
    final activities = _filteredActivities;
    final totalActivityPages = math.max(1, (activities.length / _activityPageSize).ceil());
    final safeActivityPage = _activityPage.clamp(1, totalActivityPages);
    final activityStart = (safeActivityPage - 1) * _activityPageSize;
    final paginatedActivities = activities.skip(activityStart).take(_activityPageSize).toList();

    final totalAlertPages = math.max(1, (_allAlerts.length / _alertPageSize).ceil());
    final safeAlertPage = _alertPage.clamp(1, totalAlertPages);
    final alertStart = (safeAlertPage - 1) * _alertPageSize;
    final paginatedAlerts = _allAlerts.skip(alertStart).take(_alertPageSize).toList();

    Widget activitySection({bool isCompact = false}) => _RecentActivitySection(
      isCompact: isCompact,
      activities: paginatedActivities,
      currentPage: safeActivityPage,
      totalPages: totalActivityPages,
      onPrevPage: safeActivityPage > 1 ? () => setState(() => _activityPage--) : null,
      onNextPage: safeActivityPage < totalActivityPages ? () => setState(() => _activityPage++) : null,
    );

    Widget alertSection() => _RecentAlertsSection(
      alerts: paginatedAlerts,
      currentPage: safeAlertPage,
      totalPages: totalAlertPages,
      onPrevPage: safeAlertPage > 1 ? () => setState(() => _alertPage--) : null,
      onNextPage: safeAlertPage < totalAlertPages ? () => setState(() => _alertPage++) : null,
    );

    if (_isMobile(width)) {
      return Column(
        children: [
          activitySection(isCompact: true),
          const SizedBox(height: 16),
          alertSection(),
        ],
      );
    }

    if (_isTablet(width)) {
      return Column(
        children: [
          activitySection(),
          const SizedBox(height: 16),
          alertSection(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: activitySection(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: alertSection(),
        ),
      ],
    );
}
}

// =========================
class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _AdminStat data;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: data.accent),
              ),
              const Spacer(),
              Icon(
                data.isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: data.isPositive
                    ? const Color(0xFF22B573)
                    : const Color(0xFFF97316),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            style: const TextStyle(
              color: Color(0xFF6E7F90),
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                data.changeText,
                style: TextStyle(
                  color: data.isPositive
                      ? const Color(0xFF22B573)
                      : const Color(0xFFF97316),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'so với tuần trước',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF95A3B4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
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
// BUILD WEEKLY ACTIVITY CARD
// =========================
class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({
    this.selectedPeriod = '7 ngày qua',
    this.onPeriodChanged,
    this.chartData = const [],
  });

  final String selectedPeriod;
  final ValueChanged<String>? onPeriodChanged;
  final List<_ChartPoint> chartData;

  @override
  Widget build(BuildContext context) {
    final maxVal = chartData.isEmpty ? 1.0 : chartData.map((p) => p.value).reduce(math.max).clamp(1.0, double.infinity);
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCardHeader(
            title: 'Hoạt động trong tuần',
            trailing: _CompactDropdown(
              value: selectedPeriod,
              items: const ['7 ngày qua', '14 ngày qua', '30 ngày qua'],
              onChanged: onPeriodChanged,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 250,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ChartYAxis(maxValue: maxVal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                5,
                                (_) => Container(
                                  height: 1,
                                  color: const Color(0xFFE8EEF5),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _LineChartPainter(points: chartData),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: chartData
                        .map(
                          (point) => Expanded(
                            child: Text(
                              point.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF99A6B5),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Bài đăng mới',
                style: TextStyle(
                  color: Color(0xFF6E7F90),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Tổng: ${chartData.fold(0.0, (s, p) => s + p.value).toInt()} bài đăng',
                style: const TextStyle(
                  color: AppColors.blueDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
// BUILD LISTING STATUS CARD
// =========================
class _ListingStatusCard extends StatelessWidget {
  const _ListingStatusCard({
    this.selectedFilter = 'Tất cả',
    this.onFilterChanged,
    this.listingStatuses = const [],
    this.lastFetchTime,
  });

  final String selectedFilter;
  final ValueChanged<String>? onFilterChanged;
  final List<_ListingStatus> listingStatuses;
  final DateTime? lastFetchTime;

  @override
  Widget build(BuildContext context) {
    final total = listingStatuses.fold<int>(0, (sum, item) => sum + item.count);
    final timeStr = lastFetchTime != null
        ? '${lastFetchTime!.day.toString().padLeft(2, '0')}/${lastFetchTime!.month.toString().padLeft(2, '0')}/${lastFetchTime!.year} ${lastFetchTime!.hour.toString().padLeft(2, '0')}:${lastFetchTime!.minute.toString().padLeft(2, '0')}'
        : '--';

    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCardHeader(
            title: 'Tình trạng bài đăng',
            trailing: _CompactDropdown(
              value: selectedFilter,
              items: const ['Tất cả', 'Đã xác minh', 'Chờ xác minh', 'Cần bổ sung', 'Bị từ chối'],
              onChanged: onFilterChanged,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(180),
                        painter: _DonutChartPainter(data: listingStatuses),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Tổng',
                            style: TextStyle(
                              color: Color(0xFF8D9AAA),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$total',
                            style: const TextStyle(
                              color: Color(0xFF1E2B3A),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  children: listingStatuses
                      .map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _StatusLegendTile(status: status, total: total),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const Divider(height: 26, color: Color(0xFFE7EDF5)),
          Row(
            children: [
              const Icon(
                Icons.update_rounded,
                color: Color(0xFF92A1B2),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Cập nhật: $timeStr',
                style: const TextStyle(
                  color: Color(0xFF92A1B2),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
// BUILD QUICK INSIGHTS CARD
// =========================
class _QuickInsightsCard extends StatelessWidget {
  const _QuickInsightsCard({this.insights = const []});

  final List<_QuickInsight> insights;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCardHeader(title: 'Thông tin nhanh'),
          const SizedBox(height: 16),
          ...insights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _InsightTile(data: item),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// BUILD RECENT ACTIVITY SECTION
// =========================
class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    this.isCompact = false,
    this.activities = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPrevPage,
    this.onNextPage,
  });

  final bool isCompact;
  final List<_RecentActivity> activities;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCardHeader(title: 'Hoạt động gần đây'),
          const SizedBox(height: 18),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Không có hoạt động nào',
                  style: TextStyle(color: Color(0xFF8D9AAA), fontSize: 13),
                ),
              ),
            )
          else if (isCompact)
            Column(
              children: activities
                  .map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecentActivityMobileCard(data: activity),
                    ),
                  )
                  .toList(),
            )
          else
            _RecentActivityTable(activities: activities),
          if (totalPages > 1) ...[
            const SizedBox(height: 10),
            _PaginationControls(
              currentPage: currentPage,
              totalPages: totalPages,
              onPrevPage: onPrevPage,
              onNextPage: onNextPage,
            ),
          ],
        ],
      ),
    );
  }
}

// =========================
// BUILD RECENT ALERTS SECTION
// =========================
class _RecentAlertsSection extends StatelessWidget {
  const _RecentAlertsSection({
    this.alerts = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPrevPage,
    this.onNextPage,
  });

  final List<_AlertItem> alerts;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCardHeader(title: 'Cảnh báo gần đây'),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Không có cảnh báo nào',
                  style: TextStyle(color: Color(0xFF8D9AAA), fontSize: 13),
                ),
              ),
            )
          else
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AlertTile(data: alert),
              ),
            ),
          if (totalPages > 1) ...[
            const SizedBox(height: 8),
            _PaginationControls(
              currentPage: currentPage,
              totalPages: totalPages,
              onPrevPage: onPrevPage,
              onNextPage: onNextPage,
            ),
          ],
        ],
      ),
    );
  }
}

// =========================
// PAGINATION CONTROLS
// =========================
class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    this.onPrevPage,
    this.onNextPage,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Trang $currentPage / $totalPages',
          style: const TextStyle(
            color: Color(0xFF7E8EA0),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
          color: onPrevPage != null ? AppColors.blueDark : const Color(0xFFCBD4DE),
          onPressed: onPrevPage,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          color: onNextPage != null ? AppColors.blueDark : const Color(0xFFCBD4DE),
          onPressed: onNextPage,
        ),
      ],
    );
  }
}

// SHARED SECTION HEADER
// =========================
class _SectionCardHeader extends StatelessWidget {
  const _SectionCardHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E2B3A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// =========================
// SHARED COMPACT DROPDOWN
// =========================
class _CompactDropdown extends StatelessWidget {
  const _CompactDropdown({
    required this.value,
    required this.items,
    this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E9F3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF94A3B4),
          ),
          style: const TextStyle(
            color: Color(0xFF4C5F75),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged == null ? null : (value) => onChanged!(value!),
        ),
      ),
    );
  }
}



// =========================
// CHART Y AXIS
// =========================
class _ChartYAxis extends StatelessWidget {
  const _ChartYAxis({this.maxValue = 1000});

  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final step = maxValue / 4;
    final labels = List.generate(5, (i) => '${(maxValue - step * i).round()}');

    return SizedBox(
      width: 30,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: labels
            .map(
              (label) => Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFA3AFBD),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// =========================
// STATUS LEGEND TILE
// =========================
class _StatusLegendTile extends StatelessWidget {
  const _StatusLegendTile({
    required this.status,
    required this.total,
  });

  final _ListingStatus status;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (status.count / total * 100);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.label,
                style: const TextStyle(
                  color: Color(0xFF55687B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${status.count} (${percent.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  color: Color(0xFF8F9CAB),
                  fontSize: 12,
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

// =========================
// QUICK INSIGHT TILE
// =========================
class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.data});

  final _QuickInsight data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF6B7D90),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.changeText,
                  style: TextStyle(
                    color: data.isPositive
                        ? const Color(0xFF22B573)
                        : const Color(0xFFF97316),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            data.value,
            style: const TextStyle(
              color: Color(0xFF1E2B3A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// RECENT ACTIVITY TABLE
// =========================
class _RecentActivityTable extends StatelessWidget {
  const _RecentActivityTable({this.activities = const []});

  final List<_RecentActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Expanded(flex: 4, child: _TableHeaderLabel('Mã phòng')),
              Expanded(flex: 3, child: _TableHeaderLabel('Chủ trọ')),
              Expanded(flex: 2, child: _TableHeaderLabel('Trạng thái')),
              Expanded(flex: 2, child: _TableHeaderLabel('Ngày đăng')),
              SizedBox(width: 36),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...activities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7EDF5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _RoomInfoCell(data: activity),
                  ),
                  Expanded(
                    flex: 3,
                    child: _OwnerInfoCell(data: activity),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _StatusChip(status: activity.status),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      activity.postedAt,
                      style: const TextStyle(
                        color: Color(0xFF6E7F90),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => showAdminComingSoon(context),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF92A1B2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =========================
// RECENT ACTIVITY MOBILE CARD
// =========================
class _RecentActivityMobileCard extends StatelessWidget {
  const _RecentActivityMobileCard({required this.data});

  final _RecentActivity data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDF5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildRoomThumb(data.imageAsset, 56, 56),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.roomCode,
                      style: const TextStyle(
                        color: Color(0xFF1E2B3A),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.roomName,
                      style: const TextStyle(
                        color: Color(0xFF6E7F90),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusChip(status: data.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE9F8F4),
                child: Text(
                  _getInitial(data.ownerName),
                  style: const TextStyle(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.ownerName,
                      style: const TextStyle(
                        color: Color(0xFF324558),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      data.ownerEmail,
                      style: const TextStyle(
                        color: Color(0xFF8D9AAA),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                data.postedAt,
                style: const TextStyle(
                  color: Color(0xFF8D9AAA),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
// ALERT TILE
// =========================
class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.data});

  final _AlertItem data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF26384A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF748496),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            data.timeAgo,
            style: const TextStyle(
              color: Color(0xFF94A2B2),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// TABLE HEADER LABEL
// =========================
class _TableHeaderLabel extends StatelessWidget {
  const _TableHeaderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8D9AAA),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// =========================
// ROOM INFO CELL
// =========================
class _RoomInfoCell extends StatelessWidget {
  const _RoomInfoCell({required this.data});

  final _RecentActivity data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildRoomThumb(data.imageAsset, 52, 52),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.roomCode,
                style: const TextStyle(
                  color: Color(0xFF26384A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.roomName,
                style: const TextStyle(
                  color: Color(0xFF6E7F90),
                  fontSize: 12,
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

// =========================
// OWNER INFO CELL
// =========================
class _OwnerInfoCell extends StatelessWidget {
  const _OwnerInfoCell({required this.data});

  final _RecentActivity data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFE9F8F4),
          child: Text(
            _getInitial(data.ownerName),
            style: const TextStyle(
              color: AppColors.tealDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.ownerName,
                style: const TextStyle(
                  color: Color(0xFF324558),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.ownerEmail,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8D9AAA),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =========================
// STATUS CHIP
// =========================
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
      'Chờ duyệt' || 'Chờ xác minh' => (
          const Color(0xFFFFF3E4),
          const Color(0xFFF59E0B),
        ),
      'Cần bổ sung' => (
          const Color(0xFFE8F0FE),
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

// =========================
// LINE CHART PAINTER
// =========================
class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.points});

  final List<_ChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = points
        .map((point) => point.value)
        .fold<double>(0, (max, value) => math.max(max, value));

    final linePaint = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.blue.withValues(alpha: 0.22),
          AppColors.blue.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1 ? 0.0 : (size.width / (points.length - 1)) * i;
      final normalizedY = maxValue == 0 ? 0.0 : points[i].value / maxValue;
      final y = size.height - (normalizedY * (size.height - 14)) - 8;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1 ? 0.0 : (size.width / (points.length - 1)) * i;
      final normalizedY = maxValue == 0 ? 0.0 : points[i].value / maxValue;
      final y = size.height - (normalizedY * (size.height - 14)) - 8;

      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, pointBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

// =========================
// DONUT CHART PAINTER
// =========================
class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.data});

  final List<_ListingStatus> data;

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<int>(0, (sum, item) => sum + item.count);
    final strokeWidth = 24.0;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: math.min(size.width, size.height) / 2 - strokeWidth / 2,
    );

    final backgroundPaint = Paint()
      ..color = const Color(0xFFEFF3F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    var startAngle = -math.pi / 2;
    for (final item in data) {
      final sweepAngle = total == 0 ? 0.0 : (item.count / total) * math.pi * 2;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + 0.04;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

// =========================
// PRIVATE HELPERS
// =========================
String _getInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

class _AdminStat {
  const _AdminStat({
    required this.title,
    required this.value,
    required this.changeText,
    required this.isPositive,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String changeText;
  final bool isPositive;
  final IconData icon;
  final Color accent;
}

class _ChartPoint {
  const _ChartPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class _ListingStatus {
  const _ListingStatus({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class _QuickInsight {
  const _QuickInsight({
    required this.title,
    required this.value,
    required this.changeText,
    required this.icon,
    required this.accent,
    required this.isPositive,
  });

  final String title;
  final String value;
  final String changeText;
  final IconData icon;
  final Color accent;
  final bool isPositive;
}

class _RecentActivity {
  const _RecentActivity({
    required this.roomCode,
    required this.roomName,
    required this.ownerName,
    required this.ownerEmail,
    required this.status,
    required this.postedAt,
    required this.imageAsset,
  });

  final String roomCode;
  final String roomName;
  final String ownerName;
  final String ownerEmail;
  final String status;
  final String postedAt;
  final String imageAsset;
}

class _AlertItem {
  const _AlertItem({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String timeAgo;
  final IconData icon;
  final Color accent;
}

/// Tá»± Ä‘á»™ng chá»n Image.network hoặc Image.asset dựa trên [url].
/// Nếu [url] là Firebase Storage URL (http/https) â†’ dÃ¹ng Image.network.
/// Nếu là đ‘Æ°á»ng dáº«n asset local (assets/...) â†’ dÃ¹ng Image.asset.
/// Nếu rá»—ng hoặc lá»—i â†’ hiá»ƒn thá»‹ placeholder teal.
Widget _buildRoomThumb(String url, double width, double height) {
  Widget placeholder() => Container(
        width: width,
        height: height,
        color: const Color(0xFFE0F5F5),
        child: const Center(
          child: Icon(Icons.apartment_rounded,
              color: Color(0xFF4DD4C0), size: 22),
        ),
      );

  if (url.isEmpty) return placeholder();

  if (url.startsWith('http://') || url.startsWith('https://')) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder(),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder(),
    );
  }

  // Local asset path
  return Image.asset(
    url,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => placeholder(),
  );
}

