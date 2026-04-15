import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:provider/provider.dart';
import 'package:smart_room_finder/providers/room_provider.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  RoomModel? _selectedRoom;
  String _selectedFilter = 'Tất cả';
  LatLng? _currentLocation;
  bool _loadingLocation = false;
  String _searchQuery = '';
  bool _sortByDistance = false;
  final _searchCtrl = TextEditingController();

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().fetchRooms();
    });
  }

  static const LatLng _center = LatLng(10.7769, 106.7009);

  final List<String> _filters = [
    'Tất cả',
    'Chung cư',
    'Phòng trọ',
    'Nhà riêng',
    'Biệt thự',
  ];

  // Giả lập tọa độ các phòng dựa trên danh sách (Demo)
  final Map<String, LatLng> _roomLocations = {
  'room_1': const LatLng(10.7769, 106.7009),
  'room_2': const LatLng(10.7300, 106.7200),
  'room_3': const LatLng(10.8100, 106.7100),
};

  LatLng _fallbackRoomLocation(RoomModel room) {
    final seed =
        int.tryParse(room.id.replaceAll(RegExp(r'[^0-9]'), '')) ??
        room.id.hashCode.abs();

    final angle = (seed % 360) * math.pi / 180;
    final ring = (seed % 3) + 1;
    final radius = 0.015 * ring;

    return LatLng(
      _center.latitude + radius * math.sin(angle),
      _center.longitude + radius * math.cos(angle),
    );
  }

  LatLng _getRoomLocation(RoomModel room) {
    return _roomLocations[room.id] ?? _fallbackRoomLocation(room);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();;
    _positionStream?.cancel();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Không animate nếu vị trí hiện tại đang y hệt
    if (_mapController.camera.center.latitude == destLocation.latitude &&
        _mapController.camera.center.longitude == destLocation.longitude &&
        _mapController.camera.zoom == destZoom) return;

    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _loadingLocation = true);
    try {
      if (kIsWeb) {
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _showLocationError('Vui lòng cho phép truy cập vị trí trên trình duyệt');
          setState(() => _loadingLocation = false);
          return;
        }
        final pos = await Geolocator.getCurrentPosition();
        _updateLocation(pos, animateSelected: true);
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Vui lòng bật dịch vụ vị trí (GPS) trên thiết bị');
        setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Quyền truy cập vị trí bị từ chối');
          setState(() => _loadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng cấp quyền vị trí trong Cài đặt'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Mở cài đặt',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      // Lấy vị trí ngay lập tức (dùng cache nếu có để nhanh hơn)
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _updateLocation(pos, animateSelected: true);

      // Bật theo dõi vị trí ổn định thay vì một lần duy nhất
      _positionStream?.cancel();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Chỉ cập nhật khi di chuyển >10m
        ),
      ).listen((Position position) {
        if (mounted) _updateLocation(position, animateSelected: false);
      });

    } catch (e) {
      _showLocationError('Không thể lấy vị trí. Chờ chút và thử lại!');
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }


  void _updateLocation(Position pos, {bool animateSelected = false}) {
    if (!mounted) return;
    final loc = LatLng(pos.latitude, pos.longitude);
    setState(() => _currentLocation = loc);
    if (animateSelected) {
      _animatedMapMove(loc, 14.5);
    }
  }

  Future<void> _findNearestRoom() async {
    // 1. Nếu chưa có vị trí, sẽ bắt buộc tải vị trí (nhờ await)
    if (_currentLocation == null) {
      await _goToMyLocation();
    }
    // 2. Chắc chắn đã có vị trí
    if (_currentLocation == null) return;

    RoomModel? nearestRoom;
    double minDistance = double.infinity;

    final roomProvider = context.read<RoomProvider>();
    List<RoomModel> availableRooms = _filteredRoomsFrom(roomProvider.activePublicRooms); // Chỉ tìm trong kết quả lọc hiện tại

    if (availableRooms.isEmpty) {
      availableRooms = roomProvider.activePublicRooms; // Dự phòng quét hết mọi nơi nếu lỡ lọc kỹ quá
    }

    // 3. Tính toán phòng gần nhất thực tế
    for (var room in availableRooms) {
      final loc = _getRoomLocation(room);
      final dist = const Distance().as(LengthUnit.Meter, _currentLocation!, loc);
      if (dist < minDistance) {
        minDistance = dist;
        nearestRoom = room;
      }
    }

    if (nearestRoom != null) {
      setState(() {
        _selectedRoom = nearestRoom;
        _sortByDistance = true;
      });
      // 4. Fly Camera to that room Marker smoothly
      final loc = _getRoomLocation(nearestRoom);
      _animatedMapMove(loc, 15);
    } else {
      _showLocationError('Không tìm thấy phòng nào phù hợp khu vực này');
    }
  }

  void _showLocationError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  List<RoomModel> _filteredRoomsFrom(List<RoomModel> rooms) {
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
      result = result.where((r) {
        return r.title.toLowerCase().contains(_searchQuery) ||
            r.address.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (_sortByDistance && _currentLocation != null) {
      result.sort((a, b) {
        final locA = _getRoomLocation(a);
        final locB = _getRoomLocation(b);
        final distA = const Distance().as(
          LengthUnit.Meter,
          _currentLocation!,
          locA,
        );
        final distB = const Distance().as(
          LengthUnit.Meter,
          _currentLocation!,
          locB,
        );
        return distA.compareTo(distB);
      });
    }

    return result;
  }

  double _distanceToRoom(RoomModel room) {
    if (_currentLocation == null) return 0;
    final loc = _getRoomLocation(room);
    return const Distance().as(
      LengthUnit.Kilometer,
      _currentLocation!,
      loc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();
    final filteredRooms = _filteredRoomsFrom(roomProvider.activePublicRooms);

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
                  ...filteredRooms.map((room) {
                    final loc = _getRoomLocation(room);
                    return Marker(
                      point: loc,
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedRoom = room);
                          _animatedMapMove(loc, 14.5);
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildFilterBar(),
              ],
            ),
          ),
          // Room count Indicator - Hide when room card active
          Positioned(
            bottom: _selectedRoom != null ? 190 : 24,
            left: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${filteredRooms.length} phòng',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: _selectedRoom != null ? 190 : 24,
            right: 16,
            child: GestureDetector(
              onTap: _goToMyLocation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: _loadingLocation
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.teal,
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.teal,
                        size: 22,
                      ),
              ),
            ),
          ),

          if (_selectedRoom != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildRoomCard(_selectedRoom!),
            ),
        ],
      ),
    );
  }

  Widget _buildMarker(RoomModel room) {
    final isSelected = _selectedRoom?.id == room.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.teal : Colors.white,
        borderRadius: BorderRadius.circular(isSelected ? 10 : 24),
        border: Border.all(color: AppColors.teal, width: 2),
        boxShadow: [
          if (isSelected) BoxShadow(color: AppColors.teal.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)
          else BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: isSelected
          ? Center(
            child: Text('${(room.price / 1000000).toStringAsFixed(0)}tr',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
          )
          : Icon(Icons.home_rounded, color: room.isFavorite ? Colors.redAccent : AppColors.teal, size: 20),
    );
  }

  Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm phòng, khu vực...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              const SizedBox(width: 8),

              // Nút tìm phòng gần nhất
              GestureDetector(
                onTap: _findNearestRoom,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.tealDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Gần nhất',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppColors.teal : AppColors.mintSoft),
                boxShadow: sel ? [BoxShadow(color: AppColors.teal.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))] : [],
              ),
              child: Text(_filters[i],
                  style: TextStyle(
                      color: sel ? Colors.white : AppColors.textPrimary,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
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
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            room.imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: AppColors.mintSoft,
              child: const Icon(
                Icons.image_rounded,
                color: AppColors.teal,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.textSecondary,
                    size: 13,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      room.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.teal, AppColors.tealDark],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(room.price / 1000000).toStringAsFixed(1)}tr/tháng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star_rounded,
                    color: Colors.orangeAccent,
                    size: 14,
                  ),
                  Text(
                    room.rating.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_currentLocation != null) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.near_me_rounded,
                      color: AppColors.teal,
                      size: 13,
                    ),
                    Text(
                      '${_distanceToRoom(room).toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedRoom = null),
          child: const Icon(
            Icons.close_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ],
    ),
  );
  }
}