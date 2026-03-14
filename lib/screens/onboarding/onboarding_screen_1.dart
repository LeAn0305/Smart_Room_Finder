import 'package:flutter/material.dart';

class OnboardingPage1 extends StatelessWidget {
  final VoidCallback? onSkip;

  const OnboardingPage1({
    super.key,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallHeight = size.height < 700;
    final imageWidth = isSmallHeight ? 250.0 : 320.0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF6FBFB),
            Color(0xFFF0F7F8),
            Color(0xFFEAF3F6),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSkip ?? () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Bỏ qua',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8DA2B8),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: isSmallHeight ? 8 : 14),

                    Expanded(
                      flex: 6,
                      child: Center(
                        child: Image.asset(
                          'assets/images/Onboarding1.png',
                          width: imageWidth,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: imageWidth,
                              height: imageWidth,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 60,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallHeight ? 8 : 18),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: const Text(
                        'Tìm phòng trọ nhanh chóng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: Color(0xFF14213D),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 335),
                      child: const Text(
                        'Hệ thống lọc thông minh giúp bạn tìm thấy căn phòng phù hợp chỉ với vài thao tác.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: Color(0xFF6B7A90),
                        ),
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}