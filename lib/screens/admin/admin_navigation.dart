import 'package:flutter/material.dart';
import 'package:smart_room_finder/screens/dashboard_admin/dashboard_admin.dart';
import 'package:smart_room_finder/screens/post_approval/post_approval_screen.dart';

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
