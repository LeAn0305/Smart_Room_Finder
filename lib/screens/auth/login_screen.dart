import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/screens/auth/forgot_password_screen.dart';
import 'package:smart_room_finder/screens/auth/phone_login_screen.dart';
import 'package:smart_room_finder/screens/auth/register_screen.dart';
import 'package:smart_room_finder/screens/main_navigation_screen.dart';
import 'package:smart_room_finder/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  void _onLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => _emailError = 'Vui lòng nhập email');
      hasError = true;
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Email không hợp lệ');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Vui lòng nhập mật khẩu');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Mật khẩu tối thiểu 6 ký tự');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.signInWithEmail(email, password);

      if (!mounted) return;
      _goToHome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Đăng nhập thất bại';

      if (e.code == 'user-not-found') {
        message = 'Email chưa được đăng ký';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Email hoặc mật khẩu không đúng';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ';
      } else if (e.code == 'too-many-requests') {
        message = 'Bạn thử lại sau ít phút';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final cred = await AuthService.signInWithGoogle();

      if (cred == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;
      _goToHome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập Google thất bại: ${e.message ?? e.code}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng nhập Google: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    try {
      await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (!mounted) return;
      _goToHome();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập Apple thất bại: $e')),
      );
    }
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
                child: _buildGlow(180, AppColors.teal.withOpacity(0.12)),
              ),
              Positioned(
                bottom: -70,
                right: -40,
                child: _buildGlow(210, AppColors.blue.withOpacity(0.12)),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      'Chào mừng trở lại! 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập để tiếp tục tìm kiếm phòng trọ mơ ước của bạn.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 36),

                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'example@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 20),

                    _buildInputField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onTogglePassword: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      errorText: _passwordError,
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                            : const Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Hoặc tiếp tục với',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSocialButton(
                            icon: Icons.g_mobiledata,
                            iconColor: const Color(0xFFDB4437),
                            iconSize: 30,
                            label: 'Google',
                            onTap: _signInWithGoogle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSocialButton(
                            icon: Icons.phone_outlined,
                            iconColor: AppColors.teal,
                            iconSize: 22,
                            label: 'Điện thoại',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PhoneLoginScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (!kIsWeb && Platform.isIOS) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _signInWithApple,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apple,
                                  color: Colors.white, size: 26),
                              SizedBox(width: 10),
                              Text(
                                'Đăng nhập với Apple',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Bạn chưa có tài khoản? ',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: errorText != null
                ? Border.all(color: Colors.redAccent, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: keyboardType,
            onChanged: (_) => setState(() {
              if (isPassword) {
                _passwordError = null;
              } else {
                _emailError = null;
              }
            }),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.teal,
                size: 22,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey[400],
                        size: 22,
                      ),
                      onPressed: onTogglePassword,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color iconColor,
    required double iconSize,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: iconSize),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow(double size, Color color) {
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