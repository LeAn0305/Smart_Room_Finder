import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:smart_room_finder/core/constants/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  String _selectedAddress = 'Đang xác định địa chỉ...';
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation == null) {
      _getCurrentLocation();
    } else {
      _reverseGeocode(_selectedLocation!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Dịch vụ vị trí đã bị tắt');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Quyền vị trí bị từ chối');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Quyền vị trí bị từ chối vĩnh viễn');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final loc = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = loc;
      });
      _mapController.move(loc, 15);
      _reverseGeocode(loc);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lấy vị trí hiện tại: $e')),
        );
        // Default to Ho Chi Minh City if fails
        final defaultLoc = const LatLng(10.7769, 106.7009);
        setState(() {
          _selectedLocation = defaultLoc;
        });
        _reverseGeocode(defaultLoc);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1';
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'SmartRoomFinder/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedAddress = data['display_name'] ?? 'Không tìm thấy địa chỉ';
        });
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      setState(() {
        _selectedAddress = 'Không thể lấy địa chỉ (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 2) {
        _searchAddress(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _searchAddress(String query) async {
    setState(() => _isSearching = true);
    try {
      final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1';
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'SmartRoomFinder/1.0',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data;
        });
      }
    } catch (e) {
      debugPrint('Error searching address: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(dynamic result) {
    final lat = double.parse(result['lat']);
    final lon = double.parse(result['lon']);
    final loc = LatLng(lat, lon);
    
    setState(() {
      _selectedLocation = loc;
      _selectedAddress = result['display_name'];
      _searchResults = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
    
    _mapController.move(loc, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí phòng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation ?? const LatLng(10.7769, 106.7009),
              initialZoom: 14,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                  _selectedAddress = 'Đang xác định địa chỉ...';
                });
                _reverseGeocode(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_room_finder',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 45),
                    ),
                  ],
                ),
            ],
          ),
          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Tìm địa chỉ...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.teal),
                      suffixIcon: _searchController.text.isNotEmpty 
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                          title: Text(result['display_name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // My Location Button
          Positioned(
            bottom: _selectedLocation != null ? 140 : 24,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location_btn',
              backgroundColor: Colors.white,
              mini: true,
              onPressed: _getCurrentLocation,
              child: _isLoadingLocation
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))
                  : const Icon(Icons.my_location, color: AppColors.teal),
            ),
          ),
          // Confirmation Card
          if (_selectedLocation != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.teal, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Địa chỉ đã chọn', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(_selectedAddress, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'location': _selectedLocation,
                              'address': _selectedAddress,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Xác nhận vị trí này', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
