import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/core/providers/favorite_provider.dart';

class RoomCard extends StatefulWidget {
  final RoomModel room;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isHorizontal;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.onFavoriteTap,
    this.isHorizontal = false,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool isHovered = false;

  IconData _getAmenityIcon(String amenity) {
    final a = amenity.toLowerCase();
    if (a.contains('wifi')) return Icons.wifi_rounded;
    if (a.contains('lạnh') || a.contains('điều hòa')) return Icons.ac_unit_rounded;
    if (a.contains('tủ lạnh')) return Icons.kitchen_rounded;
    if (a.contains('giặt')) return Icons.local_laundry_service_rounded;
    if (a.contains('bếp')) return Icons.outdoor_grill_rounded;
    if (a.contains('xe')) return Icons.directions_car_rounded;
    if (a.contains('hồ bơi')) return Icons.pool_rounded;
    if (a.contains('gym')) return Icons.fitness_center_rounded;
    if (a.contains('an ninh') || a.contains('bảo vệ')) return Icons.security_rounded;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.watch<FavoriteProvider>().isFavorite(widget.room.id);
    final cardWidth = widget.isHorizontal ? 260.0 : double.infinity;
    final imageHeight = widget.isHorizontal ? 150.0 : 195.0;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedScale(
        scale: isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: cardWidth,
            margin: EdgeInsets.only(
              bottom: widget.isHorizontal ? 0 : 16,
              right: widget.isHorizontal ? 14 : 0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isHovered ? 0.12 : 0.07),
                  blurRadius: isHovered ? 24 : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Ảnh ──────────────────────────────────────
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'room_image_${widget.room.id}',
                        child: _buildImage(imageHeight),
                      ),
                      // Gradient phủ dưới ảnh
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.0),
                                Colors.black.withValues(alpha: 0.38),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Nút yêu thích
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: widget.onFavoriteTap,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFavorite ? Colors.redAccent : AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      // Badge xác thực
                      if (widget.room.isVerified)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Xác thực',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      // Giá
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.teal, AppColors.tealDark],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '${(widget.room.price / 1000000).toStringAsFixed(1)}tr / tháng',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Nội dung ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loại phòng + Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.mintSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.room.typeString.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.tealDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 3),
                              Text(
                                widget.room.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tên phòng
                      Text(
                        widget.room.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Địa chỉ
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.teal, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.room.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Diện tích + phòng ngủ nếu có
                      if (widget.room.area != null || widget.room.bedrooms != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (widget.room.area != null) ...[
                              const Icon(Icons.square_foot_rounded, color: AppColors.textSecondary, size: 13),
                              const SizedBox(width: 3),
                              Text('${widget.room.area!.toInt()}m²',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                            ],
                            if (widget.room.bedrooms != null) ...[
                              const Icon(Icons.bed_rounded, color: AppColors.textSecondary, size: 13),
                              const SizedBox(width: 3),
                              Text('${widget.room.bedrooms} PN',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Tiện ích
                      Row(
                        children: [
                          ...widget.room.amenities.take(3).map(
                                (a) => Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(_getAmenityIcon(a),
                                      size: 18,
                                      color: AppColors.tealDark.withValues(alpha: 0.75)),
                                ),
                              ),
                          if (widget.room.amenities.length > 3)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.mintSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+${widget.room.amenities.length - 3}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w800,
                                ),
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

  Widget _buildImage(double height) {
    final url = widget.room.imageUrl;
    if (url.startsWith('assets/')) {
      return Image.asset(url,
          height: height, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(height));
    }
    return Image.network(url,
        height: height, width: double.infinity, fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _placeholder(height),
        errorBuilder: (_, _, _) => _placeholder(height));
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.mintSoft,
      child: const Center(
        child: Icon(Icons.image_not_supported_rounded,
            color: AppColors.teal, size: 40),
      ),
    );
  }
}
