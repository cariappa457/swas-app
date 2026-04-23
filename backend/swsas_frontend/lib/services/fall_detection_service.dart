import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class FallDetectionService {
  final int windowSize = 50;
  final double thresholdStd = 5.0; // Empirical threshold mimicking LSTM mock
  
  List<double> _accelMagnitudes = [];

  /// Evaluates an incoming accelerometer event.
  /// Returns a distress probability between 0.0 and 1.0.
  double evaluateSensorData(AccelerometerEvent event) {
    // Calculate magnitude of acceleration
    double magnitude = sqrt(
      pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2)
    );

    _accelMagnitudes.add(magnitude);

    if (_accelMagnitudes.length >= windowSize) {
      double distressProb = _analyzeWindow(_accelMagnitudes);
      
      // Shift buffer (50% overlap for continuous detection)
      _accelMagnitudes = _accelMagnitudes.sublist(windowSize ~/ 2);
      
      return distressProb;
    }

    return 0.0;
  }

  double _analyzeWindow(List<double> window) {
    if (window.isEmpty) return 0.0;

    // Calculate mean
    double sum = window.reduce((a, b) => a + b);
    double mean = sum / window.length;

    // Calculate standard deviation (variance)
    double squaredDiffs = window
        .map((val) => pow(val - mean, 2).toDouble())
        .reduce((a, b) => a + b);
    double stdDev = sqrt(squaredDiffs / window.length);

    // Map the variance to a probability sigmoid curve mimicking LSTM output
    // A low ambient variance yields ~0.02
    // A high variance yields ~0.98
    double probability = 1.0 / (1.0 + exp(-(stdDev - thresholdStd)));
    
    return probability;
  }
}
