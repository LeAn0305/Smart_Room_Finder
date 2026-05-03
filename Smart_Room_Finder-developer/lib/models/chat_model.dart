class ChatModel {
  final String id;
  final String roomId;
  final String roomTitle;
  final String roomImageUrl;
  final String ownerId;
  final String ownerName;
  final String renterId;
  final String renterName;
  final String lastMessage;
  final String? lastMessageTime;
  final String lastSenderId;
  final List<String> participants;
  final String createdAt;
  final String updatedAt;
  final String? applicationId;

  const ChatModel({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.roomImageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.renterId,
    required this.renterName,
    required this.lastMessage,
    this.lastMessageTime,
    required this.lastSenderId,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.applicationId,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatModel(
      id: docId,
      roomId: map['roomId'] ?? '',
      roomTitle: map['roomTitle'] ?? '',
      roomImageUrl: map['roomImageUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      renterId: map['renterId'] ?? '',
      renterName: map['renterName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'],
      lastSenderId: map['lastSenderId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
      applicationId: map['applicationId'],
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
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastSenderId': lastSenderId,
      'participants': participants,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'applicationId': applicationId,
    };
  }

  ChatModel copyWith({
    String? id,
    String? roomId,
    String? roomTitle,
    String? roomImageUrl,
    String? ownerId,
    String? ownerName,
    String? renterId,
    String? renterName,
    String? lastMessage,
    String? lastMessageTime,
    String? lastSenderId,
    List<String>? participants,
    String? createdAt,
    String? updatedAt,
    String? applicationId,
  }) {
    return ChatModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      roomTitle: roomTitle ?? this.roomTitle,
      roomImageUrl: roomImageUrl ?? this.roomImageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      applicationId: applicationId ?? this.applicationId,
    );
  }
}