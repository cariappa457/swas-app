from fastapi import APIRouter, File, UploadFile, HTTPException
import speech_recognition as sr
import tempfile
import os
from voice_recognition import VoiceRecognition

router = APIRouter()

def trigger_sos_mock():
    # Integration with the existing SOS system
    print("SOS triggered via voice command!")

@router.post('/analyze')
def analyze_voice():
    """
    Listens to the server's microphone and triggers SOS if keywords are detected.
    Note: Requires PyAudio to be installed.
    """
    recognizer = sr.Recognizer()
    try:
        with sr.Microphone() as source:
            print("Listening for voice commands...")
            audio = recognizer.listen(source, timeout=5, phrase_time_limit=5)
            
        command = recognizer.recognize_google(audio)
        print(f"Recognized command: {command}")
        
        if "sos" in command.lower() or "help" in command.lower():
            trigger_sos_mock()
            
        return {"command": command}
    except sr.UnknownValueError:
        raise HTTPException(status_code=400, detail="Could not understand audio")
    except sr.RequestError as e:
        raise HTTPException(status_code=500, detail=f"Could not request results; {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post('/upload_audio')
async def upload_audio(file: UploadFile = File(...)):
    """
    Accepts an audio file upload (from mobile app) and analyzes it for SOS keywords.
    """
    if not file:
        raise HTTPException(status_code=400, detail="No file part")
    
    try:
        vr = VoiceRecognition()
        
        # Save uploaded file temporarily to process it
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name
            
        result = vr.analyze_audio(tmp_path)
        os.unlink(tmp_path)
        
        if isinstance(result, dict) and result.get("triggered"):
            trigger_sos_mock()
            
        return {"message": "Audio file processed", "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
