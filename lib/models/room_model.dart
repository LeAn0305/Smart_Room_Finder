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
    RoomModel(
      id: '1',
      ownerId: 'user_1',
      title: 'Phòng trọ gác gỗ đơn giản Quận 7',
      description:
          'Phòng trọ sạch sẽ, thiết kế gác gỗ simili chắc chắn, không gian đơn giản phù hợp sinh viên và người lao động. Gần chợ Tân Mỹ.',
      price: 2500000,
      address: 'Đường Lê Văn Lương, Quận 7, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/phong_tro_gac_lung_go.png',
      images: ['assets/images/phong_tro_gac_lung_go.png'],
      rating: 4.2,
      type: RoomType.studio,
      location: 'Quận 7',
      amenities: ['Gác gỗ', 'Kệ bếp', 'Wifi', 'WC riêng'],
      isFavorite: true,
      isVerified: true,
      postedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    RoomModel(
      id: '2',
      ownerId: 'user_2',
      title: 'Ký túc xá sinh viên sạch sẽ Quận 10',
      description:
          'Dạng giường tầng đơn giản, có máy lạnh, mỗi người một tủ cá nhân. Khu vực yên tĩnh, an ninh tốt.',
      price: 1500000,
      address: 'Đường Lý Thường Kiệt, Quận 10, TP. Hồ Chí MinhĐường Lý Thường Kiệt, Quận 10, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/ky_tuc_xa_sinh_vien.png',
      images: ['assets/images/ky_tuc_xa_sinh_vien.png'],
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
      id: '3',
      ownerId: 'user_1',
      title: 'Căn hộ mini cơ bản Quận Bình Thạnh',
      description:
          'Căn hộ nhỏ gọn có khu vực bếp riêng, toilet sạch sẽ, gạch ốp tường láng đẹp. Thích hợp gia đình nhỏ.',
      price: 4500000,
      address: 'Đường Nơ Trang Long, Quận Bình Thạnh, TP. Hồ Chí Minh',
      imageUrl: 'assets/images/can_ho_mini_don_gian.png',
      images: ['assets/images/can_ho_mini_don_gian.png'],
      rating: 4.0,
      type: RoomType.apartment,
      location: 'Bình Thạnh',
      amenities: ['Bếp riêng', 'Toilet riêng', 'Hầm xe', 'Bảo vệ'],
      isVerified: true,
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}