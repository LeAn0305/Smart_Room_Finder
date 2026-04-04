import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/core/l10n/language_provider.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:smart_room_finder/screens/welcome/welcome_screen.dart';
import 'package:smart_room_finder/screens/my_room/my_room_screen.dart';
import 'package:smart_room_finder/screens/favorite/favorite_screen.dart';
//import 'package:smart_room_finder/screens/settings/settings_screen.dart';
import 'package:smart_room_finder/screens/auth/change_password_screen.dart';
import 'package:smart_room_finder/screens/auth/verify_account_screen.dart';
import 'package:smart_room_finder/screens/history/view_history_screen.dart';
import 'package:smart_room_finder/screens/support/support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final UserModel _user = UserModel.currentUser;
  bool _notificationsEnabled = true;

  File? _avatarFile;

  // Stats tính từ dữ liệu mẫu  
  int get _totalFavorites =>
      RoomModel.sampleRooms.where((r) => r.isFavorite).length;
  int get _totalRooms => RoomModel.sampleRooms.length;

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() => _avatarFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể truy cập ảnh. Vui lòng kiểm tra quyền trong Cài đặt.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        );
      }
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
                decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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
                decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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

  void _showComingSoon() {
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang.tr('coming_soon'),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onLogout() {
    final lang = context.read<LanguageProvider>();
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Text(lang.tr('logout'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(lang.tr('logout_confirm'),
            style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.tr('cancel'),
                style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(lang.tr('logout'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
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
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildSectionLabel(lang.tr('section_account')),
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
                        icon: Icons.shield_outlined,
                        label: lang.tr('verify_account'),
                        subtitle: lang.tr('verify_account_subtitle'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyAccountScreen())),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(lang.tr('not_verified'),
                              style: const TextStyle(fontSize: 11, color: AppColors.tealDark, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildSectionLabel(lang.tr('section_activity')),
                    _buildMenuCard(children: [
                      _buildMenuItem(
                        icon: Icons.home_work_outlined,
                        label: lang.tr('my_rooms'),
                        subtitle: '$_totalRooms ${lang.tr('profile_rooms_posted')}',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRoomScreen()));
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.favorite_border_rounded,
                        label: lang.tr('saved_rooms'),
                        subtitle: '$_totalFavorites ${lang.tr('profile_favorites')}',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteScreen()));
                        },
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
                    _buildSectionLabel(lang.tr('section_settings')),
                    _buildMenuCard(children: [
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        label: lang.tr('notifications'),
                        subtitle: lang.tr('notifications_subtitle'),
                        onTap: () => setState(() => _notificationsEnabled = !_notificationsEnabled),
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (val) => setState(() => _notificationsEnabled = val),
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
                    _buildSectionLabel(lang.tr('section_other')),
                    _buildMenuCard(children: [
                      _buildMenuItem(
                        icon: Icons.info_outline_rounded,
                        label: lang.tr('about_app'),
                        subtitle: lang.tr('about_app_subtitle'),
                        onTap: _showComingSoon,
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
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.teal.withOpacity(0.22),
                      blurRadius: 40,
                      spreadRadius: 8),
                ],
              ),
            ),
            // Avatar border + image
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
                      ? FileImage(_avatarFile!) as ImageProvider
                      : NetworkImage(_user.profileImageUrl),
                  backgroundColor: AppColors.mintGreen,
                  onBackgroundImageError: (_, __) {},
                ),
              ),
            ),
            // Camera button
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
                          color: AppColors.teal.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _user.name,
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
            const Icon(Icons.email_outlined,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              _user.email,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.85),
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              _user.location,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.85),
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final lang = context.read<LanguageProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            _buildStatItem(value: '$_totalRooms', label: lang.tr('profile_rooms_posted')),
            _buildStatDivider(),
            _buildStatItem(value: '$_totalFavorites', label: lang.tr('profile_favorites')),
            _buildStatDivider(),
            _buildStatItem(value: '4.8 ★', label: lang.tr('profile_rating')),
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
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.035),
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
                  color: ic.withOpacity(0.1),
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
              if (trailing != null) trailing,
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
    final nameController = TextEditingController(text: _user.name);
    final emailController = TextEditingController(text: _user.email);
    final locationController = TextEditingController(text: _user.location);

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
            _buildEditField(controller: emailController, label: lang.tr('email'), icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _buildEditField(controller: locationController, label: lang.tr('address'), icon: Icons.location_on_outlined),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(lang.tr('save_changes'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                    onTap: () {
                      provider.setLocale(lang.$1);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${provider.tr('language_changed')} ${lang.$2}'),
                          backgroundColor: AppColors.teal,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          duration: const Duration(seconds: 2),
                        ),
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
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, color: AppColors.teal, size: 20),
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
}
