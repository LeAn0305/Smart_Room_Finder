enum RoomType {
  apartment,
  studio,
  house,
  villa,
}

enum RoomDirection { east, west, south, north, southEast, southWest, northEast, northWest }

class RoomModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String address;
  final String imageUrl;
  final List<String> images;
  final double rating;
  final RoomType type;
  final String location;
  final List<String> amenities;
  final bool isFavorite;
  final bool isVerified;
  final bool isActive;
  final int viewCount;
  final int contactCount;
  final double? area;
  final int? bedrooms;
  final RoomDirection? direction;
  final DateTime? postedAt;
  final DateTime? expiresAt;
  final bool isDraft;

  RoomModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.address,
    required this.imageUrl,
    this.images = const [],
    required this.rating,
    required this.type,
    required this.location,
    required this.amenities,
    this.isFavorite = false,
    this.isVerified = true,
    this.isActive = true,
    this.viewCount = 0,
    this.contactCount = 0,
    this.area,
    this.bedrooms,
    this.direction,
    this.postedAt,
    this.expiresAt,
    this.isDraft = false,
  });

  String get directionString {
    switch (direction) {
      case RoomDirection.east: return 'Đông';
      case RoomDirection.west: return 'Tây';
      case RoomDirection.south: return 'Nam';
      case RoomDirection.north: return 'Bắc';
      case RoomDirection.southEast: return 'Đông Nam';
      case RoomDirection.southWest: return 'Tây Nam';
      case RoomDirection.northEast: return 'Đông Bắc';
      case RoomDirection.northWest: return 'Tây Bắc';
      default: return '';
    }
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  int get daysLeft {
    if (expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  RoomModel copyWith({
    String? title, String? description, double? price, String? address,
    String? imageUrl, List<String>? images, RoomType? type, String? location,
    List<String>? amenities, bool? isFavorite, bool? isVerified, bool? isActive,
    int? viewCount, int? contactCount, double? area, int? bedrooms,
    RoomDirection? direction, DateTime? postedAt, DateTime? expiresAt, bool? isDraft,
  }) {
    return RoomModel(
      id: id, rating: rating,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
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
      expiresAt: expiresAt ?? this.expiresAt,
      isDraft: isDraft ?? this.isDraft,
    );
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

  RoomModel copyWith({bool? isFavorite}) {
    return RoomModel(
      id: id, title: title, description: description,
      price: price, address: address, imageUrl: imageUrl,
      rating: rating, type: type, location: location,
      amenities: amenities, isVerified: isVerified,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  static List<RoomModel> get sampleRooms => [
        RoomModel(
          id: '1', title: 'Căn hộ Studio cao cấp',
          description: 'Căn hộ đầy đủ tiện nghi, gần trung tâm thành phố, an ninh 24/7.',
          price: 5500000, address: 'Quận 1, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_studio_luxury.png',
          rating: 4.8, type: RoomType.studio, location: 'TP. Hồ Chí Minh',
          amenities: ['Wifi', 'Máy lạnh', 'Tủ lạnh', 'Máy giặt'],
          isFavorite: true, isVerified: true,
          viewCount: 128, contactCount: 12, area: 35, bedrooms: 1,
          direction: RoomDirection.east,
          postedAt: DateTime.now().subtract(const Duration(days: 5)),
          expiresAt: DateTime.now().add(const Duration(days: 25)),
        ),
        RoomModel(
          id: '2', title: 'Chung cư 2 phòng ngủ',
          description: 'View đẹp, thoáng mát, gần công viên và trường học.',
          price: 8000000, address: 'Quận 7, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_apartment_2br.png',
          rating: 4.5, type: RoomType.apartment, location: 'TP. Hồ Chí Minh',
          amenities: ['Hồ bơi', 'Phòng gym', 'Wifi', 'Máy lạnh'],
          isVerified: true,
          viewCount: 85, contactCount: 7, area: 65, bedrooms: 2,
          direction: RoomDirection.southEast,
          postedAt: DateTime.now().subtract(const Duration(days: 10)),
          expiresAt: DateTime.now().add(const Duration(days: 3)),
        ),
        RoomModel(
          id: '3', title: 'Nhà nguyên căn mặt tiền',
          description: 'Phù hợp cho gia đình hoặc nhóm bạn, có sân đậu xe hơi.',
          price: 15000000, address: 'Quận Bình Thạnh, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_house_frontage.png',
          rating: 4.9, type: RoomType.house, location: 'TP. Hồ Chí Minh',
          amenities: ['Sân vườn', 'Bếp rộng', 'Wifi', 'Máy lạnh'],
          isVerified: false,
          viewCount: 210, contactCount: 23, area: 120, bedrooms: 3,
          direction: RoomDirection.south,
          postedAt: DateTime.now().subtract(const Duration(days: 2)),
          expiresAt: DateTime.now().add(const Duration(days: 28)),
        ),
        RoomModel(
          id: '4', title: 'Căn hộ mini hiện đại',
          description: 'Giá rẻ, sạch sẽ, chủ nhà thân thiện, không chung chủ.',
          price: 3500000, address: 'Quận Gò Vấp, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_apartment_mini.png',
          rating: 4.2, type: RoomType.apartment, location: 'TP. Hồ Chí Minh',
          amenities: ['Wifi', 'Bếp', 'Chỗ để xe'],
          isVerified: true,
          viewCount: 44, contactCount: 3, area: 28, bedrooms: 1,
          direction: RoomDirection.west,
          postedAt: DateTime.now().subtract(const Duration(days: 15)),
          expiresAt: DateTime.now().add(const Duration(days: 15)),
        ),
        RoomModel(
          id: '5', title: 'Phòng trọ sinh viên tiện nghi',
          description: 'Gần các trường đại học, an ninh tốt, wifi tốc độ cao.',
          price: 2800000, address: 'Quận Thủ Đức, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_student_room.png',
          rating: 4.0, type: RoomType.studio, location: 'TP. Hồ Chí Minh',
          amenities: ['Wifi', 'Quạt', 'Giường nệm'],
          isVerified: true,
          viewCount: 67, contactCount: 5, area: 20, bedrooms: 1,
          direction: RoomDirection.north,
          postedAt: DateTime.now().subtract(const Duration(days: 8)),
          expiresAt: DateTime.now().add(const Duration(days: 22)),
        ),
        RoomModel(
          id: '6', title: 'Căn hộ Horizon View',
          description: 'Căn hộ cao cấp với tầm nhìn toàn thành phố, nội thất nhập khẩu.',
          price: 12000000, address: 'Quận 2, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_apartment_horizon.png',
          rating: 4.9, type: RoomType.apartment, location: 'TP. Hồ Chí Minh',
          amenities: ['Hồ bơi cực mây', 'Gym', 'Wifi', 'Full nội thất'],
          isVerified: true, isFavorite: true,
          viewCount: 312, contactCount: 41, area: 80, bedrooms: 2,
          direction: RoomDirection.northEast,
          postedAt: DateTime.now().subtract(const Duration(days: 1)),
          expiresAt: DateTime.now().add(const Duration(days: 29)),
        ),
        RoomModel(
          id: '7', title: 'Nhà cho thuê nguyên căn hẻm xe hơi',
          description: 'Khu vực yên tĩnh, dân trí cao, phù hợp ở gia đình.',
          price: 18000000, address: 'Quận Tân Bình, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_house_alley.png',
          rating: 4.6, type: RoomType.house, location: 'TP. Hồ Chí Minh',
          amenities: ['Garage', 'Sân thượng', 'Máy lạnh'],
          isVerified: false,
          viewCount: 156, contactCount: 18, area: 150, bedrooms: 4,
          direction: RoomDirection.southWest,
          postedAt: DateTime.now().subtract(const Duration(days: 20)),
          expiresAt: DateTime.now().add(const Duration(days: 10)),
        ),
        RoomModel(
          id: '8', title: 'Studio nhỏ gọn phong cách Muji',
          description: 'Phong cách tối giản, đầy đủ ánh sáng tự nhiên.',
          price: 4800000, address: 'Quận 3, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_muji_studio.png',
          rating: 4.7, type: RoomType.studio, location: 'TP. Hồ Chí Minh',
          amenities: ['Wifi', 'Nội thất gỗ', 'Bình nóng lạnh'],
          isVerified: true,
          viewCount: 93, contactCount: 9, area: 30, bedrooms: 1,
          direction: RoomDirection.east,
          postedAt: DateTime.now().subtract(const Duration(days: 3)),
          expiresAt: DateTime.now().add(const Duration(days: 27)),
        ),
      ];
}
