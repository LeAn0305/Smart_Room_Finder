class ApplicationModel {
  final String id;
  final String roomId;
  final String roomTitle;
  final String roomImageUrl;
  final String ownerId;
  final String ownerName;
  final String renterId;
  final String renterName;
  final String renterPhone;
  final String message;
  final String status;
  final String? expectedMoveInDate;
  final String note;
  final String createdAt;
  final String updatedAt;

  const ApplicationModel({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.roomImageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.renterId,
    required this.renterName,
    required this.renterPhone,
    required this.message,
    required this.status,
    this.expectedMoveInDate,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String docId) {
    return ApplicationModel(
      id: docId,
      roomId: map['roomId'] ?? '',
      roomTitle: map['roomTitle'] ?? '',
      roomImageUrl: map['roomImageUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      renterId: map['renterId'] ?? '',
      renterName: map['renterName'] ?? '',
      renterPhone: map['renterPhone'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      expectedMoveInDate: map['expectedMoveInDate'],
      note: map['note'] ?? '',
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomTitle': roomTitle,
      'roomImageUrl': roomImageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'renterId': renterId,
      'renterName': renterName,
      'renterPhone': renterPhone,
      'message': message,
      'status': status,
      'expectedMoveInDate': expectedMoveInDate,
      'note': note,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ApplicationModel copyWith({
    String? id,
    String? roomId,
    String? roomTitle,
    String? roomImageUrl,
    String? ownerId,
    String? ownerName,
    String? renterId,
    String? renterName,
    String? renterPhone,
    String? message,
    String? status,
    String? expectedMoveInDate,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomTitle: roomTitle ?? this.roomTitle,
      roomImageUrl: roomImageUrl ?? this.roomImageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      renterPhone: renterPhone ?? this.renterPhone,
      message: message ?? this.message,
      status: status ?? this.status,
      expectedMoveInDate: expectedMoveInDate ?? this.expectedMoveInDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}