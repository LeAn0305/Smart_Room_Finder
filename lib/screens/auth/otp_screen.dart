import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/screens/home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto-focus first cell
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendSeconds > 0) _resendSeconds--;
      });
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onVerify() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    // Demo: simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isVerifying = false);

    // Navigate to home (demo)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _onFieldChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Auto-verify when all filled
    if (_otpCode.length == 6) {
      _onVerify();
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
                child: _buildGlow(180, AppColors.teal.withValues(alpha: 0.12)),
              ),
              Positioned(
                bottom: -70,
                right: -40,
                child: _buildGlow(210, AppColors.blue.withValues(alpha: 0.12)),
              ),

              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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

                    const SizedBox(height: 40),

                    // Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🔐', style: TextStyle(fontSize: 36)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Header
                    const Text(
                      'Xác minh OTP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Nhập mã 6 chữ số đã được gửi đến\n',
                          ),
                          TextSpan(
                            text: widget.phoneNumber,
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // OTP cells
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (index) => _buildOtpCell(index),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Resend timer
                    Center(
                      child: _resendSeconds > 0
                          ? Text(
                              'Gửi lại mã sau $_resendSeconds giây',
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : GestureDetector(
                              onTap: _startResendTimer,
                              child: const Text(
                                'Gửi lại mã OTP',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 40),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _onVerify,
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
                        child: _isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Xác nhận',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpCell(int index) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.teal, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onFieldChanged(value, index),
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
          BoxShadow(color: color, blurRadius: 70, spreadRadius: 24),
        ],
      ),
    );
  }
}
