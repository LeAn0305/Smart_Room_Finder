enum RoomType {
  apartment,
  studio,
  house,
  villa,
}

class RoomModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String address;
  final String imageUrl;
  final double rating;
  final RoomType type;
  final String location;
  final List<String> amenities;
  final bool isFavorite;

  RoomModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.address,
    required this.imageUrl,
    required this.rating,
    required this.type,
    required this.location,
    required this.amenities,
    this.isFavorite = false,
  });

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

  static List<RoomModel> get sampleRooms => [
        RoomModel(
          id: '1',
          title: 'Căn hộ Studio cao cấp',
          description: 'Căn hộ đầy đủ tiện nghi, gần trung tâm thành phố, an ninh 24/7.',
          price: 5500000,
          address: 'Quận 1, TP. Hồ Chí Minh',
          imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=60',
          rating: 4.8,
          type: RoomType.studio,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Wifi', 'Máy lạnh', 'Tủ lạnh', 'Máy giặt'],
        ),
        RoomModel(
          id: '2',
          title: 'Chung cư 2 phòng ngủ',
          description: 'View đẹp, thoáng mát, gần công viên và trường học.',
          price: 8000000,
          address: 'Quận 7, TP. Hồ Chí Minh',
          imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=60',
          rating: 4.5,
          type: RoomType.apartment,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Hồ bơi', 'Phòng gym', 'Wifi', 'Máy lạnh'],
        ),
        RoomModel(
          id: '3',
          title: 'Nhà nguyên căn mặt tiền',
          description: 'Phù hợp cho gia đình hoặc nhóm bạn, có sân đậu xe hơi.',
          price: 15000000,
          address: 'Quận Bình Thạnh, TP. Hồ Chí Minh',
          imageUrl: 'https://images.unsplash.com/photo-1481437156560-3205f6a55735?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=60',
          rating: 4.9,
          type: RoomType.house,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Sân vườn', 'Bếp rộng', 'Wifi', 'Máy lạnh'],
        ),
        RoomModel(
          id: '4',
          title: 'Căn hộ mini hiện đại',
          description: 'Giá rẻ, sạch sẽ, chủ nhà thân thiện, không chung chủ.',
          price: 3500000,
          address: 'Quận Gò Vấp, TP. Hồ Chí Minh',
          imageUrl: 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=60',
          rating: 4.2,
          type: RoomType.apartment,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Wifi', 'Bếp', 'Chỗ để xe'],
        ),
      ];
}
