import 'package:flutter/material.dart';

class FavoriteProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = {'1'}; // Default favorite id based on sample room

  Set<String> get favoriteIds => _favoriteIds;

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  void addFavorite(String id) {
    if (!_favoriteIds.contains(id)) {
      _favoriteIds.add(id);
      notifyListeners();
    }
  }

  void removeFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
      notifyListeners();
    }
  }
}
