enum UserRole {
  renter,
  landlord,
  admin,
}

extension UserRoleX on UserRole {
  String get value => name;

  static UserRole? fromValue(dynamic raw) {
    if (raw == null) return null;

    final value = raw.toString().trim().toLowerCase();

    try {
      return UserRole.values.firstWhere((role) => role.name == value);
    } catch (_) {
      return null;
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final String location;
  final String phoneNumber;
  final UserRole? role;
  final bool hasSelectedRole;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl = '',
    this.location = 'TP. Ho Chi Minh',
    this.phoneNumber = '',
    this.role,
    this.hasSelectedRole = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirebase(Map<String, dynamic> json, String docId) {
    final parsedRole = UserRoleX.fromValue(json['role']);

    return UserModel(
      id: docId,
      name: json['name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      location: json['location'] ?? 'TP. Ho Chi Minh',
      phoneNumber: json['phoneNumber'] ?? '',
      role: parsedRole,
      hasSelectedRole: json['hasSelectedRole'] ?? (parsedRole != null),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'location': location,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'role': role?.value,
      'hasSelectedRole': hasSelectedRole,
    };
  }

  Map<String, dynamic> toFirebaseForUpdate() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'location': location,
      'phoneNumber': phoneNumber,
      'updatedAt': updatedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'role': role?.value,
      'hasSelectedRole': hasSelectedRole,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? location,
    UserRole? role,
    bool clearRole = false,
    bool? hasSelectedRole,
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
      role: clearRole ? null : (role ?? this.role),
      hasSelectedRole: hasSelectedRole ?? this.hasSelectedRole,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isLandlord => role == UserRole.landlord;
  bool get isRenter => role == UserRole.renter;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: ${role?.value}, location: $location, phoneNumber: $phoneNumber)';
  }

  static final List<UserModel> sampleUsers = [
    UserModel(
      id: 'user_1',
      name: 'Nguyen Van A',
      email: 'vana@example.com',
      profileImageUrl: 'https://i.pravatar.cc/150?u=vana@example.com',
      location: 'TP. Ho Chi Minh',
      role: UserRole.renter,
      hasSelectedRole: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserModel(
      id: 'user_2',
      name: 'Tran Thi B',
      email: 'tranthib@example.com',
      profileImageUrl: 'https://i.pravatar.cc/150?u=tranthib@example.com',
      location: 'Ha Noi',
      role: UserRole.renter,
      hasSelectedRole: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];
}
