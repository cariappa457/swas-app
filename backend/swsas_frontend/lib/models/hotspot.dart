import 'package:google_maps_flutter/google_maps_flutter.dart';

class Hotspot {
  final String id;
  final LatLng center;
  final double radiusMeters;
  final String riskLevel;

  Hotspot({
    required this.id,
    required this.center,
    required this.radiusMeters,
    this.riskLevel = 'high',
  });

  /// Factory constructor to parse the GeoJSON format returned by the backend.
  factory Hotspot.fromGeoJsonFeature(Map<String, dynamic> feature, String id) {
    var coords = feature['geometry']['coordinates'];
    // GeoJSON is [longitude, latitude]
    LatLng center = LatLng(coords[1], coords[0]);
    
    var properties = feature['properties'];
    // The backend provides radius_degrees, but we converted it to meters in MapScreen previously.
    // 1 degree is roughly 111,000 meters at the equator.
    double radiusMeters = (properties['radius_degrees'] ?? 0.01) * 111000;
    
    return Hotspot(
      id: id,
      center: center,
      radiusMeters: radiusMeters,
      riskLevel: properties['risk_level'] ?? 'high',
    );
  }
}
