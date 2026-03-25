import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  RoomModel? _selectedRoom;
  String _selectedFilter = 'Tất cả';

  // Tọa độ trung tâm TP.HCM
  static const LatLng _center = LatLng(10.7769, 106.7009);

  final List<String> _filters = ['Tất cả', 'Chung cư', 'Phòng trọ', 'Nhà riêng', 'Biệt thự'];

  // Tọa độ giả lập cho từng phòng
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

  List<RoomModel> get _filteredRooms {
    final rooms = RoomModel.sampleRooms;
    if (_selectedFilter == 'Tất cả') return rooms;
    final typeMap = {
      'Chung cư': RoomType.apartment,
      'Phòng trọ': RoomType.studio,
      'Nhà riêng': RoomType.house,
      'Biệt thự': RoomType.villa,
    };
    return rooms.where((r) => r.type == typeMap[_selectedFilter]).toList();
  }

  Set<Marker> get _markers {
    return _filteredRooms.map((room) {
      final loc = _roomLocations[room.id] ?? _center;
      return Marker(
        markerId: MarkerId(room.id),
        position: loc,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          room.isFavorite ? BitmapDescriptor.hueRed : BitmapDescriptor.hueCyan,
        ),
        infoWindow: InfoWindow(
          title: room.title,
          snippet: '${(room.price / 1000000).toStringAsFixed(1)}tr VNĐ/tháng',
        ),
        onTap: () => setState(() => _selectedRoom = room),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _center, zoom: 12),
            markers: _markers,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onTap: (_) => setState(() => _selectedRoom = null),
          ),
          // Header
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildFilterBar(),
              ],
            ),
          ),
          // Bottom room card
          if (_selectedRoom != null)
            Positioned(
              bottom: 24, left: 16, right: 16,
              child: _buildRoomCard(_selectedRoom!),
            ),
          // Room count badge
          Positioned(
            bottom: _selectedRoom != null ? 200 : 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Text(
                '${_filteredRooms.length} phòng',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const Icon(Icons.search_rounded, color: AppColors.teal, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Tìm kiếm khu vực...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          GestureDetector(
            onTap: () => _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 12)),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.my_location_rounded, color: AppColors.teal, size: 18),
            ),
          ),
        ]),
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
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
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
    return GestureDetector(
      onTap: () {
        final loc = _roomLocations[room.id] ?? _center;
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(room.imageUrl, width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: AppColors.mintSoft,
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
              ]),
            ]),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedRoom = null),
            child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
          ),
        ]),
      ),
    );
  }
}
