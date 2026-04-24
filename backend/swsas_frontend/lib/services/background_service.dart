import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'telemetry_service.dart';
import 'fall_detection_service.dart';
import 'emergency_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final fallService = FallDetectionService();
  final telemetry = TelemetryService(userId: "user_123"); 

  DateTime lastUpload = DateTime.now();
  DateTime lastDistressTrigger = DateTime.now().subtract(const Duration(minutes: 1));

  userAccelerometerEvents.listen((UserAccelerometerEvent event) async {
    // 1. Local/On-device basic check
    double distressProb = fallService.evaluateSensorData(event);
    
    if (distressProb > 0.8) {
       DateTime now = DateTime.now();
       // Debounce: prevent triggering multiple SOS alerts for the same fall event (30s window)
       if (now.difference(lastDistressTrigger).inSeconds > 30) {
         lastDistressTrigger = now;
         
         print("🚨 ON-DEVICE DISTRESS DETECTED! Prob: $distressProb");
         
         if (service is AndroidServiceInstance) {
           service.setForegroundNotificationInfo(
              title: "🚨 SOS TRIGGERED!",
              content: "Heavy movement detected. Emergency protocol initiated.",
           );
         }

         // PRODUCTION READY: Actually trigger the emergency protocol (SMS, Call, Backend)
         try {
           await EmergencyService.triggerEmergencyProtocol("automatic_motion_detected");
         } catch (e) {
           print("Error triggering automated SOS: $e");
         }
       }
    }

    // 2. Stream to Backend for Deep ML Analysis (Throttled to ~5Hz)
    if (DateTime.now().difference(lastUpload).inMilliseconds > 200) {
      lastUpload = DateTime.now();
      telemetry.uploadSensorData(event.x, event.y, event.z);
    }
  });

  // Background Sensor and Location Loop
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Attempt to get location quietly
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
          telemetry.broadcastLocation(position.latitude, position.longitude);
        } catch (e) {
          // Ignore if permission denied in background
        }

        service.setForegroundNotificationInfo(
          title: "SWSAS is monitoring your safety",
          content: position != null 
              ? "Location tracked. Accelerometer active." 
              : "Sensors active.",
        );
      }
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'swsas_channel_v2',
      initialNotificationTitle: 'SWSAS Active',
      initialNotificationContent: 'Monitoring environment for safety.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  
  await service.startService();
}
