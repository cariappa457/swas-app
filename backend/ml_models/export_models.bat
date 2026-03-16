@echo off
echo Preparing Machine Learning environment...
if not exist venv (
    echo Creating python virtual environment...
    python -m venv venv
)
call venv\Scripts\activate.bat
echo Installing dependencies for ML (this might take a few moments)...
pip install -r requirements.txt >nul 2>&1

echo Exporting CNN Audio Distress model...
python model_cnn.py

echo Exporting LSTM Movement Anomaly model...
python model_lstm.py

echo Export complete! Your .tflite files are ready to be integrated into Flutter assets.
