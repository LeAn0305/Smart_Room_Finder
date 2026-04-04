import 'package:flutter/material.dart';
import 'package:smart_room_finder/models/room_model.dart';

class RoomProvider extends ChangeNotifier {
  final List<RoomModel> _rooms = List.from(RoomModel.sampleRooms);

  List<RoomModel> get allRooms => List.unmodifiable(_rooms);

  /// Phòng hiển thị trên Home: isActive=true, isDraft=false
  List<RoomModel> get activePublicRooms =>
      _rooms.where((r) => r.isActive && !r.isDraft).toList();

  /// Phòng của user (My Room)
  List<RoomModel> get myActiveRooms =>
      _rooms.where((r) => r.isActive && !r.isDraft).toList();

  List<RoomModel> get myHiddenRooms =>
      _rooms.where((r) => !r.isActive && !r.isDraft).toList();

  List<RoomModel> get myDraftRooms =>
      _rooms.where((r) => r.isDraft).toList();

  /// Đăng phòng mới hoặc lưu nháp
  void addRoom(RoomModel room) {
    _rooms.add(room);
    notifyListeners();
  }

  /// Cập nhật phòng (chỉnh sửa)
  void updateRoom(RoomModel updated) {
    final idx = _rooms.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _rooms[idx] = updated;
      notifyListeners();
    }
  }

  /// Ẩn / Hiện phòng
  void toggleActive(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      _rooms[idx] = _rooms[idx].copyWith(isActive: !_rooms[idx].isActive);
      notifyListeners();
    }
  }

  /// Xóa phòng
  void deleteRoom(String roomId) {
    _rooms.removeWhere((r) => r.id == roomId);
    notifyListeners();
  }

  /// Nhân bản phòng
  void duplicateRoom(RoomModel room) {
    final copy = room.copyWith(
      postedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    // tạo id mới
    final newRoom = RoomModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${room.title} (bản sao)',
      description: room.description,
      price: room.price,
      address: room.address,
      imageUrl: room.imageUrl,
      images: room.images,
      rating: room.rating,
      type: room.type,
      location: room.location,
      amenities: room.amenities,
      isVerified: false,
      isActive: false,
      isDraft: true,
      area: room.area,
      bedrooms: room.bedrooms,
      direction: room.direction,
      postedAt: DateTime.now(),
    );
    _rooms.add(newRoom);
    notifyListeners();
  }

  /// Gia hạn phòng thêm 30 ngày
  void renewRoom(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      final r = _rooms[idx];
      final base = (r.expiresAt != null && r.expiresAt!.isAfter(DateTime.now()))
          ? r.expiresAt!
          : DateTime.now();
      _rooms[idx] = r.copyWith(expiresAt: base.add(const Duration(days: 30)));
      notifyListeners();
    }
  }

  /// Toggle favorite
  void toggleFavorite(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      _rooms[idx] = _rooms[idx].copyWith(isFavorite: !_rooms[idx].isFavorite);
      notifyListeners();
    }
  }
}
