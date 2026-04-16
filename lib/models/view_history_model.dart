class ViewHistoryModel {
  final String id;
  final String userId;
  final String roomId;
  final String title;
  final double price;
  final String address;
  final String imageUrl;
  final DateTime viewedAt;

  ViewHistoryModel({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.title,
    required this.price,
    required this.address,
    required this.imageUrl,
    required this.viewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'roomId': roomId,
      'title': title,
      'price': price,
      'address': address,
      'imageUrl': imageUrl,
      'viewedAt': viewedAt.toIso8601String(),
    };
  }

  factory ViewHistoryModel.fromMap(String id, Map<String, dynamic> map) {
    return ViewHistoryModel(
      id: id,
      userId: map['userId'] ?? '',
      roomId: map['roomId'] ?? '',
      title: map['title'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      viewedAt: DateTime.tryParse(map['viewedAt'] ?? '') ?? DateTime.now(),
    );
  }
}