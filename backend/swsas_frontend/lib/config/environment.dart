import 'package:flutter/foundation.dart' show kIsWeb;

class Environment {
  // Toggle this flag before moving to Production Cloud
  static const bool isProduction = false;
  
  // Example for Google Cloud Run / Render: "https://swsas-api-xyz.run.app"
  static const String productionApiBaseUrl = 'https://your-production-cloud-url.com';
  
  // Local testing inside Android Emulator points 10.0.2.2 to the host machine's localhost
  static const String localApiBaseUrl = 'http://10.0.2.2:8000';
  
  static const String webApiBaseUrl = 'http://localhost:8000';

  static String get apiBaseUrl {
    if (isProduction) return productionApiBaseUrl;
    if (kIsWeb) return webApiBaseUrl;
    return localApiBaseUrl;
  }
}
