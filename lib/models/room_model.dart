import 'package:cloud_firestore/cloud_firestore.dart';

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
  final double price;
  final String address;
  final String location;

  final bool isDraft;
  final bool isFavorite;
  final bool isVerified;
  final bool isActive;

  // Ảnh cũ
  final String imageUrl;
  final List<String> images;

  // Ảnh mới
  final String mainImageUrl;
  final List<String> subImageUrls;

  final double rating;
  final int totalReviews;
  final double latitude;
  final double longitude;
  final RoomType type;
  final double area;
  final int bedrooms;
  final List<String> amenities;
  final int viewCount;
  final int contactCount;
  final String postedBy;
  final RoomDirection? direction;
  final DateTime? postedAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const RoomModel({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description = '',
    required this.price,
    this.address = '',
    this.location = '',
    this.isDraft = false,
    this.isFavorite = false,
    this.isVerified = false,
    this.isActive = true,

    // Ảnh cũ
    this.imageUrl = '',
    this.images = const [],

    // Ảnh mới
    this.mainImageUrl = '',
    this.subImageUrls = const [],

    this.rating = 0,
    this.totalReviews = 0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.type = RoomType.studio,
    this.area = 0,
    this.bedrooms = 0,
    this.amenities = const [],
    this.viewCount = 0,
    this.contactCount = 0,
    this.postedBy = '',
    this.direction,
    this.postedAt,
    this.updatedAt,
    this.expiresAt,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map, String docId) {
    final resolvedMainImage =
        (map['mainImageUrl'] ?? map['imageUrl'] ?? '').toString();

    final resolvedSubImages = List<String>.from(
      map['subImageUrls'] ?? map['images'] ?? [],
    );

    return RoomModel(
      id: docId,
      ownerId: (map['ownerId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      price: _toDouble(map['price']),
      address: (map['address'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      isDraft: map['isDraft'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? true,

      // field cũ
      imageUrl: (map['imageUrl'] ?? map['mainImageUrl'] ?? '').toString(),
      images: List<String>.from(map['images'] ?? map['subImageUrls'] ?? []),

      // field mới
      mainImageUrl: resolvedMainImage,
      subImageUrls: resolvedSubImages,

      rating: _toDouble(map['rating']),
      totalReviews: _toInt(map['totalReviews']),
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      type: _parseRoomType(map['type']),
      area: _toDouble(map['area']),
      bedrooms: _toInt(map['bedrooms']),
      amenities: List<String>.from(map['amenities'] ?? []),
      viewCount: _toInt(map['viewCount']),
      contactCount: _toInt(map['contactCount']),
      postedBy: (map['postedBy'] ?? '').toString(),
      direction: _parseDirectionNullable(map['direction']),
      postedAt: _parseDateTime(map['postedAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      expiresAt: _parseDateTime(map['expiresAt']),
    );
  }

  factory RoomModel.fromFirebase(Map<String, dynamic> data, String docId) {
    return RoomModel.fromMap(data, docId);
  }

  factory RoomModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RoomModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'price': price,
      'address': address,
      'location': location,
      'isDraft': isDraft,
      'isFavorite': isFavorite,
      'isVerified': isVerified,
      'isActive': isActive,

      // giữ field cũ để code cũ không gãy
      'imageUrl': mainImageUrl.isNotEmpty ? mainImageUrl : imageUrl,
      'images': subImageUrls.isNotEmpty ? subImageUrls : images,

      // field mới
      'mainImageUrl': mainImageUrl.isNotEmpty ? mainImageUrl : imageUrl,
      'subImageUrls': subImageUrls.isNotEmpty ? subImageUrls : images,

      'rating': rating,
      'totalReviews': totalReviews,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'area': area,
      'bedrooms': bedrooms,
      'amenities': amenities,
      'viewCount': viewCount,
      'contactCount': contactCount,
      'postedBy': postedBy,
      'direction': direction?.name,
      'postedAt': postedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirebase() => toMap();

  Map<String, dynamic> toFirebaseForUpdate() => toMap();

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }

  int get daysLeft {
    if (expiresAt == null) return 0;
    final now = DateTime.now();
    final difference = expiresAt!.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  String get typeString {
    switch (type) {
      case RoomType.apartment:
        return 'apartment';
      case RoomType.studio:
        return 'studio';
      case RoomType.house:
        return 'house';
      case RoomType.villa:
        return 'villa';
    }
  }

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
      case null:
        return '';
    }
  }


  RoomModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    double? price,
    String? address,
    String? location,
    bool? isDraft,
    bool? isFavorite,
    bool? isVerified,
    bool? isActive,
    String? imageUrl,
    List<String>? images,
    String? mainImageUrl,
    List<String>? subImageUrls,
    double? rating,
    int? totalReviews,
    double? latitude,
    double? longitude,
    RoomType? type,
    double? area,
    int? bedrooms,
    List<String>? amenities,
    int? viewCount,
    int? contactCount,
    String? postedBy,
    RoomDirection? direction,
    DateTime? postedAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      address: address ?? this.address,
      location: location ?? this.location,
      isDraft: isDraft ?? this.isDraft,
      isFavorite: isFavorite ?? this.isFavorite,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      subImageUrls: subImageUrls ?? this.subImageUrls,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      area: area ?? this.area,
      bedrooms: bedrooms ?? this.bedrooms,
      amenities: amenities ?? this.amenities,
      viewCount: viewCount ?? this.viewCount,
      contactCount: contactCount ?? this.contactCount,
      postedBy: postedBy ?? this.postedBy,
      direction: direction ?? this.direction,
      postedAt: postedAt ?? this.postedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static RoomType _parseRoomType(dynamic value) {
    final raw = (value ?? '').toString();
    return RoomType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => RoomType.studio,
    );
  }

  static RoomDirection? _parseDirectionNullable(dynamic value) {
    if (value == null) return null;
    final raw = value.toString();
    try {
      return RoomDirection.values.firstWhere((e) => e.name == raw);
    } catch (_) {
      return null;
    }
  }

  static final List<RoomModel> sampleRooms = [
    RoomModel(
      id: '1',
      ownerId: 'user_1',
      title: 'Phòng trọ gác gỗ đơn giản Quận 7',
      description:
          'Phòng trọ sạch sẽ, thiết kế gác gỗ simili chắc chắn, không gian đơn giản phù hợp sinh viên và người lao động. Gần chợ Tân Mỹ.',
      price: 2500000,
      address: 'Đường Lê Văn Lương, Quận 7, TP. Hồ Chí Minh',
      location: 'Quận 7',
      imageUrl: 'assets/images/phong_tro_gac_lung_go.png',
      images: ['assets/images/phong_tro_gac_lung_go.png'],
      mainImageUrl: 'assets/images/phong_tro_gac_lung_go.png',
      subImageUrls: ['assets/images/phong_tro_gac_lung_go.png'],
      rating: 4.2,
      totalReviews: 124,
      latitude: 10.732,
      longitude: 106.700,
      type: RoomType.studio,
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
      address: 'Đường Lý Thường Kiệt, Quận 10, TP. Hồ Chí Minh',
      location: 'Quận 10',
      imageUrl: 'assets/images/ky_tuc_xa_sinh_vien.png',
      images: ['assets/images/ky_tuc_xa_sinh_vien.png'],
      mainImageUrl: 'assets/images/ky_tuc_xa_sinh_vien.png',
      subImageUrls: ['assets/images/ky_tuc_xa_sinh_vien.png'],
      rating: 4.4,
      totalReviews: 85,
      latitude: 10.776,
      longitude: 106.660,
      type: RoomType.studio,
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
      location: 'Bình Thạnh',
      imageUrl: 'assets/images/can_ho_mini_don_gian.png',
      images: ['assets/images/can_ho_mini_don_gian.png'],
      mainImageUrl: 'assets/images/can_ho_mini_don_gian.png',
      subImageUrls: ['assets/images/can_ho_mini_don_gian.png'],
      rating: 4.0,
      totalReviews: 42,
      latitude: 10.810,
      longitude: 106.690,
      type: RoomType.apartment,
      amenities: ['Bếp riêng', 'Toilet riêng', 'Hầm xe', 'Bảo vệ'],
      isVerified: true,
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}