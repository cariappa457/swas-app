You are an expert full-stack mobile app developer and AI/ML engineer. Build a complete 
"Smart Women Safety Analytics System" mobile application based on the following 
specifications. This is an AI-driven safety app that automatically detects distress 
situations, sends SOS alerts, and predicts high-risk zones in real time.

---

## PROJECT OVERVIEW

App Name: Smart Women Safety Analytics System (SWSAS)
Target Users: Women (primary), Authorities & Emergency Contacts (secondary)
Platform: Android (primary), iOS (secondary)
Core Goal: Proactively detect distress using AI — without requiring manual user input —
and respond instantly via alerts, location sharing, and hotspot warnings.

---

## TECH STACK

Frontend (Mobile App): Flutter (cross-platform) or Android Studio (Java/Kotlin)
Backend: Python (FastAPI or Django REST Framework)
Database: Firebase Firestore (real-time) + PostgreSQL (analytics/historical)
Cloud: Firebase (auth, push notifications, storage) / Google Cloud
ML/AI: TensorFlow Lite (on-device inference), Python scikit-learn / Keras (server-side)
Maps & Location: Google Maps API (geolocation, hotspot visualization)
IoT (optional): ESP32/Arduino with GPS, GSM, accelerometer, heart-rate sensor
Version Control: GitHub

---

## MODULES TO BUILD

### MODULE 1 — USER PROFILE & ONBOARDING
- User registration/login (Firebase Auth — email, phone OTP)
- Profile setup: name, photo, age, emergency contacts (up to 5)
- Consent & privacy settings
- Toggle for: auto-distress detection, microphone access, sensor monitoring
- Trusted contact management (add/remove/notify)

### MODULE 2 — REAL-TIME SENSOR MONITORING
Continuously monitor in the background:
- GPS: live location tracking (high-accuracy mode)
- Accelerometer + Gyroscope: detect sudden falls, erratic movement, abnormal motion
- Microphone: ambient audio monitoring for distress sounds (screaming, crying)
- Heart Rate Sensor (IoT/wearable): spike detection (optional)
- Preprocessing pipeline: noise removal, feature extraction, activity classification

### MODULE 3 — AI DISTRESS DETECTION ENGINE
Train and deploy ML models for:
- Movement anomaly detection (LSTM or Random Forest on accelerometer/gyroscope data)
- Audio distress classification (CNN on MFCC features from microphone input)
- Multi-sensor fusion: combine signals for higher accuracy
- On-device inference using TensorFlow Lite (low battery consumption)
- Confidence threshold logic: only trigger alert above X% confidence
- False positive suppression: cooldown timers, user confirmation prompt

### MODULE 4 — SOS ALERT SYSTEM
Trigger SOS via:
- Auto-detection (AI model)
- Manual: one-tap panic button
- Voice command: "Help me", "SOS", "Emergency"
- Shake gesture (3x rapid shake)

On SOS trigger:
- Send push notification + SMS to all emergency contacts (with live Google Maps link)
- Alert nearest law enforcement (configurable)
- Start audio/video recording (store to Firebase)
- Activate loud buzzer (IoT wearable)
- Display countdown timer with "Cancel" option (15 seconds) to avoid false alarms

### MODULE 5 — LIVE LOCATION SHARING
- Real-time GPS tracking shared with trusted contacts during SOS
- Location history stored securely (encrypted)
- "Share my journey" mode: share route live until destination reached
- Geofence alerts: notify contacts if user enters/exits safe zones

### MODULE 6 — SAFETY HOTSPOT ANALYTICS (Dashboard)
- Crime data ingestion (public datasets + user incident reports)
- ML clustering (K-Means / DBSCAN) to identify high-risk zones
- Heat map visualization on Google Maps
- Time-based risk scoring (hotspots by time of day)
- Safe route suggestions: avoid high-risk areas
- Analytics dashboard (admin/authority view):
  - Incident frequency by area
  - Response time metrics
  - Hotspot trend analysis over time

