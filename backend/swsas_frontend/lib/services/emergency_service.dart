import 'dart:io' show Platform;
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/environment.dart';

class EmergencyService {
  static const String policeNumber = "112";

  static Future<void> triggerEmergencyProtocol(String triggerType, {List<String>? emergencyContacts}) async {
    // 1. Fetch Location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("GPS unavailable, proceeding without precise location.");
    }

    // 2. Notify Backend (Logs Event)
    await _notifyBackend(position, triggerType);

    // 3. Send SMS to Contacts (if available) with Location Link
    if (position != null) {
       await sendEmergencySMS(position.latitude, position.longitude, recipients: emergencyContacts);
    }

    // 4. Initiate the Phone Call (Optional logic: You might want to delay this or rely on the user sending the SMS first, but keeping existing flow)
    await callNumber(policeNumber);
  }
  
  /// Opens the native SMS app with a pre-filled emergency message and Google Maps link.
  /// Supports multiple recipients based on the platform.
  static Future<bool> sendEmergencySMS(double lat, double lng, {List<String>? recipients}) async {
      final String locationLink = "https://maps.google.com/?q=$lat,$lng";
      final String message = "HELP! I am in danger.\nMy location: $locationLink";
      
      String phoneVariables = "";
      if (recipients != null && recipients.isNotEmpty) {
          // Join numbers appropriately based on platform
          if (kIsWeb) {
              phoneVariables = recipients.join(',');
          } else if (Platform.isAndroid) {
              phoneVariables = recipients.join(';'); // Android typically uses ';' as separator
          } else if (Platform.isIOS) {
              phoneVariables = recipients.join(','); // iOS uses ','
          } else {
             phoneVariables = recipients.join(',');
          }
      } else {
         // Placeholder if no contacts are provided
         phoneVariables = "112"; 
      }

      // Construct the SMS URI
      // Note: URI encoding is tricky for SMS. On Android, `?body=` works. On iOS, `&body=` is sometimes needed if numbers are present.
      // The `url_launcher` package documentation recommends `?body=` for the first parameter.
      final String scheme = 'sms:$phoneVariables';
      final String query = '?body=${Uri.encodeComponent(message)}';
      
      final Uri smsUri = Uri.parse('$scheme$query');

      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          return true;
        } else {
          print("Could not launch SMS app with URI: $smsUri");
           // Fallback attempt without body if the complex URI fails
           final Uri fallbackUri = Uri.parse('sms:$phoneVariables');
           if (await canLaunchUrl(fallbackUri)) {
              await launchUrl(fallbackUri);
              return true;
           }
          return false;
        }
      } catch (e) {
         print("Error launching SMS app: $e");
         return false;
      }
  }

  static Future<void> _notifyBackend(Position? position, String type) async {
    try {
      String token = "test_token";
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          token = await user.getIdToken() ?? "test_token";
        } else {
          print("User not logged into Firebase. Using test_token fallback.");
        }
      } catch (authError) {
        print("Firebase Auth exception: $authError. Using test_token fallback.");
      }

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
    if (kIsWeb) {
      print("Native phone calling is not supported on Web. Cannot dial $number.");
      return false;
    }
    
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
