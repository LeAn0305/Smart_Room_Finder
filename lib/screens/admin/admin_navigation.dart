import 'package:flutter/material.dart';
import 'package:smart_room_finder/screens/admin/admin_report_screen.dart';
import 'package:smart_room_finder/screens/admin/admin_settings_screen.dart';
import 'package:smart_room_finder/screens/admin/admin_support_screen.dart';
import 'package:smart_room_finder/screens/admin/admin_user_screen.dart';
import 'package:smart_room_finder/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_room_finder/screens/admin/admin_PostApproval_screen.dart';

// =========================
// ADMIN NAVIGATION HELPERS
// =========================

void _openAdminScreen(BuildContext context, Widget screen) {
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final localNavigator = Navigator.of(context);

  // Nếu đang mở Drawer/Menu trên mobile thì đóng trước.
  if (localNavigator.canPop()) {
    localNavigator.pop();
  }

  // Đợi Drawer đóng xong rồi mới chuyển màn để tránh lỗi Navigator stack trên Android.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    rootNavigator.push(
      MaterialPageRoute(builder: (_) => screen),
    );
  });
}

void openAdminDashboard(BuildContext context) {
  _openAdminScreen(context, const AdminDashboardScreen());
}

void openPostApproval(BuildContext context) {
  _openAdminScreen(context, const PostApprovalScreen());
}

void openAdminUsers(BuildContext context) {
  _openAdminScreen(context, const AdminUserScreen());
}

void openAdminReports(BuildContext context) {
  _openAdminScreen(context, const AdminReportScreen());
}

void openAdminSupport(BuildContext context) {
  _openAdminScreen(context, const AdminSupportScreen());
}

void openAdminSettings(BuildContext context) {
  _openAdminScreen(context, const AdminSettingsScreen());
}
