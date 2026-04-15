enum UserRole { tenant, landlord }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final String location;
  final UserRole role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl = 'https://i.pravatar.cc/150?u=antigravity',
    this.location = 'TP. Hồ Chí Minh',
    this.role = UserRole.tenant,
  });

  bool get isLandlord => role == UserRole.landlord;

  static UserModel get currentUser => UserModel(
        id: 'user_1',
        name: 'Nguyễn Văn A',
        email: 'vana@example.com',
        role: UserRole.landlord, // đổi thành tenant để test vai trò người thuê
      );

  factory UserModel.fromFirebase(Map<String, dynamic> json, String docId) {
    return UserModel(
      id: docId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      location: json['location'] ?? 'TP. Hồ Chí Minh',
      role: json['role'] == 'landlord' ? UserRole.landlord : UserRole.tenant,
    );
  }
}
