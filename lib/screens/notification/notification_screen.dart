import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/screens/chat/chat_detail_screen.dart';
import 'package:smart_room_finder/screens/application/application_screen.dart';
import 'package:smart_room_finder/services/fcm_service.dart';
import 'package:smart_room_finder/services/chat_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Đánh dấu tất cả đã đọc khi mở màn hình
    FCMService.markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.mintGreen),
        ),
      ),
      body: _NotificationBody(),
    );
  }
}

class _NotificationBody extends StatelessWidget {
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  _NotificationBody();

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Center(
        child: Text('Vui lòng đăng nhập',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FCMService.notificationsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.teal));
        }

        final notifications = snap.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 52,
                    color: AppColors.teal.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có thông báo nào',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Thông báo tin nhắn và đơn thuê\nsẽ xuất hiện ở đây',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final n = notifications[i];
            return _NotificationTile(
              notification: n,
              onTap: () => _handleTap(context, n),
            );
          },
        );
      },
    );
  }

  void _handleTap(BuildContext context, Map<String, dynamic> n) async {
    final type = n['type'] as String? ?? '';
    final refId = n['refId'] as String? ?? '';

    if (type == 'message' && refId.isNotEmpty) {
      // Mở chat detail
      try {
        final chatDoc = await ChatService.getChatById(refId);
        if (chatDoc == null || !context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chatDoc)),
        );
      } catch (_) {}
    } else if (type == 'application_approved' ||
        type == 'application_rejected') {
      // Mở màn hình đơn yêu cầu
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationScreen(
            highlightApplicationId: refId.isNotEmpty ? refId : null,
          ),
        ),
      );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] as String? ?? '';
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final isRead = notification['isRead'] as bool? ?? true;
    final createdAt = notification['createdAt'] as String? ?? '';

    final info = _typeInfo(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.teal.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? Colors.white
                : AppColors.teal.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(info.icon, color: info.color, size: 22),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TypeInfo _typeInfo(String type) {
    switch (type) {
      case 'message':
        return _TypeInfo(Icons.chat_bubble_rounded, AppColors.teal);
      case 'application_approved':
        return _TypeInfo(Icons.check_circle_rounded, Colors.green);
      case 'application_rejected':
        return _TypeInfo(Icons.cancel_rounded, Colors.redAccent);
      default:
        return _TypeInfo(Icons.notifications_rounded, AppColors.teal);
    }
  }

  String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _TypeInfo {
  final IconData icon;
  final Color color;
  _TypeInfo(this.icon, this.color);
}
