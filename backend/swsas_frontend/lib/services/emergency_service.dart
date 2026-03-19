import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/environment.dart';

class EmergencyService {
  static const String policeNumber = "112";

  static Future<void> triggerEmergencyProtocol(String triggerType) async {
    // 1. Fetch Location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("GPS unavailable, proceeding without precise location.");
    }

    // 2. Notify Backend (Logs Event + SMS Contacts natively)
    await _notifyBackend(position, triggerType);

    // 3. Initiate the Phone Call
    await callNumber(policeNumber);
  }

  static Future<void> _notifyBackend(Position? position, String type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
          print("User not logged into Firebase");
          return;
      }

      final token = await user.getIdToken();

      await http.post(
        Uri.parse('${Environment.apiBaseUrl}/api/sos/trigger-call'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lat': position?.latitude ?? 0.0,
          'lng': position?.longitude ?? 0.0,
          'trigger_type': type,
        }),
      );
    } catch (e) {
      print("Backend notification failed: $e");
    }
  }

  static Future<bool> callNumber(String number) async {
    // Check Android Phone Permissions
    if (await Permission.phone.request().isGranted) {
      // Direct call attempt (bypasses dialer for speed)
      bool? res = await FlutterPhoneDirectCaller.callNumber(number);
      if (res != null && res) return true;
    }

    // Fallback: Launch the native dialer UI
    final Uri telUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
      return true;
    }
    
    print("Error: Could not launch dialer.");
    return false;
  }
}
