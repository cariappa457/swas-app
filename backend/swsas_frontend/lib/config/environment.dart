import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Environment {
  // Toggle this flag before moving to Production Cloud
  static const bool isProduction = false;
  
  // --- TUNNEL SETUP ---
  // If you are using Ngrok or LocalTunnel, put your public URL here:
  static const String tunnelApiBaseUrl = 'https://YOUR-TUNNEL-URL.ngrok-free.app';
  static const bool useTunnel = false; // Set to true when your partner tests from elsewhere
  
  static String get apiBaseUrl {
    if (isProduction) return 'https://YOUR-PRODUCTION-URL.com';
    if (useTunnel) return tunnelApiBaseUrl;
    
    if (kIsWeb) return 'https://swsas-backend-1011.loca.lt';
    
    // Physical devices on the same Wi-Fi use the computer's local IP
    // Your current Local IP: 192.168.0.122
    if (Platform.isAndroid || Platform.isIOS) return 'http://192.168.0.122:8000';
    
    return 'http://localhost:8000';
  }
}
