import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/screens/admin/admin_navigation.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ticketSearchController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  int _selectedMenuIndex = 4;
  int _selectedTabIndex = 0;
  String _selectedTicketId = _supportTickets.first.id;
  String _selectedFilter = 'Bộ lọc';
  String _selectedSort = 'Sắp xếp: Mới nhất';
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    _ticketSearchController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  bool _isMobile(double width) => width < 700;

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

    if (index == 3) {
      openAdminReports(context);
      return;
    }

    if (index == 5) {
      openAdminSettings(context);
      return;
    }

    setState(() => _selectedMenuIndex = index);
  }

  _SupportTicket get _selectedTicket {
    return _supportTickets.firstWhere(
      (ticket) => ticket.id == _selectedTicketId,
      orElse: () => _supportTickets.first,
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
          children: _supportStats
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

  Widget _buildMainSection(double width) {
    final isDesktop = _isDesktop(width);

    final queue = _SupportQueueCard(
      tickets: _supportTickets,
      selectedTicketId: _selectedTicketId,
      selectedTabIndex: _selectedTabIndex,
      selectedFilter: _selectedFilter,
      selectedSort: _selectedSort,
      currentPage: _currentPage,
      isCompact: !isDesktop,
      searchController: _ticketSearchController,
      onSelectTicket: (ticket) {
        setState(() => _selectedTicketId = ticket.id);
      },
      onTabChanged: (index) {
        setState(() => _selectedTabIndex = index);
      },
      onFilterChanged: (value) {
        if (value == null) return;
        setState(() => _selectedFilter = value);
      },
      onSortChanged: (value) {
        if (value == null) return;
        setState(() => _selectedSort = value);
      },
      onPageChanged: (page) {
        setState(() => _currentPage = page);
      },
    );

    final detail = _SupportDetailPanel(
      ticket: _selectedTicket,
      replyController: _replyController,
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: queue),
          const SizedBox(width: 16),
          SizedBox(width: 430, child: detail),
        ],
      );
    }

    return Column(
      children: [
        queue,
        const SizedBox(height: 16),
        detail,
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
      'Quản lý hỗ trợ',
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
          hintText: 'Tìm kiếm...',
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

  final _SupportStat data;

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

class _SupportQueueCard extends StatelessWidget {
  const _SupportQueueCard({
    required this.tickets,
    required this.selectedTicketId,
    required this.selectedTabIndex,
    required this.selectedFilter,
    required this.selectedSort,
    required this.currentPage,
    required this.isCompact,
    required this.searchController,
    required this.onSelectTicket,
    required this.onTabChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onPageChanged,
  });

  final List<_SupportTicket> tickets;
  final String selectedTicketId;
  final int selectedTabIndex;
  final String selectedFilter;
  final String selectedSort;
  final int currentPage;
  final bool isCompact;
  final TextEditingController searchController;
  final ValueChanged<_SupportTicket> onSelectTicket;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String?> onFilterChanged;
  final ValueChanged<String?> onSortChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SupportTabs(
            selectedIndex: selectedTabIndex,
            onChanged: onTabChanged,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: isCompact
                ? Column(
                    children: [
                      _QueueSearchField(controller: searchController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SmallDropdown(
                              value: selectedFilter,
                              items: _filterOptions,
                              icon: Icons.tune_rounded,
                              onChanged: onFilterChanged,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmallDropdown(
                              value: selectedSort,
                              items: _sortOptions,
                              onChanged: onSortChanged,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _QueueSearchField(controller: searchController),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 112,
                        child: _SmallDropdown(
                          value: selectedFilter,
                          items: _filterOptions,
                          icon: Icons.tune_rounded,
                          onChanged: onFilterChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 170,
                        child: _SmallDropdown(
                          value: selectedSort,
                          items: _sortOptions,
                          onChanged: onSortChanged,
                        ),
                      ),
                    ],
                  ),
          ),
          if (!isCompact) const _SupportTableHeader(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Color(0xFFEAF0F7),
            ),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _SupportTableRow(
                ticket: ticket,
                isSelected: ticket.id == selectedTicketId,
                isCompact: isCompact,
                onTap: () => onSelectTicket(ticket),
              );
            },
          ),
          _PaginationBar(
            currentPage: currentPage,
            onPageChanged: onPageChanged,
          ),
        ],
      ),
    );
  }
}

