import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
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
  String _selectedListingId = _moderationListings.first.id;
  int _selectedPreviewIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _tableSearchController.dispose();
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

    if (index == 0) {
      openAdminDashboard(context);
      return;
    }

    setState(() => _selectedMenuIndex = index);
  }

  _ModerationListing get _selectedListing {
    return _moderationListings.firstWhere(
      (item) => item.id == _selectedListingId,
      orElse: () => _moderationListings.first,
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
    final selectedListing = _selectedListing;

    if (_isMobile(width)) {
      return Column(
        children: [
          _ModerationListCard(
            isCompact: true,
            selectedSort: _selectedSort,
            selectedListingId: _selectedListingId,
            listings: _moderationListings,
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
          ),
          const SizedBox(height: 16),
          _ListingDetailPanel(
            listing: selectedListing,
            isCompact: true,
            selectedPreviewIndex: _selectedPreviewIndex,
            onPreviewChanged: (index) {
              setState(() => _selectedPreviewIndex = index);
            },
          ),
        ],
      );
    }

    if (_isTablet(width)) {
      return Column(
        children: [
          _ModerationListCard(
            isCompact: false,
            selectedSort: _selectedSort,
            selectedListingId: _selectedListingId,
            listings: _moderationListings,
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
          ),
          const SizedBox(height: 16),
          _ListingDetailPanel(
            listing: selectedListing,
            isCompact: false,
            selectedPreviewIndex: _selectedPreviewIndex,
            onPreviewChanged: (index) {
              setState(() => _selectedPreviewIndex = index);
            },
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: _ModerationListCard(
            isCompact: false,
            selectedSort: _selectedSort,
            selectedListingId: _selectedListingId,
            listings: _moderationListings,
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
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: _ListingDetailPanel(
            listing: selectedListing,
            isCompact: false,
            selectedPreviewIndex: _selectedPreviewIndex,
            onPreviewChanged: (index) {
              setState(() => _selectedPreviewIndex = index);
            },
          ),
        ),
      ],
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
                  _MockRoomImage(
                    label: listing.galleryLabels.first,
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
                _MockRoomImage(
                  label: listing.galleryLabels.first,
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
  });

  final _ModerationListing listing;
  final bool isCompact;
  final int selectedPreviewIndex;
  final ValueChanged<int> onPreviewChanged;

  @override
  Widget build(BuildContext context) {
    final safePreviewIndex = selectedPreviewIndex
        .clamp(0, listing.galleryLabels.length - 1)
        .toInt();

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
                _MockRoomImage(
                  label: listing.galleryLabels[safePreviewIndex],
                  width: double.infinity,
                  height: 220,
                  borderRadius: 20,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: listing.galleryLabels.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == safePreviewIndex;
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
                              color: isSelected
                                  ? AppColors.blueDark
                                  : const Color(0xFFE2EAF3),
                            ),
                          ),
                          child: _MockRoomImage(
                            label: listing.galleryLabels[index],
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
                  child: _MockRoomImage(
                    label: listing.galleryLabels[safePreviewIndex],
                    width: double.infinity,
                    height: 220,
                    borderRadius: 20,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 110,
                  child: Column(
                    children: [
                      for (var i = 0; i < listing.galleryLabels.length; i++) ...[
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
                                _MockRoomImage(
                                  label: listing.galleryLabels[i],
                                  width: 104,
                                  height: 58,
                                  borderRadius: 12,
                                ),
                                if (i == listing.galleryLabels.length - 1)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.38),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+ 6 ảnh',
                                        style: TextStyle(
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
                        if (i != listing.galleryLabels.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
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
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _ModerationActionButton(
                  label: 'Yêu cầu bổ sung',
                  icon: Icons.edit_note_rounded,
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _ModerationActionButton(
                  label: 'Từ chối',
                  icon: Icons.close_rounded,
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  onTap: () {},
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
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModerationActionButton(
                    label: 'Yêu cầu bổ sung',
                    icon: Icons.edit_note_rounded,
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModerationActionButton(
                    label: 'Từ chối',
                    icon: Icons.close_rounded,
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
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

  final _ModerationDocument document;

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
              color: document.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(document.icon, color: document.accent, size: 20),
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

  final _ReviewHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: entry.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(entry.icon, color: entry.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.time,
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

class _MockRoomImage extends StatelessWidget {
  const _MockRoomImage({
    required this.label,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  final String label;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          colors: [Color(0xFFEFE5DD), Color(0xFFD6E1EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height * 0.24,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F8).withValues(alpha: 0.86),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(borderRadius),
                  bottomRight: Radius.circular(borderRadius),
                ),
              ),
            ),
          ),
          Positioned(
            left: width * 0.1,
            top: height * 0.18,
            child: Container(
              width: width * 0.18,
              height: height * 0.48,
              decoration: BoxDecoration(
                color: const Color(0xFF8A6B54).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            right: width * 0.08,
            top: height * 0.18,
            child: Container(
              width: width * 0.18,
              height: height * 0.22,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            right: width * 0.12,
            bottom: height * 0.28,
            child: Container(
              width: width * 0.48,
              height: height * 0.18,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5F1).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF6C7A8C).withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// MOCK DATA
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

final List<_ModerationListing> _moderationListings = [
  _ModerationListing(
    id: 'room_1',
    roomCode: 'SRF-10293',
    title: 'Phòng trọ quận 10, TP.HCM',
    subtitle: 'Có cửa sổ, giờ giấc tự do',
    shortAddress: 'Phòng trọ quận 10, TP.HCM',
    area: 'Q.10, TP.HCM',
    address: 'Đường 3/2, Phường 12, Quận 10, TP.HCM',
    status: 'Chờ xác minh',
    postedAtShort: '19/05/2025\n09:15',
    postedAtFull: '19/05/2025 09:15',
    updatedAtFull: '19/05/2025 09:20',
    ownerName: 'Nguyễn Văn Bình',
    ownerPhone: '0901 234 567',
    ownerEmail: 'binh.nv@gmail.com',
    price: '3.200.000 đ/tháng',
    galleryLabels: ['Phòng ngủ', 'Cửa sổ', 'Khu bếp', 'Lối vào'],
    amenities: const [
      'Wi-Fi',
      'Điều hòa',
      'Tủ lạnh',
      'Máy giặt',
      'Nhà vệ sinh riêng',
      'Giờ giấc tự do',
    ],
    description:
        'Phòng rộng 20m², có cửa sổ thoáng mát, ánh sáng tự nhiên. Khu vực an ninh, yên tĩnh, gần chợ, siêu thị và các tiện ích. Giờ giấc tự do, không chung chủ.',
    documents: [
      _ModerationDocument(
        title: 'Sổ đỏ / Hợp đồng nhà',
        fileType: 'PDF',
        fileSize: '1.2 MB',
        icon: Icons.picture_as_pdf_rounded,
        accent: const Color(0xFFEF6A5B),
      ),
      _ModerationDocument(
        title: 'CMND / CCCD chủ trọ',
        fileType: 'JPG',
        fileSize: '824 KB',
        icon: Icons.badge_outlined,
        accent: const Color(0xFF22B573),
      ),
      _ModerationDocument(
        title: 'Giấy phép kinh doanh',
        fileType: 'PDF',
        fileSize: '1.1 MB',
        icon: Icons.description_outlined,
        accent: const Color(0xFFF59E0B),
      ),
    ],
    reviewHistory: [
      _ReviewHistoryEntry(
        time: '19/05/2025 09:15',
        title: 'Hệ thống tạo bài đăng mới',
        subtitle: 'Bài đăng được gửi lên để chờ kiểm duyệt.',
        icon: Icons.add_circle_outline_rounded,
        accent: AppColors.blue,
      ),
      _ReviewHistoryEntry(
        time: '19/05/2025 09:20',
        title: 'Đồng bộ ảnh và giấy tờ',
        subtitle: 'Ảnh minh họa và tài liệu pháp lý đã được đính kèm đầy đủ.',
        icon: Icons.sync_rounded,
        accent: AppColors.tealDark,
      ),
    ],
  ),
  _ModerationListing(
    id: 'room_2',
    roomCode: 'SRF-10292',
    title: 'Phòng trọ gần Đại Bách Khoa',
    subtitle: 'Nội thất đủ, vào ở ngay',
    shortAddress: 'Phòng trọ gần Đại Bách Khoa',
    area: 'Q. Hai Bà Trưng, Hà Nội',
    address: 'Trần Đại Nghĩa, Hai Bà Trưng, Hà Nội',
    status: 'Đã xác minh',
    postedAtShort: '19/05/2025\n08:45',
    postedAtFull: '19/05/2025 08:45',
    updatedAtFull: '19/05/2025 09:00',
    ownerName: 'Trần Thị Mai',
    ownerPhone: '0912 345 678',
    ownerEmail: 'mai.tt@gmail.com',
    price: '3.800.000 đ/tháng',
    galleryLabels: ['Nội thất', 'Bàn học', 'Cửa sổ', 'Kệ bếp'],
    amenities: const [
      'Wi-Fi',
      'Nóng lạnh',
      'Bãi xe',
      'Máy giặt',
    ],
    description:
        'Phòng sạch sẽ, nội thất cơ bản, phù hợp sinh viên và người đi làm. Khu dân cư yên tĩnh, gần trường và bến xe buýt.',
    documents: [
      _ModerationDocument(
        title: 'Hợp đồng thuê',
        fileType: 'PDF',
        fileSize: '950 KB',
        icon: Icons.picture_as_pdf_rounded,
        accent: const Color(0xFFEF6A5B),
      ),
    ],
    reviewHistory: [
      _ReviewHistoryEntry(
        time: '19/05/2025 08:45',
        title: 'Bài đăng đã xác minh',
        subtitle: 'Admin Lan đã xác minh và cho phép hiển thị công khai.',
        icon: Icons.verified_rounded,
        accent: const Color(0xFF22B573),
      ),
    ],
  ),
  _ModerationListing(
    id: 'room_3',
    roomCode: 'SRF-10291',
    title: 'Phòng full nội thất, Quận 7',
    subtitle: 'Gần Lotte Mart',
    shortAddress: 'Phòng full nội thất, Quận 7',
    area: 'Q.7, TP.HCM',
    address: 'Nguyễn Thị Thập, Quận 7, TP.HCM',
    status: 'Chờ xác minh',
    postedAtShort: '19/05/2025\n08:30',
    postedAtFull: '19/05/2025 08:30',
    updatedAtFull: '19/05/2025 08:35',
    ownerName: 'Lê Minh Tuấn',
    ownerPhone: '0938 234 888',
    ownerEmail: 'tuanlm@gmail.com',
    price: '4.200.000 đ/tháng',
    galleryLabels: ['Giường ngủ', 'Ban công', 'Tủ đồ', 'WC riêng'],
    amenities: const ['Ban công', 'Máy lạnh', 'Máy nước nóng'],
    description:
        'Phòng mới sơn sửa, nội thất hoàn chỉnh, phù hợp ở lâu dài. Gần trung tâm thương mại và khu ăn uống.',
    documents: [],
    reviewHistory: [],
  ),
  _ModerationListing(
    id: 'room_4',
    roomCode: 'SRF-10290',
    title: 'Phòng trọ giá rẻ Gò Vấp',
    subtitle: 'Giờ giấc tự do',
    shortAddress: 'Phòng trọ giá rẻ Gò Vấp',
    area: 'Gò Vấp, TP.HCM',
    address: 'Phan Huy Ích, Gò Vấp, TP.HCM',
    status: 'Cần bổ sung',
    postedAtShort: '19/05/2025\n07:50',
    postedAtFull: '19/05/2025 07:50',
    updatedAtFull: '19/05/2025 08:10',
    ownerName: 'Phạm Văn Hùng',
    ownerPhone: '0898 200 123',
    ownerEmail: 'hungpv@gmail.com',
    price: '2.500.000 đ/tháng',
    galleryLabels: ['Mặt tiền', 'Phòng chính', 'Kệ bếp', 'Sân trước'],
    amenities: const ['Giờ giấc tự do', 'Bãi xe'],
    description:
        'Phòng phù hợp người đi làm, giá tốt, gần chợ và tuyến xe buýt. Hiện cần cập nhật thêm giấy tờ xác minh chủ sở hữu.',
    documents: [],
    reviewHistory: [
      _ReviewHistoryEntry(
        time: '19/05/2025 08:10',
        title: 'Yêu cầu bổ sung giấy tờ',
        subtitle: 'Admin yêu cầu cập nhật ảnh mặt tiền và giấy tờ pháp lý.',
        icon: Icons.edit_note_rounded,
        accent: const Color(0xFF3B82F6),
      ),
    ],
  ),
  _ModerationListing(
    id: 'room_5',
    roomCode: 'SRF-10289',
    title: 'Phòng mới xây, Tân Bình',
    subtitle: 'Có thang máy, hầm xe',
    shortAddress: 'Phòng mới xây, Tân Bình',
    area: 'Tân Bình, TP.HCM',
    address: 'Cộng Hòa, Tân Bình, TP.HCM',
    status: 'Đã xác minh',
    postedAtShort: '19/05/2025\n07:20',
    postedAtFull: '19/05/2025 07:20',
    updatedAtFull: '19/05/2025 07:45',
    ownerName: 'Đỗ Thu Hằng',
    ownerPhone: '0988 320 456',
    ownerEmail: 'hangdt@gmail.com',
    price: '5.100.000 đ/tháng',
    galleryLabels: ['Phòng mới', 'Sảnh', 'Thang máy', 'Ban công'],
    amenities: const ['Thang máy', 'Hầm xe', 'Khóa vân tay'],
    description: 'Tòa nhà mới xây, nội thất cơ bản và hệ thống an ninh tốt.',
    documents: [],
    reviewHistory: [],
  ),
  _ModerationListing(
    id: 'room_6',
    roomCode: 'SRF-10288',
    title: 'Phòng trọ Cầu Giấy',
    subtitle: 'Gần công viên Cầu Giấy',
    shortAddress: 'Phòng trọ Cầu Giấy',
    area: 'Cầu Giấy, Hà Nội',
    address: 'Dịch Vọng, Cầu Giấy, Hà Nội',
    status: 'Từ chối',
    postedAtShort: '18/05/2025\n21:10',
    postedAtFull: '18/05/2025 21:10',
    updatedAtFull: '18/05/2025 21:45',
    ownerName: 'Hoàng Anh Dũng',
    ownerPhone: '0905 444 999',
    ownerEmail: 'dungha@gmail.com',
    price: '3.000.000 đ/tháng',
    galleryLabels: ['Phòng chính', 'Nhà vệ sinh', 'Lối đi', 'Tầng trệt'],
    amenities: const ['Gần công viên', 'An ninh'],
    description: 'Thông tin địa chỉ và giấy tờ chưa khớp với nội dung bài đăng.',
    documents: [],
    reviewHistory: [],
  ),
];

// =========================
// MODELS
// =========================
class _AdminMenuItem {
  const _AdminMenuItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _ModerationListing {
  const _ModerationListing({
    required this.id,
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
    required this.galleryLabels,
    required this.amenities,
    required this.description,
    required this.documents,
    required this.reviewHistory,
  });

  final String id;
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
  final List<String> galleryLabels;
  final List<String> amenities;
  final String description;
  final List<_ModerationDocument> documents;
  final List<_ReviewHistoryEntry> reviewHistory;
}

class _ModerationDocument {
  const _ModerationDocument({
    required this.title,
    required this.fileType,
    required this.fileSize,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String fileType;
  final String fileSize;
  final IconData icon;
  final Color accent;
}

class _ReviewHistoryEntry {
  const _ReviewHistoryEntry({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
}
