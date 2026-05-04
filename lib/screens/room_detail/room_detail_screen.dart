import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/chat_model.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'package:smart_room_finder/screens/booking/booking_status_screen.dart';
import 'package:smart_room_finder/screens/map/route_map_screen.dart';
import 'package:smart_room_finder/screens/room_detail/widgets/report_bottom_sheet.dart';
import 'package:smart_room_finder/screens/room_detail/widgets/review_section.dart';
import 'package:smart_room_finder/screens/application/send_application_screen.dart';
import 'package:smart_room_finder/screens/chat/chat_detail_screen.dart';
import 'package:smart_room_finder/services/chat_service.dart';
import 'package:smart_room_finder/services/view_history_service.dart';

class RoomDetailScreen extends StatefulWidget {
  final RoomModel room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  int _selectedImage = 0;
  late RoomModel _room;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _saveViewHistory();
  }

  Future<void> _saveViewHistory() async {
    try {
      await ViewHistoryService.addToHistory(widget.room);
    } catch (e) {
      debugPrint('Lỗi khi lưu lịch sử xem: $e');
    }
  }

  List<String> get _images {
    final base = [_room.imageUrl];
    final extras = _room.images.where((e) => e != _room.imageUrl).toList();
    return [...base, ...extras];
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(isWideScreen),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 900 : double.infinity,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mintSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  room.typeString.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.tealDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.orangeAccent,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    room.rating.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${room.totalReviews})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary.withValues(alpha: 
                                        0.7,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            room.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.teal,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room.address,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        if (room.latitude == 0 || room.longitude == 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Phòng này chưa có tọa độ để chỉ đường.'),
                                              backgroundColor: Colors.orange,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RouteMapScreen(room: room),
                                          ),
                                        );
                                      },
                                      child: const Row(
                                        children: [
                                          Icon(Icons.directions_rounded, size: 16, color: AppColors.teal),
                                          SizedBox(width: 4),
                                          Text(
                                            'Chỉ đường',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.teal,
                                              fontWeight: FontWeight.bold,
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
                          const SizedBox(height: 16),
                          _buildQuickStats(room),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.mintSoft),
                          const SizedBox(height: 20),
                          _buildHostSection(),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.mintSoft),
                          const SizedBox(height: 20),
                          const Text(
                            'Mô tả chi tiết',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            room.description,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary.withValues(alpha: 0.9),
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.mintSoft),
                          const SizedBox(height: 20),
                          const Text(
                            'Tiện ích căn phòng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: room.amenities
                                .map(
                                  (a) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.mintSoft,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _amenityIcon(a),
                                          size: 18,
                                          color: AppColors.teal,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          a,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.mintSoft),
                          const SizedBox(height: 20),
                          ReviewSection(
                            room: room,
                            onReviewAdded: () async {
                              // Fetch updated rooms
                              final provider = Provider.of<RoomProvider>(context, listen: false);
                              await provider.fetchRooms();
                              
                              final updatedRooms = provider.allRooms;
                              final updatedRoom = updatedRooms.firstWhere(
                                (r) => r.id == _room.id,
                                orElse: () => _room,
                              );
                              
                              if (mounted) {
                                setState(() {
                                  _room = updatedRoom;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleBtn(
                    Icons.arrow_back_ios_new_rounded,
                    () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      _circleBtn(Icons.flag_rounded, () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => ReportBottomSheet(room: room),
                        );
                      }),
                      const SizedBox(width: 10),
                      _circleBtn(Icons.share_rounded, () {}),
                      const SizedBox(width: 10),
                      _circleBtn(
                        room.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        () {},
                        iconColor: room.isFavorite
                            ? Colors.redAccent
                            : AppColors.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Giá thuê',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${(room.price / 1000000).toStringAsFixed(1)}tr',
                              style: const TextStyle(
                                color: AppColors.teal,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const TextSpan(
                              text: '/tháng',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng đăng nhập để đặt phòng'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SendApplicationScreen(room: room),
                          ),
                        );
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.teal, AppColors.tealDark],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Đặt lịch ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildImageSection(bool isWideScreen) {
    final images = _images;
    final mainImage = images[_selectedImage];

    return Column(
      children: [
        Hero(
          tag: 'room_image_${widget.room.id}',
          child: SizedBox(
            height: isWideScreen ? 420 : 300,
            width: double.infinity,
            child: _buildDisplayImage(mainImage),
          ),
        ),
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(images.length, (i) {
                final sel = _selectedImage == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImage = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? AppColors.teal : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildThumbImage(images[i]),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayImage(String imgPath) {
    if (imgPath.startsWith('assets/')) {
      return Image.asset(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorImage(),
      );
    } else if (imgPath.startsWith('http') || kIsWeb) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorImage(),
      );
    } else {
      return Image.file(
        File(imgPath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorImage(),
      );
    }
  }

  Widget _buildThumbImage(String imgPath) {
    if (imgPath.startsWith('assets/')) {
      return Image.asset(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorThumb(),
      );
    } else if (imgPath.startsWith('http') || kIsWeb) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorThumb(),
      );
    } else {
      return Image.file(
        File(imgPath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorThumb(),
      );
    }
  }

  Widget _errorImage() => Container(
        color: AppColors.mintSoft,
        child: const Center(
          child: Icon(
            Icons.image_rounded,
            color: AppColors.teal,
            size: 42,
          ),
        ),
      );

  Widget _errorThumb() => Container(
        color: AppColors.mintSoft,
        child: const Icon(
          Icons.image_rounded,
          color: AppColors.teal,
        ),
      );

  Widget _buildQuickStats(RoomModel room) {
    final stats = [
      if (room.area > 0)
        (Icons.square_foot_rounded, '${room.area.toInt()}m²', 'Diện tích'),
      if (room.bedrooms > 0)
        (Icons.bed_rounded, '${room.bedrooms} PN', 'Phòng ngủ'),
      if (room.direction != null)
        (Icons.explore_rounded, room.directionString, 'Hướng'),
      (Icons.visibility_rounded, '${room.viewCount}', 'Lượt xem'),
    ];

    if (stats.isEmpty) return const SizedBox.shrink();

    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(s.$1, color: AppColors.teal, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      s.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      s.$3,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildHostSection() {
    final room = widget.room;
    return Row(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=host'),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.postedBy.isNotEmpty ? room.postedBy : 'Chủ nhà',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Chủ nhà • Smart Room Finder',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async => _openChatWithOwner(context),
          child: _actionBtn(
            Icons.chat_bubble_rounded,
            AppColors.teal.withValues(alpha: 0.1),
            AppColors.teal,
          ),
        ),
        const SizedBox(width: 10),
        _actionBtn(Icons.phone_rounded, AppColors.teal, Colors.white),
      ],
    );
  }

  Future<void> _openChatWithOwner(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để nhắn tin'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final room = widget.room;

    // Nếu là chủ phòng thì không chat với chính mình
    if (room.ownerId == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đây là phòng của bạn')),
      );
      return;
    }

    // Hiện loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Đang mở chat...'),
            ],
          ),
          duration: Duration(seconds: 10),
          backgroundColor: AppColors.teal,
        ),
      );
    }

    try {
      final now = DateTime.now().toIso8601String();
      final displayName =
          FirebaseAuth.instance.currentUser?.displayName ?? 'Người thuê';

      final chat = ChatModel(
        id: '',
        roomId: room.id,
        roomTitle: room.title,
        roomImageUrl:
            room.imageUrl.isNotEmpty ? room.imageUrl : room.mainImageUrl,
        ownerId: room.ownerId.isNotEmpty ? room.ownerId : uid,
        ownerName: room.postedBy.isNotEmpty ? room.postedBy : 'Chủ nhà',
        renterId: uid,
        renterName: displayName,
        lastMessage: '',
        lastSenderId: uid,
        participants: [uid, room.ownerId.isNotEmpty ? room.ownerId : uid],
        createdAt: now,
        updatedAt: now,
      );

      final chatId = await ChatService.getOrCreateChat(chat);
      final chatWithId = chat.copyWith(id: chatId);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chatWithId)),
      );
    } catch (e) {
      debugPrint('❌ Lỗi mở chat: $e');
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

  Widget _actionBtn(IconData icon, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }

  IconData _amenityIcon(String a) {
    switch (a.toLowerCase()) {
      case 'wifi':
        return Icons.wifi_rounded;
      case 'máy lạnh':
      case 'may lanh':
        return Icons.ac_unit_rounded;
      case 'tủ lạnh':
      case 'tu lanh':
        return Icons.kitchen_rounded;
      case 'máy giặt':
      case 'may giat':
        return Icons.local_laundry_service_rounded;
      case 'bếp':
      case 'bep':
        return Icons.outdoor_grill_rounded;
      case 'chỗ để xe':
      case 'cho de xe':
        return Icons.directions_car_rounded;
      case 'hồ bơi':
      case 'ho boi':
        return Icons.pool_rounded;
      case 'phòng gym':
      case 'phong gym':
        return Icons.fitness_center_rounded;
      case 'an ninh':
        return Icons.security_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }
}