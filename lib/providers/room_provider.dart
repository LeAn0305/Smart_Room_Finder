import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Import Firestore để đọc collection rooms
import 'package:smart_room_finder/models/room_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomProvider extends ChangeNotifier {
  // 🔥 Tham chiếu tới collection rooms trong Firestore
  final CollectionReference _roomsRef =
      FirebaseFirestore.instance.collection('rooms');

  // 🔥 Danh sách phòng đang dùng trong app
  // Ban đầu vẫn để mock để app không bị trống nếu Firestore chưa load xong
  List<RoomModel> _rooms = List.from(RoomModel.sampleRooms);

  // 🔥 Trạng thái loading để sau này nếu muốn có thể show loading UI
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<RoomModel> get allRooms => List.unmodifiable(_rooms);

  // ⚠️ Tạm thời vẫn dùng mock user hiện tại
  // Sau này khi nối Firebase Auth thật thì đổi sang uid thật
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Phòng hiển thị trên Home: isActive=true, isDraft=false
  List<RoomModel> get myActiveRooms {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    return _rooms.where((r) => r.ownerId == uid && r.isActive && !r.isDraft).toList();
  }

  List<RoomModel> get myHiddenRooms {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    return _rooms.where((r) => r.ownerId == uid && !r.isActive && !r.isDraft).toList();
  }

  List<RoomModel> get myDraftRooms {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    return _rooms.where((r) => r.ownerId == uid && r.isDraft).toList();
  }

  List<RoomModel> get activePublicRooms =>
    _rooms.where((r) => r.isActive && !r.isDraft).toList();

  // ==================== FIREBASE READ ====================

  /// 🔥 Hàm đọc toàn bộ rooms từ Firestore
  /// - Lấy tất cả document trong collection rooms
  /// - Chuyển từng document thành RoomModel
  /// - Gán lại vào _rooms
  /// - notifyListeners() để UI tự cập nhật
  Future<void> fetchRooms() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _roomsRef.get();

      // Nếu Firestore có data → dùng data thật, bỏ mock
      if (snapshot.docs.isNotEmpty) {
        _rooms = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return RoomModel.fromFirebase(data, doc.id);
        }).toList();
        debugPrint('✅ Đã load ${_rooms.length} phòng từ Firestore');
      } else {
        // Firestore rỗng → giữ mock để app không trắng
        debugPrint('⚠️ Firestore chưa có phòng, dùng mock data tạm');
        _rooms = List.from(RoomModel.sampleRooms);
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi đọc rooms từ Firestore: $e');
      _rooms = List.from(RoomModel.sampleRooms);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== FIREBASE WRITE ====================

  /// 🔥 Đăng phòng mới lên Firestore + local
  Future<void> addRoomToFirebase(RoomModel room) async {
    try {
      final docRef = await _roomsRef.add(room.toFirebase());
      final newRoom = RoomModel(
        id: docRef.id,
        ownerId: room.ownerId,
        title: room.title,
        description: room.description,
        price: room.price,
        address: room.address,
        imageUrl: room.imageUrl,
        images: room.images,
        rating: room.rating,
        type: room.type,
        location: room.location,
        amenities: room.amenities,
        isVerified: room.isVerified,
        isActive: room.isActive,
        isDraft: room.isDraft,
        viewCount: room.viewCount,
        contactCount: room.contactCount,
        area: room.area,
        bedrooms: room.bedrooms,
        direction: room.direction,
        postedAt: room.postedAt,
        updatedAt: room.updatedAt,
        expiresAt: room.expiresAt,
      );
      _rooms.add(newRoom);
      notifyListeners();
      debugPrint('✅ Đã đăng phòng lên Firestore: ${docRef.id}');
    } catch (e) {
      debugPrint('❌ Lỗi đăng phòng: $e');
      // Fallback: thêm local
      _rooms.add(room);
      notifyListeners();
    }
  }

  /// 🔥 Cập nhật phòng lên Firestore + local
  Future<void> updateRoomToFirebase(RoomModel updated) async {
    try {
      await _roomsRef.doc(updated.id).update(updated.toFirebaseForUpdate());
      final idx = _rooms.indexWhere((r) => r.id == updated.id);
      if (idx != -1) {
        _rooms[idx] = updated;
        notifyListeners();
      }
      debugPrint('✅ Đã cập nhật phòng: ${updated.id}');
    } catch (e) {
      debugPrint('❌ Lỗi cập nhật phòng: $e');
      updateRoom(updated);
    }
  }

  // ==================== LOCAL METHODS ====================

  /// Đăng phòng mới hoặc lưu nháp
  /// Hiện tại vẫn thêm local trước
  /// Sau này có thể đổi thành add lên Firestore
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

  /// Ẩn / Hiện phòng — đồng bộ Firestore
  void toggleActive(String roomId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      final newActive = !_rooms[idx].isActive;
      _rooms[idx] = _rooms[idx].copyWith(isActive: newActive, updatedAt: DateTime.now());
      notifyListeners();
      try {
        await _roomsRef.doc(roomId).update({'isActive': newActive, 'updatedAt': DateTime.now().toIso8601String()});
      } catch (e) {
        debugPrint('❌ Lỗi toggleActive: $e');
      }
    }
  }

  /// Xóa phòng — đồng bộ Firestore
  void deleteRoom(String roomId) async {
    _rooms.removeWhere((r) => r.id == roomId);
    notifyListeners();
    try {
      await _roomsRef.doc(roomId).delete();
    } catch (e) {
      debugPrint('❌ Lỗi deleteRoom: $e');
    }
  }

  /// Nhân bản phòng
  void duplicateRoom(RoomModel room) {
    final newRoom = RoomModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ownerId: room.ownerId,
      title: '${room.title} (bản sao)',
      description: room.description,
      price: room.price,
      address: room.address,
      imageUrl: room.imageUrl,
      images: List<String>.from(room.images),
      rating: room.rating,
      type: room.type,
      location: room.location,
      amenities: List<String>.from(room.amenities),
      isFavorite: false,
      isVerified: false,
      isActive: false,
      isDraft: true,
      viewCount: 0,
      contactCount: 0,
      area: room.area,
      bedrooms: room.bedrooms,
      direction: room.direction,
      postedAt: DateTime.now(),
      updatedAt: null,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
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

      _rooms[idx] = r.copyWith(
        expiresAt: base.add(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Toggle favorite (chỉ dùng local/mock UI)
  void toggleFavorite(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      _rooms[idx] = _rooms[idx].copyWith(
        isFavorite: !_rooms[idx].isFavorite,
      );
      notifyListeners();
    }
  }
}