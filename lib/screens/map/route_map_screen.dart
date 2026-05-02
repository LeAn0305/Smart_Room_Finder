import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_room_finder/core/constants/app_colors.dart';
import 'package:smart_room_finder/models/room_model.dart';
import 'package:smart_room_finder/services/directions_service.dart';

class RouteMapScreen extends StatefulWidget {
  final RoomModel room;
  final LatLng? userLocation;

  const RouteMapScreen({super.key, required this.room, this.userLocation});

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
      // Platform check for GPS accuracy warning
      if (kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux))) {
        await _showPlatformWarning();
      }

      if (widget.room.latitude == 0.0 || widget.room.longitude == 0.0) {
        _showErrorDialog('Phòng này chưa có tọa độ để chỉ đường');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final destination = LatLng(widget.room.latitude, widget.room.longitude);

      LatLng? origin;

      if (widget.userLocation != null) {
        origin = widget.userLocation;
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        LocationPermission permission = await Geolocator.checkPermission();

        if (!serviceEnabled ||
            permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
        }

        if (!serviceEnabled ||
            permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _showErrorDialog(
            'Hiện tại chưa lấy được tọa độ chính xác của vị trí của bạn. Nếu bạn vẫn muốn sử dụng chức năng này, chức năng này có thể sai lệch do vị trí của bạn đang không xác định.',
          );
          if (mounted) setState(() => _isLoading = false);
          // Move camera to destination
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              try {
                _mapController.move(destination, 13);
              } catch (_) {}
            }
          });
          return;
        }

        Position? pos;
        try {
          pos = await Geolocator.getCurrentPosition().timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw Exception('Lỗi lấy vị trí: Hết thời gian chờ');
            },
          );
        } catch (e) {
          _showErrorDialog(
            'Không thể lấy vị trí hiện tại của bạn. Vui lòng kiểm tra lại GPS hoặc quyền truy cập vị trí.',
          );
          if (mounted) {
            setState(() => _isLoading = false);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                try {
                  _mapController.move(destination, 13);
                } catch (_) {}
              }
            });
          }
          return;
        }
        origin = LatLng(pos.latitude, pos.longitude);
      }

      if (mounted && origin != null) {
        setState(() => _currentLocation = origin);
      }

      if (origin == null) {
        _showError('Không thể xác định vị trí khởi đầu. Vui lòng thử lại.');
        if (mounted) setState(() => _isLoading = false);
        return;
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
        final bounds = LatLngBounds.fromPoints([
          origin,
          destination,
          ..._routePoints,
        ]);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            try {
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50.0),
                ),
              );
            } catch (_) {}
          }
        });
      } else {
        _showError('Không thể lấy đường đi');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Có lỗi xảy ra: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showPlatformWarning() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Lưu ý vị trí'),
          ],
        ),
        content: const Text(
          'Bạn đang sử dụng thiết bị máy tính hoặc trình duyệt web. Vị trí hiện tại có thể không chính xác bằng thiết bị di động có GPS. '
          'Để có trải nghiệm chỉ đường tốt nhất, vui lòng sử dụng ứng dụng trên điện thoại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination =
        widget.room.latitude != 0.0 && widget.room.longitude != 0.0
        ? LatLng(widget.room.latitude, widget.room.longitude)
        : const LatLng(10.7769, 106.7009);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chỉ đường đến phòng',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: destination, initialZoom: 13),
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
                  if (widget.room.latitude != 0.0 &&
                      widget.room.longitude != 0.0)
                    Marker(
                      point: destination,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
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
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.mintSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_bike_rounded,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Khoảng cách và Thời gian',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_distance • ước tính $_duration',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
