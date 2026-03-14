import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/screens/onboarding/onboarding_screen.dart';
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final double titleSize = (size.width * 0.085).clamp(26.0, 36.0);
    final double subtitleSize = (size.width * 0.040).clamp(14.0, 18.0);
    final double buttonTextSize = (size.width * 0.040).clamp(14.0, 17.0);
    final double logoSize = (size.width * 0.36).clamp(120.0, 160.0);

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
          child: Stack(
            children: [
              Positioned(
                top: -60,
                left: -40,
                child: _buildGlow(
                  size: 180,
                  color: AppColors.teal.withOpacity(0.12),
                ),
              ),
              Positioned(
                bottom: -70,
                right: -40,
                child: _buildGlow(
                  size: 210,
                  color: AppColors.blue.withOpacity(0.12),
                ),
              ),
              Positioned(
                top: 50,
                right: 28,
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.teal.withOpacity(0.65),
                  size: 24,
                ),
              ),
              Positioned(
                top: 78,
                right: 52,
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.tealLight.withOpacity(0.70),
                  size: 14,
                ),
              ),
              Positioned(
                bottom: 120,
                left: 26,
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.white.withOpacity(0.70),
                  size: 18,
                ),
              ),

              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 380,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),

                              Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.teal,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.blue.withOpacity(0.12),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.white,
                                      AppColors.mintLight,
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.white.withOpacity(0.95),
                                    ),
                                    child: ClipOval(
                                      child: SizedBox.expand(
                                        child: Transform.translate(
                                          offset: const Offset(0, -10),
                                          child: Transform.scale(
                                            scale: 2.6,
                                            child: Image.asset(
                                              'assets/images/LogoApp.png',
                                              fit: BoxFit.cover,
                                              alignment: Alignment.center,
                                              errorBuilder:
                                                  (_, __, ___) => const Icon(
                                                    Icons.home_work_rounded,
                                                    size: 56,
                                                    color: AppColors.blueDark,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              Text(
                                'Chào mừng đến với\nSmart Room Finder',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),

                              const SizedBox(height: 14),

                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'Tìm phòng trọ nhanh hơn, đúng nhu cầu hơn và thuận tiện hơn ngay trên điện thoại của bạn.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: subtitleSize,
                                    height: 1.55,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.72),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppColors.teal.withOpacity(0.18),
                                  ),
                                ),
                                child: Row(
                                  children: const [
                                    Expanded(
                                      child: _FeatureItem(
                                        icon: Icons.search_rounded,
                                        label: 'Tìm kiếm\nthông minh',
                                      ),
                                    ),
                                    Expanded(
                                      child: _FeatureItem(
                                        icon: Icons.map_rounded,
                                        label: 'Vị trí\nthuận tiện',
                                      ),
                                    ),
                                    Expanded(
                                      child: _FeatureItem(
                                        icon: Icons.verified_user_rounded,
                                        label: 'Trải nghiệm\nan toàn',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const OnboardingScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.teal,
                                    foregroundColor: AppColors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(
                                    'Bắt đầu ngay',
                                    style: TextStyle(
                                      fontSize: buttonTextSize,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlow({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 70,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.blueDark,
            size: 24,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}