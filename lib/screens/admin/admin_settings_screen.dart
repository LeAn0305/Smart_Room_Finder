import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/screens/admin/admin_navigation.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _platformNameController =
      TextEditingController(text: 'Smart Room Finder');
  final TextEditingController _supportEmailController =
      TextEditingController(text: 'support@smartroomfinder.vn');
  final TextEditingController _hotlineController =
      TextEditingController(text: '1900 1234');

  int _selectedMenuIndex = 5;
  String _timezone = 'GMT+7 (Asia/Ho Chi Minh)';
  String _language = 'Tiếng Việt';
  String _currency = 'VND (Việt Nam Đồng)';
  String _backupFrequency = 'Hàng ngày';
  String _backupTime = '02:30 AM';
  String _backupRetention = '30 ngày';
  bool _autoFlagUnverified = true;
  bool _requireOwnerDocs = true;
  bool _imageModeration = true;
  bool _hideUnverified = false;
  bool _requiredEmailVerification = true;
  bool _lockAfterFailedLogin = true;
  bool _criticalReportNotice = true;
  bool _emailNotice = true;
  bool _pushNotice = true;
  bool _inAppNotice = true;
  bool _lightTheme = true;
  String _density = 'Vừa';
  String _corner = 'Thẳng';

  @override
  void dispose() {
    _searchController.dispose();
    _platformNameController.dispose();
    _supportEmailController.dispose();
    _hotlineController.dispose();
    super.dispose();
  }

  bool _isMobile(double width) => width < 700;

  bool _isTablet(double width) => width >= 700 && width <= 1100;

  bool _isDesktop(double width) => width > 1100;

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

    if (index == 4) {
      openAdminSupport(context);
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
              _buildSettingsGrid(width),
              const SizedBox(height: 16),
              _ActionBar(isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGrid(double width) {
    final general = Column(
      children: [
        _GeneralSettingsCard(
          platformNameController: _platformNameController,
          supportEmailController: _supportEmailController,
          hotlineController: _hotlineController,
          timezone: _timezone,
          language: _language,
          currency: _currency,
          onTimezoneChanged: (value) {
            if (value == null) return;
            setState(() => _timezone = value);
          },
          onLanguageChanged: (value) {
            if (value == null) return;
            setState(() => _language = value);
          },
          onCurrencyChanged: (value) {
            if (value == null) return;
            setState(() => _currency = value);
          },
        ),
        const SizedBox(height: 16),
        _SecuritySettingsCard(
          requiredEmailVerification: _requiredEmailVerification,
          lockAfterFailedLogin: _lockAfterFailedLogin,
          criticalReportNotice: _criticalReportNotice,
          onEmailVerificationChanged: (value) {
            setState(() => _requiredEmailVerification = value);
          },
          onLockAfterFailedLoginChanged: (value) {
            setState(() => _lockAfterFailedLogin = value);
          },
          onCriticalReportNoticeChanged: (value) {
            setState(() => _criticalReportNotice = value);
          },
        ),
        const SizedBox(height: 16),
        _DisplaySettingsCard(
          lightTheme: _lightTheme,
          density: _density,
          corner: _corner,
          onThemeChanged: (value) {
            setState(() => _lightTheme = value);
          },
          onDensityChanged: (value) {
            setState(() => _density = value);
          },
          onCornerChanged: (value) {
            setState(() => _corner = value);
          },
        ),
      ],
    );

    final operation = Column(
      children: [
        _ModerationSettingsCard(
          autoFlagUnverified: _autoFlagUnverified,
          requireOwnerDocs: _requireOwnerDocs,
          imageModeration: _imageModeration,
          hideUnverified: _hideUnverified,
          onAutoFlagChanged: (value) {
            setState(() => _autoFlagUnverified = value);
          },
          onRequireOwnerDocsChanged: (value) {
            setState(() => _requireOwnerDocs = value);
          },
          onImageModerationChanged: (value) {
            setState(() => _imageModeration = value);
          },
          onHideUnverifiedChanged: (value) {
            setState(() => _hideUnverified = value);
          },
        ),
        const SizedBox(height: 16),
        _NotificationSettingsCard(
          emailNotice: _emailNotice,
          pushNotice: _pushNotice,
          inAppNotice: _inAppNotice,
          onEmailChanged: (value) {
            setState(() => _emailNotice = value);
          },
          onPushChanged: (value) {
            setState(() => _pushNotice = value);
          },
          onInAppChanged: (value) {
            setState(() => _inAppNotice = value);
          },
        ),
        const SizedBox(height: 16),
        _BackupSettingsCard(
          frequency: _backupFrequency,
          time: _backupTime,
          retention: _backupRetention,
          onFrequencyChanged: (value) {
            if (value == null) return;
            setState(() => _backupFrequency = value);
          },
          onTimeChanged: (value) {
            if (value == null) return;
            setState(() => _backupTime = value);
          },
          onRetentionChanged: (value) {
            if (value == null) return;
            setState(() => _backupRetention = value);
          },
        ),
      ],
    );

    const monitoring = Column(
      children: [
        _SystemStatusCard(),
        SizedBox(height: 16),
        _ActivityLogCard(),
      ],
    );

    if (_isDesktop(width)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: general),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: operation),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: monitoring),
        ],
      );
    }

    if (_isTablet(width)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: general),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                operation,
                const SizedBox(height: 16),
                monitoring,
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        general,
        const SizedBox(height: 16),
        operation,
        const SizedBox(height: 16),
        monitoring,
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
      'Cài đặt hệ thống',
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

