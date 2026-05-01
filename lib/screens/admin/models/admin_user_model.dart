import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserModel {
  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.profileImageUrl,
    required this.location,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLogin,
    required this.hasSelectedRole,
    required this.hasCompletedPreferences,
    required this.status,
    required this.lockedReason,
    required this.lockedAt,
  });

  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String profileImageUrl;
  final String location;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final bool hasSelectedRole;
  final bool hasCompletedPreferences;
  final String status;
  final String lockedReason;
  final DateTime? lockedAt;

  factory AdminUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final statusValue = _readString(data['status']).trim();

    return AdminUserModel(
      id: doc.id,
      name: _readString(data['name']),
      email: _readString(data['email']),
      phoneNumber: _readString(data['phoneNumber']),
      profileImageUrl: _readString(data['profileImageUrl']),
      location: _readString(data['location']),
      role: _readString(data['role']),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      lastLogin: _parseDateTime(data['lastLogin']),
      hasSelectedRole: _readBool(data['hasSelectedRole']),
      hasCompletedPreferences: _readBool(data['hasCompletedPreferences']),
      status: statusValue.isEmpty ? 'active' : statusValue.toLowerCase(),
      lockedReason: _readString(data['lockedReason']),
      lockedAt: _parseDateTime(data['lockedAt']),
    );
  }

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return 'Unknown User';
  }

  String get phone => phoneNumber.trim().isNotEmpty ? phoneNumber.trim() : '--';

  String get displayLocation =>
      location.trim().isNotEmpty ? location.trim() : '--';

  String get roleLabel {
    switch (role.trim().toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'landlord':
      case 'owner':
        return 'Chủ trọ';
      case 'renter':
        return 'Người thuê';
      default:
        return 'Chưa chọn';
    }
  }

  String get statusLabel {
    switch (status.trim().toLowerCase()) {
      case 'locked':
        return 'Tạm khóa';
      case 'active':
        return 'Hoạt động';
      default:
        return 'Hoạt động';
    }
  }

  bool get hasCompletedAccountSetup {
    if (!hasSelectedRole) return false;

    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'admin' ||
        normalizedRole == 'landlord' ||
        normalizedRole == 'owner') {
      return true;
    }

    if (normalizedRole == 'renter') {
      return hasCompletedPreferences;
    }

    return false;
  }

  String get accountSetupLabel => hasCompletedAccountSetup
      ? 'Đã hoàn tất'
      : 'Chưa hoàn tất';

  String get accountSetupDescription => hasCompletedAccountSetup
      ? 'Đã chọn vai trò và hoàn tất thiết lập'
      : 'Tài khoản chưa hoàn tất thiết lập ban đầu';

  String get joinedAt => _formatDateTime(createdAt);

  String get lastLoginLabel => _formatDateTime(lastLogin);

  String get lockedAtLabel => _formatDateTime(lockedAt);

  int get postCount => 0;

  int get reportCount => 0;

  bool get isOnline => false;

  bool get isAdmin => role.trim().toLowerCase() == 'admin';

  bool get isLocked {
    final normalized = status.trim().toLowerCase();
    return normalized == 'locked';
  }

  Color get avatarColor {
    const colors = [
      Color(0xFF2F9BEF),
      Color(0xFF47C7B5),
      Color(0xFFF59E0B),
      Color(0xFFFF5B6E),
      Color(0xFF8B5CF6),
      Color(0xFF22B573),
      Color(0xFFFF8A4C),
      Color(0xFF9B5CFF),
    ];
    final seed = (id.isNotEmpty ? id : email).hashCode.abs();
    return colors[seed % colors.length];
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatDateTime(DateTime? date) {
    if (date == null) return '--';
    return '${_formatDate(date)}\n'
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
