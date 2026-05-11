import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/application_model.dart';
import 'package:smart_room_finder/models/chat_model.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:smart_room_finder/services/application_service.dart';
import 'package:smart_room_finder/services/auth_service.dart';
import 'package:smart_room_finder/services/chat_service.dart';
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
  UserRole? _userRole;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadUserRole();

    // Nếu vừa gửi đơn xong → tự mở chat
    if (widget.openChatId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openChatById(widget.openChatId!);
      });
    }
  }

  Future<void> _loadUserRole() async {
    final user = await AuthService.getCurrentUserData();
    if (!mounted) return;
    setState(() {
      _userRole = user?.role;
      _isLoadingRole = false;
      // Chủ trọ → mặc định mở tab "Nhận được" (index 1)
      if (_userRole == UserRole.landlord) {
        _tabCtrl.index = 1;
      }
    });
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
    if (_isLoadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }

    final isLandlord = _userRole == UserRole.landlord;

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
              // Chỉ hiện TabBar nếu không xác định được role (fallback)
              if (_userRole == null) _buildTabBar(),
              Expanded(
                child: _userRole == null
                    // Không xác định role → hiện cả 2 tab
                    ? TabBarView(
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
                      )
                    : isLandlord
                        // Chủ trọ → chỉ hiện đơn nhận được
                        ? _ApplicationList(
                            stream: ApplicationService.ownerApplicationsStream(),
                            emptyLabel: 'Chưa có đơn nào từ người thuê',
                            isOwnerView: true,
                          )
                        // Người thuê → chỉ hiện đơn của tôi
                        : _ApplicationList(
                            stream: ApplicationService.myApplicationsStream(),
                            emptyLabel: 'Bạn chưa gửi đơn nào',
                            highlightId: widget.highlightApplicationId,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isLandlord = _userRole == UserRole.landlord;
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
          Text(
            isLandlord ? 'Tiếp nhận đơn yêu cầu' : 'Đơn yêu cầu',
            style: const TextStyle(
              fontSize: 22,
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
          color: isHighlighted ? AppColors.teal : Colors.white,
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
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            Icon(status.icon, size: 12, color: status.color),
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

          // ── Thông tin người thuê (chỉ hiện bên chủ trọ) ─
          if (isOwnerView) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.15), width: 1),
              ),
              child: Column(
                children: [
                  // Tên người thuê
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 14, color: AppColors.teal),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          application.renterName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // SĐT
                  if (application.renterPhone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.phone_rounded,
                              size: 14, color: Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          application.renterPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Ngày gửi đơn
                  if (application.createdAt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Gửi lúc: ${_formatDate(application.createdAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Ngày dọn vào ─────────────────────────────────
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

          // ── Lời nhắn ─────────────────────────────────────
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

          // ── Nút hành động ────────────────────────────────
          if (isOwnerView && application.status == 'pending')
            // Chủ trọ + đơn đang chờ → hiện nút Duyệt / Từ chối nổi bật
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Nút Duyệt / Từ chối to và rõ ràng
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(context, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('Chấp nhận',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(context, 'rejected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          label: const Text('Từ chối',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            // Người thuê hoặc đơn đã xử lý → nút thường
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
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
                  // Nút xóa đơn cho chủ trọ (đơn đã xử lý xong)
                  if (isOwnerView &&
                      (application.status == 'approved' ||
                          application.status == 'rejected' ||
                          application.status == 'cancelled')) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _confirmDelete(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent, size: 20),
                      ),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Xóa đơn yêu cầu',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn xóa đơn này khỏi danh sách không?\nHành động này không thể hoàn tác.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ApplicationService.deleteApplication(application.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa đơn yêu cầu'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openChat(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để nhắn tin'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Đang mở chat...'),
        ]),
        duration: Duration(seconds: 10),
        backgroundColor: AppColors.teal,
      ),
    );

    try {
      final now = DateTime.now().toIso8601String();
      final chatModel = ChatModel(
        id: '',
        roomId: application.roomId,
        roomTitle: application.roomTitle,
        roomImageUrl: application.roomImageUrl,
        ownerId: application.ownerId,
        ownerName: application.ownerName,
        renterId: application.renterId,
        renterName: application.renterName,
        lastMessage: '',
        lastMessageTime: now,
        lastSenderId: '',
        participants: [application.ownerId, application.renterId],
        createdAt: now,
        updatedAt: now,
      );

      final chatId = await ChatService.getOrCreateChat(chatModel);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final chat = chatModel.copyWith(id: chatId);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chat)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
