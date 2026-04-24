import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'sos_dashboard.dart';
import 'profile_screen.dart';
import 'dart:math';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  
  const MainShell({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainShellState createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  StreamSubscription? _accelerometerSub;
  bool _isSosCooldown = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _setupShakeDetection();
  }

  void _setupShakeDetection() {
    try {
      _accelerometerSub = accelerometerEvents.listen((AccelerometerEvent event) {
        if (_isSosCooldown) return;
        double gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) / 9.8;
        
        // SHAKE/FALL DETECTION THRESHOLD (Roughly 3 Gs of force)
        if (gForce > 3.0) {
          _isSosCooldown = true;
          _triggerEmergencySos();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🚨 DISTRESS DETECTED (SHAKE/FALL)! Triggering SOS 🚨"), backgroundColor: Colors.red),
          );
          Future.delayed(const Duration(seconds: 15), () {
            _isSosCooldown = false;
          });
        }
      });
    } catch (e) {
      print("Accelerometer init failed (likely requires HTTPS on mobile): $e");
    }
  }

  Future<void> _triggerEmergencySos() async {
    try {
      final url = Uri.parse('${Environment.apiBaseUrl}/api/sos/trigger-call');
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        // Hardcoding standard params for test mock
        body: jsonEncode({"lat": 12.9716, "lng": 77.5946, "trigger_type": "auto_sensor"}),
      );
    } catch (e) {
      print("SOS API Error: $e");
    }
  }

  final List<Widget> _screens = [
    const SosDashboard(isStandalone: false),
    const Center(child: Text("Calls")), // Placeholder
    const MapScreen(isStandalone: false),
    const Center(child: Text("Directory")), // Placeholder
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          
          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFC8BA2), // Soft pink matching theme
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(0, Icons.warning_amber_rounded),
                  _navItem(1, Icons.call),
                  _navItem(2, Icons.map_outlined),
                  _navItem(3, Icons.menu_book_rounded),
                  _navItem(4, Icons.person_outline),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFFFA648C) : Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
