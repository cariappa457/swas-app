import 'dart:io' show Platform;
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import '../config/environment.dart';

class EmergencyService {
  static const String policeNumber = "112";

  static Future<void> triggerEmergencyProtocol(String triggerType, {List<String>? emergencyContacts}) async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("GPS unavailable, proceeding without precise location.");
    }

    await _notifyBackend(position, triggerType);

    if (position != null) {
       await sendEmergencySMS(position.latitude, position.longitude, recipients: emergencyContacts);
    }

    await callNumber(policeNumber);
  }
  
  static const platform = MethodChannel('com.example.swsas_app/sms');

  /// Sends an automated SMS directly in the background using native Android SmsManager.
  /// Falls back to URL launcher if permissions fail or on unsupported platforms.
  static Future<bool> sendEmergencySMS(double lat, double lng, {List<String>? recipients}) async {
      final String locationLink = "https://maps.google.com/?q=$lat,$lng";
      final String message = "HELP! I am in danger.\nMy location: $locationLink";
      
      if (kIsWeb || Platform.isIOS) {
          return _fallbackUrlLauncherSMS(message, recipients);
      }

      try {
          if (await Permission.sms.request().isGranted) {
              if (recipients != null && recipients.isNotEmpty) {
                  for (String number in recipients) {
                      await platform.invokeMethod('sendDirectSms', {
                          "phoneNumber": number,
                          "message": message,
                      });
                  }
              } else {
                  await platform.invokeMethod('sendDirectSms', {
                      "phoneNumber": '112',
                      "message": message,
                  });
              }
              print("Native Direct SMS sent successfully.");
              return true;
          }
      } catch (e) {
          print("Native Direct SMS failed: $e");
      }

      return _fallbackUrlLauncherSMS(message, recipients);
  }

  static Future<bool> _fallbackUrlLauncherSMS(String message, List<String>? recipients) async {
      String phoneVariables = "";
      if (recipients != null && recipients.isNotEmpty) {
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
         phoneVariables = "112"; 
      }

      final String scheme = 'sms:$phoneVariables';
      final String query = '?body=${Uri.encodeComponent(message)}';
      final Uri smsUri = Uri.parse('$scheme$query');

      try {
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          return true;
        } else {
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
      
      // Check if Firebase is actually initialized before using it
      if (Firebase.apps.isNotEmpty) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            token = await user.getIdToken() ?? "test_token";
          }
        } catch (authError) {
          print("Firebase Auth exception: $authError. Using test_token fallback.");
        }
      } else {
        print("Firebase not initialized. Using test_token fallback for SOS.");
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
