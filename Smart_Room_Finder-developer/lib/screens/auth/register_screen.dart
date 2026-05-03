import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/services/auth_service.dart';
import 'package:smart_room_finder/screens/chose_role/chose_role_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(val.trim())) return 'Email không hợp lệ';
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (val.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (val != _passwordController.text) return 'Mật khẩu không khớp';
    return null;
  }

Future<void> _onRegister() async {
  if (!_formKey.currentState!.validate()) return;

  if (!_agreedToTerms) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vui lòng đồng ý với Điều khoản & Chính sách'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  final name = _nameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text;

  try {
    await AuthService.registerWithEmail(email, password, name);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đăng ký thành công!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.teal,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChoseRoleScreen()),
      (_) => false,
    );
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    String message = 'Đăng ký thất bại';

    if (e.code == 'email-already-in-use') {
      message = 'Email này đã được đăng ký rồi';
    } else if (e.code == 'invalid-email') {
      message = 'Email không hợp lệ';
    } else if (e.code == 'weak-password') {
      message = 'Mật khẩu quá yếu';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
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
              // Decorative Glows
              Positioned(
                top: -60,
                left: -40,
                child: _buildGlow(180, AppColors.teal.withValues(alpha: 0.12)),
              ),
              Positioned(
                bottom: -70,
                right: -40,
                child: _buildGlow(210, AppColors.blue.withValues(alpha: 0.12)),
              ),

              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),

                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
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

                      const SizedBox(height: 32),

                      // Header
                      const Text(
                        'Tạo tài khoản mới 🚀',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tham gia cùng chúng tôi để tìm phòng trọ lý tưởng của bạn.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Full Name
                      _buildValidatedField(
                        controller: _nameController,
                        label: 'Họ và tên',
                        hint: 'Nguyễn Văn A',
                        icon: Icons.person_outline_rounded,
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Vui lòng nhập họ và tên'
                            : null,
                      ),
                      const SizedBox(height: 18),

                      // Email
                      _buildValidatedField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'example@gmail.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 18),

                      // Password
                      _buildValidatedField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        hint: 'Tối thiểu 6 ký tự',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isPasswordVisible: _isPasswordVisible,
                        onTogglePassword: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 18),

                      // Confirm Password
                      _buildValidatedField(
                        controller: _confirmPasswordController,
                        label: 'Xác nhận mật khẩu',
                        hint: 'Nhập lại mật khẩu',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isPasswordVisible: _isConfirmPasswordVisible,
                        onTogglePassword: () => setState(() =>
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                        validator: _validateConfirmPassword,
                      ),

                      const SizedBox(height: 16),

                      // Password strength hint
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppColors.teal, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Mật khẩu tối thiểu 6 ký tự',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Terms & Conditions
                      GestureDetector(
                        onTap: () =>
                            setState(() => _agreedToTerms = !_agreedToTerms),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _agreedToTerms
                                    ? AppColors.teal
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _agreedToTerms
                                      ? AppColors.teal
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: _agreedToTerms
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 14),
                                  children: const [
                                    TextSpan(text: 'Tôi đồng ý với '),
                                    TextSpan(
                                      text: 'Điều khoản',
                                      style: TextStyle(
                                          color: AppColors.teal,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Chính sách',
                                      style: TextStyle(
                                          color: AppColors.teal,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.teal.withValues(alpha: 0.5),
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
                                      color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  'Tạo tài khoản',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Đã có tài khoản? ',
                              style: TextStyle(color: Colors.grey[700])),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Đăng nhập ngay',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidatedField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: keyboardType,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              prefixIcon: Icon(icon, color: AppColors.teal, size: 22),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              errorStyle: const TextStyle(fontSize: 12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 70, spreadRadius: 24),
        ],
      ),
    );
  }
}
