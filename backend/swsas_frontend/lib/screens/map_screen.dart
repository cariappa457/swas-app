import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

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

  final LatLng _center = const LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    _fetchHotspots();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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

    List<dynamic> features = geoJson['features'];
    int markerIdCounter = 0;
    int circleIdCounter = 0;

    for (var feature in features) {
      var coords = feature['geometry']['coordinates'];
      LatLng position = LatLng(coords[1], coords[0]);
      var properties = feature['properties'];

      if (properties['type'] == 'hotspot_center') {
        newCircles.add(
          Circle(
            circleId: CircleId('circle_${circleIdCounter++}'),
            center: position,
            radius: properties['radius_degrees'] * 111000,
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

    setState(() {
      _markers = newMarkers;
      _circles = newCircles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isStandalone ? AppBar(
        title: const Text('Safety Hotspots', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ) : null,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 12.0,
            ),
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            compassEnabled: true,
          ),
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
    );
  }
}
