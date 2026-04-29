import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// ENUMS
// =============================================================================

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

/// Trạng thái kiểm duyệt bài đăng phòng từ phía Admin.
/// Lưu trong Firestore với field name là 'approvalStatus'.
///
/// Backward-compatible: nếu field 'approvalStatus' chưa có trong Firestore
/// (phòng cũ), tự động suy ra từ [isVerified] và [isDraft].
enum RoomStatus {
  /// Phòng vừa được chủ trọ đăng lên, đang chờ Admin xem xét và xác minh.
  /// Phòng vẫn hiển thị công khai trên Home Screen với nhãn "Chưa xác minh".
  /// Điều kiện tương đương: isVerified=false, isDraft=false
  pending,

  /// Admin đã kiểm tra thông tin, xác minh hợp lệ và cho phép hiển thị đầy đủ.
  /// Phòng hiển thị trên Home Screen với nhãn "Đã xác minh".
  /// Điều kiện tương đương: isVerified=true
  verified,

  /// Admin từ chối bài đăng do vi phạm nội dung, thông tin sai lệch hoặc
  /// không đủ tiêu chuẩn đăng tải.
  /// Phòng bị ẩn hoàn toàn khỏi Home Screen (isActive=false, isDraft=true).
  /// Mọi đơn yêu cầu (applications) liên quan đều bị hủy.
  rejected,

  /// Admin yêu cầu chủ trọ bổ sung thêm giấy tờ, ảnh hoặc thông tin còn thiếu.
  /// Phòng vẫn hiển thị công khai với nhãn "Chưa xác minh" trong khi chờ bổ sung.
  /// Chủ trọ nhận thông báo và cần cập nhật trước khi Admin xét duyệt lại.
  needsInfo,
}

// =============================================================================
// SUPPORTING MODELS
// =============================================================================

/// Giấy tờ pháp lý do chủ trọ đính kèm vào bài đăng phòng.
/// Admin sẽ xem xét các giấy tờ này trước khi xác minh bài đăng.
/// Lưu trong Firestore dưới dạng array of map trong field 'documents' của room.
class RoomDocument {
  /// ID duy nhất của giấy tờ (tạo tự động khi upload).
  final String id;

  /// Tên mô tả giấy tờ. Ví dụ: "Sổ đỏ / Hợp đồng nhà", "CMND/CCCD chủ trọ".
  final String title;

  /// Loại định dạng file. Ví dụ: "PDF", "JPG", "PNG".
  final String fileType;

  /// Kích thước file hiển thị cho người dùng. Ví dụ: "1.2 MB", "824 KB".
  final String fileSize;

  /// URL download/preview của file trên Firebase Storage.
  final String url;

  const RoomDocument({
    required this.id,
    required this.title,
    required this.fileType,
    required this.fileSize,
    required this.url,
  });

