import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteProvider extends ChangeNotifier {
  final CollectionReference _favoritesRef =
      FirebaseFirestore.instance.collection('favorites');

  Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => _favoriteIds;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool isFavorite(String id) => _favoriteIds.contains(id);

  // ==================== READ ====================

  Future<void> fetchFavorites() async {
    try {
      if (_currentUserId.isEmpty) {
        _favoriteIds.clear();
        debugPrint('⚠️ Chưa có user đăng nhập nên favorite rỗng');
        notifyListeners();
        return;
      }

      final snapshot = await _favoritesRef
          .where('userId', isEqualTo: _currentUserId)
          .get();

      _favoriteIds = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final roomId = data['roomId'];

            if (roomId == null) {
              debugPrint('⚠️ Favorite ${doc.id} không có roomId');
              return null;
            }

            return roomId.toString();
          })
          .whereType<String>()
          .toSet();

      debugPrint('✅ Đã load ${_favoriteIds.length} favorite từ Firestore');
      debugPrint('👤 UID hiện tại favorite: $_currentUserId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Lỗi khi đọc favorites từ Firestore: $e');
    }
  }

  // ==================== WRITE ====================

  Future<void> toggleFavorite(String roomId) async {
    if (_favoriteIds.contains(roomId)) {
      await removeFavorite(roomId);
    } else {
      await addFavorite(roomId);
    }
  }

  Future<void> addFavorite(String roomId) async {
    try {
      if (_currentUserId.isEmpty) {
        debugPrint('⚠️ Không thể thêm favorite vì chưa đăng nhập');
        return;
      }

      final existing = await _favoritesRef
          .where('userId', isEqualTo: _currentUserId)
          .where('roomId', isEqualTo: roomId)
          .get();

      if (existing.docs.isEmpty) {
        await _favoritesRef.add({
          'userId': _currentUserId,
          'roomId': roomId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      _favoriteIds.add(roomId);
      notifyListeners();

      debugPrint('✅ Đã thêm favorite: $roomId cho user $_currentUserId');
    } catch (e) {
      debugPrint('❌ Lỗi khi thêm favorite: $e');
    }
  }

  Future<void> removeFavorite(String roomId) async {
    try {
      if (_currentUserId.isEmpty) {
        debugPrint('⚠️ Không thể xóa favorite vì chưa đăng nhập');
        return;
      }

      final snapshot = await _favoritesRef
          .where('userId', isEqualTo: _currentUserId)
          .where('roomId', isEqualTo: roomId)
          .get();

      for (final doc in snapshot.docs) {
        await _favoritesRef.doc(doc.id).delete();
      }

      _favoriteIds.remove(roomId);
      notifyListeners();

      debugPrint('✅ Đã xóa favorite: $roomId của user $_currentUserId');
    } catch (e) {
      debugPrint('❌ Lỗi khi xóa favorite: $e');
    }
  }

  void clearFavorites() {
    _favoriteIds.clear();
    notifyListeners();
  }
}