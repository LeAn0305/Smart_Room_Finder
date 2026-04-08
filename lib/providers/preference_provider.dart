import 'package:flutter/material.dart';
import 'package:smart_room_finder/models/room_model.dart';

class PreferenceProvider extends ChangeNotifier {
  String? _location;
  final Set<String> _amenities = {};
  RoomType? _roomType;
  int? _maxPrice;
  int _minPrice = 0;
  bool _completed = false;

  String? get location => _location;
  Set<String> get amenities => Set.unmodifiable(_amenities);
  RoomType? get roomType => _roomType;
  int? get maxPrice => _maxPrice;
  int get minPrice => _minPrice;
  bool get completed => _completed;

  void setLocation(String loc) {
    _location = loc;
    notifyListeners();
  }

  void setRoomType(RoomType? t) {
    _roomType = t;
    notifyListeners();
  }

  void setMaxPrice(int price) {
    _maxPrice = price;
    notifyListeners();
  }

  void setMinPrice(int price) {
    _minPrice = price;
    notifyListeners();
  }

  void toggleAmenity(String a) {
    if (_amenities.contains(a)) {
      _amenities.remove(a);
    } else {
      _amenities.add(a);
    }
    notifyListeners();
  }

  void complete() {
    _completed = true;
    notifyListeners();
  }

  /// Ưu tiên phòng đúng khu vực lên đầu, các khu vực khác xuống sau
  List<RoomModel> applyPreference(List<RoomModel> rooms) {
    if (!_completed) return rooms;

    // Nếu user đã chọn khu vực → chỉ hiện phòng đúng khu vực đó
    if (_location != null) {
      final matched = rooms.where((r) => _isMatchLocation(r)).toList();
      // Nếu có phòng đúng khu vực thì chỉ hiện phòng đó
      if (matched.isNotEmpty) {
        matched.sort((a, b) => _score(b).compareTo(_score(a)));
        return matched;
      }
      // Nếu không có phòng nào đúng khu vực thì hiện tất cả (fallback)
    }

    return List.from(rooms)..sort((a, b) => _score(b).compareTo(_score(a)));
  }

  bool _isMatchLocation(RoomModel r) {
    if (_location == null) return false;
    final loc = _location!.toLowerCase();
    return r.location.toLowerCase().contains(loc) ||
        r.address.toLowerCase().contains(loc);
  }

  int _score(RoomModel r) {
    int s = 0;

    if (_location != null &&
        r.location.toLowerCase().contains(_location!.toLowerCase())) {
      s += 3;
    }

    if (_roomType != null && r.type == _roomType) {
      s += 3;
    }

    if (_maxPrice != null && r.price <= _maxPrice! && r.price >= _minPrice) {
      s += 2;
    }

    for (final a in _amenities) {
      if (r.amenities.any(
        (ra) => ra.toLowerCase().contains(a.toLowerCase()),
      )) {
        s += 1;
      }
    }

    return s;
  }
}