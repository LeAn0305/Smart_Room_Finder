import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_room_finder/models/report_model.dart';

class ReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> hasUserReported(String roomId, String userId) async {
    if (userId.isEmpty) return false;
    final snapshot = await _firestore
        .collection('reports')
        .where('roomId', isEqualTo: roomId)
        .where('reporterId', isEqualTo: userId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<void> addReport(ReportModel report) async {
    await _firestore.collection('reports').add(report.toMap());
  }
}
