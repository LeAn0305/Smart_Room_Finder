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
void openAdminDashboard(BuildContext context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
  );
}

void openPostApproval(BuildContext context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const PostApprovalScreen()),
  );
}

void openAdminUsers(BuildContext context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const AdminUserScreen()),
  );
}

void openAdminReports(BuildContext context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const AdminReportScreen()),
  );
}

void openAdminSupport(BuildContext context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const AdminSupportScreen()),
  );
}

void openAdminSettings(BuildContext context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
  );
}
