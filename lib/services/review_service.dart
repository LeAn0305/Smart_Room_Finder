import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_room_finder/models/review_model.dart';
import 'package:smart_room_finder/models/room_model.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<ReviewModel>> getReviews(String roomId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('roomId', isEqualTo: roomId)
        .get();

    final reviews = snapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
        .where((r) => r.isHidden == false)
        .toList();
    
    // Sort locally by createdAt descending to avoid composite index requirement
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
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

    // Check if user already reviewed
    final existingSnapshot = await _firestore.collection('reviews')
      .where('roomId', isEqualTo: room.id)
      .where('userId', isEqualTo: review.userId)
      .get();

    final roomRef = _firestore.collection('rooms').doc(room.id);

    if (existingSnapshot.docs.isNotEmpty) {
      // Update existing review
      final doc = existingSnapshot.docs.first;
      final oldReview = ReviewModel.fromMap(doc.data(), doc.id);
      
      batch.update(doc.reference, {
        'rating': review.rating,
        'comment': review.comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update room rating
      final int currentTotal = room.totalReviews > 0 ? room.totalReviews : 1;
      final double currentRating = room.rating;
      final double newRating = ((currentRating * currentTotal) - oldReview.rating + review.rating) / currentTotal;
      
      batch.update(roomRef, {
        'rating': double.parse(newRating.toStringAsFixed(1)),
      });
    } else {
      // Add new review
      final reviewRef = _firestore.collection('reviews').doc();
      batch.set(reviewRef, review.toMap());

      // Update room average rating & total reviews
      final int currentTotal = room.totalReviews;
      final double currentRating = room.rating;
      final int newTotal = currentTotal + 1;
      final double newRating = ((currentRating * currentTotal) + review.rating) / newTotal;

      batch.update(roomRef, {
        'totalReviews': newTotal,
        'rating': double.parse(newRating.toStringAsFixed(1)),
      });
    }

    await batch.commit();
  }
}
