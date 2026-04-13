import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:smart_room_finder/screens/onboarding/preference_screen.dart';
import 'package:smart_room_finder/screens/onboarding/landlord_preference_screen.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  UserRole? _selected;

  void _continue() {
    if (_selected == null) return;
    final screen = _selected == UserRole.landlord
        ? const LandlordPreferenceScreen()
        : const PreferenceScreen();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.teal, AppColors.blue]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 20, spreadRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.home_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Bạn là ai? 👋',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Chọn vai trò để chúng tôi\ncá nhân hóa trải nghiệm cho bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 48),

                // Người thuê
                _buildRoleCard(
                  role: UserRole.tenant,
                  icon: Icons.person_search_rounded,
                  title: 'Người đi thuê',
                  description: 'Tôi muốn tìm và thuê phòng trọ phù hợp',
                  features: ['Tìm kiếm phòng theo khu vực', 'Lưu phòng yêu thích', 'Gửi đơn yêu cầu thuê'],
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),

                // Chủ phòng
                _buildRoleCard(
                  role: UserRole.landlord,
                  icon: Icons.home_work_rounded,
                  title: 'Chủ phòng cho thuê',
                  description: 'Tôi muốn đăng và quản lý phòng cho thuê',
                  features: ['Đăng phòng cho thuê', 'Quản lý phòng & đơn thuê', 'Xem thống kê lượt xem'],
                  color: AppColors.teal,
                ),

                const Spacer(),

                // Nút tiếp tục
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selected != null ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      disabledBackgroundColor: AppColors.teal.withOpacity(0.4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Bắt đầu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
    required Color color,
  }) {
    final sel = _selected == role;
    return GestureDetector(
      onTap: () => setState(() => _selected = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.07) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? color : Colors.grey[200]!, width: sel ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: sel ? color.withOpacity(0.18) : Colors.black.withOpacity(0.05),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.15) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: sel ? color : Colors.grey[400], size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: sel ? color : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Icon(Icons.check_rounded, size: 13, color: sel ? color : Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(f, style: TextStyle(fontSize: 12, color: sel ? AppColors.textPrimary : Colors.grey[500])),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            if (sel)
              Icon(Icons.check_circle_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
