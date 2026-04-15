import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({
    super.key,
    required this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final AnimationController _pulseController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => widget.nextScreen,
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final double logoSize = (size.width * 0.46).clamp(170.0, 240.0);
    final double titleSize = (size.width * 0.10).clamp(28.0, 44.0);
    final double subtitleSize = (size.width * 0.045).clamp(16.0, 22.0);

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                  AppColors.blueSoft,
                ],
              ),
            ),
          ),

          Positioned(
            top: -120,
            left: -80,
            child: _buildGlow(
              size: 260,
              color: AppColors.teal.withValues(alpha: 0.18),
            ),
          ),

          Positioned(
            bottom: -120,
            right: -80,
            child: _buildGlow(
              size: 280,
              color: AppColors.blue.withValues(alpha: 0.16),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: _buildGlow(
              size: 330,
              color: AppColors.mintGreen.withValues(alpha: 0.22),
            ),
          ),

          Positioned(
            top: 110,
            right: 92,
            child: _Sparkle(
              size: 28,
              color: AppColors.tealLight,
            ),
          ),
          Positioned(
            top: 145,
            right: 62,
            child: _Sparkle(
              size: 14,
              color: AppColors.teal,
            ),
          ),
          Positioned(
            top: 170,
            right: 108,
            child: _Sparkle(
              size: 18,
              color: AppColors.tealLight,
            ),
          ),
          Positioned(
            bottom: 160,
            left: 42,
            child: _Sparkle(
              size: 18,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
          ),
          Positioned(
            bottom: 185,
            left: 62,
            child: _Sparkle(
              size: 30,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
          ),
          Positioned(
            bottom: 110,
            right: 34,
            child: _Sparkle(
              size: 38,
              color: AppColors.mintSoft.withValues(alpha: 0.65),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 90,
            child: _Sparkle(
              size: 22,
              color: AppColors.mintSoft.withValues(alpha: 0.45),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.88, end: 1.0),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    final double safeOpacity = value.clamp(0.0, 1.0);

                    return Opacity(
                      opacity: safeOpacity,
                      child: Transform.scale(
                        scale: value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.97,
                          end: 1.03,
                        ).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
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
                                color: AppColors.blue.withValues(alpha: 0.18),
                                blurRadius: 28,
                                spreadRadius: 3,
                                offset: const Offset(0, 10),
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
                                color: AppColors.white.withValues(alpha: 0.95),
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
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.home_work_rounded,
                                              size: 90,
                                              color: AppColors.blueDark,
                                            ),
                                          );
                                        },
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
                        'Smart Room Finder',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              offset: const Offset(0, 3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Tìm phòng nhanh, đúng nhu cầu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white.withValues(alpha: 0.92),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 42),

                      _RotatingDots(controller: _rotateController),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
            blurRadius: 90,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

class _RotatingDots extends StatelessWidget {
  final Animation<double> controller;

  const _RotatingDots({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * 2 * math.pi,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              children: List.generate(8, (index) {
                final double angle = (2 * math.pi / 8) * index;
                const double radius = 18.0;
                const double center = 27.0;
                final double dotSize = index == 7 ? 10.0 : 8.0;

                final double x =
                    center + radius * math.cos(angle) - dotSize / 2;
                final double y =
                    center + radius * math.sin(angle) - dotSize / 2;

                final Color color = index == 7
                    ? AppColors.blueDark
                    : AppColors.white.withValues(alpha: 0.45 + index * 0.05);

                return Positioned(
                  left: x,
                  top: y,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;
  final Color color;

  const _Sparkle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: color,
    );
  }
}