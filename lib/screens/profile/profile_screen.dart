import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/core/l10n/language_provider.dart';
//import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:smart_room_finder/screens/welcome/welcome_screen.dart';
import 'package:smart_room_finder/screens/my_room/my_room_screen.dart';
import 'package:smart_room_finder/screens/auth/change_password_screen.dart';
import 'package:smart_room_finder/screens/history/view_history_screen.dart';
import 'package:smart_room_finder/screens/support/support_screen.dart';

import 'package:smart_room_finder/core/providers/favorite_provider.dart';
import 'package:smart_room_finder/providers/room_provider.dart';

import 'package:smart_room_finder/services/auth_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_room_finder/services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  UserModel? _user;
  bool _isLoadingUser = true;
  bool _notificationsEnabled = true;

  File? _avatarFile;
  final StorageService _storageService = StorageService();
  
  // Stats tính từ dữ liệu mẫu  
  int _getTotalFavorites(BuildContext context) {
    return context.watch<FavoriteProvider>().favoriteIds.length;
  }

  int _getTotalRooms(BuildContext context) {
  final provider = context.watch<RoomProvider>();
  return provider.myActiveRooms.length +
      provider.myHiddenRooms.length +
      provider.myDraftRooms.length;
  }

  Future<void> _loadUserProfile() async {
  try {
    final user = await AuthService.getCurrentUserData();

    if (!mounted) return;

    setState(() {
      _user = user;
      _isLoadingUser = false;
    });
  } catch (e) {
    debugPrint('❌ Lỗi khi load user profile: $e');

    if (!mounted) return;

    setState(() {
      _isLoadingUser = false;
    });
  }
}

 @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _loadUserProfile();
    _loadNotificationSetting();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);

      if (mounted) {
        setState(() => _avatarFile = file);
      }

      await _showControlledSnackBar('Đang tải ảnh lên...', backgroundColor: AppColors.teal);

      final imageUrl = await _storageService.uploadProfileImage(file);

      await AuthService.updateUserProfile(
        name: _user?.name ?? '',
        location: _user?.location ?? '',
        profileImageUrl: imageUrl,
      );

      await _loadUserProfile();

      if (!mounted) return;

      await _showControlledSnackBar('Cập nhật ảnh đại diện thành công');
    } catch (e) {
      if (!mounted) return;

      await _showControlledSnackBar(
        'Không thể cập nhật ảnh đại diện: $e',
        backgroundColor: Colors.redAccent,
      );
    }
  }

  void _showImageSourcePicker() {
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
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Chọn ảnh đại diện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_outlined, color: AppColors.teal),
              ),
              title: const Text('Thư viện ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.teal),
              ),
              title: const Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showComingSoon() async {
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await _showControlledSnackBar(lang.tr('coming_soon'));
  }

