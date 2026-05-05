import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_room_finder/models/user_model.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  // ── Lấy user theo UID ────────────────────────────────────
  static Future<UserModel?> getUserById(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirebase(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // ── Stream user theo UID (realtime) ──────────────────────
  static Stream<UserModel?> userStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirebase(doc.data()!, doc.id);
    });
  }
}
