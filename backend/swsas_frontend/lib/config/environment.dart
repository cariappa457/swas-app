import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Environment {
  // Toggle this flag before moving to Production Cloud
  static const bool isProduction = false;
  
  // Example for Google Cloud Run / Render: "https://swsas-api-xyz.run.app"
  static const String productionApiBaseUrl = 'https://your-production-cloud-url.com';
  
  static String get apiBaseUrl {
    if (isProduction) return productionApiBaseUrl;
    
    // Use the current local Wi-Fi IPv4 address for local testing
    return 'http://192.168.0.122:8000';
  }
}
