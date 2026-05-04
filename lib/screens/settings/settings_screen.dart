import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/core/l10n/language_provider.dart';
import 'package:smart_room_finder/screens/auth/change_password_screen.dart';
import 'package:smart_room_finder/screens/welcome/welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _emailNotifications = false;
  bool _darkMode = false;
  bool _locationEnabled = true;
  bool _biometric = false;
  String _selectedTheme = 'system';

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
            colors: [AppColors.mintLight, AppColors.mintSoft, AppColors.mintGreen],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildSectionLabel('Thông báo'),
                      _buildCard(children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_outlined,
                          label: 'Thông báo đẩy',
                          subtitle: 'Nhận thông báo về phòng mới',
                          value: _notifications,
                          onChanged: (v) => setState(() => _notifications = v),
                        ),
                        _buildSwitchTile(
                          icon: Icons.email_outlined,
                          label: 'Thông báo email',
                          subtitle: 'Nhận email về hoạt động tài khoản',
                          value: _emailNotifications,
                          onChanged: (v) => setState(() => _emailNotifications = v),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSectionLabel('Giao diện'),
                      _buildCard(children: [
                        _buildSwitchTile(
                          icon: Icons.dark_mode_outlined,
                          label: 'Chế độ tối',
                          subtitle: 'Bật giao diện tối',
                          value: _darkMode,
                          onChanged: (v) => setState(() => _darkMode = v),
                        ),
                        _buildTapTile(
                          icon: Icons.palette_outlined,
                          label: 'Chủ đề màu sắc',
                          subtitle: _selectedTheme == 'system' ? 'Theo hệ thống' : _selectedTheme == 'light' ? 'Sáng' : 'Tối',
                          onTap: _showThemePicker,
                        ),
                        _buildTapTile(
                          icon: Icons.language_rounded,
                          label: lang.tr('language'),
                          subtitle: lang.currentLanguageName,
                          onTap: () => _showLanguagePicker(lang),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSectionLabel('Quyền riêng tư & Bảo mật'),
                      _buildCard(children: [
                        _buildSwitchTile(
                          icon: Icons.location_on_outlined,
                          label: 'Vị trí',
                          subtitle: 'Cho phép truy cập vị trí',
                          value: _locationEnabled,
                          onChanged: (v) => setState(() => _locationEnabled = v),
                        ),
                        _buildSwitchTile(
                          icon: Icons.fingerprint_rounded,
                          label: 'Xác thực sinh trắc học',
                          subtitle: 'Dùng Face ID / Touch ID để đăng nhập',
                          value: _biometric,
                          onChanged: (v) => setState(() => _biometric = v),
                        ),
                        _buildTapTile(
                          icon: Icons.lock_outline_rounded,
                          label: 'Đổi mật khẩu',
                          subtitle: 'Cập nhật mật khẩu tài khoản',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                        ),
                        _buildTapTile(
                          icon: Icons.shield_outlined,
                          label: 'Chính sách bảo mật',
                          subtitle: 'Xem chính sách bảo mật',
                          onTap: _showPrivacyPolicy,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSectionLabel('Dữ liệu'),
                      _buildCard(children: [
                        _buildTapTile(
                          icon: Icons.storage_outlined,
                          label: 'Bộ nhớ cache',
                          subtitle: 'Xóa dữ liệu tạm thời',
                          onTap: _clearCache,
                        ),
                        _buildTapTile(
                          icon: Icons.download_outlined,
                          label: 'Xuất dữ liệu',
                          subtitle: 'Tải xuống dữ liệu tài khoản',
                          onTap: _showComingSoon,
                        ),
                        _buildTapTile(
                          icon: Icons.delete_outline_rounded,
                          label: 'Xóa tài khoản',
                          subtitle: 'Xóa vĩnh viễn tài khoản của bạn',
                          onTap: _showDeleteAccount,
                          textColor: Colors.redAccent,
                          iconColor: Colors.redAccent,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSectionLabel('Thông tin'),
                      _buildCard(children: [
                        _buildTapTile(
                          icon: Icons.info_outline_rounded,
                          label: 'Về ứng dụng',
                          subtitle: 'Phiên bản 1.0.0',
                          onTap: _showAbout,
                        ),
                        _buildTapTile(
                          icon: Icons.star_outline_rounded,
                          label: 'Đánh giá ứng dụng',
                          subtitle: 'Chia sẻ trải nghiệm của bạn',
                          onTap: _showComingSoon,
                        ),
                        _buildTapTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Trung tâm hỗ trợ',
                          subtitle: 'Câu hỏi thường gặp & liên hệ',
                          onTap: _showComingSoon,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildCard(children: [
                        _buildTapTile(
                          icon: Icons.logout_rounded,
                          label: lang.tr('logout'),
                          onTap: () => _onLogout(lang),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          const Text('Cài đặt', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          if (i.isOdd) return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFF0F4F8)));
          return children[i ~/ 2];
        }),
      ),
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String label, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: AppColors.teal, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          Switch(
            value: value,
            onChanged: (v) { HapticFeedback.selectionClick(); onChanged(v); },
            activeThumbColor: AppColors.teal,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildTapTile({required IconData icon, required String label, String? subtitle, required VoidCallback onTap, Color? textColor, Color? iconColor, bool showChevron = true}) {
    final ic = iconColor ?? AppColors.teal;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: ic.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: ic, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor ?? AppColors.textPrimary)),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
              if (showChevron) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Chức năng đang được phát triển', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Chủ đề màu sắc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ...[('system', 'Theo hệ thống', Icons.phone_android_rounded), ('light', 'Sáng', Icons.light_mode_outlined), ('dark', 'Tối', Icons.dark_mode_outlined)].map((item) {
              final selected = _selectedTheme == item.$1;
              return GestureDetector(
                onTap: () { setState(() => _selectedTheme = item.$1); Navigator.pop(context); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.mintSoft : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? AppColors.teal : Colors.transparent, width: 1.5),
                  ),
                  child: Row(children: [
                    Icon(item.$3, color: selected ? AppColors.teal : AppColors.textSecondary),
                    const SizedBox(width: 14),
                    Text(item.$2, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: selected ? AppColors.tealDark : AppColors.textPrimary)),
                    const Spacer(),
                    if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 20),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: lang,
        child: Consumer<LanguageProvider>(
          builder: (ctx, provider, _) => Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text(provider.tr('select_language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                ...LanguageProvider.languages.map((l) {
                  final selected = provider.locale.languageCode == l.$1;
                  return GestureDetector(
                    onTap: () { provider.setLocale(l.$1); Navigator.pop(ctx); },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.mintSoft : Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? AppColors.teal : Colors.transparent, width: 1.5),
                      ),
                      child: Row(children: [
                        Text(l.$3, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Text(l.$2, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: selected ? AppColors.tealDark : AppColors.textPrimary)),
                        const Spacer(),
                        if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 20),
                      ]),
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

  void _clearCache() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa cache', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bạn có muốn xóa toàn bộ dữ liệu tạm thời không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Đã xóa cache thành công'),
                backgroundColor: AppColors.teal,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Xóa tài khoản', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: const Text('Hành động này không thể hoàn tác. Toàn bộ dữ liệu của bạn sẽ bị xóa vĩnh viễn.', style: TextStyle(height: 1.5, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Xóa tài khoản', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Chính sách bảo mật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Smart Room Finder cam kết bảo vệ thông tin cá nhân của người dùng.\n\n'
                  '1. Thông tin thu thập\nChúng tôi thu thập thông tin bạn cung cấp khi đăng ký tài khoản, bao gồm tên, email và số điện thoại.\n\n'
                  '2. Sử dụng thông tin\nThông tin được sử dụng để cung cấp dịch vụ, cải thiện trải nghiệm và gửi thông báo liên quan.\n\n'
                  '3. Bảo mật dữ liệu\nChúng tôi áp dụng các biện pháp bảo mật tiêu chuẩn để bảo vệ thông tin của bạn.\n\n'
                  '4. Chia sẻ thông tin\nChúng tôi không bán hoặc chia sẻ thông tin cá nhân với bên thứ ba mà không có sự đồng ý của bạn.\n\n'
                  '5. Liên hệ\nNếu có thắc mắc, vui lòng liên hệ support@smartroomfinder.vn',
                  style: TextStyle(fontSize: 14, height: 1.7, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.teal, AppColors.blue]), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Smart Room Finder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Phiên bản 1.0.0', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('Ứng dụng tìm kiếm phòng trọ thông minh, giúp bạn tìm được nơi ở phù hợp nhất.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _onLogout(LanguageProvider lang) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Text(lang.tr('logout'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        content: Text(lang.tr('logout_confirm'), style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.tr('cancel'), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(lang.tr('logout'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
