import 'package:flutter/material.dart';
import 'package:smart_room_finder/models/room_model.dart';

class PreferenceProvider extends ChangeNotifier {
  String? _location;
  final Set<String> _amenities = {};
  RoomType? _roomType;
  int? _maxPrice;
  bool _completed = false;

  String? get location => _location;
  Set<String> get amenities => Set.unmodifiable(_amenities);
  RoomType? get roomType => _roomType;
  int? get maxPrice => _maxPrice;
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

  /// Sắp xếp phòng theo độ phù hợp với sở thích
  List<RoomModel> applyPreference(List<RoomModel> rooms) {
    if (!_completed) return rooms;

    return List.from(rooms)
      ..sort((a, b) => _score(b).compareTo(_score(a)));
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

    if (_maxPrice != null && r.price <= _maxPrice!) {
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