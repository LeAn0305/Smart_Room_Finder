import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// firebase_messaging hỗ trợ Android, iOS, Web — skip runtime trên desktop
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static final _db = FirebaseFirestore.instance;

  // ── Khởi tạo FCM ────────────────────────────────────────
  static Future<void> initialize() async {
    // Skip trên Windows/Linux/macOS desktop
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Xin quyền notification — nếu bị denied thì bỏ qua, không crash
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Nếu bị denied hoặc không được cấp quyền → skip, không lỗi
      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        return;
      }

      // Lấy và lưu FCM token
      await _saveToken();

      // Lắng nghe token refresh
      messaging.onTokenRefresh.listen((token) async {
        await _updateTokenInFirestore(token);
      });

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 FCM foreground: ${message.notification?.title}');
      });
    } catch (_) {
      // Bỏ qua mọi lỗi FCM — không ảnh hưởng app
    }
  }

  // ── Lưu FCM token sau khi đăng nhập ─────────────────────
  static Future<void> onUserLogin() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return;
    }
    await _saveToken();
  }

  static Future<void> _saveToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      String? token;

      if (kIsWeb) {
        try {
          token = await messaging.getToken();
        } catch (_) {
          // VAPID key chưa cấu hình hoặc permission bị block — bỏ qua
          return;
        }
      } else {
        token = await messaging.getToken();
      }

      if (token == null) return;
      await _updateTokenInFirestore(token);
    } catch (_) {
      // Bỏ qua lỗi token
    }
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final field = kIsWeb ? 'webFcmToken' : 'androidFcmToken';
      await _db.collection('users').doc(uid).set({
        field: token,
        'fcmToken': token,
        'notificationsEnabled': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Bỏ qua lỗi Firestore
    }
  }

  // ── Lưu in-app notification vào Firestore ───────────────
  // Dùng để hiển thị badge/list thông báo trong app
  static Future<void> saveNotification({
    required String toUid,       // uid người nhận
    required String title,
    required String body,
    required String type,        // 'message' | 'application_approved' | 'application_rejected'
    String? refId,               // chatId hoặc applicationId
  }) async {
    try {
      await _db
          .collection('users')
          .doc(toUid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'refId': refId ?? '',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Notification saved → $toUid ($type)');
    } catch (e) {
      debugPrint('❌ saveNotification error: $e');
    }
  }

  // ── Đếm notification chưa đọc ───────────────────────────
  static Stream<int> unreadNotificationStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    // Query đơn giản chỉ 1 field, không cần composite index
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ── Đánh dấu tất cả đã đọc ──────────────────────────────
  static Future<void> markAllRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Stream danh sách notifications ──────────────────────
  static Stream<List<Map<String, dynamic>>> notificationsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    // Không dùng orderBy để tránh cần composite index
    // Sort ở client thay thế
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .limit(50)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList();
          // Sort mới nhất lên đầu ở client
          list.sort((a, b) {
            final aTime = (a['createdAt'] as String?) ?? '';
            final bTime = (b['createdAt'] as String?) ?? '';
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }
}
