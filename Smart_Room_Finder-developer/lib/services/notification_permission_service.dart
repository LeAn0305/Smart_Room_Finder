import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';

/// Service xin quyền notification trên Android 13+ (API 33).
/// Trên các phiên bản cũ hơn, quyền được cấp tự động.
class NotificationPermissionService {
  /// Xin quyền notification. Trả về true nếu được cấp quyền.
  static Future<bool> requestPermission() async {
    // Chỉ cần xin trên Android
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.status;

    if (status.isGranted) return true;

    // Xin quyền — Android 13+ sẽ hiển thị popup hệ thống
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Kiểm tra quyền hiện tại
  static Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    return await Permission.notification.isGranted;
  }

  /// Hiện dialog giải thích trước khi xin quyền (UX tốt hơn)
  static Future<bool> requestWithExplanation(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    if (!context.mounted) return false;

    // Nếu bị từ chối vĩnh viễn → mở Settings
    if (status.isPermanentlyDenied) {
      final shouldOpen = await _showSettingsDialog(context);
      if (shouldOpen) {
        await openAppSettings();
      }
      return await Permission.notification.isGranted;
    }

    // Yêu cầu quyền thông báo ngay lập tức để hệ thống hiển thị popup native của Android 13+
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Dialog giải thích tại sao cần quyền notification
  static Future<bool> _showExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: AppColors.teal, size: 36),
            ),
            title: const Text(
              'Bật thông báo',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            content: const Text(
              'Smart Room Finder cần quyền thông báo để gửi cập nhật về phòng mới, '
              'trạng thái đặt phòng và tin nhắn quan trọng đến bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Để sau',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Cho phép',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Dialog hướng dẫn mở Settings khi bị từ chối vĩnh viễn
  static Future<bool> _showSettingsDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_rounded,
                  color: Colors.orange, size: 36),
            ),
            title: const Text(
              'Thông báo bị tắt',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            content: const Text(
              'Bạn đã từ chối quyền thông báo trước đó. '
              'Để bật lại, vui lòng vào Cài đặt ứng dụng và cho phép thông báo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Để sau',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Mở Cài đặt',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
