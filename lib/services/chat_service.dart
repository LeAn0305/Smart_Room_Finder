import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/models/chat_model.dart';
import 'package:smart_room_finder/models/message_model.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;
  static final _chats = _db.collection('chats');

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Stream danh sách chat realtime ──────────────────────
  // Sort ở phía client theo updatedAt descending (tránh composite index)
  static Stream<List<ChatModel>> myChatsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _chats
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => ChatModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  // ── Stream tin nhắn realtime ─────────────────────────────
  static Stream<List<MessageModel>> messagesStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => MessageModel.fromMap(d.data(), d.id)).toList());
  }

  // ── Tạo hoặc lấy chat ───────────────────────────────────
  static Future<String> getOrCreateChat(ChatModel chat) async {
    final existing = await _chats
        .where('roomId', isEqualTo: chat.roomId)
        .where('renterId', isEqualTo: chat.renterId)
        .where('ownerId', isEqualTo: chat.ownerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final ref = await _chats.add(chat.toMap());
    return ref.id;
  }

  // ── Gửi tin nhắn + cập nhật lastMessage realtime ────────
  static Future<void> sendMessage(String chatId, MessageModel msg) async {
    final batch = _db.batch();
    final msgRef = _chats.doc(chatId).collection('messages').doc();
    batch.set(msgRef, msg.toMap());
    batch.update(_chats.doc(chatId), {
      'lastMessage': msg.text,
      'lastMessageTime': msg.createdAt,
      'lastSenderId': msg.senderId,
      'updatedAt': msg.createdAt,
    });
    await batch.commit();
  }

  // ── Đánh dấu đã đọc ─────────────────────────────────────
  static Future<void> markMessagesAsRead(String chatId) async {
    final uid = _uid;
    if (uid == null) return;

    final unread = await _chats
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: uid)
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Đếm tin nhắn chưa đọc ───────────────────────────────
  static Stream<int> unreadCountStream(String chatId) {
    final uid = _uid;
    if (uid == null) return Stream.value(0);

    return _chats
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ── Tổng tin nhắn chưa đọc (tất cả chat) ────────────────
  static Stream<int> totalUnreadStream() {
    final uid = _uid;
    if (uid == null) return Stream.value(0);

    return _chats
        .where('participants', arrayContains: uid)
        .snapshots()
        .asyncMap((chatsSnap) async {
      int total = 0;
      for (final chatDoc in chatsSnap.docs) {
        final unread = await chatDoc.reference
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .where('senderId', isNotEqualTo: uid)
            .get();
        total += unread.docs.length;
      }
      return total;
    });
  }
}
