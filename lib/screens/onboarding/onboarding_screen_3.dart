import 'package:flutter/material.dart';

class OnboardingPage3 extends StatelessWidget {
  final VoidCallback? onSkip;

  const OnboardingPage3({
    super.key,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallHeight = size.height < 700;
    final horizontalPadding = isSmallHeight ? 20.0 : 24.0;
    final imageWidth = isSmallHeight ? 190.0 : 250.0;

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
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: isSmallHeight ? 6 : 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSkip ?? () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Onboarding3.png',
                      width: imageWidth,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: imageWidth,
                          height: imageWidth,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.smart_toy_outlined,
                              size: 60,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: isSmallHeight ? 20 : 28),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'AI hỗ trợ tìm phòng\nphù hợp',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: Color(0xFF14213D),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Nhận gợi ý thông minh để tìm phòng nhanh hơn và đúng nhu cầu hơn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                          color: Color(0xFF6B7A90),
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallHeight ? 120 : 135),
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