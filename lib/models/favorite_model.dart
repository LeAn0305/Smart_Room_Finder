class FavoriteModel {
  final String id;
  final String userId;
  final String roomId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.roomId,
    this.createdAt,
    this.updatedAt,
  });

  /// 🔥 Chuyển từ Firebase JSON sang FavoriteModel
  /// Dùng khi lấy dữ liệu từ Firestore
  factory FavoriteModel.fromFirebase(Map<String, dynamic> json, String docId) {
    return FavoriteModel(
      id: docId,
      userId: json['userId'] ?? '',
      roomId: json['roomId'] ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  /// 🔥 Dùng khi tạo favorite mới trên Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'userId': userId,
      'roomId': roomId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 🔥 Dùng khi cập nhật favorite
  Map<String, dynamic> toFirebaseForUpdate() {
    return {
      'userId': userId,
      'roomId': roomId,
      'updatedAt': updatedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
    };
  }

  /// 📝 Copy with
  FavoriteModel copyWith({
    String? id,
    String? userId,
    String? roomId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  @override
  String toString() {
    return 'FavoriteModel(id: $id, userId: $userId, roomId: $roomId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FavoriteModel &&
        other.id == id &&
        other.userId == userId &&
        other.roomId == roomId;
  }

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ roomId.hashCode;

  // ============ SAMPLE DATA (dùng để test UI) ============

  static List<FavoriteModel> sampleFavorites = [
    FavoriteModel(
      id: 'fav_1',
      userId: 'user_1',
      roomId: '1',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    FavoriteModel(
      id: 'fav_2',
      userId: 'user_1',
      roomId: '3',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}