class _SupportTabs extends StatelessWidget {
  const _SupportTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            _SupportTabButton(
              tab: _tabs[i],
              isSelected: selectedIndex == i,
              onTap: () => onChanged(i),
            ),
        ],
      ),
    );
  }
}

class _SupportTabButton extends StatelessWidget {
  const _SupportTabButton({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _SupportTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              tab.label,
              style: TextStyle(
                color: isSelected ? AppColors.blueDark : const Color(0xFF52657A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEAF4FF)
                    : const Color(0xFFF1F5FA),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${tab.count}',
                style: TextStyle(
                  color: isSelected ? AppColors.blueDark : const Color(0xFF7D8EA3),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTableHeader extends StatelessWidget {
  const _SupportTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: const Color(0xFFF7FAFD),
      child: const Row(
        children: [
          SizedBox(width: 32),
          _HeaderCell('Mã hỗ trợ', flex: 2),
          _HeaderCell('Người gửi', flex: 3),
          _HeaderCell('Chủ đề', flex: 4),
          _HeaderCell('Loại', flex: 2),
          _HeaderCell('Ưu tiên', flex: 2),
          _HeaderCell('Trạng thái', flex: 2),
          _HeaderCell('Cập nhật', flex: 2),
        ],
      ),
    );
  }
}

class _SupportTableRow extends StatelessWidget {
  const _SupportTableRow({
    required this.ticket,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final _SupportTicket ticket;
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
                  _SelectionBox(isSelected: isSelected),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ticket.id,
                      style: const TextStyle(
                        color: AppColors.blueDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusChip(label: ticket.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E2B3A),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Avatar(name: ticket.sender, size: 30, color: ticket.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ticket.sender,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF52657A),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CategoryChip(label: ticket.category),
                  _PriorityChip(label: ticket.priority),
                  _MetaPill(icon: Icons.schedule_rounded, text: ticket.updatedAt),
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
            SizedBox(width: 32, child: _SelectionBox(isSelected: isSelected)),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.id, style: _strongBlueStyle),
                  const SizedBox(height: 3),
                  Text(ticket.createdAgo, style: _smallMutedStyle),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _Avatar(name: ticket.sender, size: 30, color: ticket.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.sender,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1E2B3A),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          ticket.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _smallMutedStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                ticket.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E2B3A),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(flex: 2, child: _CategoryChip(label: ticket.category)),
            Expanded(flex: 2, child: _PriorityChip(label: ticket.priority)),
            Expanded(flex: 2, child: _StatusChip(label: ticket.status)),
            Expanded(flex: 2, child: Text(ticket.updatedAt, style: _smallMutedStyle)),
          ],
        ),
      ),
    );
  }
}

class _SupportDetailPanel extends StatelessWidget {
  const _SupportDetailPanel({
    required this.ticket,
    required this.replyController,
  });

