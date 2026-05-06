import 'dart:async';
import 'dart:math';
import 'emergency_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';
import '../config/environment.dart';
import 'package:flutter/foundation.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double accX = 0, accY = 0, accZ = 0;
  double gyroX = 0, gyroY = 0, gyroZ = 0;

  List<Map<String, double>> _buffer = [];
  Timer? _uploadTimer;

  bool _isRunning = false;

  void startListening() {
    if (_isRunning) return;
    _isRunning = true;

    _accelSub = accelerometerEvents.listen((AccelerometerEvent event) {
      accX = event.x;
      accY = event.y;
      accZ = event.z;
      
      double magnitude = sqrt(accX * accX + accY * accY + accZ * accZ);
      if (magnitude > 25.0) { // Lowered threshold to ~2.5G for easier testing
         debugPrint("SHAKE DETECTED! Magnitude: $magnitude");
         EmergencyService.triggerEmergencyProtocol("shake");
      }
    });

    _gyroSub = gyroscopeEvents.listen((GyroscopeEvent event) {
      gyroX = event.x;
      gyroY = event.y;
      gyroZ = event.z;
    });

    // Sample at roughly 10Hz (100ms) to accumulate 50 items quickly
    _uploadTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _buffer.add({
        "acc_x": accX,
        "acc_y": accY,
        "acc_z": accZ,
        "gyro_x": gyroX,
        "gyro_y": gyroY,
        "gyro_z": gyroZ,
        "lat": 12.9716, // Mock location for ML trigger
        "lng": 77.5946
      });

      // Send immediately when we have data, let backend buffer it
      _uploadToBackend(_buffer.last);
    });
    
    debugPrint("SensorService started listening...");
  }

  Future<void> _uploadToBackend(Map<String, double> payload) async {
    try {
      final url = Uri.parse('${Environment.apiBaseUrl}/api/sensor/upload');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test_token', // Dummy token
        },
        body: jsonEncode(payload),
      );
      // We don't print on success to avoid console spam
    } catch (e) {
      debugPrint("Sensor upload error: $e");
    }
  }

  void stopListening() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _uploadTimer?.cancel();
    _isRunning = false;
    debugPrint("SensorService stopped listening.");
  }
}