void _onLogout() {
  final lang = context.read<LanguageProvider>();
  HapticFeedback.mediumImpact();

  showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            lang.tr('logout'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Text(
        lang.tr('logout_confirm'),
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: Colors.black54,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            lang.tr('cancel'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              Navigator.pop(dialogContext);

              await AuthService.signOut();

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const WelcomeScreen(),
                ),
                (route) => false,
              );
            } catch (e) {
              if (!mounted) return;
                await _showControlledSnackBar(
                  'Đăng xuất thất bại: $e',
                  backgroundColor: Colors.redAccent,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            lang.tr('logout'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final totalFavorites = _getTotalFavorites(context);
    final totalRooms = _getTotalRooms(context);
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildTopBar(),
                    const SizedBox(height: 24),
                    _buildAvatarSection(),
                    const SizedBox(height: 20),
                    _buildStatsRow(
                      totalRooms: totalRooms,
                      totalFavorites: totalFavorites,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionLabel('📋 ${lang.tr('section_account')}'),
                    _buildMenuCard(children: [
                      _buildMenuItem(
                        icon: Icons.person_outline_rounded,
                        label: lang.tr('edit_profile'),
                        subtitle: lang.tr('edit_profile_subtitle'),
                        onTap: () => _showEditProfile(),
                      ),
                      _buildMenuItem(
                        icon: Icons.lock_outline_rounded,
                        label: lang.tr('change_password'),
                        subtitle: lang.tr('change_password_subtitle'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                      ),
                      _buildMenuItem(
                        icon: Icons.credit_card_rounded,
                        label: 'Phương thức thanh toán',
                        subtitle: 'Quản lý thẻ và tài khoản',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Lịch sử giao dịch',
                        subtitle: 'Xem các giao dịch trước',
                        onTap: () => _showComingSoon(),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildSectionLabel('🎯 ${lang.tr('section_activity')}'),
                    _buildMenuCard(children: [
                      _buildMenuItem(
                        icon: Icons.home_work_outlined,
                        label: 'Phòng trọ của tôi',
                        subtitle: '$totalRooms phòng đã đăng',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRoomScreen()));
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.message_outlined,
                        label: 'Tin nhắn / Chat',
                        subtitle: 'Nhắn tin với chủ phòng',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: Icons.assignment_outlined,
                        label: 'Đơn yêu cầu / Applications',
                        subtitle: 'Xem đơn yêu cầu',
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: Icons.history_rounded,
                        label: lang.tr('view_history'),
                        subtitle: lang.tr('view_history_subtitle'),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewHistoryScreen()));
                        },
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildSectionLabel('⚙️ ${lang.tr('section_settings')}'),
                    _buildMenuCard(children: [
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        label: lang.tr('notifications'),
                        subtitle: lang.tr('notifications_subtitle'),
                        onTap: () => _saveNotificationSetting(!_notificationsEnabled),
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (val) => _saveNotificationSetting(val),
                          activeColor: AppColors.teal,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      _buildMenuItem(
                        icon: Icons.language_rounded,
                        label: lang.tr('language'),
                        subtitle: lang.currentLanguageName,
                        onTap: _showLanguagePicker,
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        label: lang.tr('support'),
                        subtitle: lang.tr('support_subtitle'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildSectionLabel('⭐ ${lang.tr('section_other')}'),
                    _buildMenuCard(children: [
                      _buildMenuItem(
                        icon: Icons.info_outline_rounded,
                        label: lang.tr('about_app'),
                        subtitle: lang.tr('about_app_subtitle'),
                        onTap: () => _showComingSoon(),
                      ),
                      _buildMenuItem(
                        icon: Icons.logout_rounded,
                        label: lang.tr('logout'),
                        onTap: _onLogout,
                        textColor: Colors.redAccent,
                        iconColor: Colors.redAccent,
                        showChevron: false,
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final lang = context.read<LanguageProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            lang.tr('profile_title'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined,
                  color: AppColors.textPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
  final displayName =
      (_user?.name != null && _user!.name.trim().isNotEmpty)
          ? _user!.name
          : 'Người dùng';

  final displayEmail =
      (_user?.email != null && _user!.email.trim().isNotEmpty)
          ? _user!.email
          : 'Chưa có email';

  final displayLocation =
      (_user?.location != null && _user!.location.trim().isNotEmpty)
          ? _user!.location
          : 'Chưa cập nhật';

  final displayImageUrl = _user?.profileImageUrl ?? '';

  return Column(
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.22),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                backgroundImage: _avatarFile != null
                    ? FileImage(_avatarFile!)
                    : (displayImageUrl.isNotEmpty
                        ? NetworkImage(displayImageUrl)
                        : null),
                child: _avatarFile == null && displayImageUrl.isEmpty
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 100,
            child: GestureDetector(
              onTap: _showImageSourcePicker,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      if (_isLoadingUser)
        const CircularProgressIndicator(color: AppColors.teal)
      else ...[
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.email_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              displayEmail,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              displayLocation,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

  Widget _buildStatsRow({
  required int totalRooms,
  required int totalFavorites,
}) {
  final lang = context.read<LanguageProvider>();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            value: '$totalRooms',
            label: lang.tr('profile_rooms_posted'),
          ),
          _buildStatDivider(),
          _buildStatItem(
            value: '$totalFavorites',
            label: lang.tr('profile_favorites'),
          ),
          _buildStatDivider(),
          _buildStatItem(
            value: '4.8 ★',
            label: lang.tr('profile_rating'),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStatItem({required String value, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 36, color: AppColors.mintGreen);
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Color(0xFFF0F4F8)),
            );
          }
          return children[i ~/ 2];
        }),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    Widget? trailing,
    bool showChevron = true,
  }) {
    final ic = iconColor ?? AppColors.teal;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ic.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: ic, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400)),
                    ],
                  ],
                ),
              ),
              ?trailing,
              if (trailing == null && showChevron)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfile() {
    final lang = context.read<LanguageProvider>();
    final nameController = TextEditingController(text: _user?.name ?? '');
    final emailController = TextEditingController(text: _user?.email ?? '');
    final locationController = TextEditingController(text: _user?.location ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 24, left: 24, right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(lang.tr('edit_profile'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            _buildEditField(controller: nameController, label: lang.tr('full_name'), icon: Icons.person_outline_rounded),
            const SizedBox(height: 14),
            _buildEditField(controller: emailController, label: lang.tr('email'), icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, readOnly: true,),
            const SizedBox(height: 14),
            _buildEditField(controller: locationController, label: lang.tr('address'), icon: Icons.location_on_outlined),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final location = locationController.text.trim();

                  if (name.isEmpty) {
                    await _showControlledSnackBar(
                      'Vui lòng nhập họ và tên',
                      backgroundColor: Colors.redAccent,
                    );
                    return;
                  }

                  if (location.isEmpty) {
                    await _showControlledSnackBar(
                      'Vui lòng nhập địa chỉ',
                      backgroundColor: Colors.redAccent,
                    );
                    return;
                  }

                  try {
                    await AuthService.updateUserProfile(
                      name: name,
                      location: location,
                      profileImageUrl: _user?.profileImageUrl,
                    );

                    if (!mounted) return;

                    Navigator.pop(context);

                    await _loadUserProfile();

                    if (!mounted) return;

                    await _showControlledSnackBar('Cập nhật thông tin thành công');
                  } catch (e) {
                    if (!mounted) return;

                    await _showControlledSnackBar(
                      'Cập nhật thất bại: $e',
                      backgroundColor: Colors.redAccent,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  lang.tr('save_changes'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    final lang = context.read<LanguageProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: lang,
        child: Consumer<LanguageProvider>(
          builder: (ctx, provider, _) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text(
                  provider.tr('select_language'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                ...LanguageProvider.languages.map((lang) {
                  final selected = provider.locale.languageCode == lang.$1;
                  return GestureDetector(
                    onTap: () async{
                      provider.setLocale(lang.$1);
                      Navigator.pop(ctx);
                      await _showControlledSnackBar(
                        '${provider.tr('language_changed')} ${lang.$2}',
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.mintSoft : Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? AppColors.teal : Colors.transparent, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Text(lang.$3, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Text(lang.$2,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: selected ? AppColors.tealDark : AppColors.textPrimary,
                              )),
                          const Spacer(),
                          if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.teal, size: 20),
            filled: true,
            fillColor: AppColors.mintLight,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    if (!mounted) return;

    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<bool> _isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> _showControlledSnackBar(
    String message, {
    Color backgroundColor = AppColors.teal,
    }) async {
        final enabled = await _isNotificationEnabled();
        if (!enabled || !mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        );
      }


}
