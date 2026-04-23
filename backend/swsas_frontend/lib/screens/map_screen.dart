import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/hotspot.dart';
import '../utils/route_utils.dart';

class MapScreen extends StatefulWidget {
  final bool isStandalone;
  const MapScreen({Key? key, this.isStandalone = true}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  
  List<Hotspot> _hotspots = [];
  bool? _isRouteUnsafe;
  List<LatLng> _currentRoute = [];

  final LatLng _startLocation = const LatLng(12.9716, 77.5946); // Bangalore Center
  // A mock destination that crosses our dummy hotspots
  final LatLng _mockDestination = const LatLng(12.9516, 77.6146); 

  @override
  void initState() {
    super.initState();
    _fetchHotspots();
  }

  void _onMapCreated(GoogleMapController controller) {
    debugPrint("🗺️ DIAGNOSTIC: Google Map Widget created.");
    mapController = controller;
    
    // Check if the controller is responsive
    mapController?.getVisibleRegion().then((bounds) {
      debugPrint("🗺️ DIAGNOSTIC: Map visible region: $bounds");
    }).catchError((e) {
      debugPrint("🗺️ DIAGNOSTIC ERROR: Could not get visible region. This usually means the API key is invalid or unauthorized. Error: $e");
    });
  }

  Future<void> _fetchHotspots() async {
    final baseUrl = Environment.apiBaseUrl;
    final url = '$baseUrl/api/hotspots';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _processGeoJSON(data);
      } else {
        debugPrint('Failed to load hotspots');
      }
    } catch (e) {
      debugPrint('Error fetching hotspots: $e');
    }
  }

  void _processGeoJSON(Map<String, dynamic> geoJson) {
    Set<Marker> newMarkers = {};
    Set<Circle> newCircles = {};
    List<Hotspot> parsedHotspots = [];

    List<dynamic> features = geoJson['features'];
    int markerIdCounter = 0;
    int circleIdCounter = 0;

    for (var feature in features) {
      if (feature['geometry']['type'] == 'Point') {
        var coords = feature['geometry']['coordinates'];
        LatLng position = LatLng(coords[1], coords[0]);
        var properties = feature['properties'];

        if (properties['type'] == 'hotspot_center') {
          String id = 'circle_${circleIdCounter++}';
          
          // Use our new model
          final hotspot = Hotspot.fromGeoJsonFeature(feature, id);
          parsedHotspots.add(hotspot);

          newCircles.add(
            Circle(
              circleId: CircleId(id),
              center: hotspot.center,
              radius: hotspot.radiusMeters,
              fillColor: Colors.red.withOpacity(0.3),
              strokeColor: Colors.red,
              strokeWidth: 2,
            ),
          );
        } else {
          newMarkers.add(
            Marker(
              markerId: MarkerId('marker_${markerIdCounter++}'),
              position: position,
              infoWindow: InfoWindow(
                title: properties['type'].toString().replaceAll('_', ' ').toUpperCase(),
                snippet: 'Time: ${properties['timestamp']}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = newMarkers;
      _circles = newCircles;
      _hotspots = parsedHotspots;
    });
  }

  Future<void> _simulateRoute() async {
    // Generate a direct route
    final route = await RouteUtils.generateMockRoute(_startLocation, _mockDestination);
    _evaluateAndDrawRoute(route);
  }

  Future<void> _findSaferRoute() async {
    // Generate an offset route to avoid the center
    final safeRoute = await RouteUtils.generateSafeRoute(_startLocation, _mockDestination);
    _evaluateAndDrawRoute(safeRoute);
  }

  void _evaluateAndDrawRoute(List<LatLng> routePoints) {
    if (routePoints.isEmpty) return;

    final isUnsafe = RouteUtils.isRouteUnsafe(routePoints, _hotspots);
    
    setState(() {
      _currentRoute = routePoints;
      _isRouteUnsafe = isUnsafe;
      
      _polylines = {
        Polyline(
          polylineId: const PolylineId('current_route'),
          points: routePoints,
          color: isUnsafe ? Colors.redAccent : Colors.teal,
          width: 5,
        ),
      };
      
      // Add a marker for the destination
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: routePoints.last,
          infoWindow: const InfoWindow(title: "Destination"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        )
      );
    });
    
    // Zoom out slightly to see the route
    mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(
          routePoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b) - 0.01,
          routePoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b) - 0.01,
        ),
        northeast: LatLng(
          routePoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b) + 0.01,
          routePoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b) + 0.01,
        ),
      ),
      50.0,
    ));
  }

  Widget _buildSafetyBanner() {
    if (_isRouteUnsafe == null) return const SizedBox.shrink();

    final isUnsafe = _isRouteUnsafe!;
    
    return Positioned(
      top: widget.isStandalone ? 16 : 96,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnsafe ? const Color(0xFFD50000) : const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isUnsafe ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isUnsafe 
                      ? "⚠️ This route passes through high-risk areas." 
                      : "✅ This is the safest available route.",
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (isUnsafe) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _findSaferRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD50000),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.alt_route_rounded),
                  label: const Text("Find Safer Route", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isStandalone ? AppBar(
        title: const Text('Safety Hotspots & Routing', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ) : null,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _startLocation,
              zoom: 12.0,
            ),
            markers: _markers,
            circles: _circles,
            polylines: _polylines,
            myLocationEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),
          
          _buildSafetyBanner(),
          
          if (!widget.isStandalone)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFA648C),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateRoute,
        backgroundColor: Colors.black87,
        icon: const Icon(Icons.directions_rounded, color: Colors.white),
        label: const Text("Simulate Route", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

