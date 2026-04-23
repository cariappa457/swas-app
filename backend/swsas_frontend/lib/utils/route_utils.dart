import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/hotspot.dart';

class RouteUtils {
  /// Calculates the Haversine distance in meters between two coordinates.
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // in meters
    final double dLat = _degreesToRadians(point2.latitude - point1.latitude);
    final double dLon = _degreesToRadians(point2.longitude - point1.longitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(point1.latitude)) *
            cos(_degreesToRadians(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Evaluates if ANY portion of the given route passes too close to a hotspot.
  /// A route is considered unsafe if the distance from any polyline point
  /// to a hotspot center is less than the hotspot's radius.
  static bool isRouteUnsafe(List<LatLng> routePoints, List<Hotspot> hotspots) {
    if (routePoints.isEmpty || hotspots.isEmpty) return false;

    for (var point in routePoints) {
      for (var hotspot in hotspots) {
        final distance = _calculateDistance(point, hotspot.center);
        // If the point is within the hotspot's radius, the route is unsafe.
        if (distance <= hotspot.radiusMeters) {
          return true;
        }
      }
    }
    return false;
  }

  /// Generates a real route between two points using OSRM to follow actual streets.
  /// Falls back to mock route if network fails.
  static Future<List<LatLng>> generateMockRoute(LatLng start, LatLng end) async {
    return await _fetchOSRMRoute(start, end);
  }

  /// Generates a "Safer" alternative route. In production, this would use waypoints.
  static Future<List<LatLng>> generateSafeRoute(LatLng start, LatLng end) async {
      // Calculate a midpoint that is offset to force OSRM to find an alternative real-street route.
      double dLat = end.latitude - start.latitude;
      double dLng = end.longitude - start.longitude;
      
      LatLng midpointOffset = LatLng(
        start.latitude + (dLat / 2) - dLng * 0.3, 
        start.longitude + (dLng / 2) + dLat * 0.3,
      );

      final part1 = await _fetchOSRMRoute(start, midpointOffset);
      final part2 = await _fetchOSRMRoute(midpointOffset, end);
      
      if (part1.isEmpty || part2.isEmpty) {
         return []; // Fallback handled by caller if empty
      }
      return [...part1, ...part2];
  }

  static Future<List<LatLng>> _fetchOSRMRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
          'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full');
      
      // Import http client dynamically or rely on caller context. 
      // Luckily we can just use the standard http or dio, but we don't have it imported here.
      // Let's add the import at the top using multi_replace in a second.
      // For now, I will write the code using http.get.
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'];
        if (routes != null && routes.isNotEmpty) {
          final coordinates = routes[0]['geometry']['coordinates'] as List;
          return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        }
      }
    } catch (e) {
      print("OSRM Routing failed: $e");
    }
    
    // Fallback Mock straight line
    List<LatLng> points = [];
    const int segments = 20;
    for (int i = 0; i <= segments; i++) {
      double fraction = i / segments;
      double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }
    return points;
  }
}
