class UserModel {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final String location;
  final String phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl = '',
    this.location = 'TP. Hồ Chí Minh',
    this.phoneNumber = '',
    this.createdAt,
    this.updatedAt,
  });

  /// 🔥 Chuyển từ Firebase JSON sang UserModel
  /// Dùng khi lấy dữ liệu từ Firestore
  factory UserModel.fromFirebase(Map<String, dynamic> json, String docId) {
    return UserModel(
      id: docId,
      name: json['name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      location: json['location'] ?? 'TP. Hồ Chí Minh',
      phoneNumber: json['phoneNumber'] ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  /// 🔥 Dùng khi tạo user mới trên Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'location': location,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 🔥 Dùng khi cập nhật user
  /// Không ghi đè createdAt
  Map<String, dynamic> toFirebaseForUpdate() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'location': location,
      'phoneNumber': phoneNumber,
      'updatedAt': updatedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
    };
  }

  /// 📝 Copy with
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? location,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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
    return 'UserModel(id: $id, name: $name, email: $email, location: $location, phoneNumber: $phoneNumber)';
  }

  // ============ SAMPLE DATA (dùng để test UI) ============

  static List<UserModel> sampleUsers = [
    UserModel(
      id: 'user_1',
      name: 'Nguyễn Văn A',
      email: 'vana@example.com',
      profileImageUrl: 'https://i.pravatar.cc/150?u=vana@example.com',
      location: 'TP. Hồ Chí Minh',
      phoneNumber: '',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserModel(
      id: 'user_2',
      name: 'Trần Thị B',
      email: 'tranthib@example.com',
      profileImageUrl: 'https://i.pravatar.cc/150?u=tranthib@example.com',
      location: 'Hà Nội',
      phoneNumber: '',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];
}