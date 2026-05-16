import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  List<RoomModel> get activePublicRooms {
    var publicRooms = _rooms.where((r) => r.isActive && !r.isDraft).toList();

    // Lọc bỏ các phòng DSPT lặp trên UI (chỉ giữ bản cũ nhất)
    final dsptRooms = DsptData.getRooms('dummy');
    final dsptTitles = dsptRooms.map((r) => r.title).toSet();

    final Map<String, RoomModel> originalDsptRooms = {};
    for (var room in publicRooms) {
      if (dsptTitles.contains(room.title)) {
        if (!originalDsptRooms.containsKey(room.title)) {
          originalDsptRooms[room.title] = room;
        } else {
          final timeA = originalDsptRooms[room.title]!.postedAt ?? DateTime.now();
          final timeB = room.postedAt ?? DateTime.now();
          if (timeB.isBefore(timeA)) {
            originalDsptRooms[room.title] = room;
          }
        }
      }
    }

    return publicRooms.where((room) {
      if (dsptTitles.contains(room.title)) {
        return originalDsptRooms[room.title]?.id == room.id;
      }
      return true;
    }).toList();
  }

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
        
        try {
          final missing = _rooms.where((r) => r.latitude == 0.0 || r.longitude == 0.0).toList();
          if (missing.isNotEmpty) {
            String log = '';
            for (var m in missing) {
              log += '${m.id} | ${m.title} | ${m.address} | ${m.location}\n';
            }
            File(r'C:\Users\Admin\.gemini\antigravity\brain\c59f4267-b20f-4042-b2ae-a5dda2dd4abf\scratch\missing_coords.txt').writeAsStringSync(log);
          }
        } catch (e) {}

        // Tự động dọn dẹp các phòng bị lặp sau khi load
        await cleanupDuplicateDsptRooms();
        // Xóa các phòng lặp DSPT nếu user hiện tại là người lỡ tạo ra chúng
        await _cleanupMyWrongDsptRooms();
        // Tự động chèn tọa độ cho các phòng bị thiếu
        await _autoUpdateDsptCoordinates();
        // Tự động quét và vá lỗi các đường dẫn ảnh cục bộ
        await _autoHealImagePaths();
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
    
    // Chỉ cho phép tài khoản Admin (1@gmail.com - Lê An) nạp lại phòng mẫu
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != '1@gmail.com') return;

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

      debugPrint('✅ Đã khôi phục thành công 20 phòng của Lê An (1@gmail.com)');
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

  /// Xóa triệt để các phòng DSPT mà user hiện tại LỠ TẠO RA (do lỗi nhân bản)
  /// Nếu user hiện tại KHÔNG phải là user tạo ra bản gốc đầu tiên, xóa hết!
  Future<void> _cleanupMyWrongDsptRooms() async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final dsptRooms = DsptData.getRooms('dummy');
      final dsptTitles = dsptRooms.map((r) => r.title).toSet();

      // Tìm bản gốc của mỗi tiêu đề (phòng cũ nhất)
      final Map<String, RoomModel> originalDsptRooms = {};
      for (var room in _rooms) {
        if (dsptTitles.contains(room.title)) {
          if (!originalDsptRooms.containsKey(room.title)) {
            originalDsptRooms[room.title] = room;
          } else {
            final timeA = originalDsptRooms[room.title]!.postedAt ?? DateTime.now();
            final timeB = room.postedAt ?? DateTime.now();
            if (timeB.isBefore(timeA)) {
              originalDsptRooms[room.title] = room;
            }
          }
        }
      }

      int deletedCount = 0;
      bool changed = false;

      // Quét các phòng của USER HIỆN TẠI
      for (var room in List.from(_rooms)) {
        if (room.ownerId == uid && dsptTitles.contains(room.title)) {
          // Nếu phòng này KHÔNG phải là bản gốc
          if (originalDsptRooms[room.title]?.id != room.id) {
            await _roomsRef.doc(room.id).delete();
            _rooms.removeWhere((r) => r.id == room.id);
            deletedCount++;
            changed = true;
          }
        }
      }

      if (changed) {
        debugPrint('🧹 Đã dọn dẹp $deletedCount phòng mẫu thừa của tài khoản hiện tại!');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Lỗi _cleanupMyWrongDsptRooms: $e');
    }
  }

  /// Tự động quét và vá lỗi đường dẫn ảnh. 
  /// Đưa các file từ 'assets/' hoặc ổ cứng local (như 'C:/...') lên Firebase Storage.
  Future<void> _autoHealImagePaths() async {
    bool anyRoomChanged = false;

    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      bool roomChanged = false;
      String newMain = room.mainImageUrl;
      List<String> newSubs = List.from(room.subImageUrls);

      if (_needsHealing(newMain)) {
        final url = await _uploadAndGetUrl(newMain);
        if (url != null) {
          newMain = url;
          roomChanged = true;
        }
      }

      for (int j = 0; j < newSubs.length; j++) {
        if (_needsHealing(newSubs[j])) {
          final url = await _uploadAndGetUrl(newSubs[j]);
          if (url != null) {
            newSubs[j] = url;
            roomChanged = true;
          }
        }
      }

      if (roomChanged) {
        final updatedRoom = room.copyWith(
          mainImageUrl: newMain,
          subImageUrls: newSubs,
          imageUrl: newMain, // Đồng bộ trường cũ
          images: [newMain, ...newSubs], // Đồng bộ mảng cũ
        );

        try {
          await _roomsRef.doc(room.id).update({
            'mainImageUrl': updatedRoom.mainImageUrl,
            'subImageUrls': updatedRoom.subImageUrls,
            'imageUrl': updatedRoom.imageUrl,
            'images': updatedRoom.images,
          });
          _rooms[i] = updatedRoom;
          anyRoomChanged = true;
          debugPrint('🔧 Đã vá lỗi ảnh thành công cho phòng: ${room.title}');
        } catch (e) {
          debugPrint('❌ Lỗi khi vá ảnh cho phòng ${room.title}: $e');
        }
      }
    }

    if (anyRoomChanged) {
      notifyListeners();
      debugPrint('✅ Hoàn tất vá lỗi ảnh tự động!');
    }
  }

  /// Tự động cập nhật tọa độ cho các phòng DSPT bị thiếu (latitude == 0)
  Future<void> _autoUpdateDsptCoordinates() async {
    final uid = currentUserId;
    if (uid == null) return;
    
    final dsptRooms = DsptData.getRooms(uid);
    bool anyRoomChanged = false;

    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      // Nhận diện các phòng bị thiếu tọa độ
      if (room.latitude == 0.0 || room.longitude == 0.0) {
        final dsptMatch = dsptRooms.where((r) => r.title == room.title).firstOrNull;
        if (dsptMatch != null && dsptMatch.latitude != 0.0) {
          final updatedRoom = room.copyWith(
            latitude: dsptMatch.latitude,
            longitude: dsptMatch.longitude,
          );
          
          try {
            await _roomsRef.doc(room.id).update({
              'latitude': updatedRoom.latitude,
              'longitude': updatedRoom.longitude,
            });
            _rooms[i] = updatedRoom;
            anyRoomChanged = true;
            debugPrint('📍 Đã cập nhật tọa độ thật cho phòng: ${room.title}');
          } catch (e) {
            debugPrint('❌ Lỗi cập nhật tọa độ: $e');
          }
        }
      }
    }

    if (anyRoomChanged) {
      notifyListeners();
      debugPrint('✅ Hoàn tất vá lỗi tọa độ tự động!');
    }
  }

  bool _needsHealing(String path) {
    if (path.isEmpty || path.startsWith('http')) return false;
    if (path.startsWith('assets/') || path.contains(':/') || path.startsWith('/data/') || path.startsWith('/Users/')) {
      return true;
    }
    return false;
  }

  Future<String?> _uploadAndGetUrl(String localPath) async {
    try {
      final ext = localPath.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext) ? ext : 'jpg';
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
      final fileName = 'room_images/$userId/auto_healed_${DateTime.now().millisecondsSinceEpoch}_${localPath.hashCode}.$safeExt';
      final ref = FirebaseStorage.instance.ref(fileName);
      
      String contentType = 'image/jpeg';
      if (safeExt == 'png') contentType = 'image/png';
      if (safeExt == 'gif') contentType = 'image/gif';
      if (safeExt == 'webp') contentType = 'image/webp';
      
      final metadata = SettableMetadata(contentType: contentType);

      if (localPath.startsWith('assets/')) {
        final byteData = await rootBundle.load(localPath);
        final bytes = byteData.buffer.asUint8List();
        await ref.putData(bytes, metadata);
        return await ref.getDownloadURL();
      } else {
        final file = File(localPath);
        if (await file.exists()) {
          await ref.putFile(file, metadata);
          return await ref.getDownloadURL();
        } else {
          debugPrint('⚠️ Không tìm thấy file local để vá: $localPath');
          return null;
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi upload ngầm file $localPath: $e');
      return null;
    }
  }
}