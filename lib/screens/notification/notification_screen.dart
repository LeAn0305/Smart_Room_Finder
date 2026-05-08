import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/screens/chat/chat_screen.dart';
import 'package:smart_room_finder/screens/application/application_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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

  _NotificationBody({super.key});

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Center(
        child: Text('Vui lòng đăng nhập',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Tin nhắn chưa đọc ───────────────────────────
        _buildSection(
          context,
          icon: Icons.chat_bubble_rounded,
          color: AppColors.teal,
          title: 'Tin nhắn',
          subtitle: 'Xem các cuộc trò chuyện',
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: _uid)
              .snapshots()
              .asyncMap((snap) async {
            int total = 0;
            for (final doc in snap.docs) {
              final unread = await doc.reference
                  .collection('messages')
                  .where('isRead', isEqualTo: false)
                  .where('senderId', isNotEqualTo: _uid)
                  .get();
              total += unread.docs.length;
            }
            return total;
          }),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ChatScreen()),
          ),
        ),
        const SizedBox(height: 12),

        // ── Đơn yêu cầu ─────────────────────────────────
        _buildSection(
          context,
          icon: Icons.assignment_rounded,
          color: Colors.orange,
          title: 'Đơn yêu cầu',
          subtitle: 'Xem đơn thuê phòng',
          stream: FirebaseFirestore.instance
              .collection('applications')
              .where('ownerId', isEqualTo: _uid)
              .where('status', isEqualTo: 'pending')
              .snapshots()
              .map((s) => s.docs.length),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApplicationScreen()),
          ),
        ),
        const SizedBox(height: 12),

        // ── Đơn của tôi (renter) ─────────────────────────
        _buildSection(
          context,
          icon: Icons.home_rounded,
          color: AppColors.blue,
          title: 'Đơn của tôi',
          subtitle: 'Trạng thái đơn thuê phòng',
          stream: FirebaseFirestore.instance
              .collection('applications')
              .where('renterId', isEqualTo: _uid)
              .where('status', whereIn: ['accepted', 'rejected'])
              .snapshots()
              .map((s) => s.docs.length),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApplicationScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Stream<int> stream,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count > 0
                            ? '$count thông báo mới'
                            : subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: count > 0
                              ? color
                              : AppColors.textSecondary,
                          fontWeight: count > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}
