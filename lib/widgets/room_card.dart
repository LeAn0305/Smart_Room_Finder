import 'package:flutter/material.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';

class RoomCard extends StatefulWidget {
  final RoomModel room;
  final VoidCallback? onTap;
  final bool isHorizontal;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.isHorizontal = false,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool isHovered = false;

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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedScale(
        scale: isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: widget.isHorizontal ? 280 : double.infinity,
          margin: const EdgeInsets.only(bottom: 16, right: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withOpacity(isHovered ? 0.12 : 0.06),
                blurRadius: isHovered ? 25 : 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: 'room_image_${widget.room.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: widget.room.imageUrl.startsWith('assets/')
                            ? Image.asset(
                                widget.room.imageUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 180,
                                  color: AppColors.mintSoft,
                                  child: const Icon(Icons.image_not_supported_rounded, color: AppColors.teal, size: 40),
                                ),
                              )
                            : Image.network(
                                widget.room.imageUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 180,
                                  color: AppColors.mintSoft,
                                  child: const Icon(Icons.image_not_supported_rounded, color: AppColors.teal, size: 40),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.room.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: widget.room.isFavorite ? Colors.redAccent : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    if (widget.room.isVerified)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified_rounded, color: AppColors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Xác thực',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.teal, AppColors.tealDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '${(widget.room.price / 1000000).toStringAsFixed(1)}tr VNĐ/tháng',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.mintSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.room.typeString,
                              style: const TextStyle(
                                color: AppColors.tealDark,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                widget.room.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.room.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.textSecondary, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.room.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.mintSoft),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ...widget.room.amenities.take(3).map((amenity) => Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getAmenityIcon(amenity),
                                      size: 14,
                                      color: AppColors.teal,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      amenity,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          if (widget.room.amenities.length > 3)
                            Text(
                              '+${widget.room.amenities.length - 3}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
