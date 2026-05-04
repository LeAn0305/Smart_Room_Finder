import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/application_model.dart';
import 'package:smart_room_finder/services/application_service.dart';
import 'package:smart_room_finder/screens/chat/chat_detail_screen.dart';

class BookingStatusScreen extends StatelessWidget {
  final ApplicationModel application;

  const BookingStatusScreen({super.key, required this.application});

  Widget _buildDisplayImage(String imgPath) {
    if (imgPath.startsWith('assets/')) {
      return Image.asset(imgPath, fit: BoxFit.cover);
    } else if (imgPath.startsWith('http') || kIsWeb) {
      return Image.network(imgPath, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    } else if (imgPath.isNotEmpty) {
      return Image.file(File(imgPath), fit: BoxFit.cover);
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: AppColors.mintSoft,
        child: const Icon(Icons.home_rounded, color: AppColors.teal, size: 32),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ApplicationModel>>(
      stream: ApplicationService.myApplicationsStream(),
      builder: (context, snap) {
        // Lấy trạng thái mới nhất từ stream
        final liveApp = snap.data?.firstWhere(
          (a) => a.id == application.id,
          orElse: () => application,
        ) ?? application;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            title: const Text(
              'Tiến độ yêu cầu',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Info Card
                _buildRoomCard(liveApp),
                const SizedBox(height: 32),

                const Text(
                  'Chi tiết tiến trình',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Timeline
                _buildTimeline(liveApp.status),

                const SizedBox(height: 24),

                // Thông tin đơn
                _buildInfoSection(liveApp),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút nhắn tin chủ nhà
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openChat(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text(
                        'Nhắn tin với chủ nhà',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Hủy đơn (chỉ khi pending)
                  if (liveApp.status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _cancelApplication(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text(
                          'Hủy yêu cầu',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomCard(ApplicationModel app) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: _buildDisplayImage(app.roomImageUrl),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusBadge(app.status),
                const SizedBox(height: 8),
                Text(
                  app.roomTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chủ nhà: ${app.ownerName}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'ĐÃ DUYỆT';
        break;
      case 'rejected':
        color = Colors.redAccent;
        label = 'ĐÃ TỪ CHỐI';
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'ĐÃ HỦY';
        break;
      case 'completed':
        color = AppColors.teal;
        label = 'HOÀN TẤT';
        break;
      default:
        color = Colors.orange;
        label = 'ĐANG CHỜ DUYỆT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTimeline(String status) {
    final steps = [
      _TimelineStep(
        icon: Icons.send_rounded,
        title: 'Đã gửi yêu cầu',
        description: 'Yêu cầu của bạn đã được gửi đến chủ phòng.',
        isCompleted: true,
      ),
      _TimelineStep(
        icon: Icons.pending_actions_rounded,
        title: 'Đang phê duyệt',
        description: 'Chủ phòng đang xem xét yêu cầu của bạn.',
        isCompleted: ['approved', 'rejected', 'completed'].contains(status),
        isActive: status == 'pending',
        isFailed: status == 'rejected' || status == 'cancelled',
      ),
      _TimelineStep(
        icon: status == 'rejected'
            ? Icons.cancel_rounded
            : Icons.check_circle_outline_rounded,
        title: status == 'rejected' ? 'Đã từ chối' : 'Đã phê duyệt',
        description: status == 'rejected'
            ? 'Yêu cầu của bạn không được chấp nhận.'
            : 'Yêu cầu được chủ phòng xác nhận.',
        isCompleted: ['approved', 'completed'].contains(status),
        isActive: status == 'approved',
        isFailed: status == 'rejected',
      ),
      _TimelineStep(
        icon: Icons.task_alt_rounded,
        title: 'Hoàn tất đặt phòng',
        description: 'Thanh toán cọc hoặc làm hợp đồng.',
        isCompleted: status == 'completed',
        isLast: true,
      ),
    ];

    return Column(
      children: steps.map((s) => _buildTimelineItem(s)).toList(),
    );
  }

  Widget _buildTimelineItem(_TimelineStep step) {
    final Color color;
    if (step.isFailed) {
      color = Colors.redAccent;
    } else if (step.isCompleted || step.isActive) {
      color = AppColors.teal;
    } else {
      color = AppColors.textSecondary.withValues(alpha: 0.3);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: step.isCompleted
                      ? AppColors.teal
                      : (step.isFailed
                          ? Colors.redAccent
                          : (step.isActive ? AppColors.mintSoft : Colors.white)),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  step.icon,
                  color: (step.isCompleted || step.isFailed)
                      ? Colors.white
                      : color,
                  size: 20,
                ),
              ),
              if (!step.isLast)
                Expanded(
                  child: Container(width: 2, color: color),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: (step.isCompleted || step.isActive || step.isFailed)
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ApplicationModel app) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mintGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin đơn',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (app.expectedMoveInDate != null &&
              app.expectedMoveInDate!.isNotEmpty)
            _infoRow(Icons.calendar_today_rounded,
                'Ngày dọn vào', app.expectedMoveInDate!),
          if (app.renterPhone.isNotEmpty)
            _infoRow(Icons.phone_rounded, 'SĐT', app.renterPhone),
          if (app.message.isNotEmpty)
            _infoRow(Icons.message_rounded, 'Lời nhắn', app.message),
          if (app.note.isNotEmpty)
            _infoRow(Icons.note_rounded, 'Ghi chú chủ nhà', app.note),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.teal),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    try {
      final chat =
          await ApplicationService.getChatForApplication(application.id);
      if (chat == null || !context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chat)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở chat: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _cancelApplication(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hủy yêu cầu?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Bạn có chắc muốn hủy yêu cầu đặt phòng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApplicationService.cancelApplication(application.id);
      if (!context.mounted) return;
      Navigator.pop(context);
    }
  }
}

class _TimelineStep {
  final IconData icon;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isActive;
  final bool isFailed;
  final bool isLast;

  _TimelineStep({
    required this.icon,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.isActive = false,
    this.isFailed = false,
    this.isLast = false,
  });
}
