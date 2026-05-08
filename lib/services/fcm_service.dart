import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Chỉ import firebase_messaging và flutter_local_notifications trên mobile/web
// Không import trên Windows/Linux/macOS desktop để tránh lỗi platform
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static final _db = FirebaseFirestore.instance;

  /// Khởi tạo FCM — skip hoàn toàn trên Windows/Linux/macOS desktop
  static Future<void> initialize() async {
    // Skip trên desktop platforms (Windows, Linux, macOS)
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      debugPrint('⚠️ FCMService: skip trên desktop platform');
      return;
    }

    try {
      // Xin quyền notification
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

      // Lấy và lưu FCM token
      await _saveToken();

      // Lắng nghe token refresh
      messaging.onTokenRefresh.listen((token) async {
        await _updateTokenInFirestore(token, isWeb: kIsWeb);
      });

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 FCM foreground: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('❌ FCMService.initialize error: $e');
    }
  }

  static Future<void> _saveToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      String? token;

      if (kIsWeb) {
        // Web cần VAPID key — nếu chưa có thì bỏ qua
        try {
          token = await messaging.getToken();
        } catch (e) {
          debugPrint('⚠️ Web FCM token error (VAPID missing?): $e');
          return;
        }
      } else {
        token = await messaging.getToken();
      }

      if (token == null) return;
      debugPrint('✅ FCM Token: ${token.substring(0, 20)}...');
      await _updateTokenInFirestore(token, isWeb: kIsWeb);
    } catch (e) {
      debugPrint('❌ _saveToken error: $e');
    }
  }

  static Future<void> _updateTokenInFirestore(String token,
      {required bool isWeb}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final field = isWeb ? 'webFcmToken' : 'androidFcmToken';
      await _db.collection('users').doc(uid).set({
        field: token,
        'fcmToken': token,
        'notificationsEnabled': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      debugPrint('✅ FCM token saved to Firestore ($field)');
    } catch (e) {
      debugPrint('❌ _updateTokenInFirestore error: $e');
    }
  }

  /// Gọi sau khi user đăng nhập để lưu token
  static Future<void> onUserLogin() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      return;
    }
    await _saveToken();
  }
}
