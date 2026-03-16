import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3' # suppres info output
import csv
import json
import random
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout
import numpy as np

def generate_dummy_data(filename="sensor_data.csv", samples=500, timesteps=50, features=6):
    """
    Generate dummy accelerometer and gyroscope time-series data.
    Features: AccX, AccY, AccZ, GyroX, GyroY, GyroZ
    """
    print(f"Generating {samples} labeled sensor readings in {filename}...")
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        header = []
        for t in range(timesteps):
            for i in range(features):
                header.append(f"f_{t}_{i}")
        header.append("label") # 1 for distress, 0 for normal
        writer.writerow(header)
        
        for _ in range(samples):
            # 20% chance of distress simulation
            is_distress = 1 if random.random() < 0.2 else 0
            
            row = []
            if is_distress:
                # Erratic, high amplitude movements (falling, shaking)
                row.extend([random.uniform(-15.0, 15.0) for _ in range(timesteps * features)])
            else:
                # Normal walking/ambient movements
                row.extend([random.uniform(-2.0, 2.0) for _ in range(timesteps * features)])
                
            row.append(is_distress)
            writer.writerow(row)
    print("Dummy dataset generated successfully.")

def load_data(filename="sensor_data.csv", timesteps=50, features=6):
    X = []
    y = []
    with open(filename, 'r') as f:
        reader = csv.reader(f)
        next(reader) # skip header
        for row in reader:
            parsed = [float(v) for v in row]
            label = parsed[-1]
            features_data = parsed[:-1]
            
            x_seq = np.array(features_data).reshape((timesteps, features))
            X.append(x_seq)
            y.append(label)
            
    return np.array(X), np.array(y)

def build_lstm_model(input_shape):
    model = Sequential([
        LSTM(32, return_sequences=True, input_shape=input_shape),
        Dropout(0.2),
        LSTM(16, return_sequences=False),
        Dropout(0.2),
        Dense(8, activation='relu'),
        Dense(1, activation='sigmoid') # Binary Output: 1 (Anomaly/Distress), 0 (Normal)
    ])
    
    model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
    return model

def export_to_tflite(model, filename="movement_anomaly.tflite"):
    print("\nStarting TFLite conversion...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS, 
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    tflite_model = converter.convert()
    with open(filename, 'wb') as f:
        f.write(tflite_model)
    print(f"[{filename}] Model exported to TFLite successfully!")

if __name__ == "__main__":    
    timesteps = 50
    features = 6
    csv_file = "sensor_data.csv"
    
    generate_dummy_data(csv_file, samples=500, timesteps=timesteps, features=features)
    
    X, y = load_data(csv_file, timesteps, features)
    print(f"Loaded training data shape: {X.shape}")
    
    model = build_lstm_model((timesteps, features))
    
    print("\nTraining LSTM Model for 3 epochs with dummy data...")
    model.fit(X, y, epochs=3, batch_size=32, validation_split=0.2)
    
    export_to_tflite(model)
