import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Environment {
  // Toggle this flag before moving to Production Cloud
  static const bool isProduction = false;
  
  // Example for Google Cloud Run / Render: "https://swsas-api-xyz.run.app"
  static const String productionApiBaseUrl = 'https://your-production-cloud-url.com';
  
  static String get apiBaseUrl {
    if (isProduction) return productionApiBaseUrl;
    
    // Web uses localhost
    if (kIsWeb) return 'http://localhost:8000';
    
    // Android emulator requires 10.0.2.2 to access the host machine's localhost
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    
    // iOS Simulators / Windows / MacOS apps use localhost safely
    return 'http://localhost:8000';
  }
}
