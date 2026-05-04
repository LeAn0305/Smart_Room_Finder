import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedType = 'bug';
  bool _loading = false;

  final List<Map<String, dynamic>> _faq = [
    {'q': 'Làm thế nào để đăng phòng trọ?', 'a': 'Vào tab "Cá nhân" → "Phòng trọ của tôi" → nhấn nút "+" để đăng phòng mới.'},
    {'q': 'Tôi quên mật khẩu phải làm gì?', 'a': 'Tại màn hình đăng nhập, nhấn "Quên mật khẩu" và làm theo hướng dẫn qua email.'},
    {'q': 'Làm sao để liên hệ chủ phòng?', 'a': 'Vào trang chi tiết phòng và nhấn nút "Liên hệ" hoặc "Nhắn tin".'},
    {'q': 'Ứng dụng có miễn phí không?', 'a': 'Ứng dụng hoàn toàn miễn phí cho người tìm phòng. Chủ phòng có thể có các gói đăng tin nâng cao.'},
    {'q': 'Làm sao để xóa tài khoản?', 'a': 'Vào Cài đặt → Dữ liệu → Xóa tài khoản. Lưu ý hành động này không thể hoàn tác.'},
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.isEmpty || _messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng điền đầy đủ thông tin'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);
    _subjectCtrl.clear();
    _messageCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Đã gửi báo cáo thành công. Chúng tôi sẽ phản hồi trong 24h.', style: TextStyle(color: Colors.white)),
      backgroundColor: AppColors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      duration: const Duration(seconds: 3),
    ));
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
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact info
                      _buildContactCard(),
                      const SizedBox(height: 20),
                      // FAQ
                      _buildSectionLabel('Câu hỏi thường gặp'),
                      const SizedBox(height: 10),
                      ..._faq.map((item) => _buildFaqItem(item['q']!, item['a']!)),
                      const SizedBox(height: 20),
                      // Report form
                      _buildSectionLabel('Gửi phản hồi / Báo cáo lỗi'),
                      const SizedBox(height: 10),
                      _buildReportForm(),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          const Text('Hỗ trợ & Báo cáo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2));
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.teal, AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Liên hệ hỗ trợ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 14),
          _buildContactRow(Icons.email_outlined, 'support@smartroomfinder.vn'),
          const SizedBox(height: 8),
          _buildContactRow(Icons.phone_outlined, '1800 1234 (Miễn phí)'),
          const SizedBox(height: 8),
          _buildContactRow(Icons.access_time_rounded, 'Thứ 2 - Thứ 6: 8:00 - 17:00'),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 16),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.help_outline_rounded, color: AppColors.teal, size: 18),
        ),
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        iconColor: AppColors.teal,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          Text(answer, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildReportForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Loại phản hồi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTypeChip('bug', Icons.bug_report_outlined, 'Báo lỗi'),
              const SizedBox(width: 8),
              _buildTypeChip('suggest', Icons.lightbulb_outline_rounded, 'Góp ý'),
              const SizedBox(width: 8),
              _buildTypeChip('other', Icons.more_horiz_rounded, 'Khác'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Tiêu đề', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectCtrl,
            decoration: _inputDecoration('Nhập tiêu đề...', Icons.title_rounded),
          ),
          const SizedBox(height: 14),
          const Text('Nội dung', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration: _inputDecoration('Mô tả chi tiết vấn đề...', Icons.message_outlined),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_loading ? 'Đang gửi...' : 'Gửi phản hồi', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, IconData icon, String label) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedType = type); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : AppColors.mintLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.teal : AppColors.mintGreen, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
    prefixIcon: Icon(icon, color: AppColors.teal, size: 20),
    filled: true,
    fillColor: AppColors.mintLight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
  );
}
