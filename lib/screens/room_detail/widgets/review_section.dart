import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/review_model.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/services/auth_service.dart';
import 'package:smart_room_finder/services/review_service.dart';
import 'package:intl/intl.dart';

class ReviewSection extends StatefulWidget {
  final RoomModel room;
  final VoidCallback onReviewAdded;

  const ReviewSection({
    super.key,
    required this.room,
    required this.onReviewAdded,
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  bool _hasReviewed = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getCurrentUserData();
      _currentUserId = user?.id;

      final reviews = await ReviewService.getReviews(widget.room.id);
      
      bool hasReviewed = false;
      if (_currentUserId != null) {
        hasReviewed = await ReviewService.hasUserReviewed(widget.room.id, _currentUserId!);
      }

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _hasReviewed = hasReviewed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddReviewSheet() {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
              const Text(
                'Viết đánh giá',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: RatingBar.builder(
                  initialRating: 5,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    selectedRating = rating;
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập nhận xét của bạn về phòng này...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập nhận xét')),
                      );
                      return;
                    }

                    final user = await AuthService.getCurrentUserData();
                    if (user == null) return;

                    final newReview = ReviewModel(
                      id: '',
                      roomId: widget.room.id,
                      userId: user.id,
                      userName: user.name,
                      userAvatar: user.profileImageUrl,
                      rating: selectedRating,
                      comment: commentController.text.trim(),
                      createdAt: DateTime.now(),
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    await ReviewService.addReview(newReview, widget.room);
                    
                    widget.onReviewAdded();
                    _loadReviews();
                  },
                  child: const Text(
                    'Gửi đánh giá',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đánh giá',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            if (_currentUserId != null && !_hasReviewed)
              TextButton.icon(
                onPressed: _showAddReviewSheet,
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.teal),
                label: const Text(
                  'Viết đánh giá',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_reviews.isEmpty)
          const Text(
            'Chưa có đánh giá nào cho phòng này.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 30),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: review.userAvatar.isNotEmpty
                        ? NetworkImage(review.userAvatar)
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(review.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              review.rating.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review.comment,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
