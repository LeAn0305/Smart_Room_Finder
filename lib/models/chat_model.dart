class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime time;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
  });
}

class ChatConversation {
  final String id;
  final String roomTitle;
  final String roomImage;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastTime;
  final int unreadCount;
  final List<ChatMessage> messages;

  const ChatConversation({
    required this.id,
    required this.roomTitle,
    required this.roomImage,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.messages = const [],
  });

  static final List<ChatConversation> sampleConversations = [
    ChatConversation(
      id: 'c1',
      roomTitle: 'Studio Luxury Q.1',
      roomImage: 'assets/images/room_studio_luxury.png',
      otherUserName: 'Trần Minh Khoa',
      lastMessage: 'Phòng còn trống không anh?',
      lastTime: DateTime.now().subtract(const Duration(minutes: 10)),
      unreadCount: 2,
      messages: [
        ChatMessage(id: 'm1', text: 'Chào anh, phòng còn trống không ạ?', isMe: false, time: DateTime.now().subtract(const Duration(minutes: 12))),
        ChatMessage(id: 'm2', text: 'Dạ còn em nhé, em muốn xem phòng không?', isMe: true, time: DateTime.now().subtract(const Duration(minutes: 11))),
        ChatMessage(id: 'm3', text: 'Phòng còn trống không anh?', isMe: false, time: DateTime.now().subtract(const Duration(minutes: 10))),
      ],
    ),
    ChatConversation(
      id: 'c2',
      roomTitle: 'Căn hộ Mini Q.3',
      roomImage: 'assets/images/room_apartment_mini.png',
      otherUserName: 'Lê Thị Hoa',
      lastMessage: 'Cảm ơn anh, em sẽ liên hệ lại',
      lastTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      messages: [
        ChatMessage(id: 'm1', text: 'Anh ơi giá phòng có thể thương lượng không?', isMe: false, time: DateTime.now().subtract(const Duration(hours: 3))),
        ChatMessage(id: 'm2', text: 'Giá đã fix em ơi, nhưng anh tặng thêm 1 tháng miễn phí nếu ký 6 tháng', isMe: true, time: DateTime.now().subtract(const Duration(hours: 2, minutes: 30))),
        ChatMessage(id: 'm3', text: 'Cảm ơn anh, em sẽ liên hệ lại', isMe: false, time: DateTime.now().subtract(const Duration(hours: 2))),
      ],
    ),
    ChatConversation(
      id: 'c3',
      roomTitle: 'Phòng trọ Gác Lửng',
      roomImage: 'assets/images/phong_tro_gac_lung_go.png',
      otherUserName: 'Nguyễn Văn Bình',
      lastMessage: 'Ok anh, em đặt cọc ngay hôm nay',
      lastTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      messages: [
        ChatMessage(id: 'm1', text: 'Anh cho em xem phòng chiều nay được không?', isMe: false, time: DateTime.now().subtract(const Duration(days: 1, hours: 3))),
        ChatMessage(id: 'm2', text: 'Được em, 5h chiều anh ở nhà', isMe: true, time: DateTime.now().subtract(const Duration(days: 1, hours: 2))),
        ChatMessage(id: 'm3', text: 'Ok anh, em đặt cọc ngay hôm nay', isMe: false, time: DateTime.now().subtract(const Duration(days: 1))),
      ],
    ),
  ];
}
