import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/models/application_model.dart';
import 'package:smart_room_finder/models/chat_model.dart';
import 'package:smart_room_finder/services/chat_service.dart';
import 'package:smart_room_finder/services/fcm_service.dart';

class ApplicationService {
  static final _db = FirebaseFirestore.instance;
  static final _col = _db.collection('applications');

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Kiểm tra đã gửi đơn cho phòng này chưa ─────────────
  static Future<ApplicationModel?> getExistingApplication({
    required String roomId,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    // Query theo renterId trước, lọc roomId ở client để tránh cần composite index
    final snap = await _col
        .where('renterId', isEqualTo: uid)
        .get();

    final docs = snap.docs.where((d) => d.data()['roomId'] == roomId).toList();
    if (docs.isEmpty) return null;
    return ApplicationModel.fromMap(docs.first.data(), docs.first.id);
  }

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

    // Kiểm tra đã có đơn cho phòng này chưa
    final existing = await getExistingApplication(roomId: roomId);
    if (existing != null) {
      throw Exception('DUPLICATE:${existing.id}');
    }

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
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ApplicationModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Stream đơn của chủ nhà ───────────────────────────────
  static Stream<List<ApplicationModel>> ownerApplicationsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _col
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ApplicationModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── Cập nhật trạng thái đơn ──────────────────────────────
  static Future<void> updateStatus(String applicationId, String status,
      {String note = ''}) async {
    await _col.doc(applicationId).update({
      'status': status,
      'note': note,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Gửi notification cho người thuê khi đơn được duyệt/từ chối
    if (status == 'approved' || status == 'rejected') {
      _sendApplicationStatusNotification(applicationId, status);
    }
  }

  static Future<void> _sendApplicationStatusNotification(
      String applicationId, String status) async {
    try {
      final doc = await _col.doc(applicationId).get();
      if (!doc.exists) return;

      final app = ApplicationModel.fromMap(doc.data()!, doc.id);
      final isApproved = status == 'approved';

      await FCMService.saveNotification(
        toUid: app.renterId,
        title: isApproved ? '🎉 Đơn thuê được chấp nhận!' : '❌ Đơn thuê bị từ chối',
        body: isApproved
            ? 'Chủ nhà đã chấp nhận đơn thuê phòng "${app.roomTitle}" của bạn.'
            : 'Chủ nhà đã từ chối đơn thuê phòng "${app.roomTitle}".',
        type: isApproved ? 'application_approved' : 'application_rejected',
        refId: applicationId,
      );
    } catch (e) {
      // Không để lỗi notification ảnh hưởng việc cập nhật đơn
    }
  }

  // ── Xóa đơn (chủ trọ xóa khỏi danh sách) ──────────────
  static Future<void> deleteApplication(String applicationId) async {
    await _col.doc(applicationId).delete();
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
