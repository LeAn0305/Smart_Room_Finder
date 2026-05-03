import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String roomId;
  final String reporterId;
  final String reason;
  final String? description;
  final DateTime createdAt;
  final String status;

  ReportModel({
    required this.id,
    required this.roomId,
    required this.reporterId,
    required this.reason,
    this.description,
    required this.createdAt,
    this.status = 'pending',
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReportModel(
      id: docId,
      roomId: map['roomId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'reporterId': reporterId,
      'reason': reason,
      if (description != null) 'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
    };
  }
}
