import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class FallDetectionService {
  final int windowSize = 50;
  
  // Empirical thresholds tuned for UserAccelerometer (gravity-free)
  // At rest, UserAccelerometer magnitude is ~0.
  final double shakeThresholdStd = 4.0; 
  final double fallThresholdMagnitude = 25.0; // Sudden extreme spike (~2.5g)
  
  List<double> _accelMagnitudes = [];

  /// Evaluates an incoming UserAccelerometer event.
  /// Returns a distress probability between 0.0 and 1.0.
  double evaluateSensorData(UserAccelerometerEvent event) {
    // Calculate magnitude of pure user movement (gravity excluded)
    double magnitude = sqrt(
      pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2)
    );

    // 1. Immediate Fall Detection (Sudden Peak/Impact)
    if (magnitude > fallThresholdMagnitude) {
      print("🚨 SUDDEN IMPACT DETECTED! Magnitude: $magnitude");
      return 1.0; 
    }

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

    // Map the variance to a probability sigmoid curve
    // Higher stdDev = higher probability of heavy shaking/distress
    double probability = 1.0 / (1.0 + exp(-(stdDev - shakeThresholdStd)));
    
    return probability;
  }
}