  final _SupportTicket ticket;
  final TextEditingController replyController;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ticket.id, style: _detailTitleStyle),
              const SizedBox(width: 8),
              _StatusChip(label: ticket.status),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
                color: const Color(0xFF90A0B4),
                tooltip: 'Thêm',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.close_rounded),
                color: const Color(0xFF90A0B4),
                tooltip: 'Đóng',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.subject,
            style: const TextStyle(
              color: Color(0xFF1E2B3A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Avatar(name: ticket.sender, size: 34, color: ticket.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.sender, style: _senderNameStyle),
                    Text(ticket.email, style: _smallMutedStyle),
                  ],
                ),
              ),
              Icon(Icons.phone_outlined, color: const Color(0xFF8EA0B4), size: 16),
              const SizedBox(width: 6),
              Text(ticket.phone, style: _smallMutedStyle),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(icon: Icons.folder_outlined, text: 'Loại: ${ticket.category}'),
              _MetaPill(icon: Icons.flag_outlined, text: 'Ưu tiên: ${ticket.priority}'),
              _MetaPill(icon: Icons.schedule_rounded, text: 'Tạo lúc: ${ticket.createdAt}'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('Hội thoại', style: _detailSectionStyle),
              const Spacer(),
              Text('Hôm nay', style: _smallMutedStyle),
            ],
          ),
          const SizedBox(height: 14),
          _ConversationMessage(
            name: ticket.sender,
            time: '09:28',
            message:
                'Chào admin, mình không thể đăng nhập vào tài khoản dù đã nhập đúng email và mật khẩu. Hệ thống báo "Email hoặc mật khẩu không đúng". Mong được hỗ trợ.',
            color: ticket.color,
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Hệ thống đã gán ticket cho bộ phận Hỗ trợ tài khoản      09:28',
              textAlign: TextAlign.center,
              style: _smallMutedStyle,
            ),
          ),
          const SizedBox(height: 10),
          const _ConversationMessage(
            name: 'Nguyễn Văn Bình (Hỗ trợ)',
            time: '09:35',
            message:
                'Chào bạn Lan,\nCảm ơn bạn đã liên hệ. Bạn vui lòng thử đặt lại mật khẩu theo hướng dẫn tại email. Nếu vẫn không được, bạn vui lòng cung cấp ảnh chụp màn hình lỗi để chúng tôi kiểm tra thêm nhé.',
            color: AppColors.blue,
            isAdmin: true,
          ),
          const SizedBox(height: 10),
          _ConversationMessage(
            name: ticket.sender,
            time: '09:41',
            message:
                'Mình đã thử đặt lại nhưng không nhận được email. Đây là ảnh chụp màn hình lỗi mình gặp.',
            color: ticket.color,
            attachmentName: 'loi_dang_nhap.png',
            attachmentSize: '342 KB',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PanelButton(
                  label: 'Phản hồi',
                  icon: Icons.reply_rounded,
                  foreground: Colors.white,
                  background: AppColors.blue,
                  border: AppColors.blue,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PanelButton(
                  label: 'Chuyển bộ phận',
                  icon: Icons.swap_horiz_rounded,
                  foreground: const Color(0xFF52657A),
                  background: Colors.white,
                  border: const Color(0xFFE2EAF3),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PanelButton(
                  label: 'Đánh dấu hoàn tất',
                  icon: Icons.check_rounded,
                  foreground: const Color(0xFF16A66A),
                  background: const Color(0xFFF4FFF9),
                  border: const Color(0xFFC8F3DD),
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ReplyBox(controller: replyController),
        ],
      ),
    );
  }
}

class _ConversationMessage extends StatelessWidget {
  const _ConversationMessage({
    required this.name,
    required this.time,
    required this.message,
    required this.color,
    this.isAdmin = false,
    this.attachmentName,
    this.attachmentSize,
  });

  final String name;
  final String time;
  final String message;
  final Color color;
  final bool isAdmin;
  final String? attachmentName;
  final String? attachmentSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isAdmin) ...[
          _Avatar(name: name, size: 30, color: color),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAdmin ? const Color(0xFFEAF4FF) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2EAF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E2B3A),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(time, style: _smallMutedStyle),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF52657A),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (attachmentName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2EAF3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: AppColors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachmentName!,
                              style: const TextStyle(
                                color: Color(0xFF52657A),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              attachmentSize ?? '',
                              style: _smallMutedStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isAdmin) ...[
          const SizedBox(width: 10),
          _Avatar(name: name, size: 30, color: color),
        ],
      ],
    );
  }
}

class _ReplyBox extends StatelessWidget {
  const _ReplyBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2EAF3)),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Nhập nội dung phản hồi...',
              hintStyle: TextStyle(
                color: Color(0xFF9AA6B5),
                fontSize: 12,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.attach_file_rounded),
                color: const Color(0xFF8EA0B4),
                tooltip: 'Đính kèm',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.image_outlined),
                color: const Color(0xFF8EA0B4),
                tooltip: 'Ảnh',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.emoji_emotions_outlined),
                color: const Color(0xFF8EA0B4),
                tooltip: 'Cảm xúc',
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text(
                  'Gửi',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.onPageChanged,
  });

  final int currentPage;
  final ValueChanged<int> onPageChanged;

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
          const Text(
            'Hiển thị 1 - 8 trong tổng số 232',
            style: TextStyle(
              color: Color(0xFF7D8EA3),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => onPageChanged(math.max(1, currentPage - 1)),
              ),
              for (final page in const [1, 2, 3, 4, 5])
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
                page: 29,
                isSelected: currentPage == 29,
                onTap: () => onPageChanged(29),
              ),
              _PageIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => onPageChanged(math.min(29, currentPage + 1)),
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

class _QueueSearchField extends StatelessWidget {
  const _QueueSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Tìm mã hỗ trợ, người gửi, chủ đề...',
          hintStyle: const TextStyle(
            color: Color(0xFF99A6B5),
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9BA7B5),
            size: 18,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2EAF3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.blue),
          ),
        ),
      ),
    );
  }
}

