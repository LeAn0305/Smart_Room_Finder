import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';

class RoomDetailScreen extends StatelessWidget {
  final RoomModel room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image
                Hero(
                  tag: 'room_image_${room.id}',
                  child: Container(
                    height: isWideScreen ? 500 : 400,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: room.imageUrl.startsWith('assets/')
                            ? AssetImage(room.imageUrl) as ImageProvider
                            : NetworkImage(room.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Main Content Container
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type & Rating
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.mintSoft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      room.typeString.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.tealDark,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 28),
                                      const SizedBox(width: 4),
                                      Text(
                                        room.rating.toString(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(124 nhận xét)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary.withOpacity(0.6),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Title
                              Text(
                                room.title,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Location
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.location_on_rounded, color: AppColors.teal, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      room.address,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              const Divider(height: 1, color: AppColors.mintSoft),
                              const SizedBox(height: 32),

                              // Host Info Section
                              const Text(
                                'Thông tin chủ phòng',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=host'),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Nguyễn Văn A',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Chủ nhà siêu cấp • 5 năm kinh nghiệm',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary.withOpacity(0.8),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildActionButton(Icons.chat_bubble_rounded, AppColors.teal.withOpacity(0.1), AppColors.teal),
                                  const SizedBox(width: 12),
                                  _buildActionButton(Icons.phone_rounded, AppColors.teal, AppColors.white),
                                ],
                              ),
                              const SizedBox(height: 32),

                              const Divider(height: 1, color: AppColors.mintSoft),
                              const SizedBox(height: 32),

                              // Description
                              const Text(
                                'Mô tả chi tiết',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                room.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary.withOpacity(0.9),
                                  height: 1.7,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Amenities Section
                              const Text(
                                'Tiện ích căn phòng',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: room.amenities.map((amenity) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(color: AppColors.mintSoft, width: 2),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_getAmenityIcon(amenity), size: 20, color: AppColors.teal),
                                        const SizedBox(width: 12),
                                        Text(
                                          amenity,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom AppBar with SafeArea
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularButton(
                    context,
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      _buildCircularButton(
                        context,
                        icon: Icons.share_rounded,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      _buildCircularButton(
                        context,
                        icon: room.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        iconColor: room.isFavorite ? Colors.redAccent : AppColors.textPrimary,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng giá thuê',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${(room.price / 1000000).toStringAsFixed(1)}tr',
                                  style: const TextStyle(
                                    color: AppColors.teal,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' VNĐ/tháng',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Container(
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.teal, AppColors.tealDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withOpacity(0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Đặt lịch ngay',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  Widget _buildCircularButton(BuildContext context, {required IconData icon, required VoidCallback onTap, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 20),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi_rounded;
      case 'máy lạnh':
      case 'điều hòa':
        return Icons.ac_unit_rounded;
      case 'tủ lạnh':
        return Icons.kitchen_rounded;
      case 'máy giặt':
        return Icons.local_laundry_service_rounded;
      case 'bếp':
        return Icons.outdoor_grill_rounded;
      case 'chỗ để xe':
        return Icons.directions_car_rounded;
      case 'hồ bơi':
        return Icons.pool_rounded;
      case 'phòng gym':
        return Icons.fitness_center_rounded;
      case 'an ninh':
        return Icons.security_rounded;
      default:
        return Icons.done_rounded;
    }
  }
}