  factory RoomDocument.fromMap(Map<String, dynamic> map) {
    return RoomDocument(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      fileType: (map['fileType'] ?? '').toString(),
      fileSize: (map['fileSize'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'fileType': fileType,
      'fileSize': fileSize,
      'url': url,
    };
  }
}

/// Một mục trong lịch sử kiểm duyệt bài đăng phòng.
/// Mỗi lần Admin thực hiện hành động (xác minh/từ chối/yêu cầu bổ sung)
/// hoặc hệ thống tạo sự kiện tự động đều được ghi lại tại đây.
/// Lưu trong Firestore dưới dạng array of map trong field 'reviewHistory' của room.
class RoomReviewHistory {
  /// ID duy nhất của mục lịch sử.
  final String id;

  /// Thời điểm xảy ra sự kiện.
  final DateTime time;

  /// Tiêu đề ngắn mô tả hành động. Ví dụ: "Bài đăng đã xác minh".
  final String title;

  /// Mô tả chi tiết hơn về sự kiện đó.
  final String subtitle;

  /// UID của Admin thực hiện hành động.
  /// Null nếu đây là hành động tự động của hệ thống (ví dụ: tạo bài đăng).
  final String? actorId;

  /// Tên hiển thị của người thực hiện.
  /// Ví dụ: "Admin Lan", hoặc "Hệ thống" nếu actorId == null.
  final String actorName;

  const RoomReviewHistory({
    required this.id,
    required this.time,
    required this.title,
    required this.subtitle,
    this.actorId,
    required this.actorName,
  });

  factory RoomReviewHistory.fromMap(Map<String, dynamic> map) {
    return RoomReviewHistory(
      id: (map['id'] ?? '').toString(),
      time: _parseDateTime(map['time']) ?? DateTime.now(),
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      actorId: map['actorId']?.toString(),
      actorName: (map['actorName'] ?? 'Hệ thống').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': Timestamp.fromDate(time),
      'title': title,
      'subtitle': subtitle,
      'actorId': actorId,
      'actorName': actorName,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

// =============================================================================
// ROOM MODEL
// =============================================================================

class RoomModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final double price;
  final String address;
  final String location;

  /// Phòng đang ở chế độ nháp (chủ trọ chưa đăng hoặc bị từ chối).
  /// true  → phòng bị ẩn khỏi Home Screen, không ai xem được ngoài chủ trọ.
  /// false → phòng hiển thị công khai (dù chưa được Admin xác minh).
  final bool isDraft;

  /// Người dùng đã thêm phòng này vào danh sách yêu thích chưa.
  /// Field này được quản lý riêng theo từng user, không phải trạng thái phòng.
  final bool isFavorite;

  /// Admin đã xác minh thông tin phòng hay chưa.
  /// true  → hiển thị badge "Đã xác minh" trên Home Screen.
  /// false → hiển thị badge "Chưa xác minh" (nếu isDraft=false và isActive=true).
  final bool isVerified;

  /// Phòng đang hoạt động (được phép hiển thị) hay không.
  /// true  → bình thường, hiển thị theo isDraft/isVerified.
  /// false → bị tắt hoàn toàn (ví dụ: Admin từ chối → isActive=false).
  final bool isActive;

  // ---------------------------------------------------------------------------
  // Ảnh (giữ cả field cũ và mới để backward compatible)
  // ---------------------------------------------------------------------------

  /// [Cũ] URL ảnh đại diện. Dùng mainImageUrl thay thế trong code mới.
  final String imageUrl;

  /// [Cũ] Danh sách ảnh phụ. Dùng subImageUrls thay thế trong code mới.
  final List<String> images;

  /// [Mới] URL ảnh đại diện chính của phòng (hiển thị trên card ở Home Screen).
  final String mainImageUrl;

  /// [Mới] Danh sách URL ảnh phụ trong gallery của bài đăng.
  final List<String> subImageUrls;

  // ---------------------------------------------------------------------------
  // Thông tin chi tiết phòng
  // ---------------------------------------------------------------------------
  final double rating;
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

  // ---------------------------------------------------------------------------
  // Trạng thái kiểm duyệt (mới)
  // ---------------------------------------------------------------------------

  /// Trạng thái kiểm duyệt của bài đăng, lưu bằng field 'approvalStatus' trong Firestore.
  ///
  /// Backward-compatible: phòng cũ chưa có field này sẽ tự động được suy ra:
  ///   - isVerified=true               → [RoomStatus.verified]
  ///   - isDraft=true                  → [RoomStatus.rejected]
  ///   - isVerified=false, isDraft=false → [RoomStatus.pending]
  final RoomStatus approvalStatus;

  /// Danh sách giấy tờ pháp lý mà chủ trọ đính kèm vào bài đăng.
  /// Admin xem xét các giấy tờ này trong quá trình kiểm duyệt.
  /// Lưu trong Firestore dưới dạng array of map, field 'documents'.
  final List<RoomDocument> documents;

  /// Lịch sử các lần Admin thao tác với bài đăng này.
  /// Mỗi hành động (xác minh/từ chối/yêu cầu bổ sung) đều được ghi lại.
  /// Lưu trong Firestore dưới dạng array of map, field 'reviewHistory'.
  final List<RoomReviewHistory> reviewHistory;

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

    // Kiểm duyệt (mới)
    this.approvalStatus = RoomStatus.pending,
    this.documents = const [],
    this.reviewHistory = const [],
  });

  factory RoomModel.fromMap(Map<String, dynamic> map, String docId) {
    final resolvedMainImage =
        (map['mainImageUrl'] ?? map['imageUrl'] ?? '').toString();

    final resolvedSubImages = List<String>.from(
      map['subImageUrls'] ?? map['images'] ?? [],
    );

    // Parse approvalStatus — backward compatible với phòng cũ
    final approvalStatus = _parseApprovalStatus(
      raw: map['approvalStatus'],
      isVerified: map['isVerified'] ?? false,
      isDraft: map['isDraft'] ?? false,
    );

    // Parse documents array
    final rawDocuments = map['documents'];
    final documents = rawDocuments is List
        ? rawDocuments
            .whereType<Map<String, dynamic>>()
            .map(RoomDocument.fromMap)
            .toList()
        : <RoomDocument>[];

    // Parse reviewHistory array
    final rawHistory = map['reviewHistory'];
    final reviewHistory = rawHistory is List
        ? rawHistory
            .whereType<Map<String, dynamic>>()
            .map(RoomReviewHistory.fromMap)
            .toList()
        : <RoomReviewHistory>[];

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

      // kiểm duyệt
      approvalStatus: approvalStatus,
      documents: documents,
      reviewHistory: reviewHistory,
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

      // kiểm duyệt (mới)
      'approvalStatus': approvalStatus.name,
      'documents': documents.map((d) => d.toMap()).toList(),
      'reviewHistory': reviewHistory.map((h) => h.toMap()).toList(),
    };
  }

  Map<String, dynamic> toFirebase() => toMap();

  Map<String, dynamic> toFirebaseForUpdate() => toMap();

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

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
    RoomStatus? approvalStatus,
    List<RoomDocument>? documents,
    List<RoomReviewHistory>? reviewHistory,
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
      approvalStatus: approvalStatus ?? this.approvalStatus,
      documents: documents ?? this.documents,
      reviewHistory: reviewHistory ?? this.reviewHistory,
    );
  }

  // ---------------------------------------------------------------------------
  // Static helpers
  // ---------------------------------------------------------------------------

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

  /// Suy ra [RoomStatus] từ field 'approvalStatus' hoặc từ các boolean cũ.
  /// Đảm bảo backward compatible với phòng cũ trong Firestore chưa có field này.
  static RoomStatus _parseApprovalStatus({
    required dynamic raw,
    required bool isVerified,
    required bool isDraft,
  }) {
    if (raw != null) {
      try {
        return RoomStatus.values.firstWhere((e) => e.name == raw.toString());
      } catch (_) {
        // fall through to legacy logic
      }
    }
    // Fallback cho phòng cũ không có approvalStatus
    if (isVerified) return RoomStatus.verified;
    if (isDraft) return RoomStatus.rejected;
    return RoomStatus.pending;
  }

  // ---------------------------------------------------------------------------
  // Sample data (chỉ dùng cho testing/UI development)
  // ---------------------------------------------------------------------------

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
      type: RoomType.studio,
      amenities: ['Gác gỗ', 'Kệ bếp', 'Wifi', 'WC riêng'],
      isFavorite: true,
      isVerified: true,
      approvalStatus: RoomStatus.verified,
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
      type: RoomType.studio,
      amenities: ['Giường tầng', 'Máy lạnh', 'Tủ cá nhân', 'Dọn phòng'],
      isVerified: true,
      approvalStatus: RoomStatus.verified,
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
      type: RoomType.apartment,
      amenities: ['Bếp riêng', 'Toilet riêng', 'Hầm xe', 'Bảo vệ'],
      isVerified: true,
      approvalStatus: RoomStatus.verified,
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}