import numpy as np
import logging

logger = logging.getLogger(__name__)

class MockLSTMPredictor:
    """
    Upgraded Real-World Signal Architecture (DSVA): 
    Detects distress signatures using impulse detection, signal jitter analysis, 
    and post-impact stabilization monitoring.
    """
    def __init__(self, timesteps=50, features=6):
        self.timesteps = timesteps
        self.features = features
        self.impact_threshold = 20.0  # Combined G-force spike for impact
        self.shake_threshold = 6.0    # Mean absolute deviation for shaking/running
        self.stillness_threshold = 0.5 # Near-zero movement detection

    def predict_anomaly(self, sensor_window):
        try:
            arr = np.array(sensor_window)
            if arr.shape != (self.timesteps, self.features):
                return 0.0

            # 1. Total Magnitude Calculation
            # Sqrt(x^2 + y^2 + z^2) for accelerometer
            acc_mag = np.linalg.norm(arr[:, :3], axis=1)
            
            # 2. Impact Detection (The Peak)
            peak_impact = np.max(acc_mag)
            
            # 3. Movement Jitter (The Shake)
            # Standard deviation of the entire window
            shake_intensity = np.mean(np.std(arr, axis=0))
            
            # 4. Post-Impact Monitoring (Stabilization)
            # Check the last 10 samples of the window (potential drop/stillness)
            tail_stillness = np.std(acc_mag[-10:])
            
            prob = 0.0
            
            # Logic: If we see a massive peak followed by sudden silence -> FAST FALL
            if peak_impact > self.impact_threshold and tail_stillness < self.stillness_threshold:
                prob = 0.95
                logger.info(f"DSVA: High Impact ({peak_impact:.1f}) and Silence detected - Prob: {prob}")
            
            # Logic: If signal has sustained high jitter -> PANIC/SHAKE/RUNNING
            elif shake_intensity > self.shake_threshold:
                # Map intensity to probability (Logistic-like sigmoid)
                prob = 1.0 / (1.0 + np.exp(-(shake_intensity - self.shake_threshold)))
                logger.info(f"DSVA: Sustained Jitter ({shake_intensity:.1f}) detected - Prob: {prob}")
            
            # Logic: Normal ambient movement
            else:
                prob = 0.02
                
            return float(prob)
            
        except Exception as e:
            logger.error(f"Error during DSVA inference: {e}")
            return 0.0

# Singleton instance
lstm_predictor = MockLSTMPredictor()
