import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/screens/admin/models/admin_user_model.dart';
import 'package:smart_room_finder/screens/admin/admin_navigation.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tableSearchController = TextEditingController();

  int _selectedMenuIndex = 2;
  String _selectedRole = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  String _selectedVerification = 'Tất cả';
  String _selectedUserId = '';
  int _currentPage = 1;
  int _pageSize = 10;
  List<AdminUserModel> _users = [];
  bool _isLoadingUsers = true;
  String? _userError;

  @override
  void initState() {
    super.initState();
    _tableSearchController.addListener(_handleUserSearchChanged);
    _fetchUsers();
  }

  @override
  void dispose() {
    _tableSearchController.removeListener(_handleUserSearchChanged);
    _searchController.dispose();
    _tableSearchController.dispose();
    super.dispose();
  }

  void _handleUserSearchChanged() {
    if (!mounted) return;
    setState(() {
      _currentPage = 1;
    });
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUsers = true;
      _userError = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final users = snapshot.docs.map(AdminUserModel.fromFirestore).toList()
        ..sort((a, b) {
          final left = a.createdAt;
          final right = b.createdAt;
          if (left == null && right == null) return 0;
          if (left == null) return 1;
          if (right == null) return -1;
          return right.compareTo(left);
        });

      if (!mounted) return;
      setState(() {
        _users = users;
        _selectedUserId = users.isNotEmpty ? users.first.id : '';
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userError = 'Không thể tải danh sách người dùng: $e';
        _isLoadingUsers = false;
      });
    }
  }

  void _showAdminSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showLockUserDialog(AdminUserModel user) async {
    if (user.isAdmin) {
      _showAdminSnackBar('Không thể khóa tài khoản Admin.', isError: true);
      return;
    }

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Khóa tài khoản',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn khóa tài khoản ${user.displayName}?',
              style: const TextStyle(
                color: Color(0xFF5C6D82),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập lý do khóa tài khoản',
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
                      const BorderSide(color: Color(0xFFFF5B6E), width: 1.4),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5B6E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Xác nhận khóa',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim().isEmpty
        ? 'Vi phạm quy định sử dụng'
        : reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true) return;
    await _lockUser(user, reason);
  }

  Future<void> _showUnlockUserDialog(AdminUserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Mở khóa tài khoản',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Bạn có chắc muốn mở khóa tài khoản ${user.displayName}?',
          style: const TextStyle(
            color: Color(0xFF5C6D82),
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Xác nhận mở khóa',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _unlockUser(user);
  }

  Future<void> _lockUser(AdminUserModel user, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'status': 'locked',
        'lockedReason': reason,
        'lockedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _fetchUsers();
      _showAdminSnackBar('Đã khóa tài khoản ${user.displayName}.');
    } catch (e) {
      _showAdminSnackBar(
        'Khóa tài khoản thất bại: $e',
        isError: true,
      );
    }
  }

  Future<void> _unlockUser(AdminUserModel user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'status': 'active',
        'lockedReason': '',
        'lockedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _fetchUsers();
      _showAdminSnackBar('Đã mở khóa tài khoản ${user.displayName}.');
    } catch (e) {
      _showAdminSnackBar(
        'Mở khóa tài khoản thất bại: $e',
        isError: true,
      );
    }
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

  List<AdminUserModel> get _filteredUsers {
    final query = _tableSearchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesRole =
          _selectedRole == 'Tất cả' || user.roleLabel == _selectedRole;
      final matchesStatus =
          _selectedStatus == 'Tất cả' || user.statusLabel == _selectedStatus;
      final matchesVerification = _selectedVerification == 'Tất cả' ||
          user.accountSetupLabel == _selectedVerification;
      final matchesSearch = query.isEmpty ||
          user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phoneNumber.toLowerCase().contains(query);

      return matchesRole &&
          matchesStatus &&
          matchesVerification &&
          matchesSearch;
    }).toList();
  }

  AdminUserModel? get _selectedUser {
    final users = _filteredUsers;
    if (users.isEmpty) return null;

    return users.firstWhere(
      (user) => user.id == _selectedUserId,
      orElse: () => users.first,
    );
  }

  List<_AdminUserStat> get _adminUserStats {
    final renters =
        _users.where((u) => u.role.trim().toLowerCase() == 'renter').length;
    final landlords =
        _users.where((u) => u.role.trim().toLowerCase() == 'landlord').length;
    final locked = _users.where((u) => u.isLocked).length;

    return [
      _AdminUserStat(
        title: 'Tổng người dùng',
        value: '${_users.length}',
        changeText: 'Dữ liệu từ Firestore',
        isPositive: true,
        icon: Icons.groups_2_outlined,
        accent: AppColors.blue,
      ),
      _AdminUserStat(
        title: 'Người thuê',
        value: '$renters',
        changeText: 'Vai trò người thuê',
        isPositive: true,
        icon: Icons.person_pin_circle_outlined,
        accent: const Color(0xFF22B573),
      ),
      _AdminUserStat(
        title: 'Chủ trọ',
        value: '$landlords',
        changeText: 'Vai trò chủ trọ',
        isPositive: true,
        icon: Icons.home_work_outlined,
        accent: const Color(0xFF9B5CFF),
      ),
      _AdminUserStat(
        title: 'Tài khoản bị khóa',
        value: '$locked',
        changeText: 'Trạng thái tạm khóa',
        isPositive: locked == 0,
        icon: Icons.lock_outline_rounded,
        accent: const Color(0xFFF59E0B),
      ),
    ];
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
        final sectionWidth = constraints.maxWidth;
        final crossAxisCount = _isDesktop(width)
            ? 4
            : _isMobile(width)
                ? 1
                : 2;
        const spacing = 16.0;
        final itemWidth =
            (sectionWidth - ((crossAxisCount - 1) * spacing)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _adminUserStats
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

    final roleBox = _FilterDropdown(
      label: 'Vai trò',
      value: _selectedRole,
      items: _roleOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedRole = value);
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

    final verificationBox = _FilterDropdown(
      label: 'Thiết lập tài khoản',
      value: _selectedVerification,
      items: _verificationOptions,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedVerification = value);
      },
    );

    final searchBox = _AdminSearchField(
      controller: _tableSearchController,
      hintText: 'Tìm theo tên, email, SĐT...',
    );

    final filterButton = _FilterActionButton(
      label: 'Bộ lọc',
      icon: Icons.filter_alt_outlined,
      onTap: () {},
    );

    final exportButton = _ExportButton(onTap: () {});

    if (isMobile) {
      return _AdminSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            roleBox,
            const SizedBox(height: 12),
            statusBox,
            const SizedBox(height: 12),
            verificationBox,
            const SizedBox(height: 12),
            searchBox,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: filterButton),
                const SizedBox(width: 12),
                Expanded(child: exportButton),
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
                Expanded(child: roleBox),
                const SizedBox(width: 12),
                Expanded(child: statusBox),
                const SizedBox(width: 12),
                Expanded(child: verificationBox),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: searchBox),
                const SizedBox(width: 12),
                filterButton,
                const SizedBox(width: 12),
                exportButton,
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
          SizedBox(width: 116, child: roleBox),
          const SizedBox(width: 12),
          SizedBox(width: 138, child: statusBox),
          const SizedBox(width: 12),
          SizedBox(width: 170, child: verificationBox),
          const SizedBox(width: 16),
          Expanded(child: searchBox),
          const SizedBox(width: 12),
          filterButton,
          const SizedBox(width: 12),
          exportButton,
        ],
      ),
    );
  }

  Widget _buildMainSection(double width) {
    final isMobile = _isMobile(width);
    final isDesktop = _isDesktop(width);
    final users = _filteredUsers;
    final selectedUser = _selectedUser;

    if (_isLoadingUsers) {
      return const _AdminStateCard(
        icon: Icons.hourglass_empty_rounded,
        title: 'Đang tải danh sách người dùng',
        message: 'Đang lấy dữ liệu người dùng từ Firestore.',
        showLoading: true,
      );
    }

    if (_userError != null) {
      return _AdminStateCard(
        icon: Icons.error_outline_rounded,
        title: 'Không thể tải dữ liệu',
        message: _userError!,
        actionLabel: 'Thử lại',
        onAction: _fetchUsers,
      );
    }

    if (users.isEmpty) {
      return const _AdminStateCard(
        icon: Icons.people_outline_rounded,
        title: 'Chưa có người dùng phù hợp',
        message: 'Thay đổi bộ lọc hoặc từ khóa tìm kiếm để xem dữ liệu khác.',
      );
    }

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: _UserTableCard(
              users: users,
              selectedUserId: _selectedUserId,
              isCompact: false,
              currentPage: _currentPage,
              pageSize: _pageSize,
              onSelectUser: (user) {
                setState(() => _selectedUserId = user.id);
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
            width: 280,
            child: _UserDetailPanel(
              user: selectedUser!,
              onLockUser: _showLockUserDialog,
              onUnlockUser: _showUnlockUserDialog,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _UserTableCard(
          users: users,
          selectedUserId: _selectedUserId,
          isCompact: isMobile,
          currentPage: _currentPage,
          pageSize: _pageSize,
          onSelectUser: (user) {
            setState(() => _selectedUserId = user.id);
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
        _UserDetailPanel(
          user: selectedUser!,
          onLockUser: _showLockUserDialog,
          onUnlockUser: _showUnlockUserDialog,
        ),
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

    final titleBlock = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quản lý người dùng',
          style: TextStyle(
            color: Color(0xFF1E2B3A),
            fontSize: 28,
            fontWeight: FontWeight.w800,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ProfileAvatar(size: 38),
              const SizedBox(width: 10),
              const Column(
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
              const SizedBox(width: 6),
              const Icon(
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
              Expanded(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 24),
                  child: titleBlock,
                ),
              ),
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

  final _AdminUserStat data;

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

class _UserTableCard extends StatelessWidget {
  const _UserTableCard({
    required this.users,
    required this.selectedUserId,
    required this.isCompact,
    required this.currentPage,
    required this.pageSize,
    required this.onSelectUser,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final List<AdminUserModel> users;
  final String selectedUserId;
  final bool isCompact;
  final int currentPage;
  final int pageSize;
  final ValueChanged<AdminUserModel> onSelectUser;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (!isCompact) const _UserTableHeader(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Color(0xFFEAF0F7),
            ),
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserTableRow(
                user: user,
                isSelected: user.id == selectedUserId,
                isCompact: isCompact,
                onTap: () => onSelectUser(user),
              );
            },
          ),
          _PaginationBar(
            currentPage: currentPage,
            pageSize: pageSize,
            totalCount: users.length,
            onPageChanged: onPageChanged,
            onPageSizeChanged: onPageSizeChanged,
          ),
        ],
      ),
    );
  }
}

class _AdminStateCard extends StatelessWidget {
  const _AdminStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.showLoading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool showLoading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLoading)
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            Icon(icon, size: 38, color: AppColors.blue),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1E2B3A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7D8EA3),
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            _FilterActionButton(
              label: actionLabel!,
              icon: Icons.refresh_rounded,
              onTap: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

class _UserTableHeader extends StatelessWidget {
  const _UserTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 34,
            child: Icon(
              Icons.check_box_outline_blank_rounded,
              color: Color(0xFFC2CEDA),
              size: 18,
            ),
          ),
          _HeaderCell('Tên', flex: 3),
          _HeaderCell('Email', flex: 3),
          _HeaderCell('Vai trò', flex: 2),
          _HeaderCell('Số điện thoại', flex: 2),
          _HeaderCell('Trạng thái', flex: 2),
          _HeaderCell('Ngày tham gia', flex: 2),
          SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _UserTableRow extends StatelessWidget {
  const _UserTableRow({
    required this.user,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final AdminUserModel user;
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
                  _ProfileAvatar(user: user, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
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
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7D8EA3),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz_rounded, color: Color(0xFF8EA0B4)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RoleChip(label: user.roleLabel),
                  _StatusChip(label: user.statusLabel),
                  _MetaPill(icon: Icons.phone_outlined, text: user.phone),
                  _MetaPill(icon: Icons.calendar_today_rounded, text: user.joinedAt),
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
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        color: isSelected ? const Color(0xFFEAF4FF) : Colors.white,
        child: Row(
          children: [
            SizedBox(width: 34, child: _SelectionBox(isSelected: isSelected)),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _ProfileAvatar(user: user, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1E2B3A),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 3, child: _TableText(user.email)),
            Expanded(flex: 2, child: _RoleChip(label: user.roleLabel)),
            Expanded(flex: 2, child: _TableText(user.phone)),
            Expanded(flex: 2, child: _StatusChip(label: user.statusLabel)),
            Expanded(flex: 2, child: _TableText(user.joinedAt)),
            const SizedBox(
              width: 32,
              child: Icon(Icons.more_horiz_rounded, color: Color(0xFF8EA0B4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDetailPanel extends StatelessWidget {
  const _UserDetailPanel({
    required this.user,
    required this.onLockUser,
    required this.onUnlockUser,
  });

  final AdminUserModel user;
  final ValueChanged<AdminUserModel> onLockUser;
  final ValueChanged<AdminUserModel> onUnlockUser;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFF90A0B4),
              tooltip: 'Đóng',
            ),
          ),
          _ProfileAvatar(user: user, size: 76),
          const SizedBox(height: 14),
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1E2B3A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _RoleChip(label: user.roleLabel),
          const SizedBox(height: 20),
          _ContactLine(icon: Icons.email_outlined, text: user.email),
          const SizedBox(height: 10),
          _ContactLine(icon: Icons.phone_outlined, text: user.phone),
          const SizedBox(height: 10),
          _ContactLine(icon: Icons.location_on_outlined, text: user.displayLocation),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE5EDF6)),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Trạng thái thiết lập tài khoản',
              style: _detailLabelStyle,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: _StatusChip(label: user.accountSetupLabel),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              user.accountSetupDescription,
              style: const TextStyle(
                color: Color(0xFF8EA0B4),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5EDF6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DetailMetric(
                    title: 'Bài đăng',
                    value: '${user.postCount}',
                    subtitle: 'Chưa thống kê',
                  ),
                ),
                Container(width: 1, height: 72, color: const Color(0xFFE5EDF6)),
                Expanded(
                  child: _DetailMetric(
                    title: 'Báo cáo nhận',
                    value: '${user.reportCount}',
                    subtitle: 'Chưa thống kê',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (user.isLocked)
            _SuccessButton(
              label: 'Mở khóa',
              icon: Icons.lock_open_outlined,
              onTap: () => onUnlockUser(user),
            )
          else
            _DangerButton(
              label: 'Khóa tài khoản',
              icon: Icons.lock_outline_rounded,
              onTap: () => onLockUser(user),
            ),
          const SizedBox(height: 10),
          _GhostButton(
            label: 'Xem chi tiết',
            icon: Icons.arrow_forward_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final int currentPage;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int?> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $totalCount người dùng',
            style: const TextStyle(
              color: Color(0xFF7D8EA3),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageNumberButton(
                page: 1,
                isSelected: true,
                onTap: () => onPageChanged(1),
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
  const _TableText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF63748A),
        fontSize: 11,
        fontWeight: FontWeight.w700,
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

class _AdminSearchField extends StatelessWidget {
  const _AdminSearchField({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF99A6B5),
            fontSize: 12,
          ),
          suffixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9BA7B5),
            size: 20,
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
          foregroundColor: const Color(0xFF4C5F75),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2EAF3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.file_download_outlined, size: 17),
        label: const Text(
          'Xuất dữ liệu',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    this.user,
    required this.size,
  });

  final AdminUserModel? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final source = user;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  (source?.avatarColor ?? const Color(0xFF8ECDF7))
                      .withValues(alpha: 0.92),
                  (source?.avatarColor ?? const Color(0xFF47C7B5))
                      .withValues(alpha: 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: source != null && source.profileImageUrl.trim().isNotEmpty
                ? Image.network(
                    source.profileImageUrl.trim(),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _AvatarInitial(source: source, size: size),
                  )
                : _AvatarInitial(source: source, size: size),
          ),
        ),
        if (source?.isOnline ?? false)
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: const Color(0xFF22B573),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({
    required this.source,
    required this.size,
  });

  final AdminUserModel? source;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _getInitial(source?.displayName ?? 'Admin'),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isOwner = label == 'Chủ trọ';
    final color = isOwner ? const Color(0xFF9B5CFF) : AppColors.blue;
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

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF7F8EA0)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF5C6D82),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _detailLabelStyle),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E2B3A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8EA0B4),
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PanelButton(
      label: label,
      icon: icon,
      onTap: onTap,
      foreground: const Color(0xFFFF5B6E),
      background: const Color(0xFFFFF7F7),
      border: const Color(0xFFFFC9D0),
    );
  }
}

class _SuccessButton extends StatelessWidget {
  const _SuccessButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PanelButton(
      label: label,
      icon: icon,
      onTap: onTap,
      foreground: const Color(0xFF16A66A),
      background: const Color(0xFFF4FFF9),
      border: const Color(0xFFC8F3DD),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PanelButton(
      label: label,
      icon: icon,
      onTap: onTap,
      foreground: AppColors.blueDark,
      background: const Color(0xFFF7FAFD),
      border: const Color(0xFFE2EAF3),
      iconAfter: true,
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.foreground,
    required this.background,
    required this.border,
    this.iconAfter = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color foreground;
  final Color background;
  final Color border;
  final bool iconAfter;

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, size: 16, color: foreground),
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
    ];

    return SizedBox(
      width: double.infinity,
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
              children: iconAfter ? children.reversed.toList() : children,
            ),
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
          width: page > 99 ? 42 : 30,
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
  color: Color(0xFF7D8EA3),
  fontSize: 12,
  fontWeight: FontWeight.w800,
);

Color _statusColor(String status) {
  switch (status) {
    case 'Hoạt động':
    case 'Đã hoàn tất':
      return const Color(0xFF22B573);
    case 'Chưa hoàn tất':
      return const Color(0xFFF59E0B);
    case 'Tạm khóa':
      return const Color(0xFFFF5B6E);
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

const List<String> _roleOptions = ['Tất cả', 'Người thuê', 'Chủ trọ'];
const List<String> _statusOptions = ['Tất cả', 'Hoạt động', 'Tạm khóa'];
const List<String> _verificationOptions = [
  'Tất cả',
  'Đã hoàn tất',
  'Chưa hoàn tất',
];


class _AdminMenuItem {
  const _AdminMenuItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _AdminUserStat {
  const _AdminUserStat({
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

