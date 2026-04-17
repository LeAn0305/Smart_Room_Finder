import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/models/room_model.dart';

class RoomProvider extends ChangeNotifier {
  final CollectionReference _roomsRef =
      FirebaseFirestore.instance.collection('rooms');

  List<RoomModel> _rooms = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  List<RoomModel> get allRooms => List.unmodifiable(_rooms);

  List<RoomModel> get activePublicRooms =>
      _rooms.where((r) => r.isActive && !r.isDraft).toList();

  List<RoomModel> get myActiveRooms {
    final uid = currentUserId;
    if (uid == null) return [];
    return _rooms
        .where((r) => r.ownerId == uid && r.isActive && !r.isDraft)
        .toList();
  }

  List<RoomModel> get myHiddenRooms {
    final uid = currentUserId;
    if (uid == null) return [];
    return _rooms
        .where((r) => r.ownerId == uid && !r.isActive && !r.isDraft)
        .toList();
  }

  List<RoomModel> get myDraftRooms {
    final uid = currentUserId;
    if (uid == null) return [];
    return _rooms.where((r) => r.ownerId == uid && r.isDraft).toList();
  }

  Future<void> fetchRooms() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _roomsRef.get();

      if (snapshot.docs.isNotEmpty) {
        _rooms = snapshot.docs.map((doc) {
          return RoomModel.fromFirebase(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        debugPrint('✅ Load ${_rooms.length} phòng từ Firestore');
      } else {
        debugPrint('⚠️ Firestore rỗng, dùng mock tạm');
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

  Future<void> addRoom(RoomModel room) async {
    try {
      final docRef = await _roomsRef.add(room.toFirebase());
      final newRoom = room.copyWith(id: docRef.id);

      _rooms.add(newRoom);
      notifyListeners();

      debugPrint('✅ Đăng phòng: ${docRef.id}');
    } catch (e) {
      debugPrint('❌ Lỗi addRoom: $e');
      _rooms.add(room);
      notifyListeners();
    }
  }

  Future<void> updateRoom(RoomModel updated) async {
    try {
      await _roomsRef.doc(updated.id).update(updated.toFirebaseForUpdate());

      final idx = _rooms.indexWhere((r) => r.id == updated.id);
      if (idx != -1) {
        _rooms[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Lỗi updateRoom: $e');

      final idx = _rooms.indexWhere((r) => r.id == updated.id);
      if (idx != -1) {
        _rooms[idx] = updated;
        notifyListeners();
      }
    }
  }

  Future<void> toggleActive(String roomId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;

    final newActive = !_rooms[idx].isActive;
    _rooms[idx] = _rooms[idx].copyWith(isActive: newActive);
    notifyListeners();

    try {
      await _roomsRef.doc(roomId).update({'isActive': newActive});
    } catch (e) {
      debugPrint('❌ Lỗi toggleActive: $e');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    _rooms.removeWhere((r) => r.id == roomId);
    notifyListeners();

    try {
      await _roomsRef.doc(roomId).delete();
    } catch (e) {
      debugPrint('❌ Lỗi deleteRoom: $e');
    }
  }

  void duplicateRoom(RoomModel room) {
    final newRoom = RoomModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ownerId: room.ownerId,
      title: '${room.title} (bản sao)',
      description: room.description,
      price: room.price,
      address: room.address,
      location: room.location,
      imageUrl: room.imageUrl,
      images: room.images,
      mainImageUrl: room.mainImageUrl,
      subImageUrls: room.subImageUrls,
      rating: room.rating,
      type: room.type,
      amenities: room.amenities,
      isVerified: false,
      isActive: false,
      isDraft: true,
      area: room.area,
      bedrooms: room.bedrooms,
      direction: room.direction,
      postedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expiresAt: room.expiresAt,
      postedBy: room.postedBy,
      viewCount: 0,
      contactCount: 0,
      isFavorite: false,
    );

    _rooms.add(newRoom);
    notifyListeners();
  }

  void renewRoom(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;

    final r = _rooms[idx];
    final base =
        (r.expiresAt != null && r.expiresAt!.isAfter(DateTime.now()))
            ? r.expiresAt!
            : DateTime.now();

    _rooms[idx] = r.copyWith(
      expiresAt: base.add(const Duration(days: 30)),
    );
    notifyListeners();
  }

  void toggleFavorite(String roomId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;

    _rooms[idx] = _rooms[idx].copyWith(
      isFavorite: !_rooms[idx].isFavorite,
    );
    notifyListeners();
  }
}