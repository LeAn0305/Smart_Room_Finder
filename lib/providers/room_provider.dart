import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/data/dspt_data.dart';

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
        
        // Tự động dọn dẹp các phòng bị lặp sau khi load
        await cleanupDuplicateDsptRooms();
        // Tự động import nếu thiếu phòng
        await importDsptRooms();
        // Tự động đồng bộ ảnh mới từ DsptData
        await syncDsptRoomsWithData();
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

  Future<void> importDsptRooms() async {
    final uid = currentUserId;
    if (uid == null) {
      debugPrint('❌ Phải đăng nhập để import');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final dsptRooms = DsptData.getRooms(uid);
      
      for (var room in dsptRooms) {
        // Kiểm tra xem phòng đã tồn tại chưa (dựa trên tiêu đề)
        final exists = _rooms.any((r) => r.title == room.title && r.ownerId == uid);
        if (!exists) {
          await addRoom(room);
        }
      }

      debugPrint('✅ Đã đảm bảo danh sách 20 phòng từ DSPT (không trùng lặp)');
    } catch (e) {
      debugPrint('❌ Lỗi import: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa các phòng DSPT bị lặp (cùng tiêu đề và cùng chủ sở hữu)
  Future<void> cleanupDuplicateDsptRooms() async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final dsptRooms = DsptData.getRooms(uid);
      final dsptTitles = dsptRooms.map((r) => r.title).toSet();

      // Nhóm các phòng hiện có theo tiêu đề
      final Map<String, List<RoomModel>> groupedRooms = {};
      for (var room in _rooms) {
        if (dsptTitles.contains(room.title) && room.ownerId == uid) {
          groupedRooms.putIfAbsent(room.title, () => []).add(room);
        }
      }

      int deletedCount = 0;
      bool changed = false;

      for (var title in groupedRooms.keys) {
        final roomsWithSameTitle = groupedRooms[title]!;
        if (roomsWithSameTitle.length > 1) {
          // Giữ lại phòng đầu tiên (cũ nhất hoặc mới nhất tùy vào thứ tự load, thường là theo Firestore)
          // Xóa các bản sao còn lại
          for (int i = 1; i < roomsWithSameTitle.length; i++) {
            final roomToDelete = roomsWithSameTitle[i];
            await _roomsRef.doc(roomToDelete.id).delete();
            _rooms.removeWhere((r) => r.id == roomToDelete.id);
            deletedCount++;
            changed = true;
          }
        }
      }

      if (changed) {
        debugPrint('✅ Đã dọn dẹp $deletedCount phòng bị lặp');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi dọn dẹp phòng lặp: $e');
    }
  }

  /// Đồng bộ dữ liệu ảnh mới từ DsptData lên Firestore cho các phòng đã tồn tại
  Future<void> syncDsptRoomsWithData() async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final dsptRooms = DsptData.getRooms(uid);
      bool changed = false;

      for (var localRoom in dsptRooms) {
        // Tìm phòng tương ứng trên Firestore (dựa trên tiêu đề và ownerId)
        final existingRoomIdx = _rooms.indexWhere(
            (r) => r.title == localRoom.title && r.ownerId == uid);

        if (existingRoomIdx != -1) {
          final existingRoom = _rooms[existingRoomIdx];
          
          // Kiểm tra xem danh sách ảnh có thay đổi không
          bool imageListChanged = existingRoom.mainImageUrl != localRoom.mainImageUrl ||
              existingRoom.subImageUrls.length != localRoom.subImageUrls.length;
          
          if (!imageListChanged) {
             for(int i=0; i<localRoom.subImageUrls.length; i++) {
               if(existingRoom.subImageUrls[i] != localRoom.subImageUrls[i]) {
                 imageListChanged = true;
                 break;
               }
             }
          }

          if (imageListChanged) {
            debugPrint('🔄 Đồng bộ ảnh cho phòng: ${localRoom.title}');
            
            final updatedRoom = existingRoom.copyWith(
              mainImageUrl: localRoom.mainImageUrl,
              subImageUrls: localRoom.subImageUrls,
              imageUrl: localRoom.mainImageUrl, // Cập nhật cả trường cũ nếu có dùng
              images: [localRoom.mainImageUrl, ...localRoom.subImageUrls], // Cập nhật danh sách tổng hợp
            );

            await _roomsRef.doc(existingRoom.id).update({
              'mainImageUrl': updatedRoom.mainImageUrl,
              'subImageUrls': updatedRoom.subImageUrls,
              'imageUrl': updatedRoom.imageUrl,
              'images': updatedRoom.images,
            });

            _rooms[existingRoomIdx] = updatedRoom;
            changed = true;
          }
        }
      }

      if (changed) {
        notifyListeners();
        debugPrint('✅ Đã đồng bộ toàn bộ ảnh từ file DOCX lên Firestore');
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi đồng bộ ảnh: $e');
    }
  }
}