import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/models/view_history_model.dart';

class ViewHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'view_history';

  static Future<void> addToHistory(RoomModel room) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final query = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('roomId', isEqualTo: room.id)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await _firestore.collection(_collection).doc(query.docs.first.id).update({
        'viewedAt': DateTime.now().toIso8601String(),
      });
      return;
    }

    final docRef = _firestore.collection(_collection).doc();

    final history = ViewHistoryModel(
      id: docRef.id,
      userId: user.uid,
      roomId: room.id,
      title: room.title,
      price: room.price.toDouble(),
      address: room.address,
      imageUrl: room.imageUrl,
      viewedAt: DateTime.now(),
    );

    await docRef.set(history.toMap());
  }

  static Future<List<ViewHistoryModel>> getUserHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('viewedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ViewHistoryModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  static Future<void> clearHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> deleteHistoryItem(String historyId) async {
    await _firestore.collection(_collection).doc(historyId).delete();
  }

  static Future<RoomModel?> getRoomById(String roomId) async {
    final doc = await _firestore.collection('rooms').doc(roomId).get();

    if (!doc.exists || doc.data() == null) return null;

    return RoomModel.fromFirebase(doc.data()!, doc.id);
  }
  
}