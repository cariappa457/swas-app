import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout

def build_cnn_model(input_shape):
    """
    Builds a CNN model for detecting audio distress calls (screaming, crying) 
    from MFCC spectrogram configurations.
    """
    model = Sequential([
        Conv2D(32, (3, 3), activation='relu', input_shape=input_shape),
        MaxPooling2D((2, 2)),
        Dropout(0.25),
        
        Conv2D(64, (3, 3), activation='relu'),
        MaxPooling2D((2, 2)),
        Dropout(0.25),
        
        Flatten(),
        Dense(128, activation='relu'),
        Dropout(0.5),
        Dense(1, activation='sigmoid') # Binary Output: 1 (Distress Audio), 0 (Normal ambient noise)
    ])
    
    model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
    return model

def export_to_tflite(model, filename="audio_distress.tflite"):
    """
    Exports the trained Sequential model to TensorFlow Lite for on-device inference.
    """
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    
    with open(filename, 'wb') as f:
        f.write(tflite_model)
    print(f"[{filename}] Model exported to TFLite!")

if __name__ == "__main__":
    # Placeholder shape: (128 Mel bands, 128 frames, 1 channel per 2-second clip)
    input_shape = (128, 128, 1)
    
    print("Scaffolding Audio Distress CNN Model...")
    model = build_cnn_model(input_shape)
    model.summary()
    
    print("\nSimulating Export to TFLite...")
    export_to_tflite(model)