class _GeneralSettingsCard extends StatelessWidget {
  const _GeneralSettingsCard({
    required this.platformNameController,
    required this.supportEmailController,
    required this.hotlineController,
    required this.timezone,
    required this.language,
    required this.currency,
    required this.onTimezoneChanged,
    required this.onLanguageChanged,
    required this.onCurrencyChanged,
  });

  final TextEditingController platformNameController;
  final TextEditingController supportEmailController;
  final TextEditingController hotlineController;
  final String timezone;
  final String language;
  final String currency;
  final ValueChanged<String?> onTimezoneChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '1. Cài đặt chung',
      child: Column(
        children: [
          _TextSettingField(label: 'Tên nền tảng', controller: platformNameController),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TextSettingField(
                  label: 'Email hỗ trợ',
                  controller: supportEmailController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TextSettingField(
                  label: 'Số hotline',
                  controller: hotlineController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DropdownSettingField(
                  label: 'Múi giờ',
                  value: timezone,
                  items: _timezoneOptions,
                  onChanged: onTimezoneChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownSettingField(
                  label: 'Ngôn ngữ',
                  value: language,
                  items: _languageOptions,
                  onChanged: onLanguageChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownSettingField(
                  label: 'Đơn vị tiền tệ',
                  value: currency,
                  items: _currencyOptions,
                  onChanged: onCurrencyChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModerationSettingsCard extends StatelessWidget {
  const _ModerationSettingsCard({
    required this.autoFlagUnverified,
    required this.requireOwnerDocs,
    required this.imageModeration,
    required this.hideUnverified,
    required this.onAutoFlagChanged,
    required this.onRequireOwnerDocsChanged,
    required this.onImageModerationChanged,
    required this.onHideUnverifiedChanged,
  });

  final bool autoFlagUnverified;
  final bool requireOwnerDocs;
  final bool imageModeration;
  final bool hideUnverified;
  final ValueChanged<bool> onAutoFlagChanged;
  final ValueChanged<bool> onRequireOwnerDocsChanged;
  final ValueChanged<bool> onImageModerationChanged;
  final ValueChanged<bool> onHideUnverifiedChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '2. Cài đặt xác minh & kiểm duyệt',
      child: Column(
        children: [
          _SwitchSettingRow(
            icon: Icons.verified_user_outlined,
            iconColor: AppColors.blue,
            title: 'Tự động gắn nhãn "Chưa xác minh"',
            subtitle: 'Tự động gắn nhãn cho bài đăng chưa xác minh.',
            value: autoFlagUnverified,
            onChanged: onAutoFlagChanged,
          ),
          const _SettingDivider(),
          _SwitchSettingRow(
            icon: Icons.home_work_outlined,
            iconColor: const Color(0xFF9B5CFF),
            title: 'Yêu cầu giấy tờ chủ trọ',
            subtitle: 'Bắt buộc chủ trọ xác minh giấy tờ tùy thân.',
            value: requireOwnerDocs,
            onChanged: onRequireOwnerDocsChanged,
          ),
          const _SettingDivider(),
          _SwitchSettingRow(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFFFF5B6E),
            title: 'Kiểm duyệt hình ảnh',
            subtitle: 'Kiểm tra hình ảnh trước khi hiển thị công khai.',
            value: imageModeration,
            onChanged: onImageModerationChanged,
          ),
          const _SettingDivider(),
          _SwitchSettingRow(
            icon: Icons.visibility_off_outlined,
            iconColor: const Color(0xFF7D8EA3),
            title: 'Cho phép hiển thị bài chưa xác minh trên trang chủ',
            subtitle: 'Hiển thị bài chưa xác minh ở mục riêng.',
            value: hideUnverified,
            onChanged: onHideUnverifiedChanged,
          ),
        ],
      ),
    );
  }
}

class _SecuritySettingsCard extends StatelessWidget {
  const _SecuritySettingsCard({
    required this.requiredEmailVerification,
    required this.lockAfterFailedLogin,
    required this.criticalReportNotice,
    required this.onEmailVerificationChanged,
    required this.onLockAfterFailedLoginChanged,
    required this.onCriticalReportNoticeChanged,
  });

  final bool requiredEmailVerification;
  final bool lockAfterFailedLogin;
  final bool criticalReportNotice;
  final ValueChanged<bool> onEmailVerificationChanged;
  final ValueChanged<bool> onLockAfterFailedLoginChanged;
  final ValueChanged<bool> onCriticalReportNoticeChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '3. Cài đặt người dùng & bảo mật',
      child: Column(
        children: [
          _SwitchSettingRow(
            icon: Icons.manage_accounts_outlined,
            iconColor: const Color(0xFFFF8A00),
            title: 'Xác thực email bắt buộc',
            subtitle: 'Yêu cầu xác thực email khi đăng ký tài khoản.',
            value: requiredEmailVerification,
            onChanged: onEmailVerificationChanged,
          ),
          const _SettingDivider(),
          _SwitchSettingRow(
            icon: Icons.notifications_active_outlined,
            iconColor: const Color(0xFFFF5B6E),
            title: 'Khóa tài khoản sau nhiều lần đăng nhập sai',
            subtitle: 'Tạm khóa sau 5 lần đăng nhập sai liên tiếp.',
            value: lockAfterFailedLogin,
            onChanged: onLockAfterFailedLoginChanged,
          ),
          const _SettingDivider(),
          _SwitchSettingRow(
            icon: Icons.report_gmailerrorred_outlined,
            iconColor: const Color(0xFF22B573),
            title: 'Bật thông báo báo cáo khẩn',
            subtitle: 'Nhận ngay thông báo khi có báo cáo khẩn cấp.',
            value: criticalReportNotice,
            onChanged: onCriticalReportNoticeChanged,
          ),
          const _SettingDivider(),
          const _ChevronSettingRow(
            icon: Icons.grid_view_rounded,
            title: 'Phân quyền admin',
            subtitle: 'Cho phép phân quyền chi tiết cho quản trị viên.',
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsCard extends StatelessWidget {
  const _NotificationSettingsCard({
    required this.emailNotice,
    required this.pushNotice,
    required this.inAppNotice,
    required this.onEmailChanged,
    required this.onPushChanged,
    required this.onInAppChanged,
  });

  final bool emailNotice;
  final bool pushNotice;
  final bool inAppNotice;
  final ValueChanged<bool> onEmailChanged;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onInAppChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '4. Cài đặt thông báo',
      child: Column(
        children: [
          _SwitchSettingRow(
            icon: Icons.mail_outline_rounded,
            iconColor: AppColors.blue,
            title: 'Thông báo qua Email',
            subtitle: 'Gửi email cho admin về hoạt động quan trọng.',
            value: emailNotice,
            onChanged: onEmailChanged,
          ),
          const _SettingDivider(),
          _SwitchSettingRow(
            icon: Icons.notifications_none_rounded,
            iconColor: const Color(0xFF9B5CFF),
            title: 'Thông báo Push',
            subtitle: 'Gửi thông báo đẩy khi cần duyệt.',
            value: pushNotice,
            onChanged: onPushChanged,
          ),
          const _SettingDivider(),
          _SwitchSettingRow(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF22B573),
            title: 'Thông báo trong ứng dụng',
            subtitle: 'Hiển thị thông báo trong hệ thống.',
            value: inAppNotice,
            onChanged: onInAppChanged,
          ),
        ],
      ),
    );
  }
}

class _DisplaySettingsCard extends StatelessWidget {
  const _DisplaySettingsCard({
    required this.lightTheme,
    required this.density,
    required this.corner,
    required this.onThemeChanged,
    required this.onDensityChanged,
    required this.onCornerChanged,
  });

  final bool lightTheme;
  final String density;
  final String corner;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onDensityChanged;
  final ValueChanged<String> onCornerChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '5. Giao diện & hiển thị',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingLabel('Chế độ giao diện'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  label: 'Sáng',
                  icon: Icons.wb_sunny_outlined,
                  isSelected: lightTheme,
                  onTap: () => onThemeChanged(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SegmentButton(
                  label: 'Tự động',
                  icon: Icons.desktop_windows_outlined,
                  isSelected: !lightTheme,
                  onTap: () => onThemeChanged(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SettingLabel('Màu chủ đạo'),
          const SizedBox(height: 9),
          const _ColorSwatches(),
          const SizedBox(height: 16),
          const _SettingLabel('Độ bo góc'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final item in _cornerOptions) ...[
                Expanded(
                  child: _TinyChoice(
                    label: item,
                    isSelected: corner == item,
                    onTap: () => onCornerChanged(item),
                  ),
                ),
                if (item != _cornerOptions.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const _SettingLabel('Mật độ hiển thị'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final item in _densityOptions) ...[
                Expanded(
                  child: _TinyChoice(
                    label: item,
                    isSelected: density == item,
                    onTap: () => onDensityChanged(item),
                  ),
                ),
                if (item != _densityOptions.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BackupSettingsCard extends StatelessWidget {
  const _BackupSettingsCard({
    required this.frequency,
    required this.time,
    required this.retention,
    required this.onFrequencyChanged,
    required this.onTimeChanged,
    required this.onRetentionChanged,
  });

  final String frequency;
  final String time;
  final String retention;
  final ValueChanged<String?> onFrequencyChanged;
  final ValueChanged<String?> onTimeChanged;
  final ValueChanged<String?> onRetentionChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '6. Sao lưu & bảo trì',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DropdownSettingField(
                  label: 'Tần suất sao lưu tự động',
                  value: frequency,
                  items: _backupFrequencyOptions,
                  onChanged: onFrequencyChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownSettingField(
                  label: 'Thời gian sao lưu',
                  value: time,
                  items: _backupTimeOptions,
                  onChanged: onTimeChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownSettingField(
                  label: 'Giữ bản sao lưu',
                  value: retention,
                  items: _backupRetentionOptions,
                  onChanged: onRetentionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SettingLabel('Hành động'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OutlineActionButton(
                  label: 'Sao lưu ngay',
                  icon: Icons.cloud_upload_outlined,
                  color: AppColors.blue,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OutlineActionButton(
                  label: 'Xóa bản sao cũ',
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFFF5B6E),
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

class _SystemStatusCard extends StatelessWidget {
  const _SystemStatusCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '7. Trạng thái hệ thống',
      child: Column(
        children: const [
          _SystemStatusRow(
            icon: Icons.api_outlined,
            title: 'Trạng thái hệ thống',
            subtitle: 'Tất cả dịch vụ đang hoạt động tốt.',
            badge: 'Ổn định',
            color: Color(0xFF22B573),
          ),
          _SettingDivider(),
          _SystemStatusRow(
            icon: Icons.history_rounded,
            title: 'Sao lưu gần nhất',
            subtitle: 'Tự động mỗi ngày 02:30 AM',
            badge: '19/05/2025 02:30',
            color: Color(0xFF7D8EA3),
          ),
          _SettingDivider(),
          _StorageStatusRow(),
          _SettingDivider(),
          _SystemStatusRow(
            icon: Icons.description_outlined,
            title: 'Phiên bản hệ thống',
            subtitle: 'Cập nhật: 15/05/2025',
            badge: 'v1.0.0',
            color: Color(0xFF9B5CFF),
          ),
          _SettingDivider(),
          _SystemStatusRow(
            icon: Icons.verified_outlined,
            title: 'Kết nối cơ sở dữ liệu',
            subtitle: 'Độ trễ: 12ms',
            badge: 'Đồng bộ tốt',
            color: Color(0xFF22B573),
          ),
        ],
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '8. Nhật ký hoạt động',
      trailing: TextButton(
        onPressed: () {},
        child: const Text(
          'Xem tất cả',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      child: Column(
        children: const [
          _ActivityLogItem(
            initial: 'A',
            color: AppColors.blue,
            title: 'Cập nhật cài đặt xác minh',
            subtitle: 'Admin • 19/05/2025 09:30\nThay đổi yêu cầu giấy tờ chủ trọ',
          ),
          _ActivityLogItem(
            initial: 'A',
            color: AppColors.blue,
            title: 'Thay đổi email hỗ trợ',
            subtitle: 'Admin • 19/05/2025 08:45\nsupport@smartroomfinder.vn',
          ),
          _ActivityLogItem(
            initial: 'A',
            color: Color(0xFFF59E0B),
            title: 'Bật thông báo khẩn',
            subtitle: 'Admin • 18/05/2025 16:20\nBật thông báo báo cáo khẩn',
          ),
          _ActivityLogItem(
            initial: 'S',
            color: Color(0xFF22B573),
            title: 'Cập nhật phiên bản hệ thống',
            subtitle: 'System • 18/05/2025 02:30\nNâng cấp lên v1.0.0',
          ),
          _ActivityLogItem(
            initial: 'A',
            color: AppColors.blue,
            title: 'Xuất cấu hình hệ thống',
            subtitle: 'Admin • 17/05/2025 14:10\nXuất file cấu hình hệ thống',
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final restore = _FooterButton(
      label: 'Khôi phục mặc định',
      icon: Icons.restore_rounded,
      foreground: const Color(0xFF52657A),
      background: Colors.white,
      border: const Color(0xFFDCE6F2),
      onTap: () {},
    );
    final export = _FooterButton(
      label: 'Xuất cấu hình',
      icon: Icons.file_download_outlined,
      foreground: const Color(0xFF52657A),
      background: Colors.white,
      border: const Color(0xFFDCE6F2),
      onTap: () {},
    );
    final save = _FooterButton(
      label: 'Lưu thay đổi',
      icon: Icons.save_outlined,
      foreground: Colors.white,
      background: AppColors.blue,
      border: AppColors.blue,
      onTap: () {},
    );

    return _AdminSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: isMobile
          ? Column(
              children: [
                restore,
                const SizedBox(height: 10),
                export,
                const SizedBox(height: 10),
                save,
              ],
            )
          : Row(
              children: [
                SizedBox(width: 210, child: restore),
                const Spacer(),
                SizedBox(width: 180, child: export),
                const SizedBox(width: 16),
                SizedBox(width: 220, child: save),
              ],
            ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E2B3A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _TextSettingField extends StatelessWidget {
  const _TextSettingField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingLabel(label),
        const SizedBox(height: 7),
        SizedBox(
          height: 42,
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Color(0xFF253548),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            decoration: _inputDecoration(),
          ),
        ),
      ],
    );
  }
}

class _DropdownSettingField extends StatelessWidget {
  const _DropdownSettingField({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingLabel(label),
        const SizedBox(height: 7),
        SizedBox(
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
              decoration: _inputDecoration(),
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
        ),
      ],
    );
  }
}

class _SwitchSettingRow extends StatelessWidget {
  const _SwitchSettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBox(icon: icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _settingTitleStyle),
              const SizedBox(height: 4),
              Text(subtitle, style: _settingSubtitleStyle),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: AppColors.blue,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ChevronSettingRow extends StatelessWidget {
  const _ChevronSettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBox(icon: icon, color: AppColors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _settingTitleStyle),
              const SizedBox(height: 4),
              Text(subtitle, style: _settingSubtitleStyle),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF90A0B4)),
      ],
    );
  }
}

class _SystemStatusRow extends StatelessWidget {
  const _SystemStatusRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBox(icon: icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _settingTitleStyle),
              const SizedBox(height: 4),
              Text(subtitle, style: _settingSubtitleStyle),
            ],
          ),
        ),
        _Badge(label: badge, color: color),
      ],
    );
  }
}

class _StorageStatusRow extends StatelessWidget {
  const _StorageStatusRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _IconBox(icon: Icons.storage_outlined, color: AppColors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Expanded(child: Text('Dung lượng lưu trữ', style: _settingTitleStyle)),
                  Text('245.6 GB / 500 GB', style: _settingTitleStyle),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  minHeight: 8,
                  value: 0.49,
                  backgroundColor: Color(0xFFEAF1F8),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
                ),
              ),
              const SizedBox(height: 5),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('49%', style: _settingSubtitleStyle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityLogItem extends StatelessWidget {
  const _ActivityLogItem({
    required this.initial,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final String initial;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: const Color(0xFFE1EAF4),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _settingTitleStyle),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: _settingSubtitleStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.blue : const Color(0xFFE2EAF3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.blueDark : const Color(0xFF7D8EA3),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.blueDark : const Color(0xFF52657A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyChoice extends StatelessWidget {
  const _TinyChoice({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.blue : const Color(0xFFE2EAF3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.blueDark : const Color(0xFF7D8EA3),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _swatchColors.length; i++) ...[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _swatchColors[i],
              shape: BoxShape.circle,
            ),
            child: i == 0
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null,
          ),
          if (i != _swatchColors.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
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
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SettingLabel extends StatelessWidget {
  const _SettingLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF66768A),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SettingDivider extends StatelessWidget {
  const _SettingDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: Color(0xFFE5EDF6)),
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

InputDecoration _inputDecoration() {
  return InputDecoration(
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
  );
}

String _getInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

const TextStyle _settingTitleStyle = TextStyle(
  color: Color(0xFF1E2B3A),
  fontSize: 12,
  fontWeight: FontWeight.w900,
);

const TextStyle _settingSubtitleStyle = TextStyle(
  color: Color(0xFF8EA0B4),
  fontSize: 10,
  height: 1.35,
  fontWeight: FontWeight.w600,
);

const List<_AdminMenuItem> _adminMenus = [
  _AdminMenuItem(label: 'Tổng quan', icon: Icons.dashboard_outlined),
  _AdminMenuItem(label: 'Duyệt bài đăng', icon: Icons.fact_check_outlined),
  _AdminMenuItem(label: 'Người dùng', icon: Icons.group_outlined),
  _AdminMenuItem(label: 'Báo cáo', icon: Icons.bar_chart_rounded),
  _AdminMenuItem(label: 'Hỗ trợ', icon: Icons.support_agent_outlined),
  _AdminMenuItem(label: 'Cài đặt', icon: Icons.settings_outlined),
];

const List<String> _timezoneOptions = [
  'GMT+7 (Asia/Ho Chi Minh)',
  'GMT+8 (Singapore)',
  'GMT+9 (Tokyo)',
];
const List<String> _languageOptions = ['Tiếng Việt', 'English', '日本語'];
const List<String> _currencyOptions = [
  'VND (Việt Nam Đồng)',
  'USD',
  'JPY',
];
const List<String> _backupFrequencyOptions = ['Hàng ngày', 'Hàng tuần', 'Hàng tháng'];
const List<String> _backupTimeOptions = ['02:30 AM', '03:00 AM', '11:30 PM'];
const List<String> _backupRetentionOptions = ['30 ngày', '60 ngày', '90 ngày'];
const List<String> _cornerOptions = ['Nhỏ', 'Vừa', 'Lớn'];
const List<String> _densityOptions = ['Thoáng', 'Tiêu chuẩn', 'Dày'];
const List<Color> _swatchColors = [
  AppColors.blue,
  Color(0xFF6C5CE7),
  Color(0xFF8B5CF6),
  Color(0xFF14B8A6),
  Color(0xFFFF8A00),
  Color(0xFFFF4D4F),
  Color(0xFF9AA6B5),
];

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
