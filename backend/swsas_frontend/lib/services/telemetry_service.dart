import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class TelemetryService {
  WebSocketChannel? _channel;
  final String userId;

  TelemetryService({required this.userId}) {
    _connect();
  }

  void _connect() {
    // Convert http/https to ws/wss for websocket
    final baseUrl = Environment.apiBaseUrl;
    final wsUrl = baseUrl.replaceAll('http', 'ws');
    
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/api/ws/telemetry/$userId'),
      );
      
      _channel?.stream.listen(
        (data) {
           print("Telemetry Update Received: $data");
        },
        onError: (error) => print("Telemetry Error: $error"),
        onDone: () => print("Telemetry Connection Closed"),
      );
    } catch (e) {
      print("Failed to initialize telemetry: $e");
    }
  }

  void broadcastLocation(double lat, double lng) {
    if (_channel != null) {
      final payload = jsonEncode({
        "lat": lat,
        "lng": lng
      });
      _channel!.sink.add(payload);
    }
  }

  Future<void> uploadSensorData(double ax, double ay, double az, {double gx = 0, double gy = 0, double gz = 0}) async {
    try {
      await http.post(
        Uri.parse('${Environment.apiBaseUrl}/api/sensor/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "acc_x": ax,
          "acc_y": ay,
          "acc_z": az,
          "gyro_x": gx,
          "gyro_y": gy,
          "gyro_z": gz,
        }),
      ).timeout(const Duration(milliseconds: 500));
    } catch (e) {
      // Ignore background upload errors
    }
  }

  void dispose() {
    _channel?.sink.close();
  }
}
