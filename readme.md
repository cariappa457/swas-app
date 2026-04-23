# Smart Women Safety App (SWSAS) - Project Audit & Status

## 📌 Overview
This document provides a brutally honest, code-level analysis of the **Smart Women Safety Analytics System (SWSAS)**. It identifies what is functional, what is mocked, and what critical gaps remain for production readiness.

**Current Maturity:** `Alpha / Polished UI Prototype`

---

## 🛠️ Tech Stack (Actual)
*   **Frontend:** Flutter (Dart) - Premium UI with custom animations.
*   **Backend:** FastAPI (Python) - RESTful architecture.
*   **Database:** SQLite (via SQLAlchemy ORM).
*   **Authentication:** Firebase Auth (with `test_token` fallback logic).
*   **External Services:** Twilio (SMS), Google Maps SDK.
*   **Inference:** Python-based mathematical simulation (Standard Deviation thresholding).

---

## ⚖️ Feature Validation (Truth Check)

| Feature | Category | Reality |
| :--- | :--- | :--- |
| **Emergency Calling** | **REAL** | Native Android integration dials **112** directly. |
| **Manual SOS** | **PARTIAL** | DB logging and UI work; Twilio executes if keys are set. |
| **Local SMS (App)** | **PARTIAL** | Launches native SMS app with location; **requires manual Send click**. |
| **Maps & GPS (UI)** | **REAL** | Google Maps SDK renders correctly with active GPS pings. |
| **Safe Navigation** | **MOCK** | Plots straight lines (off-road) via coordinate offsets. |
| **Hotspot Detection** | **MOCK** | Uses `NumPy` to generate randomized "crime" data in Bangalore. |
| **ML Distress Detection** | **DEAD CODE**| Sensor upload logic exists in Backend; **absent in Frontend**. |
| **ML Inference** | **MOCK** | Calculated via standard deviation, not a trained neural network. |

---

## 🚀 Key Execution Flows

### 1. Manual SOS Flow
1.  **Trigger:** User taps & holds the SOS button (UI countdown starts).
2.  **API:** Flutter sends a POST to `/api/sos/trigger-call` with the latest GPS coordinate.
3.  **Backend:** Logs the alert in SQLite and triggers a `BackgroundTasks` SMS worker.
4.  **Twilio:** If configured, an automated SMS is sent to all registered contacts.
5.  **Native Action:** Flutter bypasses dialer for **112** (Direct Call) and launches the SMS app for a secondary manual message.

### 2. Hotspot & Routing Flow
1.  **Hotspots:** Backend generates 60+ "fake" incidents using KMeans clustering to visualize risk zones.
2.  **Routing:** Straight-line paths are drawn between coordinates.
3.  **Safer Route:** The "Safe Route" is a simple geometric offset from the original straight line to avoid red circles.

---

## 🔍 Critical Issues & Risks
> [!WARNING]
> **No Background Persistence**
> The app currently lacks a background service. If the phone is locked or the app is minimized, **tracking and sensor monitoring will stop immediately.**

> [!CAUTION]
> **Authentication Bypass**
> The backend allows a `test_token` fallback, which poses a significant security risk for a safety-critical application.

> [!IMPORTANT]
> **The "Send" Barrier**
> Local device SMS requires the user to manually press "Send" in their messaging app during a panic state.

---

## 📈 Top 5 High-Impact Improvements

1.  **Background Service Integration:** Implement `flutter_background_service` to keep the app alive when locked.
2.  **Live WebSocket Tracking:** Replace static Map links with a live-tracking portal for emergency contacts.
3.  **On-Device ML (TFLite):** Move distress detection to the frontend using TFLite to reduce latency and battery drain.
4.  **Real Directions API:** Integrate Google Maps Directions API to replace straight-line "mock" routing with actual street paths.
5.  **Automated Direct SMS:** Use native SMS direct-send permissions (on Android) to remove the manual "Send" step.

---

## 🛠️ Backend Setup
1. `cd backend`
2. `pip install -r requirements.txt`
3. Configure `.env` with Twilio credentials.
4. `python main.py`

## 🌍 Remote Testing (Partner in a different place)
Since you and your partner are in different locations, you need to expose your local backend to the internet using a **Tunnel**.

### Step 1: Start your Backend
Make sure your backend is running on your computer:
```powershell
cd backend
python main.py
```

### Step 2: Create a Public Tunnel
I recommend using **Ngrok** (it's free and fast):
1.  **Download Ngrok:** [ngrok.com](https://ngrok.com/download)
2.  **Run this command** in a new terminal:
    ```powershell
    ngrok http 8000
    ```
3.  **Copy the "Forwarding" URL** (looks like `https://a1b2-c3d4.ngrok-free.app`).

### Step 3: Update Flutter Config
1.  Open `backend/swsas_frontend/lib/config/environment.dart`.
2.  Paste your Ngrok URL into `tunnelApiBaseUrl`.
3.  Set `useTunnel = true;`.

### Step 4: Push and Test
Push these changes to GitHub. Your partner can then `git pull` and run the app on their phone. It will now connect to your backend across the internet!

---

## 📱 Local Testing (Same Wi-Fi)
If you are ever in the same room:
1.  Set `useTunnel = false;` in `environment.dart`.
2.  The app will use your Local IP (`192.168.31.181`).

## 📱 Frontend Setup
1. `cd backend/swsas_frontend`
2. `flutter pub get`
3. Check `lib/config/environment.dart` for correct API URL.
4. `flutter run`