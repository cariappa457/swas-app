import 'dart:math';
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

  /// Generates a mock route between two points for demonstration purposes.
  /// In a production app, this would call the Google Directions API.
  static List<LatLng> generateMockRoute(LatLng start, LatLng end) {
    List<LatLng> points = [];
    const int segments = 20;

    for (int i = 0; i <= segments; i++) {
      double fraction = i / segments;
      double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      
      // Add slight noise to make it look like a road path instead of a straight line,
      // but keep start and end exact
      if (i > 0 && i < segments) {
         // Adds ~50 meters of jitter to make it look like urban driving
         lat += (Random().nextDouble() - 0.5) * 0.0005;
         lng += (Random().nextDouble() - 0.5) * 0.0005;
      }
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  /// Generates a "Safer" alternative route by explicitly offsetting the path
  /// to avoid the direct line. This is a functional mock for the demo.
  static List<LatLng> generateSafeRoute(LatLng start, LatLng end) {
      List<LatLng> points = [];
      const int segments = 20;
      
      // Calculate a midpoint that is significantly offset (e.g., looping around)
      // We will push the route 0.03 degrees (approx 3km) perpendicular to the straight line
      double dLat = end.latitude - start.latitude;
      double dLng = end.longitude - start.longitude;
      
      LatLng midpointOffset = LatLng(
        start.latitude + (dLat / 2) - dLng * 0.5, // Perpendicular offset
        start.longitude + (dLng / 2) + dLat * 0.5,
      );

      // Route from start -> midpointOffset -> end
      for (int i = 0; i <= segments ~/ 2; i++) {
        double fraction = i / (segments / 2);
        double lat = start.latitude + (midpointOffset.latitude - start.latitude) * fraction;
        double lng = start.longitude + (midpointOffset.longitude - start.longitude) * fraction;
        points.add(LatLng(lat, lng));
      }
      
      for (int i = 1; i <= segments ~/ 2; i++) {
        double fraction = i / (segments / 2);
        double lat = midpointOffset.latitude + (end.latitude - midpointOffset.latitude) * fraction;
        double lng = midpointOffset.longitude + (end.longitude - midpointOffset.longitude) * fraction;
        points.add(LatLng(lat, lng));
      }
      
      return points;
  }
}
