import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/screens/admin/admin_navigation.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  int _selectedMenuIndex = 0;
  String _selectedPeriod = '7 ngày qua';
  String _selectedStatusFilter = 'Tất cả';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    if (index == 1) {
      openPostApproval(context);
      return;
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
  // BUILD MAIN CONTENT
  // =========================
  Widget _buildContent({
    required BuildContext context,
    required double width,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final contentMaxWidth = isDesktop ? 1320.0 : 1080.0;

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
                searchController: _searchController,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
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
            onPeriodChanged: (value) {
              setState(() => _selectedPeriod = value);
            },
          ),
          const SizedBox(height: 16),
          _ListingStatusCard(
            selectedFilter: _selectedStatusFilter,
            onFilterChanged: (value) {
              setState(() => _selectedStatusFilter = value);
            },
          ),
          const SizedBox(height: 16),
          const _QuickInsightsCard(),
        ],
      );
    }

    if (_isTablet(width)) {
      return Column(
        children: [
          _WeeklyActivityCard(
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (value) {
              setState(() => _selectedPeriod = value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ListingStatusCard(
                  selectedFilter: _selectedStatusFilter,
                  onFilterChanged: (value) {
                    setState(() => _selectedStatusFilter = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: _QuickInsightsCard(),
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
            onPeriodChanged: (value) {
              setState(() => _selectedPeriod = value);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _ListingStatusCard(
            selectedFilter: _selectedStatusFilter,
            onFilterChanged: (value) {
              setState(() => _selectedStatusFilter = value);
            },
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          flex: 3,
          child: _QuickInsightsCard(),
        ),
      ],
    );
  }

  // =========================
  // BUILD BOTTOM SECTION
  // =========================
  Widget _buildBottomSection(double width) {
    if (_isMobile(width)) {
      return Column(
        children: const [
          _RecentActivitySection(isCompact: true),
          SizedBox(height: 16),
          _RecentAlertsSection(),
        ],
      );
    }

    if (_isTablet(width)) {
      return const Column(
        children: [
          _RecentActivitySection(),
          SizedBox(height: 16),
          _RecentAlertsSection(),
        ],
      );
    }

    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: _RecentActivitySection(),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: _RecentAlertsSection(),
        ),
      ],
    );
  }
}

// =========================
// BUILD SIDEBAR
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

// =========================
// BUILD TOPBAR
// =========================
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
    final isHeaderStacked = !isMobile && width < 1220;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Admin',
          style: TextStyle(
            color: const Color(0xFF1E2B3A),
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Theo dõi hoạt động nền tảng, duyệt bài đăng và xử lý cảnh báo nhanh chóng.',
          style: TextStyle(
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
          hintText: 'Tìm kiếm bài đăng, người dùng hoặc cảnh báo...',
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

// =========================
// BUILD STAT CARD
// =========================
class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _AdminStat data;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
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
  });

  final String selectedPeriod;
  final ValueChanged<String>? onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
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
                      const _ChartYAxis(),
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
                                painter: _LineChartPainter(points: _weeklyChartData),
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
                    children: _weeklyChartData
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
                'Lượt truy cập',
                style: TextStyle(
                  color: Color(0xFF6E7F90),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Text(
                'Tổng: 4,325',
                style: TextStyle(
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
  });

  final String selectedFilter;
  final ValueChanged<String>? onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final total = _listingStatuses.fold<int>(0, (sum, item) => sum + item.count);

    return _AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCardHeader(
            title: 'Tình trạng bài đăng',
            trailing: _CompactDropdown(
              value: selectedFilter,
              items: const ['Tất cả', 'Đã xác minh', 'Chờ xác minh', 'Bị từ chối'],
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
                        painter: _DonutChartPainter(data: _listingStatuses),
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
                  children: _listingStatuses
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
          const Row(
            children: [
              Icon(
                Icons.update_rounded,
                color: Color(0xFF92A1B2),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Cập nhật: 19/05/2025 09:30',
                style: TextStyle(
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
  const _QuickInsightsCard();

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCardHeader(title: 'Thông tin nhanh'),
          const SizedBox(height: 16),
          ..._quickInsights.map(
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
  const _RecentActivitySection({this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCardHeader(title: 'Hoạt động gần đây'),
          const SizedBox(height: 18),
          if (isCompact)
            Column(
              children: _recentActivities
                  .map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecentActivityMobileCard(data: activity),
                    ),
                  )
                  .toList(),
            )
          else
            const _RecentActivityTable(),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Xem tất cả hoạt động',
                style: TextStyle(
                  color: AppColors.blueDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// BUILD RECENT ALERTS SECTION
// =========================
class _RecentAlertsSection extends StatelessWidget {
  const _RecentAlertsSection();

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCardHeader(
            title: 'Cảnh báo gần đây',
            trailing: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.blueDark,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Xem tất cả',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AlertTile(data: alert),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blueDark,
                side: const BorderSide(color: Color(0xFFD9E5F1)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text(
                'Xem tất cả cảnh báo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// SHARED SURFACE CARD
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

// =========================
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
// SIDEBAR MENU TILE
// =========================
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
    final color = isSelected ? AppColors.blueDark : const Color(0xFF57687B);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.blue.withValues(alpha: 0.14)
                    : const Color(0xFFF3F7FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
// TOPBAR ACTION BUTTON
// =========================
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

// =========================
// CHART Y AXIS
// =========================
class _ChartYAxis extends StatelessWidget {
  const _ChartYAxis();

  @override
  Widget build(BuildContext context) {
    const labels = ['1000', '800', '600', '400', '200', '0'];

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
  const _RecentActivityTable();

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
        ..._recentActivities.map(
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
                    onPressed: () {},
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
                child: Image.asset(
                  data.imageAsset,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
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
          child: Image.asset(
            data.imageAsset,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
          ),
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
// MOCK DATA - SIDEBAR
// =========================
const List<_AdminMenuItem> _adminMenus = [
  _AdminMenuItem(label: 'Tổng quan', icon: Icons.dashboard_outlined),
  _AdminMenuItem(label: 'Duyệt bài đăng', icon: Icons.fact_check_outlined),
  _AdminMenuItem(label: 'Người dùng', icon: Icons.group_outlined),
  _AdminMenuItem(label: 'Báo cáo', icon: Icons.bar_chart_rounded),
  _AdminMenuItem(label: 'Hỗ trợ', icon: Icons.support_agent_outlined),
  _AdminMenuItem(label: 'Cài đặt', icon: Icons.settings_outlined),
];

// =========================
// MOCK DATA - STATS
// =========================
const List<_AdminStat> _adminStats = [
  _AdminStat(
    title: 'Bài đăng chờ duyệt',
    value: '128',
    changeText: '+12.5%',
    isPositive: false,
    icon: Icons.assignment_late_outlined,
    accent: Color(0xFFF59E0B),
  ),
  _AdminStat(
    title: 'Người dùng',
    value: '5,426',
    changeText: '+8.3%',
    isPositive: true,
    icon: Icons.groups_2_outlined,
    accent: Color(0xFF22B573),
  ),
  _AdminStat(
    title: 'Báo cáo mới',
    value: '23',
    changeText: '+27.8%',
    isPositive: false,
    icon: Icons.flag_outlined,
    accent: AppColors.blue,
  ),
  _AdminStat(
    title: 'Yêu cầu hỗ trợ',
    value: '15',
    changeText: '+6.7%',
    isPositive: true,
    icon: Icons.headset_mic_outlined,
    accent: Color(0xFF8B5CF6),
  ),
];

// =========================
// MOCK DATA - LINE CHART
// =========================
const List<_ChartPoint> _weeklyChartData = [
  _ChartPoint(label: '13/05', value: 300),
  _ChartPoint(label: '14/05', value: 460),
  _ChartPoint(label: '15/05', value: 810),
  _ChartPoint(label: '16/05', value: 450),
  _ChartPoint(label: '17/05', value: 360),
  _ChartPoint(label: '18/05', value: 820),
  _ChartPoint(label: '19/05', value: 610),
];

// =========================
// MOCK DATA - LISTING STATUS
// =========================
const List<_ListingStatus> _listingStatuses = [
  _ListingStatus(
    label: 'Đã xác minh',
    count: 1563,
    color: Color(0xFF57C98D),
  ),
  _ListingStatus(
    label: 'Chờ xác minh',
    count: 628,
    color: Color(0xFFFFB84D),
  ),
  _ListingStatus(
    label: 'Bị từ chối',
    count: 267,
    color: Color(0xFFFF6B6B),
  ),
];

// =========================
// MOCK DATA - QUICK INSIGHTS
// =========================
const List<_QuickInsight> _quickInsights = [
  _QuickInsight(
    title: 'Tỷ lệ xác minh',
    value: '63.6%',
    changeText: '+5.4% so với tuần trước',
    icon: Icons.verified_rounded,
    accent: Color(0xFF22B573),
    isPositive: true,
  ),
  _QuickInsight(
    title: 'Đăng mới hôm nay',
    value: '86',
    changeText: '+15.2% so với hôm qua',
    icon: Icons.note_add_rounded,
    accent: AppColors.blue,
    isPositive: true,
  ),
  _QuickInsight(
    title: 'Người dùng mới',
    value: '312',
    changeText: '+9.7% so với tuần trước',
    icon: Icons.person_add_alt_1_rounded,
    accent: Color(0xFF8B5CF6),
    isPositive: true,
  ),
  _QuickInsight(
    title: 'Lượt xem hôm nay',
    value: '2,451',
    changeText: '+11.3% so với hôm qua',
    icon: Icons.visibility_rounded,
    accent: Color(0xFFF59E0B),
    isPositive: true,
  ),
];

// =========================
// MOCK DATA - RECENT ACTIVITY
// =========================
const List<_RecentActivity> _recentActivities = [
  _RecentActivity(
    roomCode: 'SRF-10293',
    roomName: 'Phòng trọ quận 10, TP.HCM',
    ownerName: 'Nguyễn Văn Bình',
    ownerEmail: 'binh.nv@gmail.com',
    status: 'Chờ duyệt',
    postedAt: '19/05/2025\n09:15',
    imageAsset: 'assets/images/room_apartment_horizon.png',
  ),
  _RecentActivity(
    roomCode: 'SRF-10292',
    roomName: 'Phòng trọ gần Đại Bách Khoa',
    ownerName: 'Trần Thị Mai',
    ownerEmail: 'mai.tt@gmail.com',
    status: 'Đã xác minh',
    postedAt: '19/05/2025\n08:45',
    imageAsset: 'assets/images/room_student_room.png',
  ),
  _RecentActivity(
    roomCode: 'SRF-10291',
    roomName: 'Phòng full nội thất, Quận 7',
    ownerName: 'Lê Minh Tuấn',
    ownerEmail: 'tuanlm@gmail.com',
    status: 'Chờ xác minh',
    postedAt: '19/05/2025\n08:30',
    imageAsset: 'assets/images/room_muji_studio.png',
  ),
  _RecentActivity(
    roomCode: 'SRF-10290',
    roomName: 'Phòng trọ giá rẻ Gò Vấp',
    ownerName: 'Phạm Văn Hùng',
    ownerEmail: 'hungpv@gmail.com',
    status: 'Bị từ chối',
    postedAt: '19/05/2025\n07:50',
    imageAsset: 'assets/images/room_apartment_mini.png',
  ),
  _RecentActivity(
    roomCode: 'SRF-10289',
    roomName: 'Phòng mới xây, Tân Bình',
    ownerName: 'Đỗ Thu Hằng',
    ownerEmail: 'hangdt@gmail.com',
    status: 'Đã xác minh',
    postedAt: '19/05/2025\n07:20',
    imageAsset: 'assets/images/room_apartment_2br.png',
  ),
];

// =========================
// MOCK DATA - ALERTS
// =========================
const List<_AlertItem> _alerts = [
  _AlertItem(
    title: 'Báo cáo nội dung',
    subtitle: 'Bài đăng có nội dung vi phạm #RC-2025-0519',
    timeAgo: '10 phút trước',
    icon: Icons.report_gmailerrorred_rounded,
    accent: Color(0xFFFF6B6B),
  ),
  _AlertItem(
    title: 'Bài đăng bị từ chối',
    subtitle: 'Mã phòng SRF-10293 vừa bị từ chối xác minh',
    timeAgo: '35 phút trước',
    icon: Icons.warning_amber_rounded,
    accent: Color(0xFFF59E0B),
  ),
  _AlertItem(
    title: 'Yêu cầu hỗ trợ mới',
    subtitle: 'Từ người dùng Nguyễn Văn A cần phản hồi',
    timeAgo: '1 giờ trước',
    icon: Icons.info_outline_rounded,
    accent: AppColors.blue,
  ),
];

// =========================
// PRIVATE HELPERS
// =========================
String _getInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

// =========================
// PRIVATE MODELS
// =========================
class _AdminMenuItem {
  const _AdminMenuItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
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