class _SmallDropdown extends StatelessWidget {
  const _SmallDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? icon;

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
            prefixIcon: icon == null
                ? null
                : Icon(icon!, size: 16, color: const Color(0xFF7D8EA3)),
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
            fontWeight: FontWeight.w800,
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

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.blue : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? AppColors.blue : const Color(0xFFC8D3DF),
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(label);
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
            color: isSelected ? AppColors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF66768A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

const TextStyle _strongBlueStyle = TextStyle(
  color: AppColors.blueDark,
  fontSize: 11,
  fontWeight: FontWeight.w900,
);

const TextStyle _smallMutedStyle = TextStyle(
  color: Color(0xFF8EA0B4),
  fontSize: 10,
  fontWeight: FontWeight.w600,
);

const TextStyle _detailTitleStyle = TextStyle(
  color: Color(0xFF1E2B3A),
  fontSize: 14,
  fontWeight: FontWeight.w900,
);

const TextStyle _detailSectionStyle = TextStyle(
  color: Color(0xFF1E2B3A),
  fontSize: 14,
  fontWeight: FontWeight.w900,
);

const TextStyle _senderNameStyle = TextStyle(
  color: Color(0xFF1E2B3A),
  fontSize: 12,
  fontWeight: FontWeight.w900,
);

Color _categoryColor(String value) {
  switch (value) {
    case 'Tài khoản':
      return AppColors.blue;
    case 'Bài đăng':
      return const Color(0xFF7D8EA3);
    case 'Thanh toán':
      return const Color(0xFF9B5CFF);
    case 'Báo cáo':
      return const Color(0xFFFF5B6E);
    case 'Liên hệ':
      return const Color(0xFF52657A);
    default:
      return const Color(0xFF22B573);
  }
}

Color _priorityColor(String value) {
  switch (value) {
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

Color _statusColor(String value) {
  switch (value) {
    case 'Mới':
      return AppColors.blue;
    case 'Đang xử lý':
      return const Color(0xFFF59E0B);
    case 'Chờ phản hồi':
      return const Color(0xFF9B5CFF);
    case 'Đã đóng':
      return const Color(0xFF22B573);
    default:
      return const Color(0xFF52657A);
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

const List<_SupportTab> _tabs = [
  _SupportTab(label: 'Tất cả', count: 232),
  _SupportTab(label: 'Chưa trả lời', count: 28),
  _SupportTab(label: 'Đang xử lý', count: 36),
  _SupportTab(label: 'Đã đóng', count: 156),
];

const List<String> _filterOptions = [
  'Bộ lọc',
  'Tài khoản',
  'Bài đăng',
  'Thanh toán',
  'Cao',
];

const List<String> _sortOptions = [
  'Sắp xếp: Mới nhất',
  'Sắp xếp: Cũ nhất',
  'Ưu tiên cao',
  'Cập nhật gần nhất',
];

const List<_SupportStat> _supportStats = [
  _SupportStat(
    title: 'Yêu cầu mới',
    value: '28',
    changeText: '+27.3%',
    isPositive: false,
    icon: Icons.headset_mic_outlined,
    accent: Color(0xFF9B5CFF),
  ),
  _SupportStat(
    title: 'Đang phản hồi',
    value: '36',
    changeText: '+8.5%',
    isPositive: false,
    icon: Icons.forum_outlined,
    accent: Color(0xFFF59E0B),
  ),
  _SupportStat(
    title: 'Đã hoàn tất',
    value: '156',
    changeText: '+4.2%',
    isPositive: true,
    icon: Icons.check_circle_outline_rounded,
    accent: Color(0xFF22B573),
  ),
  _SupportStat(
    title: 'Mức độ ưu tiên cao',
    value: '12',
    changeText: '+20.0%',
    isPositive: false,
    icon: Icons.warning_amber_rounded,
    accent: Color(0xFFFF5B6E),
  ),
];

const List<_SupportTicket> _supportTickets = [
  _SupportTicket(
    id: 'SRF-2025-0521',
    createdAgo: '2 phút trước',
    sender: 'Nguyễn Thị Lan',
    email: 'lan.nguyen@gmail.com',
    phone: '0987 654 321',
    subject: 'Không đăng nhập được tài khoản',
    category: 'Tài khoản',
    priority: 'Cao',
    status: 'Mới',
    updatedAt: '2 phút trước',
    createdAt: '19/05/2025 09:28',
    color: Color(0xFF2F9BEF),
  ),
  _SupportTicket(
    id: 'SRF-2025-0520',
    createdAgo: '15 phút trước',
    sender: 'Trần Minh Quân',
    email: 'quan.tran@gmail.com',
    phone: '0901 111 222',
    subject: 'Thông tin phòng không chính xác',
    category: 'Bài đăng',
    priority: 'Trung bình',
    status: 'Đang xử lý',
    updatedAt: '15 phút trước',
    createdAt: '19/05/2025 09:12',
    color: Color(0xFF47C7B5),
  ),
  _SupportTicket(
    id: 'SRF-2025-0519',
    createdAgo: '1 giờ trước',
    sender: 'Lê Hoàng Yến',
    email: 'yen.le@smus.edu.vn',
    phone: '0902 222 333',
    subject: 'Vấn đề thanh toán khi đặt phòng',
    category: 'Thanh toán',
    priority: 'Cao',
    status: 'Đang xử lý',
    updatedAt: '1 giờ trước',
    createdAt: '19/05/2025 08:30',
    color: Color(0xFFF59E0B),
  ),
  _SupportTicket(
    id: 'SRF-2025-0518',
    createdAgo: '2 giờ trước',
    sender: 'Phạm Quốc Bảo',
    email: 'bao.pham@gmail.com',
    phone: '0903 333 444',
    subject: 'Theo dõi báo cáo bài đăng vi phạm',
    category: 'Báo cáo',
    priority: 'Cao',
    status: 'Chờ phản hồi',
    updatedAt: '2 giờ trước',
    createdAt: '19/05/2025 07:44',
    color: Color(0xFFFF5B6E),
  ),
  _SupportTicket(
    id: 'SRF-2025-0517',
    createdAgo: '3 giờ trước',
    sender: 'Đỗ Thu Hương',
    email: 'thu.huong@gmail.com',
    phone: '0904 444 555',
    subject: 'Không thể liên hệ với chủ phòng',
    category: 'Liên hệ',
    priority: 'Thấp',
    status: 'Đang xử lý',
    updatedAt: '3 giờ trước',
    createdAt: '19/05/2025 06:50',
    color: Color(0xFF9B5CFF),
  ),
  _SupportTicket(
    id: 'SRF-2025-0516',
    createdAgo: '5 giờ trước',
    sender: 'Nguyễn Văn Duy',
    email: 'duy.nguyen@gmail.com',
    phone: '0905 555 666',
    subject: 'Yêu cầu hoàn tiền đặt cọc',
    category: 'Thanh toán',
    priority: 'Cao',
    status: 'Mới',
    updatedAt: '5 giờ trước',
    createdAt: '19/05/2025 04:30',
    color: Color(0xFF22B573),
  ),
  _SupportTicket(
    id: 'SRF-2025-0515',
    createdAgo: '1 ngày trước',
    sender: 'Trần Thị Mai',
    email: 'mai.tran@gmail.com',
    phone: '0906 666 777',
    subject: 'Cần hỗ trợ đổi thông tin',
    category: 'Tài khoản',
    priority: 'Thấp',
    status: 'Đã đóng',
    updatedAt: '1 ngày trước',
    createdAt: '18/05/2025 20:20',
    color: Color(0xFF2F9BEF),
  ),
  _SupportTicket(
    id: 'SRF-2025-0514',
    createdAgo: '1 ngày trước',
    sender: 'Hoàng Anh Tuấn',
    email: 'tuan.hoang@gmail.com',
    phone: '0907 777 888',
    subject: 'Phòng đã thuê nhưng đã được đăng lại',
    category: 'Bài đăng',
    priority: 'Trung bình',
    status: 'Đã đóng',
    updatedAt: '1 ngày trước',
    createdAt: '18/05/2025 18:05',
    color: Color(0xFFFF8A00),
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

class _SupportTab {
  const _SupportTab({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;
}

class _SupportStat {
  const _SupportStat({
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

class _SupportTicket {
  const _SupportTicket({
    required this.id,
    required this.createdAgo,
    required this.sender,
    required this.email,
    required this.phone,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.updatedAt,
    required this.createdAt,
    required this.color,
  });

  final String id;
  final String createdAgo;
  final String sender;
  final String email;
  final String phone;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final String updatedAt;
  final String createdAt;
  final Color color;
}
