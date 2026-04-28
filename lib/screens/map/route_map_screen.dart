import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/services/directions_service.dart';

class RouteMapScreen extends StatefulWidget {
  final RoomModel room;

  const RouteMapScreen({super.key, required this.room});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  String _distance = '';
  String _duration = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Vui lòng bật dịch vụ vị trí');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Quyền truy cập vị trí bị từ chối');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Quyền truy cập vị trí bị từ chối vĩnh viễn');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final origin = LatLng(pos.latitude, pos.longitude);
      
      // Fallback destination if room has no coordinates
      final destination = widget.room.latitude != 0.0 && widget.room.longitude != 0.0
          ? LatLng(widget.room.latitude, widget.room.longitude)
          : const LatLng(10.7769, 106.7009); // Default center

      if (mounted) {
        setState(() => _currentLocation = origin);
      }

      final result = await DirectionsService.getDirections(
        origin: origin,
        destination: destination,
      );

      if (result != null && mounted) {
        setState(() {
          _routePoints = result['polyline'];
          _distance = result['distance'];
          _duration = result['duration'];
          _isLoading = false;
        });

        // Fit bounds
        final bounds = LatLngBounds.fromPoints([origin, destination, ..._routePoints]);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
        );
      } else {
        _showError('Không thể lấy đường đi');
      }
    } catch (e) {
      _showError('Có lỗi xảy ra: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.room.latitude != 0.0 && widget.room.longitude != 0.0
        ? LatLng(widget.room.latitude, widget.room.longitude)
        : const LatLng(10.7769, 106.7009);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉ đường đến phòng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: destination,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_room_finder',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blueAccent,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: destination,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
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
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.teal),
                      SizedBox(height: 16),
                      Text('Đang tìm đường đi...'),
                    ],
                  ),
                ),
              ),
            ),
          if (!_isLoading && _distance.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.mintSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_bike_rounded, color: AppColors.teal),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Khoảng cách và Thời gian',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_distance • $_duration',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
