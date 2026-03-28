class UserModel {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final String location;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl = 'https://i.pravatar.cc/150?u=antigravity',
    this.location = 'TP. Hồ Chí Minh',
  });

  static UserModel get currentUser => UserModel(
        id: 'user_1',
        name: 'Nguyễn Văn A',
        email: 'vana@example.com',
      );
}
