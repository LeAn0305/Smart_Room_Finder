import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  RoomModel? _selectedRoom;
  String _selectedFilter = 'Tất cả';
  LatLng? _currentLocation;
  bool _loadingLocation = false;
  String _searchQuery = '';
  bool _sortByDistance = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const LatLng _center = LatLng(10.7769, 106.7009);

  final List<String> _filters = ['Tất cả', 'Chung cư', 'Phòng trọ', 'Nhà riêng', 'Biệt thự'];

  final Map<String, LatLng> _roomLocations = {
    '1': LatLng(10.7769, 106.7009),
    '2': LatLng(10.7300, 106.7200),
    '3': LatLng(10.8100, 106.7100),
    '4': LatLng(10.8300, 106.6900),
    '5': LatLng(10.8500, 106.7700),
    '6': LatLng(10.7800, 106.7500),
    '7': LatLng(10.7950, 106.6650),
    '8': LatLng(10.7700, 106.6900),
  };

  Future<void> _goToMyLocation() async {
    setState(() => _loadingLocation = true);
    try {
      // Web dùng browser geolocation API qua geolocator
      if (kIsWeb) {
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _showLocationError('Vui lòng cho phép truy cập vị trí trên trình duyệt');
          return;
        }
        final pos = await Geolocator.getCurrentPosition();
        _updateLocation(pos);
        return;
      }

      // macOS / Android / iOS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Vui lòng bật dịch vụ vị trí trên thiết bị');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Quyền vị trí bị từ chối');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Vui lòng cấp quyền vị trí trong Cài đặt'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Mở cài đặt',
              textColor: Colors.white,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ));
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _updateLocation(pos);
    } catch (e) {
      _showLocationError('Lỗi: ${e.toString()}');
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  void _updateLocation(Position pos) {
    final loc = LatLng(pos.latitude, pos.longitude);
    setState(() => _currentLocation = loc);
    _mapController.move(loc, 14);
  }

  void _showLocationError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  List<RoomModel> get _filteredRooms {
    final rooms = RoomModel.sampleRooms;
    final typeMap = {
      'Chung cư': RoomType.apartment,
      'Phòng trọ': RoomType.studio,
      'Nhà riêng': RoomType.house,
      'Biệt thự': RoomType.villa,
    };

    List<RoomModel> result = _selectedFilter == 'Tất cả'
        ? rooms
        : rooms.where((r) => r.type == typeMap[_selectedFilter]).toList();

    if (_searchQuery.isNotEmpty) {
      result = result.where((r) =>
          r.title.toLowerCase().contains(_searchQuery) ||
          r.address.toLowerCase().contains(_searchQuery)).toList();
    }

    if (_sortByDistance && _currentLocation != null) {
      result.sort((a, b) {
        final locA = _roomLocations[a.id] ?? _center;
        final locB = _roomLocations[b.id] ?? _center;
        final distA = const Distance().as(LengthUnit.Meter, _currentLocation!, locA);
        final distB = const Distance().as(LengthUnit.Meter, _currentLocation!, locB);
        return distA.compareTo(distB);
      });
    }

    return result;
  }

  double _distanceToRoom(RoomModel room) {
    if (_currentLocation == null) return 0;
    final loc = _roomLocations[room.id] ?? _center;
    return const Distance().as(LengthUnit.Kilometer, _currentLocation!, loc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12,
              onTap: (_, _) => setState(() => _selectedRoom = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_room_finder',
              ),
              MarkerLayer(
                markers: [
                  ..._filteredRooms.map((room) {
                    final loc = _roomLocations[room.id] ?? _center;
                    return Marker(
                      point: loc,
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedRoom = room);
                          _mapController.move(loc, 14);
                        },
                        child: _buildMarker(room),
                      ),
                    );
                  }),
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
                        ),
                        child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Header
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildFilterBar(),
            ]),
          ),
          // Room count
          Positioned(
            bottom: _selectedRoom != null ? 190 : 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Text('${_filteredRooms.length} phòng',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          // My location button
          Positioned(
            bottom: _selectedRoom != null ? 190 : 24,
            right: 16,
            child: GestureDetector(
              onTap: _goToMyLocation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: _loadingLocation
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.teal))
                    : const Icon(Icons.my_location_rounded, color: AppColors.teal, size: 22),
              ),
            ),
          ),
          // Selected room card
          if (_selectedRoom != null)
            Positioned(
              bottom: 24, left: 16, right: 16,
              child: _buildRoomCard(_selectedRoom!),
            ),
        ],
      ),
    );
  }

  Widget _buildMarker(RoomModel room) {
    final isSelected = _selectedRoom?.id == room.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.teal : Colors.white,
        borderRadius: BorderRadius.circular(isSelected ? 12 : 24),
        border: Border.all(color: AppColors.teal, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: isSelected
          ? Text('${(room.price / 1000000).toStringAsFixed(0)}tr',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11))
          : Icon(Icons.home_rounded, color: room.isFavorite ? Colors.redAccent : AppColors.teal, size: 20),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: AppColors.teal, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm tên phòng, khu vực...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                if (_currentLocation == null) {
                  await _goToMyLocation();
                }
                setState(() => _sortByDistance = !_sortByDistance);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _sortByDistance ? AppColors.teal : AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.near_me_rounded,
                      color: _sortByDistance ? Colors.white : AppColors.teal, size: 14),
                  const SizedBox(width: 4),
                  Text('Gần nhất',
                      style: TextStyle(
                          color: _sortByDistance ? Colors.white : AppColors.teal,
                          fontWeight: FontWeight.w600, fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final sel = _selectedFilter == _filters[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = _filters[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Text(_filters[i],
                  style: TextStyle(
                      color: sel ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(room.imageUrl, width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(width: 80, height: 80, color: AppColors.mintSoft,
                  child: const Icon(Icons.image_rounded, color: AppColors.teal))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(room.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_rounded, color: AppColors.textSecondary, size: 13),
              const SizedBox(width: 2),
              Expanded(child: Text(room.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.teal, AppColors.tealDark]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${(room.price / 1000000).toStringAsFixed(1)}tr/tháng',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 14),
              Text(room.rating.toString(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (_currentLocation != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.near_me_rounded, color: AppColors.teal, size: 13),
                Text('${_distanceToRoom(room).toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
              ],
            ]),
          ]),
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedRoom = null),
          child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
        ),
      ]),
    );
  }
}
