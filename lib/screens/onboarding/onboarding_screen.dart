import 'package:flutter/material.dart';
import 'package:smart_room_finder/screens/auth/login_screen.dart';
import 'package:smart_room_finder/screens/onboarding/onboarding_screen_1.dart';
import 'package:smart_room_finder/screens/onboarding/onboarding_screen_2.dart';
import 'package:smart_room_finder/screens/onboarding/onboarding_screen_3.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Duration> _pageDurations = [
    const Duration(seconds: 2),
    const Duration(seconds: 2),
    const Duration(seconds: 2),
  ];

  @override
  void initState() {
    super.initState();
    _autoAdvance();
  }

  void _autoAdvance() async {
    for (int i = 0; i < _pageDurations.length; i++) {
      await Future.delayed(_pageDurations[i]);
      if (!mounted) return;
      if (i < _pageDurations.length - 1) {
        _pageController.animateToPage(
          i + 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = i + 1);
      } else {
        _goToNextScreen();
      }
    }
  }

  void _goToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _skipOnboarding() {
    _goToNextScreen();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      OnboardingPage1(onSkip: _skipOnboarding),
      OnboardingPage2(onSkip: _skipOnboarding),
      OnboardingPage3(onSkip: _skipOnboarding),
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: pages,
          ),
          Positioned(
            top: 16,
            right: 24,
            child: SafeArea(
              child: GestureDetector(
                onTap: _skipOnboarding,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Bỏ qua',
                      style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ),
          ),          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _currentPage == index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFD4DCE6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}