import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_room_finder/models/review_model.dart';
import 'package:smart_room_finder/models/room_model.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<ReviewModel>> getReviews(String roomId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('roomId', isEqualTo: roomId)
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Future<bool> hasUserReviewed(String roomId, String userId) async {
    if (userId.isEmpty) return false;
    final snapshot = await _firestore
        .collection('reviews')
        .where('roomId', isEqualTo: roomId)
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<void> addReview(ReviewModel review, RoomModel room) async {
    final batch = _firestore.batch();

    // 1. Add review
    final reviewRef = _firestore.collection('reviews').doc();
    batch.set(reviewRef, review.toMap());

    // 2. Update room average rating & total reviews
    final roomRef = _firestore.collection('rooms').doc(room.id);
    
    final int currentTotal = room.totalReviews;
    final double currentRating = room.rating;

    final int newTotal = currentTotal + 1;
    final double newRating = ((currentRating * currentTotal) + review.rating) / newTotal;

    batch.update(roomRef, {
      'totalReviews': newTotal,
      'rating': double.parse(newRating.toStringAsFixed(1)),
    });

    await batch.commit();
  }
}
