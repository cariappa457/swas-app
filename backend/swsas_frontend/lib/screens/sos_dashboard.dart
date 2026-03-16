import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import 'map_screen.dart';

class SosDashboard extends StatefulWidget {
  final bool isStandalone;
  const SosDashboard({Key? key, this.isStandalone = true}) : super(key: key);

  @override
  _SosDashboardState createState() => _SosDashboardState();
}

class _SosDashboardState extends State<SosDashboard> {
  bool _sosActive = false;
  int _countdown = 15;
  Timer? _timer;

  void _triggerSOS() {
    setState(() {
      _sosActive = true;
      _countdown = 15;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        _fireSOSAPI();
      }
    });
  }

  void _cancelSOS() {
    _timer?.cancel();
    setState(() {
      _sosActive = false;
    });
    // Optional: Call /api/sos/cancel if already triggered to backend
  }

  Future<void> _fireSOSAPI() async {
    setState(() {
      _sosActive = false; // Close the emergency dispatch screen
    });

    try {
      // 1. Get current location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

      // 2. Submit HTTP POST to backend
      final baseUrl = Environment.apiBaseUrl;
      final url = Uri.parse('$baseUrl/api/sos/trigger?user_id=1');
      final payload = {
        "trigger_type": "manual",
        "lat": position.latitude,
        "lng": position.longitude,
        "audio_url": null
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("SOS Alert sent! Rescue coordinates dispatched.")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to report: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error triggering SOS: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sosActive) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF1744), Color(0xFFD50000)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_rounded, size: 100, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "SOS Triggered",
                    style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "Dispatching in $_countdown seconds",
                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: _cancelSOS,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.redAccent,
                      elevation: 8,
                      minimumSize: const Size(220, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("CANCEL SOS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("SWSAS Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_pin, color: Colors.black87, size: 30),
            onPressed: () {},
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFCE4EC), // light pink
              Color(0xFFF3E5F5), // light purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "Are you safe?",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap the button below if you need immediate help",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _triggerSOS,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1744).withOpacity(0.3),
                        spreadRadius: 20,
                        blurRadius: 40,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF1744).withOpacity(0.2),
                        spreadRadius: 40,
                        blurRadius: 60,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF5252), Color(0xFFD50000)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gpp_maybe_rounded, size: 60, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            "SOS",
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton("Auto-Distress", Icons.radar_rounded, true, null),
                    _actionButton("Safety Map", Icons.map_rounded, false, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapScreen()),
                      );
                    }),
                    _actionButton("Live Route", Icons.location_on_rounded, false, null),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, bool active, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE91E63) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!active)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
          ],
          border: active ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? Colors.white : const Color(0xFFE91E63), size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
