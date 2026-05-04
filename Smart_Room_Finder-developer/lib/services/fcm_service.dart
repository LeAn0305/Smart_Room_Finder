import 'package:flutter/foundation.dart'
    show kIsWeb, debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/services/local_notifications_service.dart';

class FCMService {
  /// Kiểm tra nền tảng có hỗ trợ FCM không (Android, iOS, Web)
  /// Windows/Linux/macOS desktop KHÔNG hỗ trợ FCM
  static bool get _supportsFCM {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> initFCM() async {
    // Không hỗ trợ Windows/Linux/macOS desktop — bỏ qua hoàn toàn
    if (!_supportsFCM) {
      debugPrint('FCMService: Nền tảng không hỗ trợ FCM, bỏ qua khởi tạo.');
      return;
    }

    try {
      // 1. Khởi tạo Local Notifications (chỉ Android/iOS, KHÔNG Windows)
      await LocalNotificationsService.initialize();

      // 2. Lắng nghe thông báo foreground (Android/iOS)
      if (LocalNotificationsService.isSupported) {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            LocalNotificationsService.showNotification(
              id: notification.hashCode,
              title: notification.title ?? '',
              body: notification.body ?? '',
            );
          }
        });
      }

      // 3. Xin quyền notification (bắt buộc trên Web để browser hiện popup)
      //    Trên Android quyền đã được xin qua NotificationPermissionService
      if (kIsWeb) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('FCMService: Web notification permission = ${settings.authorizationStatus}');
      }

      // 4. Lấy và lưu FCM Token vào Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _saveTokenToFirestore(user.uid, token);
        }

        // Lắng nghe token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _saveTokenToFirestore(user.uid, newToken);
        });
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo FCM: $e');
    }
  }

  /// Lưu FCM token vào Firestore, phân biệt web/android/ios token
  static Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      final Map<String, dynamic> updateData = {
        'fcmToken': token,
        'notificationsEnabled': true,
      };

      // Lưu thêm field riêng theo nền tảng để dễ phân biệt
      if (kIsWeb) {
        updateData['webFcmToken'] = token;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        updateData['androidFcmToken'] = token;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        updateData['iosFcmToken'] = token;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));

      debugPrint('FCMService: Đã lưu token cho uid=$uid (web=$kIsWeb)');
    } catch (e) {
      debugPrint('Không thể lưu FCM Token: $e');
    }
  }
}
