import speech_recognition as sr

class VoiceRecognition:
    def __init__(self, languages=None):
        self.keywords = ["help", "emergency", "danger"]
        self.languages = languages or ["en-US"]

    def process_audio(self, audio_file):
        recognizer = sr.Recognizer()
        try:
            with sr.AudioFile(audio_file) as source:
                audio_data = recognizer.record(source)
                text = recognizer.recognize_google(audio_data, language=self.languages)
                return text
        except Exception as e:
            return str(e)

    def detect_keywords(self, text):
        detected_keywords = {keyword: text.lower().count(keyword) for keyword in self.keywords if keyword in text.lower()}
        return detected_keywords

    def analyze_audio(self, audio_file):
        text = self.process_audio(audio_file)
        keywords_detected = self.detect_keywords(text)
        confidence_score = self.calculate_confidence(text)
        return {
            "text": text,
            "keywords_detected": keywords_detected,
            "confidence_score": confidence_score,
            "triggered": bool(keywords_detected)
        }

    def calculate_confidence(self, text):
        # Placeholder for confidence calculation logic
        return len(text) / 100.0
