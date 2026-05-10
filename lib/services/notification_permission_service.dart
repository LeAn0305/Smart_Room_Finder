import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  /// Xin quyền notification — skip trên Windows/Linux/macOS
  static Future<bool> requestPermission() async {
    // Skip trên desktop
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      debugPrint('⚠️ NotificationPermission: skip trên desktop');
      return false;
    }

    // Web: Firebase Messaging tự xử lý quyền
    if (kIsWeb) return true;

    // Android 13+ cần xin quyền POST_NOTIFICATIONS
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (status.isDenied) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
    }

    return true;
  }

  static Future<bool> isGranted() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return false;
    }
    return await Permission.notification.isGranted;
  }
}
