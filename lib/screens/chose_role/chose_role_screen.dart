import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:smart_room_finder/screens/main_navigation_screen.dart';
import 'package:smart_room_finder/screens/onboarding/preference_screen.dart';
import 'package:smart_room_finder/services/auth_service.dart';

class ChoseRoleScreen extends StatefulWidget {
  const ChoseRoleScreen({super.key});

  @override
  State<ChoseRoleScreen> createState() => _ChoseRoleScreenState();
}

class _ChoseRoleScreenState extends State<ChoseRoleScreen>
    with SingleTickerProviderStateMixin {
  UserRole? _selectedRole;
  bool _isLoading = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // =========================
  // NAVIGATION
  // =========================
  Future<void> _onContinue() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn vai trò của bạn'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.updateUserRole(_selectedRole!);
      if (!mounted) return;

      if (_selectedRole == UserRole.renter) {
        // Người thuê lần đầu → màn chọn nhu cầu (preference)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PreferenceScreen()),
          (route) => false,
        );
      } else {
        // Chủ trọ → thẳng vào HomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;
        return Scaffold(
          backgroundColor: const Color(0xFFEFF9F8),
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
                  Color(0xFFDFF5F2),
                ],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 680 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 48 : 20,
                              vertical: isDesktop ? 28 : 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTopBar(isDesktop),
                                SizedBox(height: isDesktop ? 28 : 20),
                                _buildHeader(isDesktop),
                                SizedBox(height: isDesktop ? 32 : 24),
                                _buildRoleCard(
                                  role: UserRole.renter,
                                  title: 'Người thuê',
                                  subtitle:
                                      'Tìm phòng phù hợp với nhu cầu của bạn',
                                  imagePath:
                                      'assets/images/renter_character.png',
                                  isDesktop: isDesktop,
                                ),
                                const SizedBox(height: 14),
                                _buildRoleCard(
                                  role: UserRole.landlord,
                                  title: 'Chủ trọ',
                                  subtitle: 'Đăng phòng và quản lý tin cho thuê',
                                  imagePath:
                                      'assets/images/landlord_character.png',
                                  isDesktop: isDesktop,
                                ),
                                SizedBox(height: isDesktop ? 20 : 14),
                                _buildNote(),
                                SizedBox(height: isDesktop ? 32 : 24),
                              ],
                            ),
                          ),
                        ),
                        _buildContinueButton(isDesktop),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // TOP BAR
  // =========================
  Widget _buildTopBar(bool isDesktop) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: isDesktop ? 16 : 14,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Quay lại',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // HEADER
  // =========================
  Widget _buildHeader(bool isDesktop) {
    final heroImage = Container(
      width: isDesktop ? 140 : 110,
      height: isDesktop ? 140 : 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
      ),
      child: Image.asset(
        'assets/images/renter_character.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.home_work_rounded,
          size: isDesktop ? 80 : 60,
          color: AppColors.teal.withValues(alpha: 0.5),
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn vai trò',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A2B3C),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hãy chọn vai trò phù hợp để tiếp tục sử dụng ứng dụng.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          heroImage,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn vai trò',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A2B3C),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hãy chọn vai trò phù hợp để\ntiếp tục sử dụng ứng dụng.',
                style: TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        heroImage,
      ],
    );
  }

  // =========================
  // ROLE CARD
  // =========================
  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required String imagePath,
    required bool isDesktop,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 22 : 16,
          vertical: isDesktop ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.teal.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
          border: Border.all(
            color: isSelected
                ? AppColors.teal
                : const Color(0xFFD5E5E3),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.teal.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Character image
            Container(
              width: isDesktop ? 88 : 76,
              height: isDesktop ? 88 : 76,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.teal.withValues(alpha: 0.08)
                    : const Color(0xFFEEFAF9),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  role == UserRole.renter
                      ? Icons.person_search_rounded
                      : Icons.home_rounded,
                  size: 40,
                  color: AppColors.teal,
                ),
              ),
            ),
            SizedBox(width: isDesktop ? 20 : 14),

            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2B3C),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isDesktop ? 14.5 : 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Radio / Check indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isSelected
                  ? Container(
                      key: const ValueKey('check'),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  : Container(
                      key: const ValueKey('radio'),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFCBD8D7),
                          width: 2,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // NOTE
  // =========================
  Widget _buildNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 15,
          color: AppColors.teal.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Bạn có thể thay đổi vai trò sau trong hồ sơ.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // CONTINUE BUTTON
  // =========================
  Widget _buildContinueButton(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 48 : 20,
        12,
        isDesktop ? 48 : 20,
        isDesktop ? 28 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: SizedBox(
        height: isDesktop ? 58 : 54,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.5),
            elevation: 0,
            shadowColor: AppColors.teal.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 18 : 16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tiếp tục',
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}
