import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class DirectionsService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';

  static Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving',
  }) async {
    try {
      final url = '$_baseUrl/$mode/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?geometries=geojson&overview=full';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          
          final List<LatLng> polyline = coordinates.map((coord) {
            // OSRM returns [longitude, latitude]
            return LatLng(coord[1], coord[0]);
          }).toList();
          
          final distanceMeters = route['distance'];
          final durationSeconds = route['duration'];
          
          String distanceText = '';
          if (distanceMeters > 1000) {
            distanceText = '${(distanceMeters / 1000).toStringAsFixed(1)} km';
          } else {
            distanceText = '${distanceMeters.toStringAsFixed(0)} m';
          }

          String durationText = '';
          if (durationSeconds > 3600) {
            final hours = (durationSeconds / 3600).floor();
            final minutes = ((durationSeconds % 3600) / 60).ceil();
            durationText = '$hours giờ $minutes phút';
          } else {
            durationText = '${(durationSeconds / 60).ceil()} phút';
          }
          
          return {
            'polyline': polyline,
            'distance': distanceText,
            'duration': durationText,
          };
        }
      }
    } catch (e) {
      print('Error getting directions: $e');
    }
    return null;
  }
}
