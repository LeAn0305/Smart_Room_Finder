enum RoomType {
  apartment,
  studio,
  house,
  villa,
}

enum RoomDirection {
  east,
  west,
  south,
  north,
  southEast,
  southWest,
  northEast,
  northWest,
}

class RoomModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final int price;
  final String address;
  final String imageUrl;
  final List<String> images;
  final double rating;
  final RoomType type;
  final String location;
  final List<String> amenities;

  /// isFavorite chỉ nên dùng cho UI/local state
  /// Không nên coi là dữ liệu gốc của document room trong Firestore
  final bool isFavorite;

  final bool isVerified;
  final bool isActive;
  final int viewCount;
  final int contactCount;
  final double? area;
  final int? bedrooms;
  final RoomDirection? direction;
  final DateTime? postedAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final bool isDraft;

  RoomModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.address,
    required this.imageUrl,
    this.images = const [],
    this.rating = 0.0,
    required this.type,
    required this.location,
    this.amenities = const [],
    this.isFavorite = false,
    this.isVerified = false,
    this.isActive = true,
    this.viewCount = 0,
    this.contactCount = 0,
    this.area,
    this.bedrooms,
    this.direction,
    this.postedAt,
    this.updatedAt,
    this.expiresAt,
    this.isDraft = false,
  });

  // ============ FIREBASE METHODS ============

  /// Dùng khi lấy dữ liệu từ Firestore
  factory RoomModel.fromFirebase(Map<String, dynamic> json, String docId) {
    return RoomModel(
      id: docId,
      ownerId: json['ownerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: _parseInt(json['price']),
      address: json['address'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      rating: _parseDouble(json['rating']),
      type: _parseRoomType(json['type'] ?? 'studio'),
      location: json['location'] ?? '',
      amenities: List<String>.from(json['amenities'] ?? []),

      /// Không đọc isFavorite từ Firestore room làm dữ liệu gốc
      /// Có thể set lại sau khi join với favorites của user hiện tại
      isFavorite: json['isFavorite'] ?? false,

      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      viewCount: _parseInt(json['viewCount']),
      contactCount: _parseInt(json['contactCount']),
      area: json['area'] != null ? _parseDouble(json['area']) : null,
      bedrooms: json['bedrooms'] != null ? _parseInt(json['bedrooms']) : null,
      direction: json['direction'] != null
          ? _parseRoomDirection(json['direction'])
          : null,
      postedAt: _parseDateTime(json['postedAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      expiresAt: _parseDateTime(json['expiresAt']),
      isDraft: json['isDraft'] ?? false,
    );
  }

  /// Dùng khi tạo room mới trên Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'price': price,
      'address': address,
      'imageUrl': imageUrl,
      'images': images,
      'rating': rating,
      'type': _roomTypeToString(type),
      'location': location,
      'amenities': amenities,
      'isVerified': isVerified,
      'isActive': isActive,
      'viewCount': viewCount,
      'contactCount': contactCount,
      'area': area,
      'bedrooms': bedrooms,
      'direction': direction != null ? _directionToString(direction!) : null,
      'postedAt': postedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isDraft': isDraft,
    };
  }

  /// Dùng khi update room
  /// Tránh ghi đè postedAt nếu không muốn
  Map<String, dynamic> toFirebaseForUpdate() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'price': price,
      'address': address,
      'imageUrl': imageUrl,
      'images': images,
      'rating': rating,
      'type': _roomTypeToString(type),
      'location': location,
      'amenities': amenities,
      'isVerified': isVerified,
      'isActive': isActive,
      'viewCount': viewCount,
      'contactCount': contactCount,
      'area': area,
      'bedrooms': bedrooms,
      'direction': direction != null ? _directionToString(direction!) : null,
      'updatedAt': updatedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isDraft': isDraft,
    };
  }

  // ============ GETTER METHODS ============

  String get directionString {
    switch (direction) {
      case RoomDirection.east:
        return 'Đông';
      case RoomDirection.west:
        return 'Tây';
      case RoomDirection.south:
        return 'Nam';
      case RoomDirection.north:
        return 'Bắc';
      case RoomDirection.southEast:
        return 'Đông Nam';
      case RoomDirection.southWest:
        return 'Tây Nam';
      case RoomDirection.northEast:
        return 'Đông Bắc';
      case RoomDirection.northWest:
        return 'Tây Bắc';
      default:
        return '';
    }
  }

  String get typeString {
    switch (type) {
      case RoomType.apartment:
        return 'Chung cư';
      case RoomType.studio:
        return 'Phòng trọ';
      case RoomType.house:
        return 'Nhà nguyên căn';
      case RoomType.villa:
        return 'Biệt thự';
    }
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  int get daysLeft {
    if (expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  String get formattedPrice {
    return '${(price / 1000000).toStringAsFixed(1)}M';
  }

  // ============ COPY WITH ============

  RoomModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    int? price,
    String? address,
    String? imageUrl,
    List<String>? images,
    double? rating,
    RoomType? type,
    String? location,
    List<String>? amenities,
    bool? isFavorite,
    bool? isVerified,
    bool? isActive,
    int? viewCount,
    int? contactCount,
    double? area,
    int? bedrooms,
    RoomDirection? direction,
    DateTime? postedAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    bool? isDraft,
  }) {
    return RoomModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      type: type ?? this.type,
      location: location ?? this.location,
      amenities: amenities ?? this.amenities,
      isFavorite: isFavorite ?? this.isFavorite,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      viewCount: viewCount ?? this.viewCount,
      contactCount: contactCount ?? this.contactCount,
      area: area ?? this.area,
      bedrooms: bedrooms ?? this.bedrooms,
      direction: direction ?? this.direction,
      postedAt: postedAt ?? this.postedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  // ============ HELPER METHODS ============

  static RoomType _parseRoomType(String type) {
    switch (type.toLowerCase()) {
      case 'apartment':
        return RoomType.apartment;
      case 'studio':
        return RoomType.studio;
      case 'house':
        return RoomType.house;
      case 'villa':
        return RoomType.villa;
      default:
        return RoomType.studio;
    }
  }

  static String _roomTypeToString(RoomType type) {
    return type.toString().split('.').last;
  }

  static RoomDirection _parseRoomDirection(String direction) {
    switch (direction.toLowerCase()) {
      case 'east':
        return RoomDirection.east;
      case 'west':
        return RoomDirection.west;
      case 'south':
        return RoomDirection.south;
      case 'north':
        return RoomDirection.north;
      case 'southeast':
        return RoomDirection.southEast;
      case 'southwest':
        return RoomDirection.southWest;
      case 'northeast':
        return RoomDirection.northEast;
      case 'northwest':
        return RoomDirection.northWest;
      default:
        return RoomDirection.south;
    }
  }

  static String _directionToString(RoomDirection direction) {
    return direction.toString().split('.').last;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  @override
  String toString() {
    return 'RoomModel(id: $id, ownerId: $ownerId, title: $title, price: $price, location: $location)';
  }

  // ============ SAMPLE DATA (dùng để test UI) ============

  static List<RoomModel> sampleRooms = [
    // ── BÌNH THẠNH ──────────────────────────────────────────
    RoomModel(
      id: '1',
      ownerId: 'user_1',
      title: 'Căn hộ mini hiện đại Bình Thạnh',
      description: 'Căn hộ nhỏ gọn có khu vực bếp riêng, toilet sạch sẽ, gạch ốp tường láng đẹp. Thích hợp gia đình nhỏ hoặc cặp đôi.',
      price: 4500000,
      address: 'Đường Nơ Trang Long, Bình Thạnh, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/can_ho_mini_don_gian.png',
      images: ['assets/images/can_ho_mini_don_gian.png', 'assets/images/room_apartment_mini.png'],
      rating: 4.0,
      type: RoomType.apartment,
      location: 'Bình Thạnh',
      amenities: ['Bếp riêng', 'Toilet riêng', 'Hầm xe', 'Bảo vệ', 'Wifi'],
      isVerified: true,
      viewCount: 95,
      contactCount: 8,
      area: 30,
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
      expiresAt: DateTime.now().add(const Duration(days: 28)),
    ),
    RoomModel(
      id: '2',
      ownerId: 'user_2',
      title: 'Phòng trọ gác sắt Bình Thạnh',
      description: 'Phòng trọ gác sắt chắc chắn, thoáng mát, gần trường đại học Văn Lang. An ninh tốt, có camera.',
      price: 3000000,
      address: 'Đường Đinh Bộ Lĩnh, Bình Thạnh, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/phong_tro_gac_sat.png',
      images: ['assets/images/phong_tro_gac_sat.png', 'assets/images/phong_tro_gac_lung_go.png'],
      rating: 4.1,
      type: RoomType.studio,
      location: 'Bình Thạnh',
      amenities: ['Wifi', 'Máy lạnh', 'WC riêng', 'Chỗ để xe'],
      isVerified: true,
      viewCount: 60,
      contactCount: 5,
      area: 20,
      postedAt: DateTime.now().subtract(const Duration(days: 3)),
      expiresAt: DateTime.now().add(const Duration(days: 27)),
    ),
    RoomModel(
      id: '3',
      ownerId: 'user_3',
      title: 'Studio Muji phong cách Bình Thạnh',
      description: 'Studio thiết kế theo phong cách Muji tối giản, đầy đủ nội thất cao cấp, view đẹp nhìn ra công viên.',
      price: 7500000,
      address: 'Đường Xô Viết Nghệ Tĩnh, Bình Thạnh, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/room_muji_studio.png',
      images: ['assets/images/room_muji_studio.png', 'assets/images/room_apartment_mini.png'],
      rating: 4.8,
      type: RoomType.apartment,
      location: 'Bình Thạnh',
      amenities: ['Wifi', 'Máy lạnh', 'Tủ lạnh', 'Máy giặt', 'Bếp', 'Bảo vệ 24/7'],
      isVerified: true,
      viewCount: 180,
      contactCount: 22,
      area: 35,
      bedrooms: 1,
      direction: RoomDirection.east,
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 29)),
    ),
    RoomModel(
      id: '4',
      ownerId: 'user_1',
      title: 'Phòng trọ sinh viên Bình Thạnh',
      description: 'Phòng trọ dành cho sinh viên, gần ĐH Văn Lang và ĐH Kinh tế. Giá rẻ, sạch sẽ, an toàn.',
      price: 2200000,
      address: 'Hẻm 150 Đinh Bộ Lĩnh, Bình Thạnh, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/room_student_room.png',
      images: ['assets/images/room_student_room.png', 'assets/images/ky_tuc_xa_sinh_vien.png'],
      rating: 3.9,
      type: RoomType.studio,
      location: 'Bình Thạnh',
      amenities: ['Wifi', 'WC chung', 'Chỗ để xe máy'],
      isVerified: false,
      viewCount: 45,
      contactCount: 3,
      area: 15,
      postedAt: DateTime.now().subtract(const Duration(days: 5)),
      expiresAt: DateTime.now().add(const Duration(days: 25)),
    ),

    // ── QUẬN 1 ──────────────────────────────────────────────
    RoomModel(
      id: '5',
      ownerId: 'user_2',
      title: 'Căn hộ 2PN cao cấp Quận 1',
      description: 'Căn hộ rộng rãi trung tâm thành phố, view sông Sài Gòn tuyệt đẹp. Đầy đủ tiện nghi 5 sao.',
      price: 18000000,
      address: 'Đường Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/room_apartment_2br.png',
      images: ['assets/images/room_apartment_2br.png', 'assets/images/room_apartment_horizon.png'],
      rating: 4.9,
      type: RoomType.apartment,
      location: 'Quận 1',
      amenities: ['Wifi', 'Máy lạnh', 'Tủ lạnh', 'Máy giặt', 'Hồ bơi', 'Gym', 'Bảo vệ 24/7'],
      isVerified: true,
      viewCount: 320,
      contactCount: 45,
      area: 75,
      bedrooms: 2,
      direction: RoomDirection.south,
      postedAt: DateTime.now().subtract(const Duration(days: 7)),
      expiresAt: DateTime.now().add(const Duration(days: 23)),
    ),
    RoomModel(
      id: '6',
      ownerId: 'user_3',
      title: 'Studio Luxury trung tâm Quận 1',
      description: 'Studio sang trọng ngay trung tâm Q1, thiết kế hiện đại, đầy đủ nội thất nhập khẩu.',
      price: 12000000,
      address: 'Đường Lê Lợi, Quận 1, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/room_studio_luxury.png',
      images: ['assets/images/room_studio_luxury.png', 'assets/images/room_muji_studio.png'],
      rating: 4.7,
      type: RoomType.apartment,
      location: 'Quận 1',
      amenities: ['Wifi', 'Máy lạnh', 'Tủ lạnh', 'Bếp từ', 'Bảo vệ', 'Thang máy'],
      isVerified: true,
      viewCount: 250,
      contactCount: 35,
      area: 45,
      bedrooms: 1,
      direction: RoomDirection.north,
      postedAt: DateTime.now().subtract(const Duration(days: 4)),
      expiresAt: DateTime.now().add(const Duration(days: 26)),
    ),

    // ── QUẬN 7 ──────────────────────────────────────────────
    RoomModel(
      id: '7',
      ownerId: 'user_1',
      title: 'Phòng trọ gác lửng Quận 7',
      description: 'Phòng trọ sạch sẽ, thiết kế gác gỗ simili chắc chắn, không gian đơn giản phù hợp sinh viên và người lao động.',
      price: 2500000,
      address: 'Đường Lê Văn Lương, Quận 7, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/phong_tro_gac_lung_go.png',
      images: ['assets/images/phong_tro_gac_lung_go.png', 'assets/images/phong_tro_gac_sat.png'],
      rating: 4.2,
      type: RoomType.studio,
      location: 'Quận 7',
      amenities: ['Gác gỗ', 'Kệ bếp', 'Wifi', 'WC riêng'],
      isFavorite: true,
      isVerified: true,
      viewCount: 110,
      contactCount: 12,
      area: 22,
      postedAt: DateTime.now().subtract(const Duration(days: 5)),
      expiresAt: DateTime.now().add(const Duration(days: 25)),
    ),
    RoomModel(
      id: '8',
      ownerId: 'user_2',
      title: 'Căn hộ Horizon view sông Quận 7',
      description: 'Căn hộ cao cấp view sông Sài Gòn, nội thất đầy đủ, khu dân cư an ninh cao.',
      price: 14000000,
      address: 'Đường Nguyễn Văn Linh, Quận 7, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/room_apartment_horizon.png',
      images: ['assets/images/room_apartment_horizon.png', 'assets/images/room_apartment_2br.png'],
      rating: 4.6,
      type: RoomType.apartment,
      location: 'Quận 7',
      amenities: ['Wifi', 'Máy lạnh', 'Tủ lạnh', 'Máy giặt', 'Hồ bơi', 'Gym'],
      isVerified: true,
      viewCount: 195,
      contactCount: 28,
      area: 65,
      bedrooms: 2,
      direction: RoomDirection.southEast,
      postedAt: DateTime.now().subtract(const Duration(days: 6)),
      expiresAt: DateTime.now().add(const Duration(days: 24)),
    ),

    // ── QUẬN 10 ─────────────────────────────────────────────
    RoomModel(
      id: '9',
      ownerId: 'user_3',
      title: 'Ký túc xá sinh viên Quận 10',
      description: 'Dạng giường tầng đơn giản, có máy lạnh, mỗi người một tủ cá nhân. Khu vực yên tĩnh, an ninh tốt.',
      price: 1500000,
      address: 'Đường Lý Thường Kiệt, Quận 10, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/ky_tuc_xa_sinh_vien.png',
      images: ['assets/images/ky_tuc_xa_sinh_vien.png', 'assets/images/room_student_room.png'],
      rating: 4.4,
      type: RoomType.studio,
      location: 'Quận 10',
      amenities: ['Giường tầng', 'Máy lạnh', 'Tủ cá nhân', 'Dọn phòng'],
      isVerified: true,
      viewCount: 85,
      contactCount: 7,
      area: 65,
      bedrooms: 2,
      direction: RoomDirection.southEast,
      postedAt: DateTime.now().subtract(const Duration(days: 10)),
      expiresAt: DateTime.now().add(const Duration(days: 3)),
    ),
    RoomModel(
      id: '10',
      ownerId: 'user_1',
      title: 'Nhà hẻm yên tĩnh Quận 10',
      description: 'Nhà nguyên căn trong hẻm yên tĩnh, 2 phòng ngủ, phù hợp gia đình nhỏ.',
      price: 8000000,
      address: 'Hẻm 200 Tô Hiến Thành, Quận 10, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/room_house_alley.png',
      images: ['assets/images/room_house_alley.png', 'assets/images/room_house_frontage.png'],
      rating: 4.3,
      type: RoomType.house,
      location: 'Quận 10',
      amenities: ['Wifi', 'Máy lạnh', 'Bếp', 'Sân phơi', 'Chỗ để xe'],
      isVerified: true,
      viewCount: 75,
      contactCount: 9,
      area: 55,
      bedrooms: 2,
      direction: RoomDirection.north,
      postedAt: DateTime.now().subtract(const Duration(days: 8)),
      expiresAt: DateTime.now().add(const Duration(days: 22)),
    ),

    // ── TÂN BÌNH ────────────────────────────────────────────
    RoomModel(
      id: '11',
      ownerId: 'user_2',
      title: 'Nhà mặt tiền Tân Bình',
      description: 'Nhà mặt tiền rộng rãi, thuận tiện kinh doanh hoặc ở, gần sân bay Tân Sơn Nhất.',
      price: 20000000,
      address: 'Đường Hoàng Văn Thụ, Tân Bình, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/room_house_frontage.png',
      images: ['assets/images/room_house_frontage.png', 'assets/images/room_house_alley.png'],
      rating: 4.5,
      type: RoomType.house,
      location: 'Tân Bình',
      amenities: ['Wifi', 'Máy lạnh', 'Bếp', 'Sân thượng', 'Hầm xe ô tô'],
      isVerified: true,
      viewCount: 140,
      contactCount: 18,
      area: 120,
      bedrooms: 3,
      direction: RoomDirection.west,
      postedAt: DateTime.now().subtract(const Duration(days: 9)),
      expiresAt: DateTime.now().add(const Duration(days: 21)),
    ),

    // ── GÒ VẤP ──────────────────────────────────────────────
    RoomModel(
      id: '12',
      ownerId: 'user_3',
      title: 'Phòng trọ sinh viên Gò Vấp',
      description: 'Phòng trọ sạch sẽ, gần ĐH Công nghiệp, giá sinh viên, có bảo vệ 24/7.',
      price: 1800000,
      address: 'Đường Quang Trung, Gò Vấp, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/room_student_room.png',
      images: ['assets/images/room_student_room.png', 'assets/images/ky_tuc_xa_sinh_vien.png'],
      rating: 3.8,
      type: RoomType.studio,
      location: 'Gò Vấp',
      amenities: ['Wifi', 'WC riêng', 'Chỗ để xe máy', 'Bảo vệ'],
      isVerified: false,
      viewCount: 55,
      contactCount: 4,
      area: 18,
      postedAt: DateTime.now().subtract(const Duration(days: 4)),
      expiresAt: DateTime.now().add(const Duration(days: 26)),
    ),
  ];
}