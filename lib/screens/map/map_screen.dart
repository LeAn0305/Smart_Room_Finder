import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
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

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  StreamSubscription<Position>? _positionStream;

  static const LatLng _center = LatLng(10.7769, 106.7009);

  final List<String> _filters = ['Tất cả', 'Chung cư', 'Phòng trọ', 'Nhà riêng', 'Biệt thự'];

  // Giả lập tọa độ các phòng dựa trên danh sách (Demo)
  final Map<String, LatLng> _roomLocations = {
    '1': const LatLng(10.7769, 106.7009), // Quận 1
    '2': const LatLng(10.7300, 106.7200), // Quận 7
    '3': const LatLng(10.8100, 106.7100), // Bình Thạnh
    '4': const LatLng(10.8300, 106.6900), // Gò Vấp
    '5': const LatLng(10.8500, 106.7700), // Thủ Đức
    '6': const LatLng(10.7800, 106.7500), // Quận 4
    '7': const LatLng(10.7950, 106.6650), // Tân Bình
    '8': const LatLng(10.7700, 106.6900), // Quận 3
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: false);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pulseController.dispose();
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
        _showPermSettingsDialog();
        setState(() => _loadingLocation = false);
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
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _showPermSettingsDialog() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Vui lòng cấp quyền vị trí trong Cài đặt'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Mở',
          textColor: Colors.white,
          onPressed: () => Geolocator.openAppSettings(),
        ),
      ));
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
    List<RoomModel> availableRooms = _filteredRooms; // Chỉ tìm trong kết quả lọc hiện tại

    if (availableRooms.isEmpty) {
      availableRooms = RoomModel.sampleRooms; // Dự phòng quét hết mọi nơi nếu lỡ lọc kỹ quá
    }

    // 3. Tính toán phòng gần nhất thực tế
    for (var room in availableRooms) {
      final loc = _roomLocations[room.id];
      if (loc != null) {
        final dist = const Distance().as(LengthUnit.Meter, _currentLocation!, loc);
        if (dist < minDistance) {
          minDistance = dist;
          nearestRoom = room;
        }
      }
    }

    if (nearestRoom != null) {
      setState(() {
        _selectedRoom = nearestRoom;
        _sortByDistance = true;
      });
      // 4. Fly Camera to that room Marker smoothly
      final loc = _roomLocations[nearestRoom!.id];
      if (loc != null) _animatedMapMove(loc, 15);
    } else {
      _showLocationError('Không tìm thấy phòng nào phù hợp khu vực này');
    }
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
              onTap: (_, __) => setState(() => _selectedRoom = null),
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
                          _animatedMapMove(loc, 14.5);
                        },
                        child: _buildMarker(room),
                      ),
                    );
                  }),
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 80,
                      height: 80,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 80 * _pulseAnimation.value,
                                height: 80 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withOpacity((1 - _pulseAnimation.value) * 0.4),
                                ),
                              ),
                              Container(
                                width: 40 * _pulseAnimation.value,
                                height: 40 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withOpacity((1 - _pulseAnimation.value) * 0.6),
                                ),
                              ),
                              child!,
                            ],
                          );
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10, spreadRadius: 3)
                            ],
                          ),
                        ),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Text('${_filteredRooms.length} phòng tìm thấy',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          // My location button
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
                  border: Border.all(color: AppColors.mintSoft, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: _loadingLocation
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.teal))
                    : const Icon(Icons.my_location_rounded, color: AppColors.teal, size: 24),
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
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm phòng, khu vực...',
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
            // Nút Tính Năng Phát Hiện Phòng Gần Nhất
            GestureDetector(
              onTap: _findNearestRoom,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.teal, AppColors.tealDark]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.near_me_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Gần nhất',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 12)),
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
        border: Border.all(color: AppColors.mintSoft, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(room.imageUrl, width: 85, height: 85, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 85, height: 85, color: AppColors.mintSoft,
                  child: const Icon(Icons.image_rounded, color: AppColors.teal))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(room.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on_rounded, color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 4),
              Expanded(child: Text(room.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${(room.price / 1000000).toStringAsFixed(1)} Tr/tháng',
                    style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const Spacer(),
              if (_currentLocation != null) ...[
                const Icon(Icons.directions_walk_rounded, color: AppColors.teal, size: 14),
                const SizedBox(width: 2),
                Text('${_distanceToRoom(room).toStringAsFixed(1)}km',
                    style: const TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w700)),
              ],
            ]),
          ]),
        ),
        // Nút Đóng
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () => setState(() => _selectedRoom = null),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
            ),
          ),
        ),
      ]),
    );
  }
}