### MODULE 7 — BACKEND API & INFRASTRUCTURE
REST API endpoints (FastAPI/Django):
- POST /register, /login, /profile
- POST /sos/trigger, /sos/cancel
- GET /location/live/{userId}
- POST /incident/report
- GET /hotspots (returns GeoJSON for map overlay)
- POST /analytics/upload (ML model training data)

Security:
- JWT token-based authentication
- HTTPS enforced
- Encrypted location data at rest and in transit
- GDPR-compliant data retention policies

### MODULE 8 — IoT WEARABLE INTEGRATION (Optional Phase)
- ESP32/Arduino microcontroller
- Sensors: GPS module, GSM module, heart-rate sensor, panic button, buzzer
- Send sensor data to backend via MQTT/HTTP
- Pair with mobile app via Bluetooth
- Panic button triggers SOS independently of phone

---

## KEY FEATURES SUMMARY

| Feature | Description |
|---|---|
| Auto Distress Detection | AI detects emergencies without user input |
| One-Tap SOS | Instant alert to contacts & authorities |
| Voice SOS | Trigger by saying "Help" or "SOS" |
| Live Location | Real-time GPS sharing during emergencies |
| Hotspot Mapping | AI-identified high-risk zones on map |
| Safe Route | Navigation avoiding dangerous areas |
| Journey Sharing | Share live route till destination |
| Incident Reporting | Community-driven safety reports |
| Admin Dashboard | Analytics for authorities |
| IoT Wearable | Standalone emergency device (optional) |

---

## NON-FUNCTIONAL REQUIREMENTS

- Battery efficiency: background monitoring must use < 5% battery/hour
- Response time: SOS alert sent within 3 seconds of detection
- Accuracy: distress detection model > 85% precision, < 10% false positive rate
- Offline mode: SOS via SMS if no internet
- Scalability: support 10,000+ concurrent users
- Privacy: no audio stored unless SOS triggered; clear data deletion option

---

## IMPLEMENTATION PHASES (Build in this order)

Phase 1 — Core App Shell
- Flutter/Android project setup
- Firebase integration (auth, Firestore, push notifications)
- User profile & emergency contact management
- Manual SOS button with alert + SMS

Phase 2 — Sensor & Location
- Background GPS tracking
- Accelerometer/gyroscope data collection
- Google Maps integration (live location, journey sharing)
- Geofencing alerts

Phase 3 — AI/ML Models
- Collect and label sensor data
- Train movement anomaly model (LSTM)
- Train audio distress classifier (CNN + MFCC)
- Export to TensorFlow Lite
- Integrate on-device inference into app

Phase 4 — Hotspot Analytics
- Crime dataset integration
- Clustering model for hotspot detection
- Heat map overlay on Google Maps
- Safe route suggestion logic

Phase 5 — Dashboard & IoT
- Admin analytics dashboard (Flutter Web or React)
- IoT wearable firmware (ESP32)
- Bluetooth pairing with app
- End-to-end testing & security audit
- App Store / Play Store deployment

---

## CONSTRAINTS & PRIORITIES

- Minimize false alerts — implement confirmation dialogs and cooldown logic
- Keep battery drain low — use duty-cycling for background sensors
- Privacy first — microphone only active when app is foregrounded OR user has 
  explicitly enabled background audio monitoring with consent
- Cost target: stay within ₹10,000 – ₹14,000 hardware budget
- Free tier only for cloud services (Firebase free tier, Google Maps limited usage)

---

## DELIVERABLES EXPECTED

1. Flutter/Android mobile app (APK/IPA)
2. Python backend server (deployable on Google Cloud / Railway / Render)
3. TensorFlow Lite ML models (.tflite files)
4. Firebase project configuration
5. Analytics dashboard (web-based)
6. IoT firmware code (ESP32 - optional)
7. GitHub repository with README, setup instructions, and architecture diagram
8. Test report (unit tests, UAT results, model accuracy metrics)

---

Start by scaffolding the project structure, then build Module 1 (User Profile & 
Onboarding) first, followed by Module 4 (SOS Alert System), as these are the 
highest-priority MVP features.