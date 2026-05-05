import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// NotificationService xử lý trạng thái notification và lưu FCM token vào Firestore.
/// Không dùng flutter_local_notifications để tránh crash trên Windows/Web.
/// Tự động skip trên các platform không hỗ trợ (Windows, Linux).
class NotificationService {
  static bool get _isSupported {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) return true;
    if (defaultTargetPlatform == TargetPlatform.iOS) return true;
    // Windows và Linux không hỗ trợ FCM push notification
    return false;
  }

  /// Khởi tạo notification service.
  /// Trả về true nếu platform được hỗ trợ, false nếu không.
  static Future<bool> initialize() async {
    if (!_isSupported) {
      debugPrint('⚠️ NotificationService: platform không hỗ trợ (${defaultTargetPlatform.name}), bỏ qua init.');
      return false;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _saveNotificationEnabled(user.uid, enabled: true);
      }
      debugPrint('✅ NotificationService: khởi tạo thành công.');
      return true;
    } catch (e) {
      debugPrint('❌ NotificationService.initialize lỗi: $e');
      return false;
    }
  }

  /// Lưu FCM token vào Firestore (gọi sau khi lấy được token từ firebase_messaging).
  static Future<void> saveFcmToken(String token) async {
    if (!_isSupported) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final field = kIsWeb ? 'webFcmToken' : 'androidFcmToken';
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          field: token,
          'fcmToken': token,
          'notificationsEnabled': true,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      debugPrint('✅ NotificationService: FCM token đã lưu ($field).');
    } catch (e) {
      debugPrint('❌ NotificationService: lỗi lưu FCM token: $e');
    }
  }

  /// Bật/tắt notification và cập nhật Firestore.
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!enabled) {
      await _clearTokens(user.uid);
    } else {
      await _saveNotificationEnabled(user.uid, enabled: true);
    }
  }

  static Future<void> _saveNotificationEnabled(String uid, {required bool enabled}) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'notificationsEnabled': enabled,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('❌ NotificationService: lỗi lưu Firestore: $e');
    }
  }

  static Future<void> _clearTokens(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'notificationsEnabled': false,
          'fcmToken': null,
          'androidFcmToken': null,
          'webFcmToken': null,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('❌ NotificationService: lỗi xóa token: $e');
    }
  }
}
