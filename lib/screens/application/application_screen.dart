import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/application_model.dart';
import 'package:smart_room_finder/models/chat_model.dart';
import 'package:smart_room_finder/services/application_service.dart';
import 'package:smart_room_finder/screens/chat/chat_detail_screen.dart';
import 'package:smart_room_finder/screens/booking/booking_status_screen.dart';

class ApplicationScreen extends StatefulWidget {
  final String? highlightApplicationId;
  final String? openChatId;

  const ApplicationScreen({
    super.key,
    this.highlightApplicationId,
    this.openChatId,
  });

  @override
  State<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    // Nếu vừa gửi đơn xong → tự mở chat
    if (widget.openChatId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openChatById(widget.openChatId!);
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _openChatById(String chatId) async {
    final snap = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (snap == null || !mounted) return;

    final chatSnap = await ApplicationService.getChatForApplication(
        widget.highlightApplicationId ?? '');
    if (chatSnap == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chatSnap)),
    );
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
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _ApplicationList(
                      stream: ApplicationService.myApplicationsStream(),
                      emptyLabel: 'Bạn chưa gửi đơn nào',
                      highlightId: widget.highlightApplicationId,
                    ),
                    _ApplicationList(
                      stream: ApplicationService.ownerApplicationsStream(),
                      emptyLabel: 'Chưa có đơn nào từ người thuê',
                      isOwnerView: true,
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
              ),
            ),
          const SizedBox(width: 12),
          const Text(
            'Đơn yêu cầu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: AppColors.teal,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Đơn của tôi'),
          Tab(text: 'Nhận được'),
        ],
      ),
    );
  }
}

// ── Danh sách đơn ────────────────────────────────────────────
class _ApplicationList extends StatelessWidget {
  final Stream<List<ApplicationModel>> stream;
  final String emptyLabel;
  final bool isOwnerView;
  final String? highlightId;

  const _ApplicationList({
    required this.stream,
    required this.emptyLabel,
    this.isOwnerView = false,
    this.highlightId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ApplicationModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.teal));
        }

        final apps = snap.data ?? [];

        if (apps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.assignment_outlined,
                      size: 48,
                      color: AppColors.teal.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: apps.length,
          itemBuilder: (context, i) => _ApplicationCard(
            application: apps[i],
            isOwnerView: isOwnerView,
            isHighlighted: apps[i].id == highlightId,
          ),
        );
      },
    );
  }
}

// ── Application Card ─────────────────────────────────────────
class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final bool isOwnerView;
  final bool isHighlighted;

  const _ApplicationCard({
    required this.application,
    required this.isOwnerView,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(application.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? AppColors.teal
              : Colors.white,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? AppColors.teal.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isHighlighted ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Room image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: _buildImage(application.roomImageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.roomTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOwnerView
                            ? 'Từ: ${application.renterName}'
                            : 'Chủ nhà: ${application.ownerName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status.icon,
                                size: 12, color: status.color),
                            const SizedBox(width: 4),
                            Text(
                              status.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: status.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info row
          if (application.expectedMoveInDate != null &&
              application.expectedMoveInDate!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Dự kiến dọn vào: ${application.expectedMoveInDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          if (application.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        size: 16, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        application.message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                // Xem tiến độ
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openBookingStatus(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.timeline_rounded, size: 16),
                    label: const Text('Tiến độ',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                // Nhắn tin
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                    label: const Text('Nhắn tin',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                // Nếu là chủ nhà: thêm nút duyệt/từ chối
                if (isOwnerView &&
                    application.status == 'pending') ...[
                  const SizedBox(width: 10),
                  _iconBtn(
                    Icons.check_rounded,
                    Colors.green,
                    () => _updateStatus(context, 'approved'),
                  ),
                  const SizedBox(width: 6),
                  _iconBtn(
                    Icons.close_rounded,
                    Colors.redAccent,
                    () => _updateStatus(context, 'rejected'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
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

  void _openBookingStatus(BuildContext context) {
    // Tạo RoomModel tạm để hiển thị BookingStatusScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingStatusScreen(
          application: application,
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      await ApplicationService.updateStatus(application.id, status);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'approved' ? 'Đã duyệt đơn' : 'Đã từ chối đơn'),
        backgroundColor: status == 'approved' ? Colors.green : Colors.redAccent,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover);
    } else if (url.startsWith('http') || kIsWeb) {
      return Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    } else if (url.isNotEmpty) {
      return Image.file(File(url), fit: BoxFit.cover);
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: AppColors.mintSoft,
        child: const Icon(Icons.home_rounded, color: AppColors.teal),
      );

  _StatusInfo _statusInfo(String status) {
    switch (status) {
      case 'approved':
        return _StatusInfo(
            Icons.check_circle_rounded, Colors.green, 'Đã duyệt');
      case 'rejected':
        return _StatusInfo(
            Icons.cancel_rounded, Colors.redAccent, 'Đã từ chối');
      case 'cancelled':
        return _StatusInfo(
            Icons.block_rounded, Colors.grey, 'Đã hủy');
      case 'completed':
        return _StatusInfo(
            Icons.task_alt_rounded, AppColors.teal, 'Hoàn tất');
      default:
        return _StatusInfo(
            Icons.pending_rounded, Colors.orange, 'Đang chờ duyệt');
    }
  }
}

class _StatusInfo {
  final IconData icon;
  final Color color;
  final String label;
  _StatusInfo(this.icon, this.color, this.label);
}
