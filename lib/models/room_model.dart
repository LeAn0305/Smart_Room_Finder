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
  final bool isVerified;

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
    this.isVerified = true,
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
          imageUrl: 'assets/images/room_studio_luxury.png',
          rating: 4.8,
          type: RoomType.studio,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Wifi', 'Máy lạnh', 'Tủ lạnh', 'Máy giặt'],
          isFavorite: true,
          isVerified: true,
        ),
        RoomModel(
          id: '2',
          title: 'Chung cư 2 phòng ngủ',
          description: 'View đẹp, thoáng mát, gần công viên và trường học.',
          price: 8000000,
          address: 'Quận 7, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_apartment_2br.png',
          rating: 4.5,
          type: RoomType.apartment,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Hồ bơi', 'Phòng gym', 'Wifi', 'Máy lạnh'],
          isVerified: true,
        ),
        RoomModel(
          id: '3',
          title: 'Nhà nguyên căn mặt tiền',
          description: 'Phù hợp cho gia đình hoặc nhóm bạn, có sân đậu xe hơi.',
          price: 15000000,
          address: 'Quận Bình Thạnh, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_house_frontage.png',
          rating: 4.9,
          type: RoomType.house,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Sân vườn', 'Bếp rộng', 'Wifi', 'Máy lạnh'],
          isVerified: false,
        ),
        RoomModel(
          id: '4',
          title: 'Căn hộ mini hiện đại',
          description: 'Giá rẻ, sạch sẽ, chủ nhà thân thiện, không chung chủ.',
          price: 3500000,
          address: 'Quận Gò Vấp, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_apartment_mini.png',
          rating: 4.2,
          type: RoomType.apartment,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Wifi', 'Bếp', 'Chỗ để xe'],
          isVerified: true,
        ),
        RoomModel(
          id: '5',
          title: 'Phòng trọ sinh viên tiện nghi',
          description: 'Gần các trường đại học, an ninh tốt, wifi tốc độ cao.',
          price: 2800000,
          address: 'Quận Thủ Đức, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_student_room.png',
          rating: 4.0,
          type: RoomType.studio,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Wifi', 'Quạt', 'Giường nệm'],
          isVerified: true,
        ),
        RoomModel(
          id: '6',
          title: 'Căn hộ Horizon View',
          description: 'Căn hộ cao cấp với tầm nhìn toàn thành phố, nội thất nhập khẩu.',
          price: 12000000,
          address: 'Quận 2, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_apartment_horizon.png',
          rating: 4.9,
          type: RoomType.apartment,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Hồ bơi cực mây', 'Gym', 'Wifi', 'Full nội thất'],
          isVerified: true,
          isFavorite: true,
        ),
        RoomModel(
          id: '7',
          title: 'Nhà cho thuê nguyên căn hẻm xe hơi',
          description: 'Khu vực yên tĩnh, dân trí cao, phù hợp ở gia đình.',
          price: 18000000,
          address: 'Quận Tân Bình, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_house_alley.png',
          rating: 4.6,
          type: RoomType.house,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Garage', 'Sân thượng', 'Máy lạnh'],
          isVerified: false,
        ),
        RoomModel(
          id: '8',
          title: 'Studio nhỏ gọn phong cách Muji',
          description: 'Phong cách tối giản, đầy đủ ánh sáng tự nhiên.',
          price: 4800000,
          address: 'Quận 3, TP. Hồ Chí Minh',
          imageUrl: 'assets/images/room_muji_studio.png',
          rating: 4.7,
          type: RoomType.studio,
          location: 'TP. Hồ Chí Minh',
          amenities: ['Wifi', 'Nội thất gỗ', 'Bình nóng lạnh'],
          isVerified: true,
        ),
      ];
}
