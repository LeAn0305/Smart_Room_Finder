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
  northWest
}

class RoomModel {
  final String id;
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
    this.isVerified = false,
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

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  int get daysLeft {
    if (expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  RoomModel copyWith({
    String? id,
    String? title,
    String? description,
    int? price,
    String? address,
    String? imageUrl,
    List<String>? images,
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
    DateTime? expiresAt,
    bool? isDraft,
  }) {
    return RoomModel(
      id: id ?? this.id,
      rating: rating,
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
  static List<RoomModel> sampleRooms = [
        RoomModel(
          id: '1',
          title: 'Phòng trọ gác gỗ đơn giản Quận 7',
          description: 'Phòng trọ sạch sẽ, thiết kế gác gỗ simili chắc chắn, không gian đơn giản phù hợp sinh viên và người lao động. Gần chợ Tân Mỹ.',
          price: 2500000,
          address: 'Đường Lê Văn Lương, Quận 7, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/phong_tro_gac_lung_go.png',
          rating: 4.2,
          type: RoomType.studio,
          location: 'Quận 7',
          amenities: ['Gác gỗ', 'Kệ bếp', 'Wifi', 'WC riêng'],
          isFavorite: true,
          isVerified: true,
        ),
        RoomModel(
          id: '2',
          title: 'Ký túc xá sinh viên sạch sẽ Quận 10',
          description: 'Dạng giường tầng đơn giản, có máy lạnh, mỗi người một tủ cá nhân. Khu vực yên tĩnh, an ninh tốt.',
          price: 1500000,
          address: 'Đường Lý Thường Kiệt, Quận 10, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/ky_tuc_xa_sinh_vien.png',
          rating: 4.4,
          type: RoomType.studio,
          location: 'Quận 10',
          amenities: ['Giường tầng', 'Máy lạnh', 'Tủ cá nhân', 'Dọn phòng'],
          isVerified: true,
          viewCount: 85, contactCount: 7, area: 65, bedrooms: 2,
          direction: RoomDirection.southEast,
          postedAt: DateTime.now().subtract(const Duration(days: 10)),
          expiresAt: DateTime.now().add(const Duration(days: 3)),
        ),
        RoomModel(
          id: '3',
          title: 'Căn hộ mini cơ bản Quận Bình Thạnh',
          description: 'Căn hộ nhỏ gọn có khu vực bếp riêng, toilet sạch sẽ, gạch ốp tường láng đẹp. Thích hợp gia đình nhỏ.',
          price: 4500000,
          address: 'Đường Nơ Trang Long, Quận Bình Thạnh, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/can_ho_mini_don_gian.png',
          rating: 4.0,
          type: RoomType.apartment,
          location: 'Bình Thạnh',
          amenities: ['Bếp riêng', 'Toilet riêng', 'Hầm xe', 'Bảo vệ'],
          isVerified: true,
        ),
        RoomModel(
          id: '4',
          title: 'Phòng trọ gác sắt giá rẻ Quận 12',
          description: 'Thiết kế gác sắt bền bỉ, sàn gạch sạch sẽ, có cửa sổ thoáng mát. Giá cả bình dân.',
          price: 1800000,
          address: 'Đường Hà Huy Giáp, Quận 12, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/phong_tro_gac_sat.png',
          rating: 3.8,
          type: RoomType.studio,
          location: 'Quận 12',
          amenities: ['Gác sắt', 'Cửa sổ', 'Wifi nội bộ', 'Giờ tự do'],
          isVerified: true,
          viewCount: 44, contactCount: 3, area: 28, bedrooms: 1,
          direction: RoomDirection.west,
          postedAt: DateTime.now().subtract(const Duration(days: 15)),
          expiresAt: DateTime.now().add(const Duration(days: 15)),
        ),
        RoomModel(
          id: '5',
          title: 'Phòng trọ gác gỗ hẻm xe máy Quận 3',
          description: 'Phòng ở hẻm cụt yên tĩnh, gác gỗ lót Simili sạch đẹp, chủ nhà thân thiện.',
          price: 3200000,
          address: 'Đường Nguyễn Đình Chiểu, Quận 3, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/phong_tro_gac_lung_go.png',
          rating: 4.3,
          type: RoomType.studio,
          location: 'Quận 3',
          amenities: ['Gác gỗ', 'WC riêng', 'Để xe máy', 'Wifi'],
          isVerified: false,
          viewCount: 156, contactCount: 18, area: 150, bedrooms: 4,
          direction: RoomDirection.southWest,
          postedAt: DateTime.now().subtract(const Duration(days: 20)),
          expiresAt: DateTime.now().add(const Duration(days: 10)),
        ),
        RoomModel(
          id: '6',
          title: 'Ký túc xá giá rẻ Làng Đại Học',
          description: 'Dành cho sinh viên cần chỗ ở gần trường. Giường tầng gỗ chắc chắn, khu sinh hoạt chung sạch sẽ.',
          price: 1200000,
          address: 'Làng Đại Học Quốc Gia, Thủ Đức, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/ky_tuc_xa_sinh_vien.png',
          rating: 4.5,
          type: RoomType.studio,
          location: 'Thủ Đức',
          amenities: ['Giường tầng', 'Wifi mạnh', 'Gần trường', 'Giặt sấy'],
          isVerified: true,
          viewCount: 93, contactCount: 9, area: 30, bedrooms: 1,
          direction: RoomDirection.east,
          postedAt: DateTime.now().subtract(const Duration(days: 3)),
          expiresAt: DateTime.now().add(const Duration(days: 27)),
        ),
        RoomModel(
          id: '7',
          title: 'Căn hộ dịch vụ cơ bản Quận 9',
          description: 'Không gian tách biệt, có kệ bếp nhỏ, sàn gạch xám hiện đại. Gần khu công nghệ cao.',
          price: 3500000,
          address: 'Đường Lê Văn Việt, Quận 9, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/can_ho_mini_don_gian.png',
          rating: 4.1,
          type: RoomType.apartment,
          location: 'Quận 9',
          amenities: ['Kệ bếp', 'Thang máy', 'Hầm xe', 'Camera'],
          isVerified: true,
        ),
        RoomModel(
          id: '8',
          title: 'Phòng trọ gác sắt lầu cao Quận 8',
          description: 'Phòng tầng 3 thoáng mát, không chung chủ, giờ giấc thoải mái cho người đi làm.',
          price: 2200000,
          address: 'Đường Phạm Hùng, Quận 8, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/phong_tro_gac_sat.png',
          rating: 3.9,
          type: RoomType.studio,
          location: 'Quận 8',
          amenities: ['Gác sắt', 'Wifi', 'Giờ tự do', 'Không chung chủ'],
          isVerified: true,
        ),
        RoomModel(
          id: '9',
          title: 'Phòng trọ gác gỗ gần sân bay Tân Bình',
          description: 'Phòng rộng thoáng, gác gỗ cao không đụng đầu. Thích hợp ở nhóm bạn sinh viên.',
          price: 3800000,
          address: 'Đường Cộng Hòa, Quận Tân Bình, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/phong_tro_gac_lung_go.png',
          rating: 4.4,
          type: RoomType.studio,
          location: 'Tân Bình',
          amenities: ['Gác gỗ cao', 'Ban công nhỏ', 'Wifi', 'Chỗ để xe'],
          isVerified: true,
        ),
        RoomModel(
          id: '10',
          title: 'KTX sinh viên kiểu mới Quận 5',
          description: 'Phòng ngủ tập thể ngăn giường tầng sạch sẽ, có máy lạnh và bàn học chung.',
          price: 1600000,
          address: 'Đường Sư Vạn Hạnh, Quận 5, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/ky_tuc_xa_sinh_vien.png',
          rating: 4.2,
          type: RoomType.studio,
          location: 'Quận 5',
          amenities: ['Giường tầng', 'Máy lạnh', 'Bàn học', 'Wifi'],
          isVerified: true,
        ),
        RoomModel(
          id: '11',
          title: 'Chung cư mini cho người lao động Gò Vấp',
          description: 'Căn hộ tầng trệt có gác nhỏ, bếp kín thoáng, khu vực dân cư an ninh.',
          price: 4200000,
          address: 'Đường Phan Văn Trị, Quận Gò Vấp, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/can_ho_mini_don_gian.png',
          rating: 4.0,
          type: RoomType.apartment,
          location: 'Gò Vấp',
          amenities: ['Bếp kín', 'Hầm xe', 'Sân phơi', 'Giờ tự do'],
          isVerified: false,
        ),
        RoomModel(
          id: '12',
          title: 'Phòng trọ gác sắt Phường Thạnh Xuân Q12',
          description: 'Dãy trọ mới xây, gác sắt sơn trắng sạch đẹp, chủ trọ quản lý bằng vân tay.',
          price: 2000000,
          address: 'Phường Thạnh Xuân, Quận 12, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/phong_tro_gac_sat.png',
          rating: 4.1,
          type: RoomType.studio,
          location: 'Quận 12',
          amenities: ['Khóa vân tay', 'Gác sắt', 'Wifi', 'An ninh'],
          isVerified: true,
        ),
        RoomModel(
          id: '13',
          title: 'Phòng trọ gác gỗ bình dân Nhà Bè',
          description: 'Giá cực tốt cho công nhân viên, phòng có gác gỗ chắc chắn, gần khu công nghiệp Hiệp Phước.',
          price: 1600000,
          address: 'Đường Huỳnh Tấn Phát, Nhà Bè, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/phong_tro_gac_lung_go.png',
          rating: 3.7,
          type: RoomType.studio,
          location: 'Nhà Bè',
          amenities: ['Gác gỗ', 'Wifi', 'WC trong', 'Giá rẻ'],
          isVerified: true,
        ),
        RoomModel(
          id: '14',
          title: 'KTX giá rẻ cho nam Quận 6',
          description: 'Dạng giường tầng cơ bản, gần bến xe Miền Tây. Thích hợp người lao động cần chỗ nghỉ ngơi.',
          price: 1300000,
          address: '1085 Hậu Giang, Quận 6, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/ky_tuc_xa_sinh_vien.png',
          rating: 3.9,
          type: RoomType.studio,
          location: 'Quận 6',
          amenities: ['Giường tầng', 'Sân để xe', 'Khu giặt đồ', 'Bảo vệ'],
          isVerified: true,
        ),
        RoomModel(
          id: '15',
          title: 'Căn hộ mini 28m2 Quận Tân Phú',
          description: 'Phòng rộng có gác đúc chắc chắn, bếp dài sạch sẽ, khu vực chung cư mini văn minh.',
          price: 4800000,
          address: 'Đường Bờ Bao Tân Thắng, Quận Tân Phú, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/can_ho_mini_don_gian.png',
          rating: 4.2,
          type: RoomType.apartment,
          location: 'Tân Phú',
          amenities: ['Gác đúc', 'Bếp dài', 'Thang máy', 'Sân phơi'],
          isVerified: true,
        ),
        RoomModel(
          id: '16',
          title: 'Phòng trọ gác sắt lầu lửng Hóc Môn',
          description: 'Hệ thống phòng trọ gác sắt kiên cố, thang sắt có tay vịn an toàn, gần chợ đầu mối.',
          price: 1700000,
          address: 'Đường Nguyễn Văn Bứa, Hóc Môn, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/phong_tro_gac_sat.png',
          rating: 3.8,
          type: RoomType.studio,
          location: 'Hóc Môn',
          amenities: ['Thang sắt an toàn', 'Gác sắt', 'Wifi FREE', 'Điện nước rẻ'],
          isVerified: true,
        ),
        RoomModel(
          id: '17',
          title: 'Phòng trọ gác lửng gỗ Bình Chánh',
          description: 'Dành cho đối tượng thu nhập trung bình, gác gỗ simili bền đẹp, WC sạch sẽ.',
          price: 2300000,
          address: 'Quốc Lộ 50, Bình Chánh, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/phong_tro_gac_lung_go.png',
          rating: 4.0,
          type: RoomType.studio,
          location: 'Bình Chánh',
          amenities: ['Gác gỗ', 'WC riêng', 'Wifi', 'Giờ tự do'],
          isVerified: true,
        ),
        RoomModel(
          id: '18',
          title: 'KTX cao cấp máy lạnh Quận 1',
          description: 'KTX giường tầng gỗ hiện đại trung tâm thành phố, máy lạnh 24/24, đầy đủ tiện ích sinh hoạt.',
          price: 2200000,
          address: 'Đường Bùi Viện, Quận 1, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/ky_tuc_xa_sinh_vien.png',
          rating: 4.6,
          type: RoomType.studio,
          location: 'Quận 1',
          amenities: ['Giường gỗ', 'Máy lạnh', 'Bàn học', 'Khu trung tâm'],
          isVerified: true,
        ),
        RoomModel(
          id: '19',
          title: 'Căn hộ mini Studio Phú Nhuận',
          description: 'Thiết kế tối giản, kệ bếp áp tường, không gian sạch sẽ thoáng đãng, gần công viên Gia Định.',
          price: 5500000,
          address: 'Đường Phan Xích Long, Quận Phú Nhuận, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/can_ho_mini_don_gian.png',
          rating: 4.5,
          type: RoomType.apartment,
          location: 'Phú Nhuận',
          amenities: ['Kệ bếp', 'Máy lạnh', 'Wifi', 'Thang máy'],
          isVerified: false,
        ),
        RoomModel(
          id: '20',
          title: 'Phòng trọ gác sắt lợp tôn lạnh Q2',
          description: 'Trần lợp tôn lạnh chống nóng, gác sắt kiên cố, phù hợp ở ghép 3-4 người.',
          price: 4000000,
          address: 'Đường Lương Định Của, Quận 2, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/phong_tro_gac_sat.png',
          rating: 4.2,
          type: RoomType.studio,
          location: 'Quận 2',
          amenities: ['Chống nóng', 'Gác sắt rộng', 'Wifi', 'Sân để xe'],
          isVerified: false,
        ),
      ];
}
