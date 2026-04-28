import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/report_model.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/services/auth_service.dart';
import 'package:smart_room_finder/services/report_service.dart';

class ReportBottomSheet extends StatefulWidget {
  final RoomModel room;

  const ReportBottomSheet({super.key, required this.room});

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  final List<String> _reasons = [
    'Thông tin sai lệch / Ảnh không thực tế',
    'Giá không đúng thực tế',
    'Phòng không còn trống nhưng vẫn đăng',
    'Nội dung lừa đảo',
    'Lý do khác',
  ];
  
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một lý do báo cáo')),
      );
      return;
    }

    if (_selectedReason == 'Lý do khác' && _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mô tả chi tiết')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = await AuthService.getCurrentUserData();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập để báo cáo')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final hasReported = await ReportService.hasUserReported(widget.room.id, user.id);
      if (hasReported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn đã báo cáo bài đăng này rồi')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final report = ReportModel(
        id: '',
        roomId: widget.room.id,
        reporterId: user.id,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ReportService.addReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn, báo cáo của bạn đã được ghi nhận')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại sau.')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Báo cáo bài đăng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Tại sao bạn muốn báo cáo bài đăng này?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          ..._reasons.map((reason) {
            return RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              activeColor: AppColors.teal,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
            );
          }),
          if (_selectedReason == 'Lý do khác') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập mô tả chi tiết...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Gửi báo cáo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
