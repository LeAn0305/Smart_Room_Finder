import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/screens/admin/admin_navigation.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  int _selectedMenuIndex = 3;
  String _selectedReportId = _reports.first.id;
  String _selectedType = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  String _selectedPriority = 'Tất cả';
  String _selectedTime = '7 ngày qua';
  int _currentPage = 1;
  int _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isMobile(double width) => width < 700;

  bool _isTablet(double width) => width >= 700 && width <= 1024;

  bool _isDesktop(double width) => width > 1024;

  void _handleMenuSelection(BuildContext context, int index) {
    if (index == _selectedMenuIndex) return;

    if (index == 0) {
      openAdminDashboard(context);
      return;
    }

    if (index == 1) {
      openPostApproval(context);
      return;
    }

    if (index == 2) {
      openAdminUsers(context);
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

  _ReportItem get _selectedReport {
    return _reports.firstWhere(
      (report) => report.id == _selectedReportId,
      orElse: () => _reports.first,
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
              _AdminTopbar(
                width: width,
                isMobile: isMobile,
                searchController: _searchController,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _isDesktop(width)
            ? 4
            : _isMobile(width)
                ? 1
                : 2;
        const spacing = 16.0;
        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * spacing)) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _reportStats
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

  Widget _buildFilterSection(double width) {
    final isMobile = _isMobile(width);
    final isTablet = _isTablet(width);

    final typeBox = _FilterDropdown(
      label: 'Loại báo cáo',
      value: _selectedType,
      items: _typeOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedType = value);
      },
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

    final priorityBox = _FilterDropdown(
      label: 'Mức độ ưu tiên',
      value: _selectedPriority,
      items: _priorityOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedPriority = value);
      },
    );

    final timeBox = _FilterDropdown(
      label: 'Thời gian',
      value: _selectedTime,
      items: _timeOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedTime = value);
      },
    );

    final filterButton = _FilterActionButton(
      label: 'Bộ lọc',
      icon: Icons.filter_alt_outlined,
      onTap: () {},
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
            Row(
              children: [
                Expanded(child: timeBox),
                const SizedBox(width: 12),
                Expanded(child: filterButton),
              ],
            ),
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
                const SizedBox(width: 12),
                filterButton,
                const SizedBox(width: 12),
                _RefreshButton(onTap: () {}),
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
          const SizedBox(width: 12),
          filterButton,
          const SizedBox(width: 12),
          _RefreshButton(onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildMainSection(double width) {
    final isMobile = _isMobile(width);
    final isDesktop = _isDesktop(width);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: _ReportTableCard(
              reports: _reports,
              selectedReportId: _selectedReportId,
              isCompact: false,
              currentPage: _currentPage,
              pageSize: _pageSize,
              onSelectReport: (report) {
                setState(() => _selectedReportId = report.id);
              },
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              onPageSizeChanged: (size) {
                if (size == null) return;
                setState(() => _pageSize = size);
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 320,
            child: _ReportDetailPanel(report: _selectedReport),
          ),
        ],
      );
    }

    return Column(
      children: [
        _ReportTableCard(
          reports: _reports,
          selectedReportId: _selectedReportId,
          isCompact: isMobile,
          currentPage: _currentPage,
          pageSize: _pageSize,
          onSelectReport: (report) {
            setState(() => _selectedReportId = report.id);
          },
          onPageChanged: (page) {
            setState(() => _currentPage = page);
          },
          onPageSizeChanged: (size) {
            if (size == null) return;
            setState(() => _pageSize = size);
          },
        ),
        const SizedBox(height: 16),
        _ReportDetailPanel(report: _selectedReport),
      ],
    );
  }
}

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
    required this.selectedReportId,
    required this.isCompact,
    required this.currentPage,
    required this.pageSize,
    required this.onSelectReport,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final List<_ReportItem> reports;
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
                  const Text(
                    'Tổng: 391 báo cáo',
                    style: TextStyle(
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
            separatorBuilder: (_, __) => const Divider(
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
                  _Avatar(name: report.sender, size: 30, color: report.color),
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
  const _ReportDetailPanel({required this.report});

  final _ReportItem report;

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
              Text(
                report.id,
                style: const TextStyle(
                  color: Color(0xFF1E2B3A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(label: report.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Được tạo: ${report.createdAt}',
                style: _smallMutedStyle,
              ),
              const Spacer(),
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
          const _RelatedListingCard(),
          const SizedBox(height: 18),
          const _DetailLabel('Người gửi báo cáo'),
          const SizedBox(height: 10),
          Row(
            children: [
              _Avatar(name: report.sender, size: 38, color: report.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.sender,
                      style: const TextStyle(
                        color: Color(0xFF1E2B3A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      report.senderEmail,
                      style: _smallMutedStyle,
                    ),
                  ],
                ),
              ),
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
          const _DetailLabel('Bằng chứng đính kèm (2)'),
          const SizedBox(height: 10),
          const _EvidenceRow(),
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
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PanelButton(
                  label: 'Cảnh báo chủ trọ',
                  icon: Icons.warning_amber_rounded,
                  foreground: const Color(0xFFF59E0B),
                  background: const Color(0xFFFFFAF0),
                  border: const Color(0xFFFAD7A0),
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PanelButton(
                  label: 'Bỏ qua',
                  icon: Icons.close_rounded,
                  foreground: const Color(0xFF52657A),
                  background: Colors.white,
                  border: const Color(0xFFE2EAF3),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PanelButton(
                  label: 'Đánh dấu đã xử lý',
                  icon: Icons.check_rounded,
                  foreground: Colors.white,
                  background: AppColors.blue,
                  border: AppColors.blue,
                  onTap: () {},
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
  const _RelatedListingCard();

  @override
  Widget build(BuildContext context) {
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
              gradient: const LinearGradient(
                colors: [Color(0xFFE7D8C8), Color(0xFFF3F6FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Color(0xFFB7A18C),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cho thuê phòng giá rẻ chỉ 500k/tháng',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF1E2B3A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Phòng trọ giá rẻ Gò Vấp',
                  style: TextStyle(
                    color: Color(0xFF7D8EA3),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Đăng bởi Nguyễn Văn Bình\n19/05/2025 08:30',
                  style: TextStyle(
                    color: Color(0xFF9AA6B5),
                    fontSize: 10,
                    height: 1.35,
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

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _EvidenceTile(icon: Icons.receipt_long_outlined, label: 'Ảnh chụp'),
        const SizedBox(width: 8),
        const _EvidenceTile(icon: Icons.article_outlined, label: 'Nội dung'),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2EAF3)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: Color(0xFF90A0B4), size: 20),
                SizedBox(height: 4),
                Text(
                  'Thêm bằng chứng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7D8EA3),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2EAF3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF7D8EA3), size: 20),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF52657A),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
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
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => onPageChanged(math.max(1, currentPage - 1)),
              ),
              for (final page in const [1, 2, 3])
                _PageNumberButton(
                  page: page,
                  isSelected: currentPage == page,
                  onTap: () => onPageChanged(page),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '...',
                  style: TextStyle(
                    color: Color(0xFF7D8EA3),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _PageNumberButton(
                page: 40,
                isSelected: currentPage == 40,
                onTap: () => onPageChanged(40),
              ),
              _PageIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => onPageChanged(math.min(40, currentPage + 1)),
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
          value: value,
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
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(data.icon, color: color, size: 20),
            const SizedBox(width: 14),
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
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: const Color(0xFF8EA0B4),
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
    case 'Tin giả':
      return AppColors.blue;
    case 'Nội dung không phù hợp':
      return const Color(0xFF9B5CFF);
    case 'Lừa đảo':
      return const Color(0xFFFF8A00);
    case 'Spam':
      return const Color(0xFF90A0B4);
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

const List<_AdminMenuItem> _adminMenus = [
  _AdminMenuItem(label: 'Tổng quan', icon: Icons.dashboard_outlined),
  _AdminMenuItem(label: 'Duyệt bài đăng', icon: Icons.fact_check_outlined),
  _AdminMenuItem(label: 'Người dùng', icon: Icons.group_outlined),
  _AdminMenuItem(label: 'Báo cáo', icon: Icons.bar_chart_rounded),
  _AdminMenuItem(label: 'Hỗ trợ', icon: Icons.support_agent_outlined),
  _AdminMenuItem(label: 'Cài đặt', icon: Icons.settings_outlined),
];

const List<String> _typeOptions = [
  'Tất cả',
  'Tin giả',
  'Nội dung không phù hợp',
  'Lừa đảo',
  'Spam',
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

const List<_ReportStat> _reportStats = [
  _ReportStat(
    title: 'Báo cáo mới',
    value: '23',
    changeText: '+21.1%',
    isPositive: false,
    icon: Icons.headset_mic_outlined,
    accent: Color(0xFF9B5CFF),
  ),
  _ReportStat(
    title: 'Đang xử lý',
    value: '56',
    changeText: '+8.2%',
    isPositive: false,
    icon: Icons.hourglass_empty_rounded,
    accent: Color(0xFFF59E0B),
  ),
  _ReportStat(
    title: 'Đã giải quyết',
    value: '312',
    changeText: '+15.7%',
    isPositive: true,
    icon: Icons.check_circle_outline_rounded,
    accent: Color(0xFF22B573),
  ),
  _ReportStat(
    title: 'Mức độ khẩn cấp cao',
    value: '7',
    changeText: '+16.7%',
    isPositive: false,
    icon: Icons.warning_amber_rounded,
    accent: Color(0xFFFF5B6E),
  ),
];

const List<_ReportItem> _reports = [
  _ReportItem(
    id: '#RC-2025-0519',
    title: 'Cho thuê phòng giá rẻ chỉ 500k/tháng',
    subtitle: 'Đăng trong Phòng trọ giá rẻ Gò Vấp',
    sender: 'Nguyễn Văn A',
    senderEmail: '@nguyenvana',
    type: 'Tin giả',
    priority: 'Cao',
    status: 'Mới',
    timeAgo: '10 phút trước',
    createdAt: '19/05/2025 09:15',
    description:
        'Bài đăng cung cấp thông tin giá thuê không đúng sự thật. Phòng thực tế không có với mức giá như trong bài.',
    color: Color(0xFF2F9BEF),
  ),
  _ReportItem(
    id: '#RC-2025-0518',
    title: 'Hình ảnh phản cảm trong bài đăng',
    subtitle: 'Đăng trong Phòng trọ Tân Bình',
    sender: 'Trần Thị Mai',
    senderEmail: '@tranthimai',
    type: 'Nội dung không phù hợp',
    priority: 'Cao',
    status: 'Đang xử lý',
    timeAgo: '35 phút trước',
    createdAt: '19/05/2025 08:50',
    description:
        'Người dùng báo cáo ảnh minh họa không phù hợp với nội dung thuê phòng.',
    color: Color(0xFF47C7B5),
  ),
  _ReportItem(
    id: '#RC-2025-0517',
    title: 'Yêu cầu chuyển tiền đặt cọc trước',
    subtitle: 'Đăng trong Phòng trọ Bình Thạnh',
    sender: 'Lê Minh Tuấn',
    senderEmail: '@leminhtuan',
    type: 'Lừa đảo',
    priority: 'Cao',
    status: 'Đang xử lý',
    timeAgo: '1 giờ trước',
    createdAt: '19/05/2025 08:05',
    description:
        'Bên đăng yêu cầu chuyển tiền cọc trước khi cho xem phòng, có dấu hiệu lừa đảo.',
    color: Color(0xFFF59E0B),
  ),
  _ReportItem(
    id: '#RC-2025-0516',
    title: 'Liên tục đăng tin quảng cáo',
    subtitle: 'Đăng trong Căn hộ dịch vụ Q.7',
    sender: 'Phạm Văn Hùng',
    senderEmail: '@phamvanhung',
    type: 'Spam',
    priority: 'Thấp',
    status: 'Mới',
    timeAgo: '2 giờ trước',
    createdAt: '19/05/2025 07:20',
    description:
        'Tài khoản gửi nhiều nội dung quảng cáo trùng lặp trong thời gian ngắn.',
    color: Color(0xFFFF8A00),
  ),
  _ReportItem(
    id: '#RC-2025-0515',
    title: 'Thông tin sai sự thật về vị trí',
    subtitle: 'Đăng trong Phòng trọ Thủ Đức',
    sender: 'Đỗ Thu Hằng',
    senderEmail: '@dothuhang',
    type: 'Tin giả',
    priority: 'Trung bình',
    status: 'Đã giải quyết',
    timeAgo: '3 giờ trước',
    createdAt: '19/05/2025 06:40',
    description:
        'Vị trí thực tế khác với mô tả trong bài đăng, gây nhầm lẫn cho người thuê.',
    color: Color(0xFF9B5CFF),
  ),
  _ReportItem(
    id: '#RC-2025-0514',
    title: 'Nội dung miệt thị người khác',
    subtitle: 'Đăng trong Phòng trọ Quận 1',
    sender: 'Hoàng Văn Duy',
    senderEmail: '@hoangvduy',
    type: 'Nội dung không phù hợp',
    priority: 'Cao',
    status: 'Đã giải quyết',
    timeAgo: '5 giờ trước',
    createdAt: '19/05/2025 04:10',
    description:
        'Mô tả bài đăng chứa ngôn từ không phù hợp, có thể ảnh hưởng cộng đồng.',
    color: Color(0xFF22B573),
  ),
  _ReportItem(
    id: '#RC-2025-0513',
    title: 'Đường link lạ trong bài đăng',
    subtitle: 'Đăng trong Phòng trọ Tân Phú',
    sender: 'Ngô Quang Huy',
    senderEmail: '@ngoquanghuy',
    type: 'Lừa đảo',
    priority: 'Cao',
    status: 'Đã giải quyết',
    timeAgo: '1 ngày trước',
    createdAt: '18/05/2025 20:35',
    description:
        'Bài đăng gắn đường link ngoài không rõ nguồn, có dấu hiệu thu thập thông tin.',
    color: Color(0xFF2F9BEF),
  ),
  _ReportItem(
    id: '#RC-2025-0512',
    title: 'Đăng tin trùng lặp nhiều lần',
    subtitle: 'Đăng trong Phòng trọ Gò Vấp',
    sender: 'Vũ Thanh Tâm',
    senderEmail: '@vuthanhtam',
    type: 'Spam',
    priority: 'Thấp',
    status: 'Đã giải quyết',
    timeAgo: '1 ngày trước',
    createdAt: '18/05/2025 18:20',
    description:
        'Một nội dung được đăng lặp lại nhiều lần ở nhiều khu vực khác nhau.',
    color: Color(0xFFFF5B6E),
  ),
];

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _ReportStat {
  const _ReportStat({
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
}
