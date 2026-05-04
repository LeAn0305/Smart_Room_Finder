import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/models/application_model.dart';
import 'package:smart_room_finder/models/chat_model.dart';
import 'package:smart_room_finder/services/chat_service.dart';

class ApplicationService {
  static final _db = FirebaseFirestore.instance;
  static final _col = _db.collection('applications');

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Gửi đơn đặt phòng + tạo chat ────────────────────────
  static Future<({String applicationId, String chatId})> submitApplication({
    required String roomId,
    required String roomTitle,
    required String roomImageUrl,
    required String ownerId,
    required String ownerName,
    required String renterName,
    required String renterPhone,
    required String message,
    required String expectedMoveInDate,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Chưa đăng nhập');

    final now = DateTime.now().toIso8601String();

    // 1. Tạo application document
    final appRef = _col.doc();
    final application = ApplicationModel(
      id: appRef.id,
      roomId: roomId,
      roomTitle: roomTitle,
      roomImageUrl: roomImageUrl,
      ownerId: ownerId,
      ownerName: ownerName,
      renterId: uid,
      renterName: renterName,
      renterPhone: renterPhone,
      message: message,
      status: 'pending',
      expectedMoveInDate: expectedMoveInDate,
      note: '',
      createdAt: now,
      updatedAt: now,
    );
    await appRef.set(application.toMap());

    // 2. Tạo hoặc lấy chat liên kết
    final chat = ChatModel(
      id: '',
      roomId: roomId,
      roomTitle: roomTitle,
      roomImageUrl: roomImageUrl,
      ownerId: ownerId,
      ownerName: ownerName,
      renterId: uid,
      renterName: renterName,
      lastMessage: message.isNotEmpty ? message : 'Đã gửi yêu cầu đặt phòng',
      lastMessageTime: now,
      lastSenderId: uid,
      participants: [uid, ownerId],
      createdAt: now,
      updatedAt: now,
      applicationId: appRef.id,
    );
    final chatId = await ChatService.getOrCreateChat(chat);

    return (applicationId: appRef.id, chatId: chatId);
  }

  // ── Stream đơn của người thuê ────────────────────────────
  static Stream<List<ApplicationModel>> myApplicationsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _col
        .where('renterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ApplicationModel.fromMap(d.data(), d.id)).toList());
  }

  // ── Stream đơn của chủ nhà ───────────────────────────────
  static Stream<List<ApplicationModel>> ownerApplicationsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _col
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ApplicationModel.fromMap(d.data(), d.id)).toList());
  }

  // ── Cập nhật trạng thái đơn ──────────────────────────────
  static Future<void> updateStatus(String applicationId, String status,
      {String note = ''}) async {
    await _col.doc(applicationId).update({
      'status': status,
      'note': note,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ── Hủy đơn ─────────────────────────────────────────────
  static Future<void> cancelApplication(String applicationId) async {
    await updateStatus(applicationId, 'cancelled');
  }

  // ── Lấy chat liên kết với đơn ───────────────────────────
  static Future<ChatModel?> getChatForApplication(
      String applicationId) async {
    final snap = await _db
        .collection('chats')
        .where('applicationId', isEqualTo: applicationId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return ChatModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }
}
