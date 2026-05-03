import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String roomId;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isHidden;

  ReviewModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isHidden = false,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReviewModel(
      id: docId,
      roomId: map['roomId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isHidden: map['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
      'isHidden': isHidden,
    };
  }
}
