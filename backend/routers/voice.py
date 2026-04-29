from flask import Blueprint, request, jsonify
import speech_recognition as sr

voice_router = Blueprint('voice', __name__)

@voice_router.route('/analyze', methods=['POST'])
def analyze_voice():
    # Microphone input handling logic
    recognizer = sr.Recognizer()
    with sr.Microphone() as source:
        audio = recognizer.listen(source)
    try:
        command = recognizer.recognize_google(audio)
        if "SOS" in command:
            trigger_sos()
        return jsonify({"command": command}), 200
    except sr.UnknownValueError:
        return jsonify({"error": "Could not understand audio"}), 400
    except sr.RequestError as e:
        return jsonify({"error": f"Could not request results; {e}"}), 500

def trigger_sos():
    # Integration with the existing SOS system
    print("SOS triggered!")

@voice_router.route('/upload_audio', methods=['POST'])
def upload_audio():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
    # Process the audio file
    return jsonify({"message": "Audio file processed"}), 200
